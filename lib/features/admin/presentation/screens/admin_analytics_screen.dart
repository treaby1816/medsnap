import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme.dart';

// ─────────────────────────────────────────────────────────────────────
// FINANCE ANALYTICS HUB — Revenue Intelligence Dashboard
// ─────────────────────────────────────────────────────────────────────

/// Mock data model for analytics. Ready for Firestore stream integration.
class _DailyRevenue {
  final String label;
  final double amount;
  const _DailyRevenue(this.label, this.amount);
}

const _mockRevenue = [
  _DailyRevenue('Mon', 42000), _DailyRevenue('Tue', 55000), _DailyRevenue('Wed', 38000),
  _DailyRevenue('Thu', 68000), _DailyRevenue('Fri', 89000), _DailyRevenue('Sat', 76000),
  _DailyRevenue('Sun', 92000),
];

const _mockCategories = [
  {'name': 'Chronic Care', 'pct': 42.0, 'color': Color(0xFFEC5B13)},
  {'name': 'Acute', 'pct': 28.0, 'color': Color(0xFF3B82F6)},
  {'name': 'Wellness', 'pct': 18.0, 'color': Color(0xFF22C55E)},
  {'name': 'Other', 'pct': 12.0, 'color': Color(0xFF94A3B8)},
];

const _mockLeaderboard = [
  {'name': 'Alpine Wellness Center', 'volume': '2,847', 'speed': '8.2 min', 'revenue': '₦1.24M'},
  {'name': 'Central Valley Pharmacy', 'volume': '2,103', 'speed': '9.1 min', 'revenue': '₦980K'},
  {'name': 'Aspen Branch Pharmacy', 'volume': '1,892', 'speed': '11.4 min', 'revenue': '₦870K'},
  {'name': 'Summit Health Depot', 'volume': '1,640', 'speed': '12.0 min', 'revenue': '₦760K'},
  {'name': 'Rocky Mountain Meds', 'volume': '1,201', 'speed': '14.3 min', 'revenue': '₦540K'},
];

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  String _timeRange = 'This Week';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FINANCE & ANALYTICS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryColor, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text('Revenue Intelligence Hub', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
                ],
              ),
              _buildTimeToggle(),
            ],
          ),
          const SizedBox(height: 24),

          // ── Revenue Snapshot (Top Row) ──
          _buildRevenueSnapshots(),
          const SizedBox(height: 24),

          // ── Charts Row: Area Chart + Donut Chart ──
          LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < 800) {
              return Column(children: [
                _buildRevenueChart(),
                const SizedBox(height: 20),
                _buildCategoryDonut(),
              ]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _buildRevenueChart()),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: _buildCategoryDonut()),
            ]);
          }),
          const SizedBox(height: 24),

          // ── Pharmacy Leaderboard ──
          _buildLeaderboard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Time Range Toggle ──
  Widget _buildTimeToggle() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: ['Today', 'This Week', 'Monthly'].map((label) {
          final isActive = _timeRange == label;
          return InkWell(
            onTap: () => setState(() => _timeRange = label),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppTheme.textSecondaryColor),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Revenue Snapshot Cards ──
  Widget _buildRevenueSnapshots() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _revenueCard('Total Platform Revenue', '₦4.82M', '+12.4%', true, const Color(0xFF22C55E)),
        _revenueCard('Net Platform Commission', '₦482K', '+8.1%', true, const Color(0xFF22C55E)),
        _revenueCard('Active Subscriptions', '47', '-2', false, const Color(0xFFEF4444)),
        _revenueCard('Avg. Order Value', '₦18,240', '+3.2%', true, const Color(0xFF22C55E)),
      ],
    );
  }

  Widget _revenueCard(String label, String value, String trend, bool isUp, Color trendColor) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(value, style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: trendColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isUp ? Icons.trending_up : Icons.trending_down, size: 12, color: trendColor),
                    const SizedBox(width: 2),
                    Text(trend, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: trendColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Revenue Growth Area Chart ──
  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenue Growth', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor)),
          Text('$_timeRange volume trends', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor)),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25000,
                  getDrawingHorizontalLine: (value) => const FlLine(color: AppTheme.borderColor, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < _mockRevenue.length) {
                          return Text(_mockRevenue[value.toInt()].label, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textTertiaryColor));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(_mockRevenue.length, (i) => FlSpot(i.toDouble(), _mockRevenue[i].amount)),
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppTheme.primaryColor.withValues(alpha: 0.3), AppTheme.primaryColor.withValues(alpha: 0.0)],
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 100000,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category Split Donut Chart ──
  Widget _buildCategoryDonut() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category Split', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor)),
          Text('Sales by medication type', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: _mockCategories.map((cat) => PieChartSectionData(
                  color: cat['color'] as Color,
                  value: cat['pct'] as double,
                  title: '${(cat['pct'] as double).toInt()}%',
                  radius: 30,
                  titleStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          ...(_mockCategories.map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: cat['color'] as Color, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 8),
                Text(cat['name'] as String, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor)),
                const Spacer(),
                Text('${(cat['pct'] as double).toInt()}%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor)),
              ],
            ),
          ))),
        ],
      ),
    );
  }

  // ── Pharmacy Leaderboard ──
  Widget _buildLeaderboard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Top Performing Pharmacies', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor)),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded, size: 16),
                label: Text('Export Financial Statement', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              _headerCell('RANK', flex: 1),
              _headerCell('PHARMACY NAME', flex: 4),
              _headerCell('TXN VOLUME', flex: 2),
              _headerCell('AVG. FULFILLMENT', flex: 2),
              _headerCell('REVENUE', flex: 2),
            ]),
          ),
          const SizedBox(height: 4),

          // Rows
          ...List.generate(_mockLeaderboard.length, (i) {
            final pharm = _mockLeaderboard[i];
            final isTop = i == 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.5))),
              ),
              child: Row(children: [
                Expanded(flex: 1, child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: isTop ? AppTheme.primaryColor : AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text('${i + 1}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: isTop ? Colors.white : AppTheme.textSecondaryColor)),
                )),
                Expanded(flex: 4, child: Text(pharm['name']!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor))),
                Expanded(flex: 2, child: Text(pharm['volume']!, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondaryColor))),
                Expanded(flex: 2, child: Text(pharm['speed']!, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondaryColor))),
                Expanded(flex: 2, child: Text(pharm['revenue']!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryColor))),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textTertiaryColor, letterSpacing: 1.0)),
    );
  }
}
