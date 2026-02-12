import 'package:flutter/material.dart';
import '../../config/theme.dart';

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100, // ความสูงเท่าเดิม
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 20), // ⚠️ ลด Padding ขอบจอลง (เดิม 20)
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, // จัดระยะห่างเท่าๆ กัน
        children: [
          _buildNavItem(0, Icons.receipt_long, "Bill"),     // 1. ค่าใช้จ่ายประจำ
          _buildNavItem(1, Icons.groups, "Unpaid"),         // 2. คนค้างจ่าย (New!)
          _buildNavItem(2, Icons.home_filled, "Home"),      // 3. หน้าหลัก
          _buildNavItem(3, Icons.pie_chart, "Analytics"),   // 4. วิเคราะห์ (New!)
          _buildNavItem(4, Icons.person_outline, "Profile"),// 5. โปรไฟล์
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        // ⚠️ ปรับ Padding ในปุ่มให้เล็กลง เพื่อให้พอดี 5 ปุ่ม
        padding: const EdgeInsets.symmetric(
            horizontal: 12, // เดิม 20 -> ลดเหลือ 12
            vertical: 8
        ),
        decoration: BoxDecoration(
          border: Border.all(
              color: isSelected ? AppColors.primaryGold : Colors.transparent,
              width: 1.5
          ),
          borderRadius: BorderRadius.circular(14), // ลดความมนนิดนึงให้กระชับ
          color: isSelected
              ? AppColors.primaryGold.withOpacity(0.15)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryGold : AppColors.textGrey,
              size: 24, // ลดขนาดไอคอนนิดนึง (เดิม 26)
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primaryGold : AppColors.textGrey,
                fontSize: 10, // ลดขนาดตัวหนังสือ (เดิม 12)
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}