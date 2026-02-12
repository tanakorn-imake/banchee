// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:banchee/main.dart';

void main() {
  testWidgets('App launch smoke test', (WidgetTester tester) async {
    // 1. สร้างแอปจำลอง โดยส่ง startRoute เป็น '/register'
    // เพื่อแก้ Error: The named parameter 'startRoute' is required
    await tester.pumpWidget(const MyApp(startRoute: '/register'));

    // 2. รอให้แอนิเมชันและการโหลดหน้าจอเสร็จสิ้น
    await tester.pumpAndSettle();

    // 3. ตรวจสอบว่าเจอข้อความ "Welcome to Banchee" หรือไม่
    // (ข้อความนี้อยู่ในหน้า RegisterScreen ที่เราเขียนไว้)
    expect(find.text('Welcome to Banchee'), findsOneWidget);

    // ตรวจสอบว่าไม่เจอข้อความมั่วๆ
    expect(find.text('0'), findsNothing);
  });
}