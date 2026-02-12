import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../core/utils/tags_helper.dart';
import '../../data/models/transaction_model.dart';
import 'add_edit_provider.dart';

class AddEditScreen extends StatelessWidget {
  final TransactionModel? transaction;
  final bool isReadOnly; // โหมดดูอย่างเดียว

  const AddEditScreen({super.key, this.transaction, this.isReadOnly = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddEditProvider()..initData(transaction),
      child: Consumer<AddEditProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              centerTitle: true,
              title: Text(
                isReadOnly
                    ? "รายละเอียด (ดูอย่างเดียว)"
                    : (transaction == null ? "เพิ่มรายการ" : "แก้ไขรายการ"),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              actions: [
                // ซ่อนปุ่มลบ ถ้าเป็นโหมด ReadOnly
                if (transaction != null && !isReadOnly)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: const Text("ยืนยันการลบ",
                              style: TextStyle(color: Colors.white)),
                          content: const Text(
                              "คุณต้องการลบรายการนี้ใช่หรือไม่?",
                              style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("ยกเลิก",
                                  style: TextStyle(color: Colors.white54)),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                final success = await provider
                                    .deleteTransaction(transaction!.id);
                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text("ลบ",
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),

            // ✅✅✅ แก้ไข: เอา SingleChildScrollView ออกมาข้างนอก
            // เพื่อให้สามารถเลื่อนหน้าจอได้ แม้จะอยู่ในโหมด Read Only
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AbsorbPointer(
                // ✅ เอา AbsorbPointer ไปครอบเนื้อหาข้างในแทน
                // ผล: เลื่อนดูได้ แต่จิ้มแก้ไขไม่ได้
                absorbing: isReadOnly,
                child: Column(
                  children: [
                    _buildAmountInput(provider),
                    const SizedBox(height: 20),
                    _buildCategoryAndTagSelector(context, provider),
                    const SizedBox(height: 20),
                    _buildNoteInput(provider),
                    const SizedBox(height: 20),
                    _buildReceiptSection(context, provider),
                    const SizedBox(height: 20),
                    _buildSplitSection(context, provider),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // ซ่อนปุ่ม Save ด้านล่าง ถ้า ReadOnly
            bottomNavigationBar: isReadOnly
                ? const SizedBox.shrink()
                : Container(
              padding: const EdgeInsets.only(
                  left: 20, right: 20, bottom: 30, top: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, -5)),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                      final success = await provider
                          .saveTransaction(transaction);
                      if (success && context.mounted)
                        Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: provider.isLoading
                        ? const CircularProgressIndicator(
                        color: Colors.black)
                        : const Text("บันทึกรายการ",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Widgets ---

  Widget _buildAmountInput(AddEditProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Amount", style: TextStyle(color: Colors.white54)),
          TextField(
            controller: provider.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
            decoration: const InputDecoration(
              prefixText: "฿ ",
              prefixStyle: TextStyle(
                  color: AppColors.primaryGold,
                  fontSize: 40,
                  fontWeight: FontWeight.bold),
              border: InputBorder.none,
              hintText: "0.00",
              hintStyle: TextStyle(color: Colors.white24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAndTagSelector(
      BuildContext context, AddEditProvider provider) {
    final Color tagColor = TagsHelper.getColor(provider.selectedTag);

    return Row(
      children: [
        Expanded(
          flex: 6,
          child: GestureDetector(
            onTap: () => _showCategoryModal(context, provider),
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: provider.selectedColor.withOpacity(0.5), width: 2),
              ),
              child: Row(
                children: [
                  Icon(provider.categoryIcon,
                      color: provider.selectedColor, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("หมวดหมู่",
                            style:
                            TextStyle(color: Colors.white54, fontSize: 10)),
                        Text(provider.category,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white54),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 4,
          child: GestureDetector(
            onTap: () => _showTagModal(context, provider),
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tagColor.withOpacity(0.5), width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_offer, color: tagColor, size: 16),
                      const SizedBox(width: 5),
                      const Text("แท็ก",
                          style:
                          TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.selectedTag ?? "ทั่วไป",
                    style: TextStyle(
                        color: tagColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteInput(AddEditProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Note", style: TextStyle(color: Colors.white54)),
          TextField(
            controller: provider.noteController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Add a note...",
                hintStyle: TextStyle(color: Colors.white24)),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptSection(BuildContext context, AddEditProvider provider) {
    if (provider.receiptPath == null) {
      return GestureDetector(
        onTap: () => provider.pickReceiptImage(),
        child: Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.primaryGold.withOpacity(0.5),
                width: 1,
                style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo, color: AppColors.primaryGold, size: 40),
              const SizedBox(height: 10),
              Text("เพิ่มรูปสลิป / ใบเสร็จ",
                  style: TextStyle(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _LocalFullScreenImageView(
                    imagePath: provider.receiptPath!),
                fullscreenDialog: true,
              ),
            );
          },
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(provider.receiptPath!),
                key: ValueKey(provider.receiptPath),
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            decoration: BoxDecoration(
                color: Colors.black54, borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  onPressed: () => provider.pickReceiptImage(),
                ),
                Container(width: 1, height: 20, color: Colors.white24),
                IconButton(
                  icon: const Icon(Icons.delete,
                      color: Colors.redAccent, size: 20),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text("ลบรูปภาพ?",
                            style: TextStyle(color: Colors.white)),
                        content: const Text("คุณต้องการลบรูปภาพนี้ใช่หรือไม่",
                            style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("ยกเลิก",
                                  style: TextStyle(color: Colors.white54))),
                          TextButton(
                              onPressed: () {
                                provider.removeReceiptImage();
                                Navigator.pop(ctx);
                              },
                              child: const Text("ลบ",
                                  style: TextStyle(color: Colors.redAccent))),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSplitSection(BuildContext context, AddEditProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [
                Icon(Icons.groups, color: AppColors.primaryGold),
                SizedBox(width: 15),
                Text("หารรายการนี้",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold))
              ]),
              Switch(
                  value: provider.isSplitBill,
                  onChanged: (val) => provider.toggleSplitBill(val),
                  activeColor: AppColors.primaryGold,
                  activeTrackColor:
                  AppColors.primaryGold.withOpacity(0.3)),
            ],
          ),
          if (provider.isSplitBill) ...[
            const Divider(color: Colors.white10, height: 30),
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: Text("ชื่อ",
                          style:
                          TextStyle(color: Colors.white54, fontSize: 12))),
                  SizedBox(width: 10),
                  Expanded(
                      flex: 1,
                      child: Text("ยอดเงิน",
                          style:
                          TextStyle(color: Colors.white54, fontSize: 12),
                          textAlign: TextAlign.end)),
                  SizedBox(width: 10),
                  Text("จ่าย",
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  SizedBox(width: 10),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.splitPeople.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final person = provider.splitPeople[index];
                final isMe = index == 0;
                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: provider.nameControllers[index],
                        readOnly: isMe,
                        style: TextStyle(
                            color: isMe ? AppColors.primaryGold : Colors.white),
                        decoration: InputDecoration(
                          hintText: "ชื่อ",
                          hintStyle: const TextStyle(color: Colors.white24),
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          filled: true,
                          fillColor: isMe
                              ? AppColors.primaryGold.withOpacity(0.1)
                              : AppColors.background,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none),
                        ),
                        onChanged: (val) =>
                            provider.updatePersonName(index, val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: provider.amountControllers[index],
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                            color: person.isLocked
                                ? AppColors.primaryGold
                                : Colors.white),
                        textAlign: TextAlign.end,
                        decoration: InputDecoration(
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: person.isLocked
                                  ? const BorderSide(
                                  color: AppColors.primaryGold)
                                  : BorderSide.none),
                        ),
                        onChanged: (val) =>
                            provider.updatePersonAmount(index, val),
                      ),
                    ),
                    const SizedBox(width: 5),
                    if (isMe)
                      const SizedBox(width: 40)
                    else
                      SizedBox(
                          width: 40,
                          child: Checkbox(
                              value: person.isCleared,
                              activeColor: const Color(0xFF4CAF50),
                              onChanged: (val) => provider
                                  .togglePersonCleared(index, val),
                              side: const BorderSide(
                                  color: Colors.white24, width: 2),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)))),
                    if (!isMe)
                      GestureDetector(
                          onTap: () => provider.removePerson(index),
                          child: const Icon(Icons.remove_circle,
                              color: Colors.red, size: 20)),
                  ],
                );
              },
            ),
            const SizedBox(height: 15),
            TextButton.icon(
                onPressed: () => provider.addPerson(),
                icon: const Icon(Icons.add_circle,
                    color: AppColors.primaryGold),
                label: const Text("เพิ่มเพื่อน",
                    style: TextStyle(color: AppColors.primaryGold))),
          ],
        ],
      ),
    );
  }

  // Helpers for Modals
  void _showTagModal(BuildContext parentContext, AddEditProvider provider) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text("เลือกแท็ก",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (provider.availableTags.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                      "ยังไม่ได้สร้างแท็ก (ไปสร้างที่หน้า Profile)",
                      style: TextStyle(color: Colors.white38)),
                ),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.close,
                          color: AppColors.primaryGold),
                      title: const Text("ทั่วไป / ไม่ใส่แท็ก",
                          style: TextStyle(color: AppColors.primaryGold)),
                      onTap: () {
                        provider.setTag(null);
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(color: Colors.white10),
                    ...provider.availableTags.map((tag) {
                      final isSelected = tag == provider.selectedTag;
                      final tagColor = TagsHelper.getColor(tag);

                      return ListTile(
                        leading: Icon(Icons.local_offer, color: tagColor),
                        title: Text(tag,
                            style: TextStyle(
                                color: isSelected ? tagColor : Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        trailing: isSelected
                            ? Icon(Icons.check, color: tagColor)
                            : null,
                        onTap: () {
                          provider.setTag(tag);
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryModal(
      BuildContext parentContext, AddEditProvider provider) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, controller) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 20),
                    const Text("เลือกหมวดหมู่",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.builder(
                        controller: controller,
                        itemCount: provider.availableCategories.length,
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 20,
                            childAspectRatio: 0.8),
                        itemBuilder: (ctx, index) {
                          final cat = provider.availableCategories[index];
                          final isSelected = cat['name'] == provider.category;
                          return GestureDetector(
                            onTap: () {
                              provider.setCategory(
                                  cat['name'], cat['icon'], cat['color']);
                              Navigator.pop(context);
                            },
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                      color: isSelected
                                          ? cat['color'].withOpacity(0.8)
                                          : cat['color'].withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: isSelected
                                              ? AppColors.primaryGold
                                              : Colors.transparent,
                                          width: 2)),
                                  child: Icon(cat['icon'],
                                      color: isSelected
                                          ? Colors.white
                                          : cat['color'],
                                      size: 28),
                                ),
                                const SizedBox(height: 8),
                                Text(cat['name'],
                                    style: TextStyle(
                                        color: isSelected
                                            ? AppColors.primaryGold
                                            : Colors.white70,
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            });
      },
    );
  }
}

// Class สำหรับดูรูปภาพแบบเต็มจอ
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