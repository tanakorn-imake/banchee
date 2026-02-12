import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import 'register_provider.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // ใช้ ChangeNotifierProvider เพื่อผูก Logic เข้ากับหน้านี้
    return ChangeNotifierProvider(
      create: (_) => RegisterProvider(),
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Consumer<RegisterProvider>(
              builder: (context, provider, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- โลโก้ / หัวข้อ ---
                    const Icon(Icons.account_balance_wallet,
                        size: 80, color: AppColors.primaryGold),
                    const SizedBox(height: 20),
                    const Text(
                      "Welcome to Banchee",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "เริ่มต้นวางแผนการเงินของคุณเอง",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 50),

                    // --- ช่องกรอกชื่อ ---
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "ชื่อของคุณ (Display Name)",
                        prefixIcon: Icon(Icons.person, color: AppColors.primaryGold),
                      ),
                    ),

                    // --- แสดง Error (ถ้ามี) ---
                    if (provider.errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        provider.errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 30),

                    // --- ปุ่มบันทึก ---
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: provider.isLoading
                            ? null // ปิดปุ่มตอนโหลด
                            : () async {
                          // เรียกใช้ Logic
                          final success = await provider
                              .submitRegistration(_nameController.text);

                          if (success && context.mounted) {
                            // ไปหน้า Home และลบหน้า Register ออกจาก Stack
                            Navigator.pushReplacementNamed(context, '/home');
                          }
                        },
                        child: provider.isLoading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text(
                          "เริ่มต้นใช้งาน",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}