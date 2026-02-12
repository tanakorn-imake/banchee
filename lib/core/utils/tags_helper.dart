import 'package:flutter/material.dart';

import '../../config/theme.dart';

class TagsHelper {
  // ชุดสี 12 เฉด (Pastel Palette)
  static final List<Color> _tagColors = [
    const Color(0xFFE57373), // Red
    const Color(0xFFF06292), // Pink
    const Color(0xFFBA68C8), // Purple
    const Color(0xFF9575CD), // Deep Purple
    const Color(0xFF7986CB), // Indigo
    const Color(0xFF64B5F6), // Blue
    const Color(0xFF4FC3F7), // Light Blue
    const Color(0xFF4DB6AC), // Teal
    const Color(0xFF81C784), // Green
    const Color(0xFFDCE775), // Lime
    const Color(0xFFFFD54F), // Amber
    const Color(0xFFFFB74D), // Orange
  ];

  // ฟังก์ชันเรียกใช้สีจากชื่อแท็ก
  static Color getColor(String? tagName) {
    // ✅ แก้ไข: ถ้าเป็น null, ว่าง, หรือ "ทั่วไป" ให้ใช้สีทอง
    if (tagName == null || tagName.trim().isEmpty || tagName == 'ทั่วไป') {
      return AppColors.primaryGold;
    }

    // ถ้ามีชื่อแท็ก ให้สุ่มสีตาม HashCode
    return _tagColors[tagName.hashCode.abs() % _tagColors.length];
  }
}