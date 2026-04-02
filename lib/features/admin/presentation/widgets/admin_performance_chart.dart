import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme.dart';

/// Bar chart showing "Order Processing Volume" over the last 30 days.
/// Uses fl_chart with mock data, structured for future Firestore stream.
class AdminPerformanceChart extends StatelessWidget {
  const AdminPerformanceChart({super.key});

  // Mock data: daily order volumes for ~15 bars
  static const List<double> _mockData = [
    420, 550, 380, 680, 890, 760, 920, 1240, 1100, 980, 850, 720, 640, 810, 950
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title Row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Performance',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Order processing volume over the last 30 days',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      'Last 30 Days',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.textSecondaryColor),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Bar Chart ──
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1400,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rod.toY.toInt().toString(),
                        GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: const FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: List.generate(_mockData.length, (i) {
                  final isHighlight = _mockData[i] == _mockData.reduce((a, b) => a > b ? a : b);
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _mockData[i],
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                        color: isHighlight
                            ? AppTheme.primaryColor
                            : AppTheme.primaryColor.withValues(alpha: 0.3),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Footer Stats ──
          Row(
            children: [
              _buildFooterStat('AVG. FULFILLMENT', '14.2 min', AppTheme.textPrimaryColor),
              const SizedBox(width: 40),
              _buildFooterStat('ERROR RATE', '0.02%', AppTheme.primaryColor),
              const SizedBox(width: 40),
              _buildFooterStat('ACTIVE SESSIONS', '4.1k', AppTheme.textPrimaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppTheme.textTertiaryColor,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
