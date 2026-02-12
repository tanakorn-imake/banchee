import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../data/models/recurring_bill_model.dart';
import 'recurring_provider.dart';
import 'add_edit_recurring_screen.dart';

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecurringProvider()..loadBills(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          title: const Text(
            "ค่าใช้จ่ายประจำเดือน",
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.more_vert, color: AppColors.primaryGold),
                onPressed: () {},
              ),
            )
          ],
        ),
        body: Consumer<RecurringProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryGold));
            }

            return Column(
              children: [
                _buildSummaryCard(provider),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("รายการค่าใช้จ่าย", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      Text("${provider.bills.length} รายการ", style: const TextStyle(color: AppColors.primaryGold)),
                    ],
                  ),
                ),
                Expanded(
                  child: provider.bills.isEmpty
                      ? const Center(child: Text("ยังไม่มีรายการ", style: TextStyle(color: Colors.white54)))
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: provider.bills.length,
                    itemBuilder: (context, index) {
                      final bill = provider.bills[index];

                      // ✅ แก้ไข: ใช้ GestureDetector ดักการกด (Tap) เพื่อไปหน้าแก้ไข
                      return GestureDetector(
                        onTap: () {
                          // ไปหน้าแก้ไข พร้อมส่งข้อมูล bill และ provider เดิมไป
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: provider,
                                child: AddEditRecurringScreen(bill: bill),
                              ),
                            ),
                          ).then((_) {
                            if (context.mounted) provider.loadBills();
                          });
                        },
                        child: _buildBillItem(context, bill, provider),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        final recurringProvider = context.read<RecurringProvider>();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: recurringProvider,
                              child: const AddEditRecurringScreen(),
                            ),
                          ),
                        ).then((_) {
                          if (context.mounted) recurringProvider.loadBills();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.black),
                          SizedBox(width: 8),
                          Text("เพิ่มรายการ", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(RecurringProvider provider) {
    bool isPaidAll = provider.totalAmount > 0 && provider.paidAmount >= provider.totalAmount;
    Color statusColor = isPaidAll ? const Color(0xFF4CAF50) : const Color(0xFFE53935);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPaidAll ? const Color(0xFF4CAF50).withOpacity(0.5) : Colors.white10,
        ),
        boxShadow: isPaidAll ? [
          BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.2), blurRadius: 10)
        ] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text("ยอดที่ต้องจ่ายทั้งหมด", style: TextStyle(color: Colors.white54, fontSize: 12)),
              SizedBox(width: 10),
              Text("/", style: TextStyle(color: Colors.white24, fontSize: 12)),
              SizedBox(width: 10),
              Text("จ่ายแล้ว", style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "฿${provider.totalAmount.toStringAsFixed(0)}",
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text("/", style: TextStyle(color: Colors.white24, fontSize: 20)),
              ),
              Text(
                "${provider.paidAmount.toStringAsFixed(0)}",
                style: TextStyle(color: statusColor, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: provider.progress,
                    backgroundColor: Colors.black45,
                    color: isPaidAll ? const Color(0xFF4CAF50) : AppColors.primaryGold,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "${(provider.progress * 100).toStringAsFixed(0)}%",
                style: TextStyle(color: isPaidAll ? const Color(0xFF4CAF50) : Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillItem(BuildContext context, RecurringBillModel bill, RecurringProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryGold.withOpacity(0.5)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("วันที่", style: TextStyle(color: Colors.white54, fontSize: 10)),
                Text(
                  "${bill.dayOfMonth}",
                  style: const TextStyle(color: AppColors.primaryGold, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Icon(_getIconFromTitle(bill.title), size: 12, color: Colors.white54),
                    const SizedBox(width: 4),
                    const Text("รายเดือน", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Text(
            "฿${bill.amount.toStringAsFixed(0)}",
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: () => provider.toggleBillStatus(bill.id),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: bill.isPaid ? AppColors.primaryGold : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryGold,
                  width: 2,
                ),
              ),
              child: bill.isPaid
                  ? const Icon(Icons.check, size: 16, color: Colors.black)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconFromTitle(String title) {
    if (title.contains("หอ") || title.contains("บ้าน")) return Icons.home;
    if (title.contains("เน็ต") || title.contains("wifi")) return Icons.wifi;
    if (title.contains("โทร")) return Icons.phone_iphone;
    if (title.contains("ไฟ")) return Icons.electric_bolt;
    if (title.contains("น้ำ")) return Icons.water_drop;
    if (title.contains("บัตร")) return Icons.credit_card;
    if (title.contains("งวด") || title.contains("รถ")) return Icons.directions_car;
    if (title.contains("เรียน") || title.contains("เทอม")) return Icons.school;
    return Icons.receipt;
  }
// ❌ ลบฟังก์ชัน _showOptionsDialog ทิ้งไปแล้ว
}