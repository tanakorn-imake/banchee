import 'dart:convert';

class SplitEntry {
  final String name;
  final double amount;
  final bool isLocked;
  final bool isCleared;

  SplitEntry({
    required this.name,
    required this.amount,
    this.isLocked = false,
    this.isCleared = false,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'amount': amount,
    'isLocked': isLocked ? 1 : 0,
    'isCleared': isCleared ? 1 : 0,
  };

  factory SplitEntry.fromMap(Map<String, dynamic> map) {
    return SplitEntry(
      name: map['name'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      isLocked: (map['isLocked'] == 1 || map['isLocked'] == true),
      isCleared: (map['isCleared'] == 1 || map['isCleared'] == true),
    );
  }

  SplitEntry copyWith({String? name, double? amount, bool? isLocked, bool? isCleared}) {
    return SplitEntry(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      isLocked: isLocked ?? this.isLocked,
      isCleared: isCleared ?? this.isCleared,
    );
  }
}

class TransactionModel {
  final String id;
  final double amount;
  final DateTime date;
  final String category;
  final String note;
  final String? receiptPath;
  final String? tag;
  final String? creatorId;
  final String payerName;
  final String? recipientName; // ✅ เพิ่มชื่อผู้รับโอน
  final String deviceId;
  final bool isSplitBill;
  final List<SplitEntry> splitWith;
  final bool isSynced;
  final bool isDeleted;
  final DateTime lastUpdated;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.date,
    required this.category,
    this.note = '',
    this.receiptPath,
    this.tag,
    this.creatorId,
    required this.payerName,
    this.recipientName, // ✅
    required this.deviceId,
    this.isSplitBill = false,
    this.splitWith = const [],
    this.isSynced = false,
    this.isDeleted = false,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'note': note,
      'receiptPath': receiptPath,
      'tag': tag,
      'creatorId': creatorId,
      'payerName': payerName,
      'recipientName': recipientName, // ✅
      'deviceId': deviceId,
      'isSplitBill': isSplitBill ? 1 : 0,
      'splitWith': jsonEncode(splitWith.map((e) => e.toMap()).toList()),
      'isSynced': isSynced ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    List<SplitEntry> loadedSplits = [];
    if (map['splitWith'] != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(map['splitWith']);
        loadedSplits = jsonList.map((e) => SplitEntry.fromMap(e)).toList();
      } catch (_) {}
    }
    return TransactionModel(
      id: map['id'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      category: map['category'],
      note: map['note'] ?? '',
      receiptPath: map['receiptPath'],
      tag: map['tag'],
      creatorId: map['creatorId'],
      payerName: map['payerName'],
      recipientName: map['recipientName'], // ✅
      deviceId: map['deviceId'],
      isSplitBill: (map['isSplitBill'] ?? 0) == 1,
      splitWith: loadedSplits,
      isSynced: (map['isSynced'] ?? 0) == 1,
      isDeleted: (map['isDeleted'] ?? 0) == 1,
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }

  Map<String, dynamic> toCloudJson() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'note': note,
      'tag': tag,
      'creatorId': creatorId,
      'payerName': payerName,
      'recipientName': recipientName, // ✅ ส่งขึ้น Cloud ด้วย
      'deviceId': deviceId,
      'isSplitBill': isSplitBill,
      'splitWith': jsonEncode(splitWith.map((e) => e.toMap()).toList()),
      'isDeleted': isDeleted,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory TransactionModel.fromCloudJson(Map<String, dynamic> json) {
    List<SplitEntry> parseSplits(dynamic raw) {
      if (raw == null) return [];
      try {
        if (raw is String) {
          final List<dynamic> list = jsonDecode(raw);
          return list.map((e) => SplitEntry.fromMap(e)).toList();
        } else if (raw is List) {
          return raw.map((e) => SplitEntry.fromMap(e)).toList();
        }
      } catch (_) {}
      return [];
    }

    return TransactionModel(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      category: json['category'],
      note: json['note'] ?? '',
      receiptPath: null,
      tag: json['tag'],
      creatorId: json['creatorId'],
      payerName: json['payerName'],
      recipientName: json['recipientName'], // ✅
      deviceId: json['deviceId'],
      isSplitBill: json['isSplitBill'] == true || json['isSplitBill'] == 1,
      splitWith: parseSplits(json['splitWith']),
      isSynced: true,
      isDeleted: json['isDeleted'] == true || json['isDeleted'] == 1,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

  TransactionModel copyWith({
    String? id,
    double? amount,
    DateTime? date,
    String? category,
    String? note,
    String? receiptPath,
    String? tag,
    String? creatorId,
    String? payerName,
    String? recipientName, // ✅
    String? deviceId,
    bool? isSplitBill,
    List<SplitEntry>? splitWith,
    bool? isSynced,
    bool? isDeleted,
    DateTime? lastUpdated,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      note: note ?? this.note,
      receiptPath: receiptPath ?? this.receiptPath,
      tag: tag ?? this.tag,
      creatorId: creatorId ?? this.creatorId,
      payerName: payerName ?? this.payerName,
      recipientName: recipientName ?? this.recipientName, // ✅
      deviceId: deviceId ?? this.deviceId,
      isSplitBill: isSplitBill ?? this.isSplitBill,
      splitWith: splitWith ?? this.splitWith,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}