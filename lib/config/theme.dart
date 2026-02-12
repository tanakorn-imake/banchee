// lib/config/theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // สีจากรูปที่คุณให้มา
  static const Color background = Color(0xFF1E1E1E); // ดำเทา
  static const Color surface = Color(0xFF2C2C2C);    // เทาเข้มขึ้นมาหน่อย (ไว้ทำ Card)
  static const Color primaryGold = Color(0xFFD4AF37); // ทองหลัก
  static const Color secondaryGold = Color(0xFFC9A332); // ทองเข้ม
  static const Color lightGold = Color(0xFFE5C158);   // ทองสว่าง
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGrey = Color(0xFF9CA3AF);
  static const Color error = Color(0xFFB00020);
}

class AppTheme {
  static ThemeData get darkLuxury {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryGold,

      // ตั้งค่า Font และ Text Theme เบื้องต้น
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: AppColors.textWhite),
        bodyMedium: TextStyle(color: AppColors.textWhite),
      ),

      // ตั้งค่า Input Field (ช่องกรอกข้อมูล) ให้ดูแพง
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: TextStyle(color: AppColors.textGrey),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryGold.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder:  OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryGold),
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ปุ่มกดสีทอง
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          foregroundColor: Colors.black, // ตัวหนังสือบนปุ่มสีดำ
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}