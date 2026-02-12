import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ 1. เพื่อแก้เรื่องวันที่
import 'package:provider/provider.dart'; // ✅ 2. เพื่อแก้เรื่อง Provider

import 'config/theme.dart';
import 'config/routes.dart';
import 'firebase_options.dart';
import 'providers/view_preference_provider.dart'; // ✅ 3. Import ไฟล์นี้ด้วย

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ 4. โหลดข้อมูลวันที่ภาษาไทย (แก้ LocaleDataException)
  await initializeDateFormatting('th', null);

  final prefs = await SharedPreferences.getInstance();
  final bool isRegistered = prefs.getBool('is_registered') ?? false;

  runApp(
    // ✅ 5. ครอบด้วย MultiProvider (แก้ ProviderNotFoundException)
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ViewPreferenceProvider()),
      ],
      child: MyApp(startRoute: isRegistered ? AppRoutes.home : AppRoutes.register),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String startRoute;
  const MyApp({super.key, required this.startRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Banchee',
      theme: AppTheme.darkLuxury,
      initialRoute: startRoute,
      routes: AppRoutes.routes,
    );
  }
}