import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
// 👇 เช็ค Path นี้ให้ดี ถ้า auth_api_service อยู่ที่ lib/data/services/ ก็ใช้แบบนี้ถูกแล้ว
import '../../data/services/auth_api_service.dart';

class RegisterProvider extends ChangeNotifier {
  final AuthApiService _apiService = AuthApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> submitRegistration(String name) async {
    if (name.trim().isEmpty) {
      _errorMessage = "กรุณากรอกชื่อของคุณ";
      notifyListeners();
      return false;
    }

    _setLoading(true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. จัดการ Device ID
      String? deviceId = prefs.getString('device_id');
      if (deviceId == null) {
        deviceId = const Uuid().v4();
        await prefs.setString('device_id', deviceId);
      }

      // 2. จัดการ Secret Key
      String? secretKey = prefs.getString('secret_key');
      if (secretKey == null) {
        secretKey = const Uuid().v4();
        await prefs.setString('secret_key', secretKey);
      }

      // 3. เรียก API
      await _apiService.loginWithDualUid(
        deviceId: deviceId,
        secretKey: secretKey,
        name: name.trim(),
      );

      // 4. บันทึกข้อมูล
      await prefs.setString('user_name', name.trim());
      await prefs.setBool('is_registered', true);

      _setLoading(false);
      return true;

    } catch (e) {
      _errorMessage = "$e";
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _errorMessage = null;
    notifyListeners();
  }
}