import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../constants/colors.dart';
import '../../../providers/donor_provider.dart';
import '../../../models/donor.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  _AnalyticsTabState createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  int? touchedPieIndex;
  int? touchedBarIndex;
  int? touchedDonorBarIndex;
  String _selectedYear = "All Time";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DonorProvider>(context, listen: false).fetchAllDonors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final donorProvider = Provider.of<DonorProvider>(context);
    final donors = donorProvider.donors;

    return RefreshIndicator(
      onRefresh: () => donorProvider.fetchAllDonors(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: _buildAnalyticsContent(context, donorProvider, donors),
      ),
    );
  }

  Widget _buildAnalyticsContent(BuildContext context, DonorProvider donorProvider, List<DonorModel> donors) {
    if (donorProvider.isDonorsLoading && donors.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (donors.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: const Center(
          child: Text(
            "No donor data available to analyze.",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    // Extract unique years from donor donations dynamically
    Set<int> yearsSet = {};
    for (var d in donors) {
      for (var donation in d.donations) {
        yearsSet.add(donation.date.year);
      }
    }
    List<String> yearOptions = ["All Time"];
    List<int> sortedYears = yearsSet.toList()..sort((a, b) => b.compareTo(a));
    for (var year in sortedYears) {
      if (year == DateTime.now().year) {
        yearOptions.add("Current Year ($year)");
      } else {
        yearOptions.add("Year $year");
      }
    }

    // Parse the selected year filter
    int? filterYear;
    if (_selectedYear != "All Time") {
      final regex = RegExp(r'\d+');
      final match = regex.firstMatch(_selectedYear);
      if (match != null) {
        filterYear = int.tryParse(match.group(0)!);
      }
    }

    // --- Dynamic Data Aggregations ---

    double totalAmountCollected = 0.0;
    int totalDonationsCount = 0;
    Set<String> uniqueDonorsSet = {};
    Map<String, double> purposeMap = {};
    Map<String, double> monthlyMap = {}; // Key: "yyyy-MM" (for sorting), Value: total amount
    Map<String, Set<String>> monthlyDonorsMap = {}; // Key: "yyyy-MM", Value: Set of donor IDs

    for (var donor in donors) {
      bool hasDonated = false;
      for (var donation in donor.donations) {
        if (filterYear != null && donation.date.year != filterYear) {
          continue;
        }
        hasDonated = true;
        totalAmountCollected += donation.amount;
        totalDonationsCount++;

        // Purpose grouping
        String purpose = donation.purpose.trim();
        if (purpose.isEmpty) purpose = "General";
        // Capitalize first letter
        purpose = purpose[0].toUpperCase() + purpose.substring(1);
        purposeMap[purpose] = (purposeMap[purpose] ?? 0.0) + donation.amount;

        // Monthly grouping
        String yearMonth = DateFormat('yyyy-MM').format(donation.date);
        monthlyMap[yearMonth] = (monthlyMap[yearMonth] ?? 0.0) + donation.amount;

        if (monthlyDonorsMap[yearMonth] == null) {
          monthlyDonorsMap[yearMonth] = {};
        }
        monthlyDonorsMap[yearMonth]!.add(donor.id ?? donor.mobile);
      }
      if (hasDonated) {
        uniqueDonorsSet.add(donor.id ?? donor.mobile);
      }
    }

    final double avgDonation = totalDonationsCount > 0 ? (totalAmountCollected / totalDonationsCount) : 0.0;
    final int activeDonorsCount = uniqueDonorsSet.length;

    // Sort Monthly maps by date key
    List<String> sortedMonths = monthlyMap.keys.toList()..sort();
    // Only display last 6 months to avoid clutter
    if (sortedMonths.length > 6) {
      sortedMonths = sortedMonths.sublist(sortedMonths.length - 6);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Year Filter Dropdown Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Filter Analytics",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: yearOptions.contains(_selectedYear) ? _selectedYear : "All Time",
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14),
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.accent),
                  items: yearOptions.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      if (val != null) {
                        _selectedYear = val;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        // KPI Summary Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildKPICard(
              "Total Collected",
              "₹${NumberFormat('#,##,###').format(totalAmountCollected)}",
              Icons.monetization_on_rounded,
              AppColors.accent,
            ),
            _buildKPICard(
              "Total Donations",
              "$totalDonationsCount",
              Icons.receipt_long_rounded,
              AppColors.primary,
            ),
            _buildKPICard(
              "Active Donors",
              "$activeDonorsCount",
              Icons.people_alt_rounded,
              Colors.orange,
            ),
            _buildKPICard(
              "Average Donation",
              "₹${avgDonation.toStringAsFixed(0)}",
              Icons.analytics_rounded,
              Colors.purpleAccent,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Purpose Wise Collection Graph (Pie Chart)
        _buildChartCard(
          title: "Purpose-Wise Distribution",
          subtitle: "Total donation share by program/purpose",
          child: _buildPurposePieChart(purposeMap),
        ),
        const SizedBox(height: 16),

        // Month Wise Collection Chart (Bar Chart)
        _buildChartCard(
          title: "Monthly Collections",
          subtitle: "Total collection amount (₹) by month",
          child: _buildMonthlyBarChart(sortedMonths, monthlyMap),
        ),
        const SizedBox(height: 16),

        // Number of People Donated Chart (Bar Chart)
        _buildChartCard(
          title: "Donor Participation",
          subtitle: "Number of unique people who donated by month",
          child: _buildMonthlyDonorsChart(sortedMonths, monthlyDonorsMap),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.trending_up, color: AppColors.textSecondary.withOpacity(0.3), size: 14),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({required String title, required String subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: child,
          ),
        ],
      ),
    );
  }

  // --- Chart Builders ---

  Widget _buildPurposePieChart(Map<String, double> purposeMap) {
    if (purposeMap.isEmpty) {
      return const Center(child: Text("No purpose-wise data", style: TextStyle(color: AppColors.textSecondary)));
    }

    final double totalVal = purposeMap.values.fold(0.0, (sum, val) => sum + val);

    final List<Color> colors = [
      AppColors.primary,
      AppColors.accent,
      Colors.orangeAccent,
      Colors.redAccent,
      Colors.blueAccent,
      Colors.amber,
      Colors.teal,
      Colors.pinkAccent,
    ];

    List<PieChartSectionData> sections = [];
    int colorIdx = 0;
    int index = 0;

    purposeMap.forEach((purpose, amt) {
      final double pct = totalVal > 0 ? (amt / totalVal) * 100 : 0.0;
      final isTouched = index == touchedPieIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 65.0 : 55.0;
      final double shadowOpacity = isTouched ? 0.6 : 0.0;

      sections.add(
        PieChartSectionData(
          color: colors[colorIdx % colors.length],
          value: amt,
          title: '${pct.toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.black.withOpacity(shadowOpacity), blurRadius: 2),
            ],
          ),
        ),
      );
      colorIdx++;
      index++;
    });

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedPieIndex = -1;
                      return;
                    }
                    touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 40,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Custom Legend
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(purposeMap.length, (i) {
                final String purpose = purposeMap.keys.elementAt(i);
                final double amt = purposeMap.values.elementAt(i);
                final Color color = colors[i % colors.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "$purpose (₹${NumberFormat('#,##,###').format(amt)})",
                          style: TextStyle(
                            color: i == touchedPieIndex ? AppColors.textPrimary : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: i == touchedPieIndex ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyBarChart(List<String> sortedMonths, Map<String, double> monthlyMap) {
    if (sortedMonths.isEmpty) {
      return const Center(child: Text("No monthly data", style: TextStyle(color: AppColors.textSecondary)));
    }

    double maxVal = 1000;
    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < sortedMonths.length; i++) {
      final monthKey = sortedMonths[i];
      final amount = monthlyMap[monthKey] ?? 0.0;
      if (amount > maxVal) maxVal = amount;

      final isTouched = i == touchedBarIndex;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: isTouched ? AppColors.accent : AppColors.primary,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxVal * 1.15,
                color: AppColors.border.withOpacity(0.2),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.15,
        barTouchData: BarTouchData(
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  barTouchResponse == null ||
                  barTouchResponse.spot == null) {
                touchedBarIndex = -1;
                return;
              }
              touchedBarIndex = barTouchResponse.spot!.touchedBarGroupIndex;
            });
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surface,
            tooltipBorder: const BorderSide(color: AppColors.border),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final monthKey = sortedMonths[group.x];
              final date = DateFormat('yyyy-MM').parse(monthKey);
              final displayDate = DateFormat('MMM yyyy').format(date);
              return BarTooltipItem(
                "$displayDate\n",
                const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                children: [
                  TextSpan(
                    text: "₹${NumberFormat('#,##,###').format(rod.toY)}",
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                int index = value.toInt();
                if (index >= 0 && index < sortedMonths.length) {
                  final monthKey = sortedMonths[index];
                  final date = DateFormat('yyyy-MM').parse(monthKey);
                  final displayDate = DateFormat('MMM').format(date);
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      displayDate,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                String formattedValue;
                if (value >= 1000000) {
                  formattedValue = '${(value / 1000000).toStringAsFixed(1)}M';
                } else if (value >= 1000) {
                  formattedValue = '${(value / 1000).toStringAsFixed(0)}k';
                } else {
                  formattedValue = value.toStringAsFixed(0);
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    "₹$formattedValue",
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildMonthlyDonorsChart(List<String> sortedMonths, Map<String, Set<String>> monthlyDonorsMap) {
    if (sortedMonths.isEmpty) {
      return const Center(child: Text("No donor tracking data", style: TextStyle(color: AppColors.textSecondary)));
    }

    double maxVal = 10;
    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < sortedMonths.length; i++) {
      final monthKey = sortedMonths[i];
      final donorsCount = (monthlyDonorsMap[monthKey]?.length ?? 0).toDouble();
      if (donorsCount > maxVal) maxVal = donorsCount;

      final isTouched = i == touchedDonorBarIndex;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: donorsCount,
              color: isTouched ? AppColors.primary : Colors.orange,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxVal * 1.15,
                color: AppColors.border.withOpacity(0.2),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.15,
        barTouchData: BarTouchData(
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  barTouchResponse == null ||
                  barTouchResponse.spot == null) {
                touchedDonorBarIndex = -1;
                return;
              }
              touchedDonorBarIndex = barTouchResponse.spot!.touchedBarGroupIndex;
            });
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surface,
            tooltipBorder: const BorderSide(color: AppColors.border),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final monthKey = sortedMonths[group.x];
              final date = DateFormat('yyyy-MM').parse(monthKey);
              final displayDate = DateFormat('MMM yyyy').format(date);
              return BarTooltipItem(
                "$displayDate\n",
                const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                children: [
                  TextSpan(
                    text: "${rod.toY.toInt()} Unique Donors",
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                int index = value.toInt();
                if (index >= 0 && index < sortedMonths.length) {
                  final monthKey = sortedMonths[index];
                  final date = DateFormat('yyyy-MM').parse(monthKey);
                  final displayDate = DateFormat('MMM').format(date);
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      displayDate,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value % 5 != 0) return const SizedBox.shrink(); // Show every 5 increments
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: barGroups,
      ),
    );
  }
}
