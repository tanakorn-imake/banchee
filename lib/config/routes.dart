import 'package:flutter/material.dart';
import '../screens/main_wrapper.dart';
import '../screens/register/register_screen.dart';

class AppRoutes {
  static const String home = '/home';
  static const String register = '/register';

  static Map<String, WidgetBuilder> get routes => {
    // ✅ เรียก MainWrapper เป็นหน้าหลัก (ซึ่งจะจัดการ 5 แท็บข้างในเอง)
    home: (context) => const MainWrapper(),
    register: (context) => RegisterScreen(),
  };
}