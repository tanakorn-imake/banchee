import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthApiService {
  // ⭐ ต้องระบุ region ให้ตรงกับ Cloud Functions
  FirebaseFunctions get _functions => FirebaseFunctions.instanceFor(
    region: 'asia-southeast1', // ✅ ตรงกับ setGlobalOptions
  );

  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<void> loginWithDualUid({
    required String deviceId,
    required String secretKey,
    required String name,
  }) async {
    try {
      print('📤 กำลังส่ง: deviceId=$deviceId, name=$name'); // Debug log

      // 1. เรียก Cloud Function
      final callable = _functions.httpsCallable('auth_login');
      final result = await callable.call({
        'deviceId': deviceId,
        'secretKey': secretKey,
        'name': name,
      });

      print('✅ ได้รับ response จาก Cloud Function'); // Debug log

      // 2. รับ Custom Token
      final String customToken = result.data['token'];

      // 3. Sign in ด้วย Custom Token
      await _auth.signInWithCustomToken(customToken);

      print('✅ Login สำเร็จ! UID: ${_auth.currentUser?.uid}');

    } on FirebaseFunctionsException catch (e) {
      print('❌ Cloud Functions Error: ${e.code} - ${e.message}');

      // แปลง Error Code ให้อ่านง่าย
      switch (e.code) {
        case 'invalid-argument':
          throw 'ข้อมูลไม่ครบถ้วน กรุณาตรวจสอบอีกครั้ง';
        case 'unauthenticated':
          throw 'รหัสยืนยันตัวตนไม่ถูกต้อง';
        case 'internal':
          throw 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์';
        default:
          throw e.message ?? 'เกิดข้อผิดพลาดจาก Cloud Function';
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      throw 'ยืนยันตัวตนล้มเหลว: ${e.message}';
    } catch (e) {
      print('❌ Unknown Error: $e');
      throw 'เกิดข้อผิดพลาด: $e';
    }
  }

  /// ตรวจสอบสถานะการ Login
  bool get isLoggedIn => _auth.currentUser != null;

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}