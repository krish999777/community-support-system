import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../constants/colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/donor_provider.dart';
import '../auth/login_screen.dart';
import '../donors/donor_list_screen.dart';
import '../donors/add_donor_screen.dart';
import '../donors/new_donation_screen.dart';
import 'reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DonorProvider>(context, listen: false).fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final donorProvider = Provider.of<DonorProvider>(context);
    final stats = donorProvider.stats;

    final double totalAmount = (stats['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final int registeredCount = stats['totalDonorsRegistered'] ?? 0;
    final int activeCount = stats['totalDonorsDonated'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          "Dashboard",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () async {
              await authProvider.logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => donorProvider.fetchDashboardStats(),
        color: AppColors.primary,
        child: _buildDashboardBody(context, authProvider, donorProvider, stats, totalAmount, registeredCount, activeCount),
      ),
    );
  }

  Widget _buildDashboardBody(
    BuildContext context,
    AuthProvider authProvider,
    DonorProvider donorProvider,
    Map<String, dynamic> stats,
    double totalAmount,
    int registeredCount,
    int activeCount,
  ) {
    double maxMonthlyAmount = 1000.0;
    if (stats['monthlyStats'] != null && (stats['monthlyStats'] as List).isNotEmpty) {
      for (var stat in stats['monthlyStats'] as List) {
        final amt = (stat['amount'] as num?)?.toDouble() ?? 0.0;
        if (amt > maxMonthlyAmount) {
          maxMonthlyAmount = amt;
        }
      }
    }

    if (donorProvider.isStatsLoading && stats.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    if (donorProvider.errorMessage != null && stats.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(
                  donorProvider.errorMessage!,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => donorProvider.fetchDashboardStats(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome,",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                  Text(
                    authProvider.currentUser?.username ?? "Admin",
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                ),
                child: Text(
                  authProvider.currentUser?.role.toUpperCase() ?? "ADMIN",
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Metrics Grid (Optimized full-width card for total collections + side-by-side cards)
          _buildMetricCardFullWidth(
            "Total Collected",
            "₹${totalAmount.toStringAsFixed(0)}",
            Icons.account_balance_wallet_rounded,
            AppColors.primary,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  "Total Donors",
                  "$registeredCount",
                  Icons.people_alt_rounded,
                  AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  "Active Donors",
                  "$activeCount",
                  Icons.check_circle_outline_rounded,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Actions Grid
          const Text(
            "Quick Actions",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  "Add Donor",
                  "Register profiles",
                  Icons.person_add_alt_1_rounded,
                  AppColors.primaryGradient,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddDonorScreen()),
                    ).then((_) => donorProvider.fetchDashboardStats());
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  "New Donation",
                  "No PAN/Aadhaar",
                  Icons.volunteer_activism_rounded,
                  const LinearGradient(
                    colors: [AppColors.accent, Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NewDonationScreen()),
                    ).then((_) => donorProvider.fetchDashboardStats());
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Navigation List
          const Text(
            "Management Console",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildMenuTile(
            "Donor Directory",
            "Search, view profiles, and record donations",
            Icons.contact_phone_rounded,
            AppColors.primary,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DonorListScreen()),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            "Reports Generator",
            "Generate, filter, and export donation CSV reports",
            Icons.summarize_rounded,
            Colors.teal,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
          const SizedBox(height: 8),

          // Simple Charts Summary if monthly stats exist
          if (stats['monthlyStats'] != null && (stats['monthlyStats'] as List).isNotEmpty) ...[
            const Text(
              "Donation Trend Summary",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxMonthlyAmount * 1.15,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final list = stats['monthlyStats'] as List;
                          int index = value.toInt();
                          if (index >= 0 && index < list.length) {
                            String monthStr = list[index]['month']?.toString() ?? '';
                            String displayMonth = monthStr;
                            if (monthStr.contains(' ')) {
                              displayMonth = monthStr.substring(0, monthStr.indexOf(' '));
                            } else if (monthStr.length > 3) {
                              displayMonth = monthStr.substring(0, 3);
                            }
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                displayMonth,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: _buildBarGroups(stats['monthlyStats'] as List),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCardFullWidth(String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Icon(Icons.trending_up, color: color.withOpacity(0.5), size: 24),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
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
              Icon(icon, color: color, size: 24),
              Icon(Icons.trending_up, color: color.withOpacity(0.5), size: 16),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
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

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Gradient gradient,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      tileColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 16),
    );
  }

  List<BarChartGroupData> _buildBarGroups(List monthlyStats) {
    List<BarChartGroupData> groups = [];
    // Limit to last 5 months
    int count = monthlyStats.length > 5 ? 5 : monthlyStats.length;
    for (int i = 0; i < count; i++) {
      final stat = monthlyStats[i];
      final amount = (stat['amount'] as num?)?.toDouble() ?? 0.0;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: AppColors.primary,
              width: 14,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
    return groups;
  }
}
