// lib/screens/analytics/Overview_provider.dart

import 'package:flutter/material.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/database_helper.dart';
import '../../core/utils/category_helper.dart'; // ✅ แนะนำให้ import ตัวนี้เพื่อใช้สีให้ตรงกัน (ถ้ามี)

class CategorySummary {
  final String name;
  final double amount;
  final double percentage;
  final Color color;
  final IconData icon;

  CategorySummary({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.icon,
  });
}

class AnalyticsProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<CategorySummary> _categories = [];
  double _totalExpense = 0;
  bool _isLoading = true;

  // ✅ เพิ่มตัวแปรโหลด custom category
  List<Map<String, dynamic>> _customCategories = [];

  List<CategorySummary> get categories => _categories;
  double get totalExpense => _totalExpense;
  bool get isLoading => _isLoading;

  Future<void> loadMonthlyAnalytics(int month, int year) async {
    _isLoading = true;
    notifyListeners();

    // โหลด Custom Category มาด้วย (เพื่อให้สีตรงกันถ้าคุณใช้ CategoryHelper)
    _customCategories = await _dbHelper.getCustomCategories();

    List<TransactionModel> txns = await _dbHelper.getTransactionsByMonth(month, year);

    // ✅ เพิ่มการกรอง: ตัดรายการ "ย้ายเงิน" ออกจากลิสต์
    txns = txns.where((t) => t.category != "ย้ายเงิน").toList();

    _totalExpense = txns.fold(0, (sum, item) => sum + item.amount);

    Map<String, double> groupMap = {};
    for (var txn in txns) {
      groupMap[txn.category] = (groupMap[txn.category] ?? 0) + txn.amount;
    }

    _categories = groupMap.entries.map((entry) {
      final double percent = _totalExpense == 0 ? 0 : (entry.value / _totalExpense);

      // ✅ เปลี่ยนไปใช้ CategoryHelper เพื่อให้รองรับ Custom Category และสีที่ถูกต้อง
      final info = CategoryHelper.getCategoryInfo(entry.key, _customCategories);

      return CategorySummary(
        name: entry.key,
        amount: entry.value,
        percentage: percent,
        color: info['color'] as Color,
        icon: info['icon'] as IconData,
      );
    }).toList();

    _categories.sort((a, b) => b.amount.compareTo(a.amount));

    _isLoading = false;
    notifyListeners();
  }
}