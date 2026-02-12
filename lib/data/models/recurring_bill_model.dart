class RecurringBillModel {
  final String id;
  final String title;
  final double amount;
  final int dayOfMonth; // ✨ เปลี่ยนจาก category เป็น วันที่ (1-31)
  final bool isPaid;

  RecurringBillModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.dayOfMonth,
    this.isPaid = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dayOfMonth': dayOfMonth,
      'isPaid': isPaid ? 1 : 0,
    };
  }

  factory RecurringBillModel.fromMap(Map<String, dynamic> map) {
    return RecurringBillModel(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      dayOfMonth: map['dayOfMonth'] ?? 1, // กัน Error
      isPaid: (map['isPaid'] ?? 0) == 1,
    );
  }

  RecurringBillModel copyWith({
    String? id,
    String? title,
    double? amount,
    int? dayOfMonth,
    bool? isPaid,
  }) {
    return RecurringBillModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}