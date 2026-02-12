// lib/screens/unpaid/unpaid_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/view_preference_provider.dart';
import '../add_edit/add_edit_screen.dart';
import 'debt_clear_screen.dart';
import 'unpaid_provider.dart';

class UnpaidScreen extends StatelessWidget {
  const UnpaidScreen({super.key});

  final Color _pendingColorStart = const Color(0xFFFF8F00);
  final Color _pendingColorEnd = const Color(0xFFFF6F00);
  final Color _pendingAccent = const Color(0xFFFFB300);
  final Color _clearedColor = const Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    // ❌ ลบ ChangeNotifierProvider ตรงนี้ออก!
    // เพราะเราสร้างไว้ที่ MainWrapper แล้ว ให้เรียกใช้ Scaffold เลย

    // ✅ เรียก load ครั้งแรกกรณีที่ยังไม่เคยโหลด (Optional: กันเหนียว)
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (context.read<UnpaidProvider>().unpaidTransactions.isEmpty) {
    //      context.read<UnpaidProvider>().loadUnpaidData();
    //   }
    // });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("ติดตามหนี้สิน", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      // ✅ ใช้ Consumer รับค่าจาก MainWrapper โดยตรง
      body: Consumer<UnpaidProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryGold));
          }

          return RefreshIndicator(
            color: AppColors.primaryGold,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              await provider.loadUnpaidData();
            },
            child: provider.unpaidTransactions.isEmpty
                ? _buildEmptyStateScrollable(context)
                : Column(
              children: [
                _buildTotalUnpaidCard(provider.totalUnpaidAmount),
                Expanded(
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: provider.unpaidTransactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final txn = provider.unpaidTransactions[index];
                      return _buildUnpaidCard(context, txn, provider);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ... (ส่วนฟังก์ชันอื่นๆ _buildTotalUnpaidCard, _buildEmptyStateScrollable, _buildUnpaidCard คงเดิม) ...

  Widget _buildTotalUnpaidCard(double total) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_pendingColorStart, _pendingColorEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: _pendingColorEnd.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.hourglass_top_rounded, color: Colors.white.withOpacity(0.8), size: 18),
                  const SizedBox(width: 8),
                  const Text("ยอดเงินรอเก็บ", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text("จากเพื่อนๆ ทั้งหมด", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
            ],
          ),
          Text(
            "฿${total.toStringAsFixed(0)}",
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateScrollable(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: _clearedColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle_rounded, size: 80, color: _clearedColor),
                    ),
                    const SizedBox(height: 30),
                    const Text("เคลียร์หมดแล้ว!", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text(
                      "ไม่มีรายการค้างรับจากเพื่อนๆ\n(ลากลงเพื่อรีเฟรชข้อมูล)",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }

  Widget _buildUnpaidCard(BuildContext context, TransactionModel txn, UnpaidProvider provider) {
    final debtorList = [];
    for (int i = 1; i < txn.splitWith.length; i++) {
      if (!txn.splitWith[i].isCleared) {
        debtorList.add(txn.splitWith[i]);
      }
    }

    if (debtorList.isEmpty) return const SizedBox.shrink();

    double amountPending = debtorList.fold(0, (sum, p) => sum + p.amount);
    final myCreatorId = Provider.of<ViewPreferenceProvider>(context, listen: false).myCreatorId;
    bool isMyBill = txn.creatorId == myCreatorId || txn.creatorId == null; // null คือข้อมูลเก่า offline ถือเป็นของเรา
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DebtClearScreen(transaction: txn,
              isReadOnly: !isMyBill)),
        ).then((_) {
          // ใช้ provider ตัวเดิมที่ส่งเข้ามา
          if (context.mounted) provider.loadUnpaidData();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _pendingAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.receipt_long, color: _pendingAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(txn.category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      if (txn.note.isNotEmpty)
                        Text(txn.note, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("ค้างรับ", style: TextStyle(color: _pendingAccent, fontSize: 12)),
                    Text("฿${amountPending.toStringAsFixed(0)}", style: TextStyle(color: _pendingAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                )
              ],
            ),
            Divider(color: Colors.white.withOpacity(0.05), height: 24),

            ...debtorList.map((person) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(radius: 10, backgroundColor: Colors.white10, child: Icon(Icons.person, size: 12, color: Colors.white70)),
                  const SizedBox(width: 8),
                  Text(person.name, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const Spacer(),
                  Text("฿${person.amount.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
            )),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    DateFormat('dd MMM yy').format(txn.date),
                    style: const TextStyle(color: Colors.white24, fontSize: 12)
                ),
                Row(
                  children: [
                    Text("จัดการ", style: TextStyle(color: _pendingAccent, fontSize: 12)),
                    Icon(Icons.chevron_right, color: _pendingAccent, size: 16)
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}