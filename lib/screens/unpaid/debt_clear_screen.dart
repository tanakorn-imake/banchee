import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../data/models/transaction_model.dart';
import '../add_edit/add_edit_provider.dart';
import '../add_edit/add_edit_screen.dart'; // ยังคง import ไว้เผื่อใช้ในอนาคต

class DebtClearScreen extends StatelessWidget {
  final TransactionModel transaction;
  final bool isReadOnly; // ✅ 1. เพิ่มตัวแปรนี้

  const DebtClearScreen({
    super.key,
    required this.transaction,
    this.isReadOnly = false, // ค่า Default คือแก้ได้
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddEditProvider()..initData(transaction),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          // ✅ 2. เปลี่ยน Title ตามโหมด
          title: Text(
            isReadOnly ? "รายละเอียด (ดูอย่างเดียว)" : "จัดการยอดค้าง",
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: Consumer<AddEditProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildSummaryCard(provider),
                        const SizedBox(height: 20),

                        if (provider.receiptPath != null)
                          _buildReceiptView(context, provider.receiptPath!),

                        const SizedBox(height: 20),

                        // ✅ 3. ใช้ AbsorbPointer ห้ามติ๊ก ถ้าเป็น ReadOnly
                        AbsorbPointer(
                          absorbing: isReadOnly,
                          child: _buildDebtorList(provider),
                        ),
                      ],
                    ),
                  ),
                ),

                // ✅ 4. ซ่อนปุ่มอัปเดต ถ้าเป็น ReadOnly
                if (!isReadOnly)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(top: BorderSide(color: Colors.white10)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: provider.isLoading
                            ? null
                            : () async {
                          final success = await provider
                              .saveTransaction(transaction);
                          if (success && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: provider.isLoading
                            ? const CircularProgressIndicator(
                            color: Colors.black)
                            : const Text("อัปเดตยอด",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )
              ],
            );
          },
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildSummaryCard(AddEditProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ยอดรวม",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  Text("฿${provider.amountController.text}",
                      style: const TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: provider.selectedColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(provider.categoryIcon,
                    color: provider.selectedColor, size: 28),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.notes, color: Colors.white54, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  provider.noteController.text.isEmpty
                      ? "-"
                      : provider.noteController.text,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptView(BuildContext context, String path) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          // ✅ เรียกใช้คลาสที่สร้างไว้ด้านล่างไฟล์นี้
          MaterialPageRoute(
              builder: (_) => _LocalFullScreenImageView(imagePath: path)),
        );
      },
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(path), fit: BoxFit.cover),
              Container(color: Colors.black38),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, color: Colors.white),
                    SizedBox(width: 8),
                    Text("ดูสลิป",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebtorList(AddEditProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text("รายชื่อคนหาร",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: provider.splitPeople.asMap().entries.map((entry) {
              final index = entry.key;
              final person = entry.value;
              final isMe = index == 0;

              if (isMe) return const SizedBox.shrink();

              return Column(
                children: [
                  if (index > 1)
                    const Divider(color: Colors.white10, height: 1),
                  InkWell(
                    onTap: () {
                      provider.togglePersonCleared(index, !person.isCleared);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.white10,
                                  child: Text(person.name[0],
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12)),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(person.name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    Text("฿${person.amount.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                            color: AppColors.primaryGold,
                                            fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: person.isCleared
                                  ? const Color(0xFF4CAF50)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: person.isCleared
                                      ? const Color(0xFF4CAF50)
                                      : Colors.white24,
                                  width: 2),
                            ),
                            child: person.isCleared
                                ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ✅ เพิ่ม Class นี้ไว้ท้ายไฟล์ เพื่อแก้ปัญหา Undefined name และให้ใช้งานได้ทันที
class _LocalFullScreenImageView extends StatelessWidget {
  final String imagePath;
  const _LocalFullScreenImageView({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context))),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.white54, size: 50),
                  SizedBox(height: 10),
                  Text("ไม่สามารถแสดงรูปภาพได้",
                      style: TextStyle(color: Colors.white54))
                ]),
          ),
        ),
      ),
    );
  }
}