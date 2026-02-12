import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewPreferenceProvider extends ChangeNotifier {
  // ค่าเริ่มต้น: ให้เป็นโหมดส่วนตัว (false) เพื่อความปลอดภัย
  bool _isFamilyView = false;
  String? _myCreatorId;

  bool get isFamilyView => _isFamilyView;
  String? get myCreatorId => _myCreatorId;

  ViewPreferenceProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. จำค่าล่าสุดที่เลือกไว้ (เปิดแอปมาจะได้ไม่งง)
    _isFamilyView = prefs.getBool('is_family_view') ?? false;

    // 2. ดึง ID ตัวจริงของเรา
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _myCreatorId = user.uid;
    } else {
      _myCreatorId = prefs.getString('device_id');
    }

    notifyListeners();
  }

  // ✅ แก้ไข: ใช้ชื่อ toggleView เพื่อให้ตรงกับที่เรียกใช้
  void toggleView(bool value) async {
    _isFamilyView = value;
    notifyListeners(); // แจ้งเตือนทุกหน้าที่ฟังอยู่ให้รีเฟรช

    // บันทึกลงเครื่อง
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_family_view', value);
  }
}