import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import 'Overview_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  final DateTime targetDate;

  const AnalyticsScreen({super.key, required this.targetDate});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<AnalyticsProvider>(context, listen: false)
            .loadMonthlyAnalytics(widget.targetDate.month, widget.targetDate.year)
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> monthsShort = ["", "ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.", "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค."];
    String monthStr = monthsShort[widget.targetDate.month];
    int year = widget.targetDate.year + 543;
    String dateLabel = "$monthStr $year";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("สรุปรายจ่าย", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryGold));
          }

          if (provider.categories.isEmpty) {
            return const Center(child: Text("ไม่มีข้อมูลรายจ่ายในเดือนนี้", style: TextStyle(color: Colors.white54)));
          }

          return Column(
            children: [
              // 1. ส่วนกราฟ Pie Chart - FIXED (ไม่เลื่อน)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  height: 350, // ลดความสูงลงนิดนึงเพื่อให้เหลือที่ให้ List
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 90,
                          sections: _buildChartSections(provider.categories),
                          startDegreeOffset: -90,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("รายจ่าย", style: TextStyle(color: Colors.white54, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(dateLabel, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text(
                            "฿${provider.totalExpense.toStringAsFixed(0)}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. หัวข้อหมวดหมู่ - FIXED (ไม่เลื่อน)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Text("หมวดหมู่", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(width: 20),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 10),
                      height: 2,
                      child: Row(
                        children: [
                          Expanded(flex: 1, child: Container(color: Colors.white)),
                          Expanded(flex: 3, child: Container(color: Colors.white10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. รายการหมวดหมู่ - SCROLLABLE (เลื่อนได้เฉพาะส่วนนี้)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: provider.categories.length,
                  itemBuilder: (context, index) {
                    final cat = provider.categories[index];
                    return _buildCategoryItem(cat);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ... (ฟังก์ชัน _buildChartSections, _buildBadge, _buildCategoryItem เหมือนเดิมเป๊ะครับ) ...
  List<PieChartSectionData> _buildChartSections(List<CategorySummary> originalList) {
    List<CategorySummary> chartData = [];
    double otherAmount = 0;
    double total = originalList.fold(0, (sum, item) => sum + item.amount);

    for (var cat in originalList) {
      if (cat.percentage < 0.04) {
        otherAmount += cat.amount;
      } else {
        chartData.add(cat);
      }
    }

    if (otherAmount > 0) {
      chartData.add(CategorySummary(
        name: "อื่นๆ",
        amount: otherAmount,
        percentage: total == 0 ? 0 : otherAmount / total,
        color: Colors.grey[700]!,
        icon: Icons.more_horiz,
      ));
    }

    return chartData.map((cat) {
      final showPercent = cat.percentage >= 0;
      final String percentStr = "${(cat.percentage * 100).toStringAsFixed(0)}%";

      return PieChartSectionData(
        color: cat.color,
        value: cat.amount,
        title: showPercent ? percentStr : '',
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
        ),
        titlePositionPercentageOffset: 0.5,
        radius: 45,
        badgeWidget: _buildBadge(cat.name, cat.color),
        badgePositionPercentageOffset: 1.5,
      );
    }).toList();
  }

  Widget _buildBadge(String text, Color borderColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategoryItem(CategorySummary cat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cat.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(cat.icon, color: cat.color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    cat.name,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)
                ),
                Text(
                    '${(cat.percentage * 100).toStringAsFixed(2)}%',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                  "฿${cat.amount.toStringAsFixed(0)}",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white54),
            ],
          ),
        ],
      ),
    );
  }
}