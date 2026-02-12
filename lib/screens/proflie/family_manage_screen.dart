import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../core/widgets/custom_dialog.dart';
import '../../providers/family_provider.dart';

class FamilyManageScreen extends StatelessWidget {
  const FamilyManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FamilyProvider(),
      // ใช้ Consumer หุ้ม Scaffold เพื่อให้เข้าถึง provider ได้ตอนกด Back
      child: Consumer<FamilyProvider>(
        builder: (context, provider, child) {

          // ✅ ฟังก์ชันส่งข้อมูลกลับหน้า Profile
          void onBack() {
            // ถ้ายังไม่มี family ให้ส่งชื่อว่า "ยังไม่มีครอบครัว" กลับไป
            final currentName = provider.familyId == null ? "ยังไม่มีครอบครัว" : provider.familyName;
            final currentCount = provider.members.length;

            Navigator.pop(context, {
              'name': currentName,
              'count': currentCount
            });
          }

          // ✅ ดักปุ่ม Back ของ Android (PopScope)
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              if (didPop) return;
              onBack();
            },
            child: Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: onBack, // เรียกใช้ฟังก์ชันเดียวกันกับปุ่ม Back
                ),
                title: const Text("จัดการครอบครัว", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                centerTitle: true,
              ),
              body: Builder(
                builder: (context) {
                  // Loading เฉพาะตอนเข้ามาครั้งแรกแล้วยังไม่มีข้อมูล
                  if (provider.isLoading && provider.familyId == null) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryGold));
                  }

                  if (provider.familyId == null) {
                    return _buildNoFamilyView(context, provider);
                  }
                  return _buildHasFamilyView(context, provider);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= UI: ยังไม่มีครอบครัว (Clean Style) =================
  Widget _buildNoFamilyView(BuildContext context, FamilyProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10, width: 1),
              ),
              child: const Icon(Icons.family_restroom_rounded, size: 60, color: AppColors.primaryGold),
            ),
            const SizedBox(height: 24),
            const Text("เริ่มต้นครอบครัวของคุณ", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              "สร้างพื้นที่ส่วนตัวสำหรับจัดการรายรับรายจ่าย\nร่วมกับคนที่คุณรักได้ง่ายๆ",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, height: 1.5),
            ),
            const SizedBox(height: 40),

            _buildActionButton(
              label: "สร้างครอบครัวใหม่",
              icon: Icons.add_circle_outline,
              color: AppColors.primaryGold,
              textColor: Colors.black,
              onPressed: () => _showCreateDialog(context, provider),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              label: "เข้าร่วมด้วยรหัสเชิญ",
              icon: Icons.login,
              color: Colors.transparent,
              textColor: AppColors.primaryGold,
              isOutlined: true,
              onPressed: () => _showJoinDialog(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI: มีครอบครัวแล้ว (Premium Card Style) =================
  Widget _buildHasFamilyView(BuildContext context, FamilyProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.surface, AppColors.surface.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              children: [
                const Icon(Icons.home_filled, color: AppColors.primaryGold, size: 40),
                const SizedBox(height: 16),
                Text(
                  provider.familyName ?? "Family Name",
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: provider.inviteCode ?? ""));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("คัดลอกรหัสเชิญแล้ว ✅"), backgroundColor: Colors.green));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("INVITE CODE: ", style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(provider.inviteCode ?? "...", style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16)),
                        const SizedBox(width: 10),
                        const Icon(Icons.copy, size: 16, color: Colors.white54),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 10),
            child: Text("สมาชิก (${provider.members.length})", style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ),

          // 2. Member List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final member = provider.members[index];
              final isOwner = member['id'] == provider.ownerId;

              return Container(
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: isOwner ? AppColors.primaryGold.withOpacity(0.2) : Colors.blueGrey.withOpacity(0.2),
                    child: Icon(isOwner ? Icons.workspace_premium : Icons.person, color: isOwner ? AppColors.primaryGold : Colors.white70),
                  ),
                  title: Text(member['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: isOwner
                      ? const Text("หัวหน้าครอบครัว", style: TextStyle(color: AppColors.primaryGold, fontSize: 12))
                      : const Text("สมาชิก", style: TextStyle(color: Colors.white24, fontSize: 12)),
                  trailing: (provider.isOwner && !isOwner)
                      ? IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                    onPressed: () => _confirmKick(context, provider, member),
                  )
                      : null,
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          // 3. Danger Zone
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => provider.isOwner ? _confirmDelete(context, provider) : _confirmLeave(context, provider),
              icon: Icon(provider.isOwner ? Icons.delete_forever : Icons.logout, color: Colors.red[300]),
              label: Text(provider.isOwner ? "ยุบครอบครัวถาวร" : "ออกจากครอบครัว", style: TextStyle(color: Colors.red[300], fontSize: 16)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.red.withOpacity(0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required Color textColor, required VoidCallback onPressed, bool isOutlined = false}) {
    final style = isOutlined
        ? OutlinedButton.styleFrom(side: BorderSide(color: color), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14))
        : ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14));
    return SizedBox(width: double.infinity, child: isOutlined ? OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon, color: textColor), label: Text(label, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)), style: style) : ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon, color: textColor), label: Text(label, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)), style: style));
  }

  // ================= Dialogs =================

  void _showLoadingDialog(BuildContext context) {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)));
  }

  void _showCreateDialog(BuildContext context, FamilyProvider provider) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("ตั้งชื่อครอบครัว", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "เช่น บ้านแสนสุข", hintStyle: TextStyle(color: Colors.white24)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              if(ctrl.text.isEmpty) return;
              Navigator.pop(context);
              _showLoadingDialog(context);
              try {
                await provider.createFamily(ctrl.text);
                if (context.mounted) Navigator.pop(context); // ปิด Loading
              } catch (e) {
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("สร้างเลย", style: TextStyle(color: AppColors.primaryGold)),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context, FamilyProvider provider) {
    final ctrl = TextEditingController();

    // ใช้ Dialog แบบเดิมสำหรับ Input แต่ปรับแต่งให้เข้าธีม
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // ขอบมน
        title: const Text("เข้าร่วมครอบครัว", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("กรอกรหัสเชิญ 6 หลักที่คุณได้รับ", style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 15),
            TextField(
              controller: ctrl,
              style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "AB12CD",
                hintStyle: TextStyle(color: Colors.white12, letterSpacing: 1),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (ctrl.text.isEmpty) return;

              Navigator.pop(context); // ปิดกล่อง Input
              _showLoadingDialog(context); // โชว์หมุนๆ

              try {
                await provider.joinFamily(ctrl.text.toUpperCase());

                if (context.mounted) {
                  Navigator.pop(context); // ปิด Loading

                  // ✅ สำเร็จ! โชว์ Dialog สวยๆ
                  showCustomDialog(
                    context,
                    title: "ยินดีต้อนรับ!",
                    message: "คุณได้เข้าร่วมครอบครัวเรียบร้อยแล้ว",
                    isError: false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // ปิด Loading

                  // แปลง Error Message ให้ผู้ใช้อ่านรู้เรื่อง
                  String errorMessage = "เกิดข้อผิดพลาด กรุณาลองใหม่";
                  if (e.toString().contains("not-found") || e.toString().contains("ไม่ถูกต้อง")) {
                    errorMessage = "ไม่พบรหัส Invite นี้ หรือรหัสไม่ถูกต้อง";
                  }

                  // ✅ ล้มเหลว! โชว์ Dialog Error สวยๆ แทนจอแดง
                  showCustomDialog(
                    context,
                    title: "เข้าร่วมไม่สำเร็จ",
                    message: errorMessage,
                    isError: true,
                  );
                }
              }
            },
            child: const Text("เข้าร่วม", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmLeave(BuildContext context, FamilyProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("ยืนยันการออก", style: TextStyle(color: Colors.white)),
        content: const Text("คุณแน่ใจหรือไม่ที่จะออกจากครอบครัวนี้?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _showLoadingDialog(context);
              await provider.leaveFamily();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("ลาออก", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, FamilyProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("ยุบครอบครัว?", style: TextStyle(color: Colors.white)),
        content: const Text("ข้อมูลทั้งหมดจะหายไปถาวร!", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _showLoadingDialog(context);
              await provider.deleteFamily();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("ยุบทิ้ง", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmKick(BuildContext context, FamilyProvider provider, Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text("เชิญ ${member['name']} ออก?", style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.kickMember(member['id']);
            },
            child: const Text("เชิญออก", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}