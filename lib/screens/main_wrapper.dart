import 'package:banchee/screens/proflie/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/widgets/custom_bottom_bar.dart';
import '../../config/theme.dart';

// Screens
import 'home/home_screen.dart';
import 'recurring/recurring_screen.dart';
import 'proflie/profile_screen.dart';
import 'statistics/statistics_screen.dart';
import 'unpaid/unpaid_screen.dart';

// Providers
import 'home/home_provider.dart';
import 'unpaid/unpaid_provider.dart';
import 'recurring/recurring_provider.dart';
import 'statistics/statistics_provider.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 2;

  // ประกาศหน้าจอ (const เพื่อ performance)
  final List<Widget> pages = const [
    RecurringScreen(),
    UnpaidScreen(),
    HomeScreen(),
    StatisticsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // ย้ายการสร้าง Provider มาไว้ที่นี่ (Lift State Up)
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => RecurringProvider()),
        ChangeNotifierProvider(create: (_) => UnpaidProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,

        // ✅ แก้ไข: เปลี่ยนเป็น false
        // เพื่อให้เนื้อหาหยุดอยู่เหนือ Bottom Bar (ทำให้ปุ่ม Add ในหน้า Home ไม่จม)
        extendBody: false,

        // IndexedStack จะเก็บ State ของหน้าจอไว้ (ไม่รีเซ็ตเมื่อสลับ Tab)
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),

        bottomNavigationBar: Builder(
            builder: (context) {
              // ✅ ใส่ Container + SafeArea เพื่อดันเมนูหนีปุ่ม Home (iPhone)
              return Container(
                color: AppColors.background, // สีพื้นหลังส่วนที่ดันขึ้นมา
                child: SafeArea(
                  top: false,
                  bottom: true, // ดันด้านล่างขึ้นมา
                  child: CustomBottomBar(
                    currentIndex: _currentIndex,
                    onTap: (index) {
                      setState(() => _currentIndex = index);

                      // สั่งโหลดข้อมูลใหม่เมื่อกดเปลี่ยนหน้า
                      switch (index) {
                        case 0: // Recurring
                          context.read<RecurringProvider>().loadBills();
                          break;
                        case 1: // Unpaid
                          context.read<UnpaidProvider>().loadUnpaidData();
                          break;
                        case 2: // Home
                          context.read<HomeProvider>().loadData();
                          break;
                        case 3: // Statistics
                          context.read<StatisticsProvider>().loadData();
                          break;
                        case 4: // Profile
                          context.read<ProfileProvider>().loadProfile();
                          break;
                      }
                    },
                  ),
                ),
              );
            }
        ),
      ),
    );
  }
}