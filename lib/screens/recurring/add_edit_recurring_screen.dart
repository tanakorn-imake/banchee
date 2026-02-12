import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../data/models/recurring_bill_model.dart';
import 'recurring_provider.dart';

class AddEditRecurringScreen extends StatefulWidget {
  final RecurringBillModel? bill;

  const AddEditRecurringScreen({super.key, this.bill});

  @override
  State<AddEditRecurringScreen> createState() => _AddEditRecurringScreenState();
}

class _AddEditRecurringScreenState extends State<AddEditRecurringScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _dayController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.bill?.title ?? '');
    _amountController = TextEditingController(text: widget.bill?.amount.toString() ?? '');
    _dayController = TextEditingController(text: widget.bill?.dayOfMonth.toString() ?? DateTime.now().day.toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.bill == null ? "เพิ่มรายการประจำ" : "แก้ไขรายการ", style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          // ✅ เพิ่ม: ปุ่มลบ (แสดงเฉพาะตอนแก้ไข)
          if (widget.bill != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // แสดง Dialog ยืนยันการลบ
                showDialog(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text("ยืนยันการลบ", style: TextStyle(color: Colors.white)),
                    content: Text("ต้องการลบรายการ '${widget.bill!.title}' หรือไม่?", style: const TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text("ยกเลิก", style: TextStyle(color: Colors.white54))),
                      TextButton(
                        onPressed: () {
                          // สั่งลบผ่าน Provider
                          context.read<RecurringProvider>().deleteBill(widget.bill!.id);
                          Navigator.pop(dCtx); // ปิด Dialog
                          Navigator.pop(context); // ปิดหน้าแก้ไข กลับไปหน้าหลัก
                        },
                        child: const Text("ลบ", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'ชื่อรายการ (เช่น ค่าหอ)',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (val) => val!.isEmpty ? 'กรุณากรอกชื่อ' : null,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _dayController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'จ่ายทุกวันที่',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        suffixText: 'ของเดือน',
                        suffixStyle: const TextStyle(color: Colors.white30),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'ระบุวัน';
                        final day = int.tryParse(val);
                        if (day == null || day < 1 || day > 31) return '1-31 เท่านั้น';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'จำนวนเงิน',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        prefixText: '฿ ',
                        prefixStyle: const TextStyle(color: AppColors.primaryGold),
                      ),
                      validator: (val) => val!.isEmpty ? 'ระบุเงิน' : null,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final title = _titleController.text;
                      final amount = double.parse(_amountController.text);
                      final day = int.parse(_dayController.text);

                      if (widget.bill == null) {
                        context.read<RecurringProvider>().addBill(title, amount, day);
                      } else {
                        final updatedBill = widget.bill!.copyWith(
                          title: title,
                          amount: amount,
                          dayOfMonth: day,
                        );
                        context.read<RecurringProvider>().editBill(updatedBill);
                      }
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("บันทึก", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}