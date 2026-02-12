import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/view_preference_provider.dart';
import 'statistics_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<StatisticsProvider, ViewPreferenceProvider>(
      builder: (context, provider, viewPref, child) {

        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.updateViewPreference(viewPref.isFamilyView, viewPref.myCreatorId);
        });

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildCustomScopeSelector(context, provider),
                    const SizedBox(height: 15),
                    _buildModeToggle(context, viewPref),
                    const SizedBox(height: 15),

                    // ✅ 3. ถ้าเลือกคนแล้ว ให้โชว์ชื่อคนนั้น
                    if (provider.selectedMember != null)
                      Text(
                          "รายการของ: ${provider.selectedMember}",
                          style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold)
                      ),

                    // 4. กราฟ
                    SizedBox(
                      height: 280,
                      child: provider.isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
                          : (provider.displayStats.isEmpty
                          ? _buildEmptyState()
                          : _buildInteractiveChart(provider)),
                    ),

                    const SizedBox(height: 20),

                    // ✅ 5. ซ่อนปุ่มเลือก View ถ้ากำลังดูหน้าภาพรวมคน (เพราะยังไม่จำเป็น)
                    if (!provider.isShowingMemberOverview)
                      _buildViewToggle(provider),

                    const SizedBox(height: 10),
                  ],
                ),
              ),

              // ✅ 6. ปุ่มย้อนกลับ (ใช้ Logic ใหม่)
              if (provider.selectedDrillDownTag != null || provider.selectedMember != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: _buildDrillDownHeader(provider),
                ),

              Expanded(
                child: provider.displayStats.isEmpty && !provider.isLoading
                    ? const SizedBox()
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: provider.displayStats.length + 1,
                  itemBuilder: (context, index) {
                    if (index == provider.displayStats.length) {
                      return const SizedBox(height: 80);
                    }
                    return _buildListItem(provider, provider.displayStats[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Widgets ---

  Widget _buildInteractiveChart(StatisticsProvider provider) {
    double currentTotal = provider.displayStats.fold(0, (sum, item) => sum + item['amount']);

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 80,
            sections: provider.displayStats.asMap().entries.map((entry) {
              final data = entry.value;
              return PieChartSectionData(
                color: data['color'],
                value: data['amount'],
                title: '${(data['percentage'] * 100).toStringAsFixed(0)}%',
                radius: 25,
                titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              );
            }).toList(),
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) return;

                if (event is FlTapUpEvent) {
                  final index = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  if (index >= 0 && index < provider.displayStats.length) {
                    String itemName = provider.displayStats[index]['name'];

                    // ✅ Logic การกดกราฟ
                    if (provider.isShowingMemberOverview) {
                      // 1. ถ้าอยู่หน้าคน -> กดแล้วเจาะไปดูคนนั้น
                      provider.selectMember(itemName);
                    } else if (provider.currentView == StatViewType.tag && provider.selectedDrillDownTag == null) {
                      // 2. ถ้าอยู่หน้า Tag -> กดแล้วเจาะ Tag
                      provider.selectTagToDrillDown(itemName);
                    }
                    // 3. ถ้าอยู่หน้า Category ปกติ ไม่ต้องทำอะไร (เพราะ drill down ไป Tag ให้กดที่ List หรือปุ่ม Toggle เอา)
                  }
                }
              },
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // เปลี่ยนข้อความตรงกลางตามบริบท
            Text(
                provider.isShowingMemberOverview
                    ? "รวมทุกเป๋า" // ถ้าอยู่หน้าคน
                    : (provider.selectedDrillDownTag ?? "ยอดรวม"), // ถ้าเจาะลึก
                style: const TextStyle(color: Colors.white54, fontSize: 12)
            ),
            Text(
              "฿${NumberFormat("#,##0").format(currentTotal)}",
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildListItem(StatisticsProvider provider, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        // ✅ Logic การกดที่รายการ
        if (provider.isShowingMemberOverview) {
          provider.selectMember(data['name']); // เลือกคน
        } else if (provider.currentView == StatViewType.tag && provider.selectedDrillDownTag == null) {
          provider.selectTagToDrillDown(data['name']); // เลือก Tag
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: (data['color'] as Color).withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(data['icon'], color: data['color'], size: 18),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: data['percentage'],
                      backgroundColor: Colors.white10,
                      color: data['color'],
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${NumberFormat("#,##0").format(data['amount'])}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  "${(data['percentage']*100).toStringAsFixed(1)}%",
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
            // แสดงลูกศร ถ้ายังกดต่อได้
            if (provider.isShowingMemberOverview || (provider.currentView == StatViewType.tag && provider.selectedDrillDownTag == null))
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 10),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildDrillDownHeader(StatisticsProvider provider) {
    // เปลี่ยนข้อความปุ่มย้อนกลับตามบริบท
    String label = "";
    if (provider.selectedDrillDownTag != null) {
      label = "รายละเอียด: ${provider.selectedDrillDownTag}";
    } else if (provider.selectedMember != null) {
      label = "กลับไปภาพรวมครอบครัว";
    }

    return Container(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () => provider.handleBackPress(), // ✅ ใช้ฟังก์ชันย้อนกลับตัวใหม่
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back_ios, size: 14, color: AppColors.primaryGold),
              const SizedBox(width: 5),
              const Text("กลับ", style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets เดิม (Toggle, DatePicker ฯลฯ) Copy มาวางได้เลย ---
  // (ผมละไว้เพื่อประหยัดพื้นที่ ถ้าไม่มีบอกได้ครับ)
  Widget _buildModeToggle(BuildContext context, ViewPreferenceProvider viewPref) {
    // (ใช้โค้ดเดิมจากรอบที่แล้ว)
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _buildToggleItem(
            context,
            label: "ส่วนตัว",
            isSelected: !viewPref.isFamilyView,
            onTap: () => viewPref.toggleView(false),
          ),
          _buildToggleItem(
            context,
            label: "ครอบครัว",
            isSelected: viewPref.isFamilyView,
            onTap: () => viewPref.toggleView(true),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(BuildContext context, {required String label, required bool isSelected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGold : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomScopeSelector(BuildContext context, StatisticsProvider provider) {
    // (ใช้โค้ดเดิม)
    String dateLabel = "";
    List<String> monthsTH = ["", "มกราคม", "กุมภาพันธ์", "มีนาคม", "เมษายน", "พฤษภาคม", "มิถุนายน", "กรกฎาคม", "สิงหาคม", "กันยายน", "ตุลาคม", "พฤศจิกายน", "ธันวาคม"];

    if (provider.currentScope == StatScope.month) {
      String monthName = monthsTH[provider.selectedDate.month];
      int yearTH = provider.selectedDate.year + 543;
      dateLabel = "$monthName $yearTH";
    } else {
      dateLabel = "ปี ${provider.selectedDate.year + 543}";
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildScopeBtn("รายเดือน", StatScope.month, provider),
              _buildScopeBtn("รายปี", StatScope.year, provider),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _showCustomDatePicker(context, provider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(dateLabel, style: const TextStyle(color: AppColors.primaryGold, fontWeight: FontWeight.bold)),
                const SizedBox(width: 5),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.primaryGold),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCustomDatePicker(BuildContext context, StatisticsProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
      builder: (BuildContext ctx) {
        return _CustomDatePickerBody(
          initialDate: provider.selectedDate,
          initialScope: provider.currentScope,
          onDateSelected: (selectedDate) {
            provider.setDate(selectedDate);
            Navigator.pop(ctx);
          },
        );
      },
    );
  }

  Widget _buildScopeBtn(String title, StatScope scope, StatisticsProvider provider) {
    bool isSelected = provider.currentScope == scope;
    return GestureDetector(
      onTap: () => provider.changeScope(scope),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          style: TextStyle(
              color: isSelected ? Colors.black : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 12
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle(StatisticsProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _buildViewBtn("หมวดหมู่", StatViewType.category, provider),
          _buildViewBtn("แท็ก (#Tag)", StatViewType.tag, provider),
        ],
      ),
    );
  }

  Widget _buildViewBtn(String title, StatViewType type, StatisticsProvider provider) {
    bool isSelected = provider.currentView == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.toggleViewMode(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white24 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. ลดขนาดพื้นที่กราฟลง (จาก 250 เหลือ 180)
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 0,
                    // ลดขนาดรูตรงกลาง (จาก 80 เหลือ 50)
                    centerSpaceRadius: 50,
                    sections: [
                      PieChartSectionData(
                        color: Colors.white.withOpacity(0.05),
                        value: 100,
                        // ลดความหนาเส้น (จาก 25 เหลือ 20)
                        radius: 20,
                        title: "",
                        showTitle: false,
                      ),
                    ],
                    pieTouchData: PieTouchData(enabled: false),
                  ),
                ),
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ลดขนาดไอคอนและข้อความตรงกลาง
                    Icon(Icons.query_stats, size: 30, color: Colors.white24),
                    SizedBox(height: 5),
                    Text(
                      "ว่างเปล่า",
                      style: TextStyle(color: Colors.white24, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ลดช่องว่างระหว่างกราฟกับข้อความ
          const SizedBox(height: 10),

          // 2. ปรับขนาดข้อความให้กระชับขึ้น
          const Text(
            "ยังไม่มีรายการในเดือนนี้",
            style: TextStyle(
                color: Colors.white,
                fontSize: 16, // ลดจาก 18
                fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "เริ่มจดบันทึกรายการแรก\nเพื่อดูสรุปพฤติกรรมการใช้เงินของคุณ",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12), // ลดจาก 14
          ),
        ],
      ),
    );
  }
}

// _CustomDatePickerBody ... (คงเดิม)
class _CustomDatePickerBody extends StatefulWidget {
  final DateTime initialDate;
  final StatScope initialScope;
  final Function(DateTime) onDateSelected;

  const _CustomDatePickerBody({required this.initialDate, required this.initialScope, required this.onDateSelected});

  @override
  State<_CustomDatePickerBody> createState() => _CustomDatePickerBodyState();
}

class _CustomDatePickerBodyState extends State<_CustomDatePickerBody> {
  late int _currentYear;
  late bool _isYearSelectionMode;

  @override
  void initState() {
    super.initState();
    _currentYear = widget.initialDate.year;
    _isYearSelectionMode = widget.initialScope == StatScope.year;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.primaryGold, size: 30),
                onPressed: () {
                  setState(() {
                    if (_isYearSelectionMode) {
                      _currentYear -= 12;
                    } else {
                      _currentYear--;
                    }
                  });
                },
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isYearSelectionMode = !_isYearSelectionMode;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isYearSelectionMode ? AppColors.primaryGold : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryGold),
                  ),
                  child: Text(
                    "${_currentYear + 543}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _isYearSelectionMode ? Colors.black : AppColors.primaryGold,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.primaryGold, size: 30),
                onPressed: () {
                  setState(() {
                    if (_isYearSelectionMode) {
                      _currentYear += 12;
                    } else {
                      _currentYear++;
                    }
                  });
                },
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 30),
          Expanded(
            child: _isYearSelectionMode ? _buildYearGrid() : _buildMonthGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid() {
    final List<String> months = ["ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.", "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค."];
    final now = DateTime.now();

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final monthIndex = index + 1;
        final isSelected = widget.initialDate.year == _currentYear && widget.initialDate.month == monthIndex;
        final isToday = now.year == _currentYear && now.month == monthIndex;

        return GestureDetector(
          onTap: () {
            final newDate = DateTime(_currentYear, monthIndex, 1);
            widget.onDateSelected(newDate);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryGold : Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: isToday ? Border.all(color: AppColors.primaryGold, width: 2) : null,
            ),
            alignment: Alignment.center,
            child: Text(
              months[index],
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildYearGrid() {
    final startYear = _currentYear - 4;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final year = startYear + index;
        final isSelected = widget.initialDate.year == year;

        return GestureDetector(
          onTap: () {
            setState(() {
              _currentYear = year;
              if (widget.initialScope == StatScope.year) {
                widget.onDateSelected(DateTime(year, 1, 1));
              } else {
                _isYearSelectionMode = false;
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryGold : Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              "${year + 543}",
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        );
      },
    );
  }
}