// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Config & Utils
import '../../config/theme.dart';
import '../../core/utils/category_helper.dart';

// Models & Services
import '../../data/models/transaction_model.dart';
import '../../data/services/sync_service.dart';
import '../../data/services/auto_slip_manager.dart';

// Providers
import '../../providers/view_preference_provider.dart';
import 'home_provider.dart';
// ✅ Import Profile Provider
import '../proflie/profile_provider.dart';

// Screens
import '../analytics/Overview_screen.dart';
import '../analytics/Overview_provider.dart';
import '../add_edit/add_edit_screen.dart';
import '../proflie/family_manage_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<HomeProvider, ViewPreferenceProvider>(
      builder: (context, homeProvider, viewPref, child) {

        // ตรวจสอบ Config ของ View (ส่วนตัว/ครอบครัว) เมื่อ Build เสร็จ
        WidgetsBinding.instance.addPostFrameCallback((_) {
          homeProvider.setViewConfig(viewPref.isFamilyView, viewPref.myCreatorId);
        });

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column( // ✅ แก้ไข: ใช้ Column เพื่อแยกส่วน Fixed Header ออกจาก Scrollable List
              children: [
                // ==========================================
                // 📌 ส่วนที่ล็อคอยู่กับที่ (Fixed Header)
                // ==========================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    children: [
                      _buildMonthSelector(homeProvider),
                      const SizedBox(height: 20),
                      _buildTopControlBar(context, viewPref, homeProvider),
                      const SizedBox(height: 25),
                      _buildTotalBalanceCard(context, homeProvider, viewPref.isFamilyView),
                    ],
                  ),
                ),

                // ==========================================
                // 📜 ส่วนที่เลื่อนได้ (Scrollable List)
                // ==========================================
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryGold,
                    backgroundColor: AppColors.surface,
                    displacement: 20,
                    onRefresh: () async {
                      if (viewPref.isFamilyView) {
                        await homeProvider.pullFamilyData();
                      } else {
                        await homeProvider.loadData();
                      }
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // --- รายการ Transaction ---
                        if (homeProvider.isLoading)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
                          )
                        else if (homeProvider.transactions.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                  final txn = homeProvider.transactions[index];
                                  bool showDateHeader = false;

                                  if (index == 0) {
                                    showDateHeader = true;
                                  } else {
                                    final prevTxn = homeProvider.transactions[index - 1];
                                    if (!_isSameDay(txn.date, prevTxn.date)) {
                                      showDateHeader = true;
                                    }
                                  }

                                  return Column(
                                    children: [
                                      if (showDateHeader) _buildDateDivider(txn.date),
                                      _buildTransactionRow(context, homeProvider, viewPref, txn),
                                    ],
                                  );
                                },
                                childCount: homeProvider.transactions.length,
                              ),
                            ),
                          ),

                        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEditScreen()),
              ).then((_) => homeProvider.loadData());
            },
            backgroundColor: AppColors.primaryGold,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.black, size: 32),
          ),
        );
      },
    );
  }

  // ==========================================================
  // 🛰️ UI INTERACTIONS (เหมือนเดิม)
  // ==========================================================

  Future<void> _executeSlipProcessing(BuildContext context, List<SlipCandidate> slips, HomeProvider provider) async {
    final ValueNotifier<String> progressNotifier = ValueNotifier("กำลังเตรียมข้อมูล...");

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: AppColors.primaryGold),
              const SizedBox(height: 25),
              const Text("กำลังถอดข้อมูลสลิป",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<String>(
                valueListenable: progressNotifier,
                builder: (context, value, child) {
                  return Text(
                    value,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

    int savedCount = 0;

    try {
      savedCount = await provider.processIncomingSlips(
        slips,
        onProgress: (current, total) {
          progressNotifier.value = "รายการที่ $current จาก $total";
        },
      );
    } catch (e) {
      debugPrint("❌ Error in Dialog: $e");
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (context.mounted && savedCount > 0) {
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 60),
              const SizedBox(height: 20),
              Text("บันทึกสำเร็จ $savedCount รายการ",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    }
  }

  void _handleManualOCRScan(BuildContext context, HomeProvider provider) async {
    final manager = AutoSlipManager();
    final slips = await manager.scanForNewSlips();

    if (context.mounted) {
      if (slips.isNotEmpty) {
        _showSlipDiscoveryPopup(context, slips, provider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ไม่พบสลิปใหม่ในเครื่องครับ 😊"),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showSlipDiscoveryPopup(BuildContext context, List<SlipCandidate> slips, HomeProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.primaryGold,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_outlined, color: AppColors.primaryGold, size: 48),
            ),
            const SizedBox(height: 20),
            const Text("พบสลิปใหม่!",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "ตรวจพบรายการโอนเงินใหม่ ${slips.length} รายการ\nต้องการให้ระบบบันทึกอัตโนมัติเลยไหมครับ?",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: slips.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                ),
                child: Text(s.bankName, style: const TextStyle(color: AppColors.primaryGold, fontSize: 11, fontWeight: FontWeight.bold)),
              )).toList(),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("ไว้ทีหลัง", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _executeSlipProcessing(context, slips, provider);
                  },
                  child: const Text("บันทึกเลย", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // --- UI BUILDERS ---

  Widget _buildMonthSelector(HomeProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildIconButton(Icons.arrow_back_ios_new, () => provider.changeMonth(-1)),
        Text(
          DateFormat('MMMM yyyy', 'th').format(provider.selectedDate),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        _buildIconButton(Icons.arrow_forward_ios, () => provider.changeMonth(1)),
      ],
    );
  }

  Widget _buildTopControlBar(BuildContext context, ViewPreferenceProvider viewPref, HomeProvider homeProvider) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                _buildToggleOption("ส่วนตัว", !viewPref.isFamilyView, () => viewPref.toggleView(false)),
                _buildToggleOption("ครอบครัว", viewPref.isFamilyView, () => viewPref.toggleView(true)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildActionCircle(
          icon: Icons.document_scanner_outlined,
          onPressed: () => _handleManualOCRScan(context, homeProvider),
          color: AppColors.primaryGold,
        ),
        const SizedBox(width: 8),
        _buildActionCircle(
          icon: Icons.cloud_upload_outlined,
          onPressed: () => _handlePushSync(context, viewPref),
          color: Colors.white70,
        ),
      ],
    );
  }

  Widget _buildTotalBalanceCard(BuildContext context, HomeProvider provider, bool isFamily) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => AnalyticsProvider(),
              child: AnalyticsScreen(targetDate: provider.selectedDate),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [AppColors.primaryGold, AppColors.primaryGold.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isFamily ? "ยอดรวมครอบครัว" : "ยอดรวมส่วนตัว",
                  style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Icon(Icons.chevron_right, color: Colors.black54),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "฿${NumberFormat("#,##0").format(provider.totalExpense)}",
              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 18, color: AppColors.textGrey),
      onPressed: onTap,
    );
  }

  Widget _buildToggleOption(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGold : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white38,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCircle({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 22),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    String label;
    final now = DateTime.now();
    if (_isSameDay(date, now)) {
      label = "วันนี้";
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      label = "เมื่อวานนี้";
    } else {
      label = DateFormat('d MMM yyyy', 'th').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.white.withOpacity(0.05))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Divider(color: Colors.white.withOpacity(0.05))),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(BuildContext context, HomeProvider provider, ViewPreferenceProvider viewPref, TransactionModel txn) {
    bool isMe = txn.creatorId == viewPref.myCreatorId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: viewPref.isFamilyView
            ? (isMe ? MainAxisAlignment.end : MainAxisAlignment.start)
            : MainAxisAlignment.center,
        children: [
          Flexible(
            child: TransactionCard(
                txn: txn,
                isMe: isMe,
                isFullWidth: !viewPref.isFamilyView
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          const Text("ไม่มีรายการในเดือนนี้", style: TextStyle(color: Colors.white24, fontSize: 16)),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Future<void> _handlePushSync(BuildContext context, ViewPreferenceProvider viewPref) async {
    final profile = context.read<ProfileProvider>();

    if (profile.familyName == "..." || profile.familyName == "กำลังโหลด...") {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('กำลังตรวจสอบสถานะครอบครัว...'))
        );
      }
      await profile.loadProfile();
    }

    const invalidNames = ["ยังไม่มีครอบครัว", "...", "กำลังโหลด...", ""];
    bool hasFamily = !invalidNames.contains(profile.familyName) && profile.familyName != null;

    if (!hasFamily) {
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.family_restroom, color: AppColors.primaryGold),
              SizedBox(width: 10),
              Text("ยังไม่มีกลุ่มครอบครัว", style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: const Text(
            "คุณต้องมีกลุ่มครอบครัวก่อน จึงจะสามารถอัปโหลดข้อมูลขึ้น Cloud เพื่อแชร์กับสมาชิกคนอื่นได้\n\nต้องการไปสร้างหรือเข้าร่วมกลุ่มเลยไหมครับ?",
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("ไว้ทีหลัง", style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FamilyManageScreen()),
                ).then((result) {
                  if (result != null && result is Map) {
                    context.read<ProfileProvider>().updateFamilyInfo(
                        result['name'],
                        result['count']
                    );
                  }
                });
              },
              child: const Text("ไปหน้าครอบครัว", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cloud_upload, color: AppColors.primaryGold),
            SizedBox(width: 10),
            Text("อัปโหลดขึ้น Cloud?", style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Text.rich(
          TextSpan(
            text: "ข้อมูลรายจ่ายจะถูกอัปโหลดไปยังกลุ่ม ",
            style: const TextStyle(color: Colors.white70, height: 1.5),
            children: [
              TextSpan(
                  text: "\"${profile.familyName}\"",
                  style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold)
              ),
              const TextSpan(
                  text: "\nเพื่อให้สมาชิกคนอื่นดึงข้อมูลได้ (ข้อมูลจะพักอยู่บน Cloud 3 วัน)\n\nยืนยันการอัปโหลดหรือไม่?"
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ยกเลิก", style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              try {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กำลังอัปโหลด... ☁️'), duration: Duration(seconds: 1)),
                  );
                }
                await SyncService().pushTransactions();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('อัปโหลดเรียบร้อย! ครอบครัวสามารถดึงข้อมูลได้แล้ว ✅'),
                        backgroundColor: Colors.green
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("อัปโหลด", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ✅ TransactionCard (เหมือนเดิม)
class TransactionCard extends StatefulWidget {
  final TransactionModel txn;
  final bool isMe;
  final bool isFullWidth;
  const TransactionCard({super.key, required this.txn, required this.isMe, this.isFullWidth = false});
  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  bool _isExpanded = false;
  @override
  Widget build(BuildContext context) {
    final homeProvider = context.read<HomeProvider>();
    final catInfo = CategoryHelper.getCategoryInfo(widget.txn.category, homeProvider.customCategories);
    final IconData icon = catInfo['icon'];
    final Color categoryColor = catInfo['color'];

    final bgColor = widget.isFullWidth
        ? AppColors.surface
        : (widget.isMe ? AppColors.surface : const Color(0xFF2A2A2A));

    final borderRadius = widget.isFullWidth
        ? BorderRadius.circular(18)
        : BorderRadius.only(
      topLeft: widget.isMe ? const Radius.circular(18) : const Radius.circular(4),
      topRight: const Radius.circular(18),
      bottomLeft: const Radius.circular(18),
      bottomRight: widget.isMe ? const Radius.circular(4) : const Radius.circular(18),
    );

    String time = "${widget.txn.date.hour.toString().padLeft(2, '0')}:${widget.txn.date.minute.toString().padLeft(2, '0')}";
    String subtitleText = "เวลา $time";
    if (!widget.isMe && !widget.isFullWidth) {
      subtitleText += " • โดย ${widget.txn.payerName}";
    }
    if (widget.txn.note.isNotEmpty) {
      subtitleText += " • ${widget.txn.note}";
    }

    return Container(
      decoration: BoxDecoration(color: bgColor, borderRadius: borderRadius, border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              bool canEdit = widget.isMe;
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditScreen(transaction: widget.txn,
                  isReadOnly: !canEdit))).then((_) {
                if(context.mounted) context.read<HomeProvider>().loadData();
              });
            },
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: categoryColor.withOpacity(0.5))),
                    child: Icon(icon, color: categoryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.txn.category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(subtitleText, style: const TextStyle(color: Colors.white54, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text("฿${NumberFormat("#,##0").format(widget.txn.amount)}", style: const TextStyle(color: AppColors.primaryGold, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          if (widget.txn.isSplitBill && widget.txn.splitWith.isNotEmpty) ...[
            Divider(height: 1, color: Colors.white10),
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.vertical(bottom: widget.isFullWidth ? const Radius.circular(18) : (widget.isMe ? const Radius.circular(4) : const Radius.circular(18))),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.groups, size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text("หาร (${widget.txn.splitWith.length})", style: const TextStyle(fontSize: 11, color: Colors.white54)),
                    const Spacer(),
                    AnimatedRotation(turns: _isExpanded ? 0.5 : 0, duration: const Duration(milliseconds: 200), child: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white54)),
                  ],
                ),
              ),
            ),
            if (_isExpanded)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  children: widget.txn.splitWith.map((person) {
                    final isPayer = person.name == widget.txn.payerName;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text(person.name, style: TextStyle(fontSize: 12, color: isPayer ? AppColors.primaryGold : Colors.white70), overflow: TextOverflow.ellipsis)),
                          if(person.isCleared && !isPayer) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.check_circle, size: 12, color: Colors.green)),
                          Text("฿${person.amount.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12, color: Colors.white)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )
          ]
        ],
      ),
    );
  }
}