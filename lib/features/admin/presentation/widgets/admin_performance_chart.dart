import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme.dart';

/// Clinical Performance Intelligence Hub showing order volume telemetry.
class AdminPerformanceChart extends StatelessWidget {
  const AdminPerformanceChart({super.key});

  static const List<FlSpot> _spots = [
    FlSpot(0, 420), FlSpot(1, 550), FlSpot(2, 380), FlSpot(3, 680),
    FlSpot(4, 890), FlSpot(5, 760), FlSpot(6, 920), FlSpot(7, 1240),
    FlSpot(8, 1100), FlSpot(9, 980), FlSpot(10, 850), FlSpot(11, 720),
    FlSpot(12, 640), FlSpot(13, 810), FlSpot(14, 950),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SYSTEM LATENCY & THROUGHPUT',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryColor, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Digital Clinical Throughput',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor),
                  ),
                ],
              ),
              _buildPulseIndicator(),
            ],
          ),
          const SizedBox(height: 32),

          // ── Line Chart with Premium Gradients ──
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 12,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toInt()} RX',
                          GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    barWidth: 4,
                    color: AppTheme.primaryColor,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.15),
                          AppTheme.primaryColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── High-Density Telemetry ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _telemetryStat('AVG. RX TIME', '14.2m', Icons.timer_outlined),
                _separator(),
                _telemetryStat('ERROR RATE', '0.02%', Icons.error_outline_rounded),
                _separator(),
                _telemetryStat('AUDIT STATUS', 'SYNCED', Icons.sync_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('LIVE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF22C55E))),
        ],
      ),
    );
  }

  Widget _telemetryStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppTheme.textTertiaryColor),
              const SizedBox(width: 4),
              Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textTertiaryColor, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
        ],
      ),
    );
  }

  Widget _separator() {
    return Container(width: 1, height: 24, color: AppTheme.borderColor, margin: const EdgeInsets.symmetric(horizontal: 10));
  }
}
