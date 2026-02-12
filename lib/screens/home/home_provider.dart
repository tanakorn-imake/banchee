// lib/screens/home/home_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/database_helper.dart';
import '../../data/services/sync_service.dart';
import '../../data/services/auto_slip_manager.dart';

class HomeProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<TransactionModel> _transactions = [];
  double _totalExpense = 0;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  String _currentUserName = "";

  // ตัวแปรสำหรับ View Toggle
  bool _isFamilyView = false;
  String? _myCreatorId;

  // ตัวแปรเช็คสถานะ
  bool _isInitialized = false;
  bool _isSyncing = false;

  List<Map<String, dynamic>> _customCategories = [];

  // Getters
  List<TransactionModel> get transactions => _transactions;
  double get totalExpense => _totalExpense;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;
  String get currentUserName => _currentUserName;
  List<Map<String, dynamic>> get customCategories => _customCategories;

  // ==========================================================
  // ⚙️ BUSINESS LOGIC (ส่วนประมวลผลข้อมูล)
  // ==========================================================

  /// ✅ ฟังก์ชันประมวลผลสลิป: จัดการเรื่อง Loading และการบันทึก DB
  // เพิ่ม parameter onProgress
  Future<int> processIncomingSlips(List<SlipCandidate> slips, {Function(int current, int total)? onProgress}) async {
    // _isLoading = true; // เอาออก เพราะจะใช้ Dialog แสดงผลแทน
    // notifyListeners();

    final manager = AutoSlipManager();
    int savedCount = 0;

    try {
      // ส่ง onProgress ต่อไปให้ manager
      savedCount = await manager.processAndSaveSlips(slips, onProgress: onProgress);

      if (savedCount > 0) {
        await loadData();
      }
    } catch (e) {
      debugPrint("Error in HomeProvider.processIncomingSlips: $e");
    } finally {
      // _isLoading = false;
      // notifyListeners();
    }

    return savedCount;
  }

  // รับค่า Config จากหน้า Home
  void setViewConfig(bool isFamily, String? creatorId) {
    if (!_isInitialized || _isFamilyView != isFamily || _myCreatorId != creatorId) {
      _isInitialized = true;
      _isFamilyView = isFamily;
      _myCreatorId = creatorId;
      initData();
    }
  }

  void changeDate(DateTime newDate) {
    _selectedDate = newDate;
    loadData();
  }

  void changeMonth(int offset) {
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + offset, 1);
    loadData();
  }

  Future<void> initData() async {
    await loadData();
    // ❌ ลบ _silentSync() ออก เพื่อไม่ให้ดึงข้อมูลอัตโนมัติทุกครั้งที่เข้าแอป
  }

  /// ✅ ฟังก์ชันใหม่: ดึงข้อมูลครอบครัวจาก Cloud (ทำงานเฉพาะเมื่อ user สั่ง)
  Future<void> pullFamilyData() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners(); // แจ้ง UI เผื่อต้องการแสดงสถานะ Loading เพิ่มเติม

    try {
      final syncService = SyncService();
      await syncService.pullTransactions();
      await loadData();
    } catch (e) {
      debugPrint("Cloud Sync Failed: $e");
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserName = prefs.getString('user_name') ?? "Me";

    _customCategories = await _dbHelper.getCustomCategories();
    List<TransactionModel> allTxns = await _dbHelper.getTransactionsByMonth(_selectedDate.month, _selectedDate.year);

    // Filter ตามมุมมอง (ส่วนตัว / ครอบครัว)
    if (!_isFamilyView && _myCreatorId != null) {
      _transactions = allTxns.where((tx) {
        if (tx.creatorId == null) return true;
        return tx.creatorId == _myCreatorId;
      }).toList();
    } else {
      _transactions = allTxns;
    }

    // ✅ คำนวณยอดรวม โดยไม่นับหมวด "ย้ายเงิน"
    _totalExpense = 0;
    for (var tx in _transactions) {
      if (tx.category != "ย้ายเงิน") {
        _totalExpense += tx.amount;
      }
    }

    // เรียงลำดับวันที่ใหม่ไปเก่า
    _transactions.sort((a, b) => b.date.compareTo(a.date));

    _isLoading = false;
    notifyListeners();
  }
}