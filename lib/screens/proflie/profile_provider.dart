import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service = ProfileService();

  // กำหนดค่าเริ่มต้นเป็น "..." หรือค่าว่าง เพื่อความสวยงามตอนยังไม่มีข้อมูล
  String name = "...";
  String deviceId = "...";
  String familyName = "กำลังโหลด...";
  int memberCount = 0;
  String? inviteCode; // เพิ่มเผื่อไว้สำหรับการจัดการ

  bool isLoading = true;

  ProfileProvider() {
    loadProfile();
  }

  // ✅ โหลดข้อมูล: Cache -> Show -> Server -> Update -> Save Cache
  Future<void> loadProfile() async {
    isLoading = true;

    // 1. ดึงข้อมูลจาก Cache มาแสดงก่อน (User จะเห็นทันที)
    final prefs = await SharedPreferences.getInstance();
    final cachedName = prefs.getString('cached_userName');
    final cachedFamilyName = prefs.getString('cached_familyName');
    final cachedMemberCount = prefs.getInt('cached_memberCount');

    if (cachedName != null) name = cachedName;
    if (cachedFamilyName != null) familyName = cachedFamilyName;
    if (cachedMemberCount != null) memberCount = cachedMemberCount;

    // อัปเดตหน้าจอด้วยข้อมูลเก่าทันที
    notifyListeners();

    try {
      // 2. ดึงข้อมูลจริงจาก Server (ทำงานเบื้องหลัง)
      final data = await _service.getUserProfile();

      name = data['name'];
      deviceId = data['deviceId'];
      // เช็คว่ามีครอบครัวไหม ถ้าไม่มีให้ใส่ข้อความ Default
      familyName = data['familyName'] ?? "ยังไม่มีครอบครัว";
      memberCount = data['memberCount'] ?? 0;
      inviteCode = data['inviteCode'];

      // 3. บันทึกข้อมูลใหม่ลง Cache (Update ค่าล่าสุดเก็บไว้)
      await prefs.setString('cached_userName', name);
      await prefs.setString('cached_familyName', familyName);
      await prefs.setInt('cached_memberCount', memberCount);

    } catch (e) {
      print("Error loading profile: $e");
      // กรณี Error: หน้าจอจะยังคงโชว์ข้อมูลจาก Cache ต่อไป ไม่ขาวโพลน
    } finally {
      isLoading = false;
      notifyListeners(); // ปิด Loading bar
    }
  }

  // ✅ ฟังก์ชันรับค่าอัปเดตสด (เช่น กลับมาจากหน้าจัดการครอบครัว)
  void updateFamilyInfo(String? newName, int newCount) {
    if (newName != null) {
      // 1. อัปเดตตัวแปรใน Memory ทันที
      familyName = newName;
      memberCount = newCount;
      notifyListeners();

      // 2. บันทึกลง Local Storage ทันที (ครั้งหน้าเปิดมาจะได้ค่านี้เลย)
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('cached_familyName', newName);
        prefs.setInt('cached_memberCount', newCount);
      });
    }
  }

  Future<void> logout() async {
    try {
      await _service.logout();
      // ล้าง Cache ทั้งหมดเมื่อ Logout เพื่อความปลอดภัย
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      notifyListeners();
    } catch (e) {
      print("Logout error: $e");
    }
  }
}