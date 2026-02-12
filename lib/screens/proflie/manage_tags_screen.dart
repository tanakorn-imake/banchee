import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../core/utils/tags_helper.dart';
import '../../data/services/database_helper.dart';

class ManageTagsScreen extends StatefulWidget {
  const ManageTagsScreen({super.key});

  @override
  State<ManageTagsScreen> createState() => _ManageTagsScreenState();
}

class _ManageTagsScreenState extends State<ManageTagsScreen> {
  List<String> _tags = [];
  bool _isLoading = true;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    final tags = await DatabaseHelper.instance.getAllTags();
    setState(() {
      _tags = tags;
      _isLoading = false;
    });
  }

  Future<void> _addTag() async {
    if (_controller.text.trim().isEmpty) return;
    String newTag = _controller.text.trim();

    // เติม # ให้อัตโนมัติถ้า user ลืม
    if (!newTag.startsWith('#')) {
      newTag = '#$newTag';
    }

    // ป้องกันการเพิ่มแท็กซ้ำ
    if (_tags.contains(newTag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("มีแท็กนี้อยู่แล้ว")),
      );
      return;
    }

    await DatabaseHelper.instance.addTag(newTag);
    _controller.clear();
    _loadTags(); // โหลดใหม่
  }

  Future<void> _deleteTag(String name) async {
    await DatabaseHelper.instance.deleteTag(name);
    _loadTags(); // โหลดใหม่
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
        centerTitle: true,
        title: const Text(
            "จัดการแท็ก",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ส่วนเพิ่มแท็ก + คำแนะนำ ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "เช่น #ทริปญี่ปุ่น, #เบิกบริษัท",
                          hintStyle: const TextStyle(color: Colors.white24),
                          fillColor: AppColors.background,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _addTag,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(15),
                      ),
                      child: const Icon(Icons.add, color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Helper Text ช่วยสอน User
                const Text(
                  "💡 ทริค: ใช้แท็กระบุ 'กิจกรรม' หรือ 'ใคร' เพื่อแยกดูยอดรวมจากหมวดหมู่ปกติ",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- รายการแท็ก ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
                : _tags.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.style_outlined, size: 60, color: Colors.white24),
                  SizedBox(height: 10),
                  Text("ยังไม่มีแท็ก", style: TextStyle(color: Colors.white54)),
                  Text("ลองเพิ่ม #งานแต่ง หรือ #แฟน ดูสิ", style: TextStyle(color: Colors.white24, fontSize: 12)),
                ],
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _tags.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final tag = _tags[index];

                // ✅ เรียกใช้สีจาก Helper (เพื่อให้สีเหมือนกันทุกหน้า)
                final color = TagsHelper.getColor(tag);

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    // เส้นขอบสีจางๆ ตามสีแท็ก
                    border: Border.all(color: color.withOpacity(0.3), width: 1),
                  ),
                  child: ListTile(
                    // ไอคอนวงกลมสี
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2), // พื้นหลังไอคอนโปร่งแสง
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.local_offer_rounded, color: color, size: 20),
                    ),
                    title: Text(
                        tag,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white30),
                      onPressed: () => _deleteTag(tag),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}