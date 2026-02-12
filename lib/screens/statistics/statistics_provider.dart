// lib/screens/statistics/statistics_provider.dart

import 'package:flutter/material.dart';
import '../../core/utils/tags_helper.dart';
import '../../data/services/database_helper.dart';
import '../../data/models/transaction_model.dart';
import '../../core/utils/category_helper.dart';

enum StatScope { month, year }
enum StatViewType { category, tag }

class StatisticsProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  DateTime selectedDate = DateTime.now();
  StatScope currentScope = StatScope.month;
  StatViewType currentView = StatViewType.category;
  String? selectedDrillDownTag;
  String? selectedMember;

  bool _isFamilyView = false;
  String? _myCreatorId;

  List<TransactionModel> _allTransactions = [];
  List<Map<String, dynamic>> displayStats = [];
  List<Map<String, dynamic>> _customCategories = [];

  double totalExpense = 0.0;
  bool isLoading = false;

  bool get isShowingMemberOverview => _isFamilyView && selectedMember == null;

  StatisticsProvider() {
    loadData();
  }

  void updateViewPreference(bool isFamily, String? myId) {
    if (_isFamilyView != isFamily || _myCreatorId != myId) {
      _isFamilyView = isFamily;
      _myCreatorId = myId;
      selectedMember = null;
      selectedDrillDownTag = null;
      loadData();
    }
  }

  void changeScope(StatScope scope) {
    currentScope = scope;
    selectedDrillDownTag = null;
    selectedMember = null;
    loadData();
  }

  void setDate(DateTime date) {
    selectedDate = date;
    selectedDrillDownTag = null;
    selectedMember = null;
    loadData();
  }

  void selectMember(String memberName) {
    selectedMember = memberName;
    selectedDrillDownTag = null;
    _processData();
    notifyListeners();
  }

  void handleBackPress() {
    if (selectedDrillDownTag != null) {
      selectedDrillDownTag = null;
    } else if (selectedMember != null) {
      selectedMember = null;
    }
    _processData();
    notifyListeners();
  }

  void toggleViewMode(StatViewType type) {
    currentView = type;
    selectedDrillDownTag = null;
    _processData();
    notifyListeners();
  }

  void selectTagToDrillDown(String tagName) {
    selectedDrillDownTag = tagName;
    _processData();
    notifyListeners();
  }

  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();

    _customCategories = await _dbHelper.getCustomCategories();

    List<TransactionModel> rawTxns;
    if (currentScope == StatScope.month) {
      rawTxns = await _dbHelper.getTransactionsByMonth(selectedDate.month, selectedDate.year);
    } else {
      rawTxns = await _dbHelper.getTransactionsByYear(selectedDate.year);
    }

    // ✅ เพิ่มการกรอง: ตัดรายการ "ย้ายเงิน" ออกจาก rawTxns ก่อนนำไปประมวลผล
    rawTxns = rawTxns.where((tx) => tx.category != "ย้ายเงิน").toList();

    if (!_isFamilyView && _myCreatorId != null) {
      _allTransactions = rawTxns.where((tx) {
        if (tx.creatorId == null) return true;
        return tx.creatorId == _myCreatorId;
      }).toList();
    } else {
      _allTransactions = rawTxns;
    }

    _processData();
    isLoading = false;
    notifyListeners();
  }

  void _processData() {
    Map<String, double> grouped = {};
    totalExpense = 0.0;

    if (_isFamilyView && selectedMember == null) {
      for (var tx in _allTransactions) {
        totalExpense += tx.amount;
        String payer = tx.payerName.isEmpty ? "ไม่ระบุ" : tx.payerName;
        grouped[payer] = (grouped[payer] ?? 0) + tx.amount;
      }
    } else {
      List<TransactionModel> targetTxns = _allTransactions;
      if (_isFamilyView && selectedMember != null) {
        targetTxns = _allTransactions.where((tx) => tx.payerName == selectedMember).toList();
      }

      if (currentView == StatViewType.category) {
        for (var tx in targetTxns) {
          grouped[tx.category] = (grouped[tx.category] ?? 0) + tx.amount;
          totalExpense += tx.amount;
        }
      } else {
        if (selectedDrillDownTag != null) {
          totalExpense = 0.0;
          for (var tx in targetTxns) {
            bool hasTag = false;
            if (selectedDrillDownTag == "ทั่วไป") {
              if (tx.tag == null || tx.tag!.trim().isEmpty) hasTag = true;
            } else {
              if (tx.tag != null && tx.tag!.contains(selectedDrillDownTag!)) hasTag = true;
            }
            if (hasTag) {
              grouped[tx.category] = (grouped[tx.category] ?? 0) + tx.amount;
              totalExpense += tx.amount;
            }
          }
        } else {
          double sliceTotal = 0.0;
          for (var tx in targetTxns) {
            if (tx.tag == null || tx.tag!.trim().isEmpty) {
              grouped["ทั่วไป"] = (grouped["ทั่วไป"] ?? 0) + tx.amount;
              sliceTotal += tx.amount;
            } else {
              final tagsList = tx.tag!.split(',');
              for (var tag in tagsList) {
                String cleanTag = tag.trim();
                if (cleanTag.isNotEmpty) {
                  grouped[cleanTag] = (grouped[cleanTag] ?? 0) + tx.amount;
                  sliceTotal += tx.amount;
                }
              }
            }
          }
          if (sliceTotal > 0) totalExpense = sliceTotal;
        }
      }
    }

    displayStats = grouped.entries.map((entry) {
      final percentage = totalExpense == 0 ? 0.0 : (entry.value / totalExpense);
      Map<String, dynamic> info;

      if (_isFamilyView && selectedMember == null) {
        info = {'icon': Icons.person, 'color': _getPersonColor(entry.key)};
      } else {
        bool useCategoryIcon = (currentView == StatViewType.category) || (selectedDrillDownTag != null);
        if (useCategoryIcon) {
          info = CategoryHelper.getCategoryInfo(entry.key, _customCategories);
        } else {
          info = {'icon': Icons.local_offer, 'color': TagsHelper.getColor(entry.key)};
        }
      }

      return {
        'name': entry.key,
        'amount': entry.value,
        'percentage': percentage,
        'color': info['color'],
        'icon': info['icon'],
      };
    }).toList();

    displayStats.sort((a, b) => b['amount'].compareTo(a['amount']));
  }

  Color _getPersonColor(String name) {
    final colors = [Colors.blue, Colors.pink, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.redAccent];
    return colors[name.hashCode.abs() % colors.length];
  }
}