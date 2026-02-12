import 'package:flutter/material.dart';
import '../../config/theme.dart';

class CategoryHelper {
  // --- 1. กำหนดชุดสี Soft Palette (พาสเทล/ตุ่น) เพื่อความสบายตา ---
  static const Color softOrange = Color(0xFFFFAB91); // อาหาร (ส้มแซลมอน)
  static const Color softBrown = Color(0xFFA1887F);  // เครื่องดื่ม (น้ำตาลลาเต้)
  static const Color softPink = Color(0xFFF48FB1);   // ชอปปิ้ง (ชมพูอ่อน)
  static const Color softBlue = Color(0xFF90CAF9);   // เดินทาง (ฟ้าพาสเทล)
  static const Color softPurple = Color(0xFFCE93D8); // บันเทิง (ม่วงอ่อน)
  static const Color softTeal = Color(0xFF80CBC4);   // ค่าบ้าน (เขียวอมฟ้า)
  static const Color softRed = Color(0xFFEF9A9A);    // บิล/รายจ่าย (แดงอ่อน)
  static const Color softGreen = Color(0xFFA5D6A7);  // สุขภาพ (เขียวใบชา)
  static const Color softIndigo = Color(0xFF9FA8DA); // การศึกษา (คราม)
  static const Color softLime = Color(0xFFE6EE9C);   // ลงทุน (เขียวมะนาว)
  static const Color softCyan = Color(0xFF80DEEA);   // ย้ายเงิน (ฟ้าทะเล)
  static const Color softGrey = Color(0xFFB0BEC5);   // อื่นๆ (เทา)

  // สีเพิ่มเติมสำหรับให้ User เลือก (Custom Colors)
  static const Color softYellow = Color(0xFFFFF59D);
  static const Color softDeepPurple = Color(0xFFB39DDB);

  // --- 2. รายการหมวดหมู่เริ่มต้น (ใช้สีชุดใหม่) ---
  static final List<Map<String, dynamic>> defaultCategories = [
    {'name': 'อาหาร', 'icon': Icons.restaurant, 'color': softOrange},
    {'name': 'เครื่องดื่ม', 'icon': Icons.local_cafe, 'color': softBrown},
    {'name': 'ชอปปิ้ง', 'icon': Icons.shopping_bag, 'color': softPink},
    {'name': 'เดินทาง', 'icon': Icons.directions_car, 'color': softBlue},
    {'name': 'บันเทิง', 'icon': Icons.movie, 'color': softPurple},
    {'name': 'ค่าบ้าน', 'icon': Icons.home, 'color': softTeal},
    {'name': 'บิลค่าน้ำ/ไฟ', 'icon': Icons.receipt_long, 'color': softRed},
    {'name': 'สุขภาพ', 'icon': Icons.local_hospital, 'color': softGreen},
    {'name': 'การศึกษา', 'icon': Icons.school, 'color': softIndigo},
    {'name': 'ลงทุน', 'icon': Icons.trending_up, 'color': softLime},
    {'name': 'ย้ายเงิน', 'icon': Icons.sync_alt, 'color': softCyan},
    {'name': 'รายจ่าย', 'icon': Icons.payments, 'color': softRed},
    {'name': 'อื่นๆ', 'icon': Icons.category, 'color': softGrey},
  ];

  // --- 3. รายการไอคอนทั้งหมด (รวมของเดิม + ของใหม่) ---
  // ใช้สำหรับหน้า "เพิ่มหมวดหมู่"
  static final List<IconData> selectableIcons = [
    // กลุ่ม 1: ไอคอนพื้นฐาน (จาก Default Categories)
    Icons.restaurant, Icons.local_cafe, Icons.shopping_bag, Icons.directions_car,
    Icons.movie, Icons.home, Icons.receipt_long, Icons.local_hospital,
    Icons.school, Icons.trending_up, Icons.sync_alt, Icons.payments,
    Icons.category,

    // กลุ่ม 2: ไอคอนไลฟ์สไตล์ (เพิ่มเติม)
    Icons.star, Icons.favorite, Icons.pets, Icons.gamepad,
    Icons.flight, Icons.fitness_center, Icons.work, Icons.child_care,
    Icons.card_giftcard, Icons.bolt, Icons.water_drop, Icons.wifi,
    Icons.music_note, Icons.build, Icons.smartphone, Icons.local_gas_station,
    Icons.bed, Icons.directions_bike, Icons.fastfood, Icons.local_bar,
  ];

  // --- 4. รายการสีสำหรับให้เลือก ---
  static final List<Color> selectableColors = [
    softOrange, softBrown, softPink, softBlue,
    softPurple, softTeal, softRed, softGreen,
    softIndigo, softLime, softCyan, softYellow,
    softDeepPurple, softGrey,
  ];

  // ฟังก์ชันดึงข้อมูลหมวดหมู่ (เหมือนเดิม แต่รองรับสีใหม่)
  static Map<String, dynamic> getCategoryInfo(String categoryName, List<Map<String, dynamic>> customCategories) {
    try {
      final custom = customCategories.firstWhere((element) => element['name'] == categoryName);
      return {
        'icon': custom['icon'] is IconData ? custom['icon'] : IconData(custom['iconCode'], fontFamily: 'MaterialIcons'),
        'color': custom['color'] is Color ? custom['color'] : Color(custom['colorValue']),
      };
    } catch (e) {
      try {
        final def = defaultCategories.firstWhere((element) => element['name'] == categoryName);
        return def;
      } catch (e) {
        return {'icon': Icons.category, 'color': softGrey};
      }
    }
  }
}