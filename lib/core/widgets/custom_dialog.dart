import 'package:flutter/material.dart';
import '../../config/theme.dart'; // อย่าลืม import theme ของคุณ

class CustomDialog extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback? onPressed;
  final bool isError;
  final IconData? icon;

  const CustomDialog({
    super.key,
    required this.title,
    required this.description,
    this.buttonText = "ตกลง",
    this.onPressed,
    this.isError = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent, // ให้พื้นหลังใสเพื่อทำขอบมนเอง
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface, // สีพื้นหลังเทาเข้ม
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isError ? Colors.redAccent : AppColors.primaryGold, // ถ้า Error ขอบแดง ถ้าปกติขอบทอง
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ขนาดพอดีเนื้อหา
          children: [
            // 1. Icon หัวข้อ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isError
                    ? Colors.redAccent.withOpacity(0.1)
                    : AppColors.primaryGold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? (isError ? Icons.error_outline : Icons.check_circle_outline),
                size: 40,
                color: isError ? Colors.redAccent : AppColors.primaryGold,
              ),
            ),
            const SizedBox(height: 20),

            // 2. Title
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // 3. Description
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // 4. Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // ปิด Dialog ก่อน
                  if (onPressed != null) onPressed!(); // ทำคำสั่งต่อ (ถ้ามี)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isError ? Colors.redAccent : AppColors.primaryGold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.black, // ตัวหนังสือสีดำบนปุ่มทอง/แดง
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ฟังก์ชันเรียกใช้ง่ายๆ (Helper)
void showCustomDialog(BuildContext context, {
  required String title,
  required String message,
  bool isError = false,
  VoidCallback? onOk,
}) {
  showDialog(
    context: context,
    builder: (context) => CustomDialog(
      title: title,
      description: message,
      isError: isError,
      onPressed: onOk,
    ),
  );
}