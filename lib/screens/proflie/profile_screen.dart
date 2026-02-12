import 'package:banchee/screens/proflie/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import 'family_manage_screen.dart';
import 'category_manage_screen.dart';
import 'manage_tags_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider(),
      // ใช้ Consumer หุ้ม Scaffold เพื่อให้เข้าถึง provider ได้
      child: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: const Text("ข้อมูล & การตั้งค่า",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),

              // Loading Bar แบบบางๆ ไม่บังหน้าจอ
              bottom: provider.isLoading
                  ? const PreferredSize(
                preferredSize: Size.fromHeight(2.0),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: AppColors.primaryGold,
                  minHeight: 2,
                ),
              )
                  : null,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileHeader(provider),
                  const SizedBox(height: 30),

                  // ส่ง context ไปด้วยเพื่อใช้ในการเปลี่ยนหน้า
                  _buildFamilyCard(context, provider),

                  const SizedBox(height: 20),
                  _buildMenuTile(context, Icons.grid_view, "จัดการหมวดหมู่", "เพิ่ม/ลบ หมวดหมู่", const CategoryManageScreen()),
                  _buildMenuTile(context, Icons.local_offer, "จัดการแท็ก", "เพิ่ม/ลบ #แท็ก ของคุณ", const ManageTagsScreen()),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => _showLogoutDialog(context, provider),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        foregroundColor: Colors.red,
                      ),
                      child: const Text("ออกจากระบบ (Logout)"),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(ProfileProvider provider) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryGold, width: 2),
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.surface,
                child: Icon(Icons.person, size: 50, color: Colors.white54),
              ),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: AppColors.primaryGold, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.black, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(provider.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
          child: Text(provider.deviceId, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildFamilyCard(BuildContext context, ProfileProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.people, color: AppColors.primaryGold),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("My Family", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Text(
                      "ครอบครัวของฉัน",
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                onPressed: () => _navigateToFamilyManage(context, provider),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToFamilyManage(context, provider),
                  icon: const Icon(Icons.settings, size: 18, color: Colors.black),
                  label: const Text("จัดการครอบครัว", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ✅ ฟังก์ชันหัวใจสำคัญ: รอรับค่าที่ส่งกลับมาจากหน้า FamilyManage
  void _navigateToFamilyManage(BuildContext context, ProfileProvider provider) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FamilyManageScreen()),
    );

    // ถ้ามีข้อมูลส่งกลับมา (แสดงว่ามีการเปลี่ยนแปลง) ให้อัปเดตทันที
    if (result != null && result is Map<String, dynamic>) {
      // เรียกฟังก์ชัน updateFamilyInfo ที่เราเขียนเพิ่มใน Provider
      provider.updateFamilyInfo(result['name'], result['count']);
    } else {
      // ถ้าไม่มีอะไรส่งมา
    }
  }

  Widget _buildMenuTile(BuildContext context, IconData icon, String title, String subtitle, Widget? destination) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primaryGold.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primaryGold, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
        onTap: () {
          if (destination != null) Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, ProfileProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("ยืนยันการออกจากระบบ", style: TextStyle(color: Colors.white)),
        content: const Text("คุณต้องการออกจากระบบใช่หรือไม่?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ยกเลิก", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.logout();
              if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/register', (route) => false);
            },
            child: const Text("ออกจากระบบ", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}