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
  String _selectedMonth = "All";
  String _selectedPurpose = "All";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final donorProvider = Provider.of<DonorProvider>(context, listen: false);
      donorProvider.fetchAllDonors();
      donorProvider.fetchAnalyticsStats(
        year: _selectedYear,
        month: _selectedMonth,
        purpose: _selectedPurpose,
      );
    });
  }

  void _fetchStats() {
    Provider.of<DonorProvider>(context, listen: false).fetchAnalyticsStats(
      year: _selectedYear,
      month: _selectedMonth,
      purpose: _selectedPurpose,
    );
  }

  @override
  Widget build(BuildContext context) {
    final donorProvider = Provider.of<DonorProvider>(context);
    final donors = donorProvider.donors;

    return RefreshIndicator(
      onRefresh: () async {
        await donorProvider.fetchAllDonors();
        await donorProvider.fetchAnalyticsStats(
          year: _selectedYear,
          month: _selectedMonth,
          purpose: _selectedPurpose,
        );
      },
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: _buildAnalyticsContent(context, donorProvider, donors),
      ),
    );
  }

  Widget _buildAnalyticsContent(BuildContext context, DonorProvider donorProvider, List<DonorModel> donors) {
    final analyticsStats = donorProvider.analyticsStats;

    // Show loading spinner if stats are loading and we have no previous data
    final isLoading = donorProvider.isAnalyticsLoading || (donorProvider.isDonorsLoading && donors.isEmpty);
    if (isLoading && analyticsStats.isEmpty) {
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

    // Extract unique years from donor donations dynamically to populate dropdown options
    Set<int> yearsSet = {};
    Set<String> purposesSet = {"All"};
    for (var d in donors) {
      for (var donation in d.donations) {
        yearsSet.add(donation.date.year);
        if (donation.purpose.trim().isNotEmpty) {
          String purpose = donation.purpose.trim();
          purpose = purpose[0].toUpperCase() + purpose.substring(1);
          purposesSet.add(purpose);
        }
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

    List<String> purposeOptions = purposesSet.toList()..sort();
    List<String> monthOptions = [
      "All",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];

    // --- Parse Backend Analytics Data ---
    final double totalAmountCollected = (analyticsStats['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final int activeDonorsCount = (analyticsStats['totalDonorsDonated'] ?? 0) as int;

    // Parse purpose map
    Map<String, double> purposeMap = {};
    if (analyticsStats['purposes'] != null) {
      for (var item in analyticsStats['purposes']) {
        final String name = item['name'] ?? 'General';
        final double amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
        if (amount > 0) {
          final formattedName = name.trim().isNotEmpty 
              ? name[0].toUpperCase() + name.substring(1) 
              : "General";
          purposeMap[formattedName] = (purposeMap[formattedName] ?? 0.0) + amount;
        }
      }
    }

    // Parse monthly stats list
    final List monthlyStatsList = List.from(analyticsStats['monthlyStats'] ?? []);
    // Sort chronological: sortKey ascending (older to newer)
    monthlyStatsList.sort((a, b) => ((a['sortKey'] ?? 0) as num).compareTo((b['sortKey'] ?? 0) as num));

    // Calculate total donations count (sum of transaction count in all months)
    int totalDonationsCount = 0;
    for (var item in monthlyStatsList) {
      totalDonationsCount += ((item['count'] ?? 0) as num).toInt();
    }

    final double avgDonation = totalDonationsCount > 0 ? (totalAmountCollected / totalDonationsCount) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Year, Month, Purpose Filters Container
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.filter_alt_rounded, color: AppColors.primary, size: 20),
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
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Year Filter Dropdown
                      SizedBox(
                        width: (constraints.maxWidth - 24) / 3 > 100 ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth,
                        child: _buildFilterDropdown(
                          label: "Year",
                          value: _selectedYear,
                          items: yearOptions,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedYear = val;
                              });
                              _fetchStats();
                            }
                          },
                        ),
                      ),
                      // Month Filter Dropdown
                      SizedBox(
                        width: (constraints.maxWidth - 24) / 3 > 100 ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth,
                        child: _buildFilterDropdown(
                          label: "Month",
                          value: _selectedMonth,
                          items: monthOptions,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedMonth = val;
                              });
                              _fetchStats();
                            }
                          },
                        ),
                      ),
                      // Purpose Filter Dropdown
                      SizedBox(
                        width: (constraints.maxWidth - 24) / 3 > 100 ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth,
                        child: _buildFilterDropdown(
                          label: "Description",
                          value: _selectedPurpose,
                          items: purposeOptions,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPurpose = val;
                              });
                              _fetchStats();
                            }
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        if (donorProvider.isAnalyticsLoading) ...[
          const LinearProgressIndicator(color: AppColors.primary, minHeight: 2),
          const SizedBox(height: 8),
        ],

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

        // Description Wise Collection Graph (Pie Chart)
        _buildChartCard(
          title: "Description-Wise Distribution",
          subtitle: "Total donation share by description",
          child: _buildPurposePieChart(purposeMap),
        ),
        const SizedBox(height: 16),

        // Month Wise Collection Chart (Bar Chart)
        _buildChartCard(
          title: "Monthly Collections",
          subtitle: "Total collection amount (₹) by month",
          child: _buildMonthlyBarChart(monthlyStatsList),
        ),
        const SizedBox(height: 16),

        // Number of People Donated Chart (Bar Chart)
        _buildChartCard(
          title: "Donation Frequency",
          subtitle: "Number of donations by month",
          child: _buildMonthlyDonationsChart(monthlyStatsList),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.contains(value) ? value : items.first,
              dropdownColor: AppColors.surface,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary, size: 20),
              items: items.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
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

  Widget _buildPurposePieChart(Map<String, double> purposeMap) {
    if (purposeMap.isEmpty) {
      return const Center(child: Text("No description-wise data", style: TextStyle(color: AppColors.textSecondary)));
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
                            fontSize: 11,
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

  Widget _buildMonthlyBarChart(List monthlyStatsList) {
    if (monthlyStatsList.isEmpty) {
      return const Center(child: Text("No monthly data", style: TextStyle(color: AppColors.textSecondary)));
    }

    double maxVal = 1000;
    List<BarChartGroupData> barGroups = [];

    final displayList = monthlyStatsList.length > 6 
        ? monthlyStatsList.sublist(monthlyStatsList.length - 6) 
        : monthlyStatsList;

    for (int i = 0; i < displayList.length; i++) {
      final stat = displayList[i];
      final amount = (stat['amount'] as num?)?.toDouble() ?? 0.0;
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
              final stat = displayList[group.x];
              final String monthLabel = stat['month'] ?? '';
              return BarTooltipItem(
                "$monthLabel\n",
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
                if (index >= 0 && index < displayList.length) {
                  final stat = displayList[index];
                  final String monthLabel = stat['month'] ?? '';
                  String shortMonth = monthLabel;
                  if (monthLabel.isNotEmpty) {
                    final parts = monthLabel.split(' ');
                    if (parts.isNotEmpty) {
                      final monthName = parts[0];
                      if (monthName.length > 3) {
                        shortMonth = monthName.substring(0, 3);
                      } else {
                        shortMonth = monthName;
                      }
                    }
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      shortMonth,
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

  Widget _buildMonthlyDonationsChart(List monthlyStatsList) {
    if (monthlyStatsList.isEmpty) {
      return const Center(child: Text("No donation tracking data", style: TextStyle(color: AppColors.textSecondary)));
    }

    double maxVal = 10;
    List<BarChartGroupData> barGroups = [];

    final displayList = monthlyStatsList.length > 6 
        ? monthlyStatsList.sublist(monthlyStatsList.length - 6) 
        : monthlyStatsList;

    for (int i = 0; i < displayList.length; i++) {
      final stat = displayList[i];
      final donationsCount = ((stat['count'] ?? 0) as num).toDouble();
      if (donationsCount > maxVal) maxVal = donationsCount;

      final isTouched = i == touchedDonorBarIndex;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: donationsCount,
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
              final stat = displayList[group.x];
              final String monthLabel = stat['month'] ?? '';
              return BarTooltipItem(
                "$monthLabel\n",
                const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                children: [
                  TextSpan(
                    text: "${rod.toY.toInt()} Donations",
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
                if (index >= 0 && index < displayList.length) {
                  final stat = displayList[index];
                  final String monthLabel = stat['month'] ?? '';
                  String shortMonth = monthLabel;
                  if (monthLabel.isNotEmpty) {
                    final parts = monthLabel.split(' ');
                    if (parts.isNotEmpty) {
                      final monthName = parts[0];
                      if (monthName.length > 3) {
                        shortMonth = monthName.substring(0, 3);
                      } else {
                        shortMonth = monthName;
                      }
                    }
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      shortMonth,
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
                if (value % 5 != 0) return const SizedBox.shrink();
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
