import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers.dart';
import '../../../../widgets/glass_app_bar.dart';
import '../../../../widgets/hover_card.dart';

class PharmacyAnalyticsScreen extends ConsumerWidget {
  const PharmacyAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('Please log in')));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Analytics',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Cards
            _buildOverviewRow(),
            const SizedBox(height: 24),
            
            // Revenue Chart
            _buildSectionTitle('Revenue Overview'),
            const SizedBox(height: 16),
            _buildChartCard(const _RevenueChart()),
            const SizedBox(height: 32),
            
            // Order Status Breakdown
            _buildSectionTitle('Order Categories'),
            const SizedBox(height: 16),
            _buildChartCard(const _OrderPieChart()),
            const SizedBox(height: 32),
            
            // Top Products
            _buildSectionTitle('Top Performing Products'),
            const SizedBox(height: 16),
            _buildTopProductsList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildOverviewRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Revenue',
            '₦482.5k',
            Icons.account_balance_wallet_outlined,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Active Orders',
            '14',
            Icons.shopping_bag_outlined,
            AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return HoverCard(
      padding: const EdgeInsets.all(20),
      liftAmount: -10,
      scaleAmount: 1.04,
      glowColor: color,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(Widget chart) {
    return HoverCard(
      padding: const EdgeInsets.all(24),
      liftAmount: -15,
      scaleAmount: 1.02,
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 240,
        child: chart,
      ),
    );
  }

  Widget _buildTopProductsList() {
    final products = [
      {'name': 'Amoxicillin 500mg', 'sales': '124', 'growth': '+12%'},
      {'name': 'Paracetamol Extra', 'sales': '98', 'growth': '+5%'},
      {'name': 'Vitamin C 1000mg', 'sales': '86', 'growth': '+20%'},
    ];

    return Column(
      children: products.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: HoverCard(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(16),
          liftAmount: -6,
          scaleAmount: 1.02,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medication_outlined, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${p['sales']!} units sold', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                  ],
                ),
              ),
              Text(
                p['growth']!,
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart();

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 3),
              const FlSpot(2.6, 2),
              const FlSpot(4.9, 5),
              const FlSpot(6.8, 3.1),
              const FlSpot(8, 4),
              const FlSpot(9.5, 3),
              const FlSpot(11, 4),
            ],
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderPieChart extends StatelessWidget {
  const _OrderPieChart();

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: AppTheme.primaryColor,
            value: 40,
            title: '40%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            color: Colors.blueAccent,
            value: 30,
            title: '30%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            color: Colors.orangeAccent,
            value: 15,
            title: '15%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            color: Colors.tealAccent,
            value: 15,
            title: '15%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
