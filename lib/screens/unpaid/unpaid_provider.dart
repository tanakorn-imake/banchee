import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/database_helper.dart';

class UnpaidProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<TransactionModel> _unpaidTransactions = [];
  bool _isLoading = true;
  String _currentUserName = "เรา";

  List<TransactionModel> get unpaidTransactions => _unpaidTransactions;
  bool get isLoading => _isLoading;
  String get currentUserName => _currentUserName;

  double get totalUnpaidAmount {
    double total = 0;
    for (var txn in _unpaidTransactions) {
      // วนลูปเช็คทุกคน ยกเว้นคนแรก (Index 0 = เรา)
      for (int i = 1; i < txn.splitWith.length; i++) {
        final person = txn.splitWith[i];
        if (!person.isCleared) {
          total += person.amount;
        }
      }
    }
    return total;
  }

  Future<void> loadUnpaidData() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _currentUserName = prefs.getString('user_name') ?? "เรา";

    // ✅ ดึง Device ID ของเรามาเช็คความเป็นเจ้าของ
    final myDeviceId = prefs.getString('device_id') ?? 'unknown';

    final allSplits = await _dbHelper.getAllSplitTransactions();

    // ✅✅✅ แก้ไข Logic การกรองตรงนี้:
    _unpaidTransactions = allSplits.where((txn) {

      // 1. เช็คว่าเป็นบิลของเราหรือไม่? (ถ้าไม่ใช่ของฉัน ก็ไม่ต้องโชว์)
      // (creatorId == null คือรองรับข้อมูลเก่า)
      bool isMyBill = (txn.creatorId == myDeviceId) || (txn.creatorId == null);

      if (!isMyBill) {
        return false; // ข้ามไปเลย ไม่ต้องสนใจ
      }

      // 2. ถ้าเป็นบิลเรา แล้วมีคนอื่นค้างจ่ายไหม?
      bool hasOtherDebtors = false;
      for (int i = 1; i < txn.splitWith.length; i++) {
        if (!txn.splitWith[i].isCleared) {
          hasOtherDebtors = true;
          break;
        }
      }
      return hasOtherDebtors;
    }).toList();

    _isLoading = false;
    notifyListeners();
  }
}