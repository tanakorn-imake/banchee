import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/recurring_bill_model.dart';
import '../../data/services/database_helper.dart';

class RecurringProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<RecurringBillModel> _bills = [];
  bool _isLoading = true;

  List<RecurringBillModel> get bills => _bills;
  bool get isLoading => _isLoading;

  double get totalAmount => _bills.fold(0, (sum, item) => sum + item.amount);
  double get paidAmount => _bills.where((item) => item.isPaid).fold(0, (sum, item) => sum + item.amount);
  double get progress => totalAmount == 0 ? 0 : paidAmount / totalAmount;

  Future<void> loadBills() async {
    _isLoading = true;
    notifyListeners();
    _bills = await _dbHelper.getAllRecurringBills();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleBillStatus(String id) async {
    final index = _bills.indexWhere((item) => item.id == id);
    if (index != -1) {
      final updatedBill = _bills[index].copyWith(isPaid: !_bills[index].isPaid);
      _bills[index] = updatedBill;
      notifyListeners();
      await _dbHelper.updateRecurringBill(updatedBill);
    }
  }

  // ✨ รับ day แทน category
  Future<void> addBill(String title, double amount, int day) async {
    final newBill = RecurringBillModel(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      dayOfMonth: day,
      isPaid: false,
    );
    await _dbHelper.createRecurringBill(newBill);
    await loadBills();
  }

  Future<void> editBill(RecurringBillModel bill) async {
    await _dbHelper.updateRecurringBill(bill);
    await loadBills();
  }

  Future<void> deleteBill(String id) async {
    await _dbHelper.deleteRecurringBill(id);
    await loadBills();
  }
}