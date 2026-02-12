import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // ถ้าในอนาคตใช้ Firebase Auth ให้เปิดบรรทัดนี้

class ProfileService {

  // ฟังก์ชันดึงข้อมูล User Profile
  Future<Map<String, dynamic>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? "Guest";
    final deviceId = prefs.getString('device_id') ?? "Unknown-ID";

    // จำลองการดึงข้อมูล (Mock Data)
    return {
      'name': name,
      'deviceId': "ID: $deviceId",
      'imagePath': 'assets/images/user_avatar.png',

      // ✅ จุดสำคัญ 1: แก้ตรงนี้จาก 'Home 1' เป็น null
      // เพื่อบอกระบบว่า "ยังไม่มีครอบครัว" (Dialog จะได้ทำงานถูกต้อง)
      'familyName': null,

      'memberCount': 0,
    };
  }

  // ✅ จุดสำคัญ 2: เพิ่มฟังก์ชันนี้เข้าไป (แก้ Error: method not defined)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    // ลบสถานะการลงทะเบียนเพื่อให้กลับไปหน้า Login
    await prefs.remove('is_registered');

    // ถ้าคุณใช้ Firebase Auth ด้วย ให้ uncomment บรรทัดข้างล่างนี้
    // await FirebaseAuth.instance.signOut();
  }
}