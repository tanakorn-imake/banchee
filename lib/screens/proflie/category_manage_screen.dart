import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../data/services/database_helper.dart';
import '../../core/utils/category_helper.dart'; // ✅ Import Helper

class CategoryManageScreen extends StatefulWidget {
  const CategoryManageScreen({super.key});

  @override
  State<CategoryManageScreen> createState() => _CategoryManageScreenState();
}

class _CategoryManageScreenState extends State<CategoryManageScreen> {
  // ✅ ใช้รายการ Default จาก Helper โดยตรง (สีจะได้เหมือนกันเป๊ะ)
  final List<Map<String, dynamic>> _defaultCategories = CategoryHelper.defaultCategories;

  List<Map<String, dynamic>> _customCategories = []; // โหลดจาก DB
  List<Map<String, dynamic>> _allCategories = []; // รวมร่าง

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final dbData = await DatabaseHelper.instance.getCustomCategories();

    setState(() {
      _customCategories = dbData.map((data) {
        return {
          'id': data['id'],
          'name': data['name'],
          'icon': IconData(data['iconCode'], fontFamily: 'MaterialIcons'),
          'color': Color(data['colorValue']),
          'isCustom': true,
        };
      }).toList();

      _allCategories = [..._defaultCategories, ..._customCategories];
    });
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
        title: const Text("จัดการหมวดหมู่", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15
        ),
        itemCount: _allCategories.length + 1,
        itemBuilder: (context, index) {
          if (index == _allCategories.length) {
            return _buildAddButton();
          }
          return _buildCategoryCard(_allCategories[index]);
        },
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    bool isCustom = cat['isCustom'] == true;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // ใช้สีจากข้อมูลโดยตรง
                  color: (cat['color'] as Color).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(cat['icon'] as IconData, color: cat['color'], size: 28),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  cat['name'],
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (isCustom)
          Positioned(
            top: 5, right: 5,
            child: GestureDetector(
              onTap: () async {
                await DatabaseHelper.instance.deleteCustomCategory(cat['id']);
                _loadCategories();
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          )
      ],
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _showAddDialog,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryGold, style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.primaryGold, size: 35),
            SizedBox(height: 5),
            Text("เพิ่มใหม่", style: TextStyle(color: AppColors.primaryGold)),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();

    // ตั้งค่าเริ่มต้น (เอาตัวแรกจาก Helper มาโชว์)
    Color selectedColor = CategoryHelper.selectableColors[0];
    IconData selectedIcon = CategoryHelper.selectableIcons[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text("เพิ่มหมวดหมู่", style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "ชื่อหมวดหมู่",
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryGold)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text("เลือกไอคอน:", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),

                    // ✅ แสดงรายการไอคอนทั้งหมด (รวมของเก่า + ของใหม่) จาก Helper
                    Container(
                      height: 150, // จำกัดความสูงให้เลื่อนได้ ถ้าไอคอนเยอะ
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 12, runSpacing: 12,
                          children: CategoryHelper.selectableIcons.map((icon) {
                            bool isSelected = selectedIcon == icon;
                            return GestureDetector(
                              onTap: () => setDialogState(() => selectedIcon = icon),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected ? selectedColor : Colors.white10,
                                  shape: BoxShape.circle,
                                  border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                                ),
                                child: Icon(
                                    icon,
                                    color: isSelected ? Colors.white : Colors.white54,
                                    size: 24
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text("เลือกสี:", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),

                    // ✅ แสดงรายการสีทั้งหมด (Soft Palette) จาก Helper
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: CategoryHelper.selectableColors.map((color) {
                        bool isSelected = selectedColor == color;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = color),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                            ),
                            child: CircleAvatar(backgroundColor: color, radius: 14),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ยกเลิก", style: TextStyle(color: Colors.white54))),
                TextButton(
                  onPressed: () async {
                    if (nameCtrl.text.isNotEmpty) {
                      final newId = const Uuid().v4();
                      await DatabaseHelper.instance.addCustomCategory(
                          newId,
                          nameCtrl.text,
                          selectedIcon.codePoint,
                          selectedColor.value
                      );

                      if (mounted) {
                        _loadCategories(); // รีเฟรชหน้าจอ
                        Navigator.pop(ctx);
                      }
                    }
                  },
                  child: const Text("สร้างเลย", style: TextStyle(color: AppColors.primaryGold)),
                ),
              ],
            );
          }
      ),
    );
  }
}