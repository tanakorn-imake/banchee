import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../core/utils/category_helper.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/database_helper.dart';

class AddEditProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  // State
  String _category = 'อาหาร';
  IconData _categoryIcon = Icons.restaurant;
  Color _selectedColor = AppColors.primaryGold;

  DateTime _date = DateTime.now();
  String? _receiptPath;

  // จำ Tag
  String? _selectedTag;
  List<String> _availableTags = [];

  // จำชื่อผู้รับและคนสร้าง
  String? _recipientName;
  String? _creatorId;

  bool _isSplitBill = false;
  bool _isLoading = false;
  String? _error;

  // ➗ State หารเงิน
  List<SplitEntry> _splitPeople = [];
  String _myName = 'เรา';

  List<TextEditingController> nameControllers = [];
  List<TextEditingController> amountControllers = [];

  // Getters
  String get category => _category;
  IconData get categoryIcon => _categoryIcon;
  Color get selectedColor => _selectedColor;
  DateTime get date => _date;
  String? get receiptPath => _receiptPath;

  String? get selectedTag => _selectedTag;
  List<String> get availableTags => _availableTags;

  bool get isSplitBill => _isSplitBill;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<SplitEntry> get splitPeople => _splitPeople;

  List<Map<String, dynamic>> availableCategories = [];

  Future<void> initData(TransactionModel? txn) async {
    final prefs = await SharedPreferences.getInstance();
    _myName = prefs.getString('user_name') ?? 'เรา';

    // 1. โหลด Categories
    final dbData = await _dbHelper.getCustomCategories();
    final customCats = dbData.map((data) => {
      'name': data['name'],
      'icon': IconData(data['iconCode'], fontFamily: 'MaterialIcons'),
      'color': Color(data['colorValue']),
    }).toList();
    availableCategories = [...CategoryHelper.defaultCategories, ...customCats];

    // 2. โหลด Tags จาก DB
    _availableTags = await _dbHelper.getAllTags();

    if (txn != null) {
      if (txn.isSplitBill && txn.splitWith.isNotEmpty) {
        double totalBill = txn.splitWith.fold(0, (sum, item) => sum + item.amount);
        amountController.text = totalBill == totalBill.roundToDouble()
            ? totalBill.toInt().toString()
            : totalBill.toString();
      } else {
        amountController.text = txn.amount == txn.amount.roundToDouble()
            ? txn.amount.toInt().toString()
            : txn.amount.toString();
      }

      noteController.text = txn.note;
      _category = txn.category;
      _date = txn.date;
      _receiptPath = txn.receiptPath;

      // โหลดค่าเดิมมาเก็บไว้
      _selectedTag = txn.tag;
      _recipientName = txn.recipientName;
      _creatorId = txn.creatorId;

      _isSplitBill = txn.isSplitBill;
      _splitPeople = txn.splitWith.map((e) => e.copyWith()).toList();
      _updateCategoryDetails(txn.category);
    } else {
      _updateCategoryDetails('อาหาร');
      _selectedTag = null;
      _recipientName = null;
      _creatorId = null;
      _splitPeople = [SplitEntry(name: _myName, amount: 0)];
    }

    // กรณีแก้ไขรายการ ให้เช็คว่ายอดรวมตรงกันไหม
    if (txn == null && amountController.text.isNotEmpty) {
      double total = double.tryParse(amountController.text) ?? 0;
      if (_splitPeople.isNotEmpty) {
        _splitPeople[0] = _splitPeople[0].copyWith(amount: total);
      }
    }

    _syncControllers();
    amountController.addListener(_recalculateSplit);
    notifyListeners();
  }

  @override
  void dispose() {
    amountController.removeListener(_recalculateSplit);
    amountController.dispose();
    noteController.dispose();
    for (var c in nameControllers) c.dispose();
    for (var c in amountControllers) c.dispose();
    super.dispose();
  }

  void _syncControllers() {
    while (nameControllers.length < _splitPeople.length) {
      nameControllers.add(TextEditingController());
      amountControllers.add(TextEditingController());
    }
    while (nameControllers.length > _splitPeople.length) {
      nameControllers.last.dispose();
      amountControllers.last.dispose();
      nameControllers.removeLast();
      amountControllers.removeLast();
    }

    for (int i = 0; i < _splitPeople.length; i++) {
      if (nameControllers[i].text != _splitPeople[i].name) {
        nameControllers[i].text = _splitPeople[i].name;
      }
      String amountStr = _splitPeople[i].amount.toStringAsFixed(2);
      if (double.tryParse(amountControllers[i].text) != _splitPeople[i].amount) {
        amountControllers[i].text = amountStr;
      }
    }
  }

  void setTag(String? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  void toggleSplitBill(bool value) {
    _isSplitBill = value;
    if (_isSplitBill) {
      if (_splitPeople.isEmpty) {
        double totalAmount = double.tryParse(amountController.text) ?? 0;
        _splitPeople.add(SplitEntry(name: _myName, amount: totalAmount));
      } else {
        _splitPeople[0] = _splitPeople[0].copyWith(name: _myName);
      }
      _syncControllers();
      _recalculateSplit();
    }
    notifyListeners();
  }

  void addPerson() {
    int nextNum = _splitPeople.length;
    _splitPeople.add(SplitEntry(name: 'คนที่ $nextNum', amount: 0, isLocked: false));
    _syncControllers();
    _recalculateSplit();
    notifyListeners();
  }

  void removePerson(int index) {
    if (index == 0) return;
    if (_splitPeople.length > 1) {
      _splitPeople.removeAt(index);
      _syncControllers();
      _recalculateSplit();
      notifyListeners();
    }
  }

  void togglePersonCleared(int index, bool? value) {
    if (index == 0) return;
    _splitPeople[index] = _splitPeople[index].copyWith(isCleared: value ?? false);
    notifyListeners();
  }

  void updatePersonAmount(int index, String value) {
    double? newAmount = double.tryParse(value);
    if (newAmount == null) return;
    _splitPeople[index] = _splitPeople[index].copyWith(
      amount: newAmount,
      isLocked: true,
    );
    _recalculateSplit(skipIndex: index);
  }

  void updatePersonName(int index, String newName) {
    _splitPeople[index] = _splitPeople[index].copyWith(name: newName);
  }

  void _recalculateSplit({int? skipIndex}) {
    if (!_isSplitBill || _splitPeople.isEmpty) return;

    double totalAmount = double.tryParse(amountController.text) ?? 0;
    double lockedTotal = 0;
    int unlockedCount = 0;

    for (int i = 0; i < _splitPeople.length; i++) {
      if (_splitPeople[i].isLocked) {
        lockedTotal += _splitPeople[i].amount;
      } else {
        unlockedCount++;
      }
    }

    double remainingAmount = totalAmount - lockedTotal;
    if (remainingAmount < 0) remainingAmount = 0;

    for (int i = 0; i < _splitPeople.length; i++) {
      if (!_splitPeople[i].isLocked) {
        double share = unlockedCount > 0 ? remainingAmount / unlockedCount : 0;
        _splitPeople[i] = _splitPeople[i].copyWith(amount: share);

        if (i != skipIndex) {
          String newText = share.toStringAsFixed(2);
          if (amountControllers[i].text != newText) {
            amountControllers[i].text = newText;
          }
        }
      }
    }
  }

  Future<void> pickReceiptImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        _receiptPath = image.path;
        notifyListeners();
      }
    } catch (e) {
      print("❌ Error picking image: $e");
    }
  }

  void removeReceiptImage() {
    _receiptPath = null;
    notifyListeners();
  }

  void setCategory(String name, IconData icon, Color color) {
    _category = name;
    _categoryIcon = icon;
    _selectedColor = color;
    notifyListeners();
  }

  Future<bool> saveTransaction(TransactionModel? existingTxn) async {
    if (amountController.text.isEmpty) {
      _error = "กรุณาระบุจำนวนเงิน";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id') ?? 'unknown';
      final payerName = prefs.getString('user_name') ?? 'Me';
      final double totalInputAmount = double.parse(amountController.text);

      double mainExpenseAmount = totalInputAmount;

      if (_isSplitBill && _splitPeople.isNotEmpty) {
        mainExpenseAmount = _splitPeople[0].amount;
      }

      // ✅ FIX: หา creatorId ที่ถูกต้อง
      // 1. ถ้ามีของเดิม (_creatorId) ใช้ของเดิม
      // 2. ถ้าแก้ไขรายการ (existingTxn) ใช้ของ existingTxn
      // 3. ถ้าไม่มีทั้งคู่ (สร้างใหม่) ให้ใช้ deviceId ของเครื่องนี้ทันที
      String finalCreatorId = _creatorId ?? existingTxn?.creatorId ?? deviceId;

      final txn = TransactionModel(
        id: existingTxn?.id ?? const Uuid().v4(),
        amount: mainExpenseAmount,
        date: _date,
        category: _category,
        note: noteController.text,
        receiptPath: _receiptPath,
        tag: _selectedTag,
        recipientName: _recipientName,

        // ใส่ ID ที่หามาได้ลงไป (แก้ปัญหา Read Only)
        creatorId: finalCreatorId,

        payerName: payerName,
        deviceId: deviceId,
        isSplitBill: _isSplitBill,
        splitWith: _isSplitBill ? _splitPeople : [],
        isSynced: false,
        isDeleted: false,
      );

      if (existingTxn == null) {
        await _dbHelper.createTransaction(txn);
      } else {
        await _dbHelper.updateTransaction(txn);
      }

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(String transactionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _dbHelper.deleteTransaction(transactionId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print("❌ เกิดข้อผิดพลาดตอนลบ: $e");
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _updateCategoryDetails(String catName) {
    if (availableCategories.isEmpty) return;
    final categoryData = availableCategories.firstWhere(
          (element) => element['name'] == catName,
      orElse: () => availableCategories.first,
    );
    _category = categoryData['name'];
    _categoryIcon = categoryData['icon'];
    _selectedColor = categoryData['color'];
  }
}