import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme.dart';

// ─────────────────────────────────────────────────────────────────────
// FINANCE ANALYTICS HUB — Revenue Intelligence Dashboard
// ─────────────────────────────────────────────────────────────────────

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

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> with SingleTickerProviderStateMixin {
  String _timeRange = 'This Week';
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
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
                    Text(
                      'FINANCE & ANALYTICS', 
                      style: GoogleFonts.inter(
                        fontSize: 11, 
                        fontWeight: FontWeight.w800, 
                        color: AppTheme.primaryColor, 
                        letterSpacing: 2.0
                      )
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Revenue Intelligence Hub', 
                      style: GoogleFonts.inter(
                        fontSize: 28, 
                        fontWeight: FontWeight.w800, 
                        color: AppTheme.textPrimaryColor,
                        letterSpacing: -0.5
                      )
                    ),
                  ],
                ),
                _buildTimeToggle(),
              ],
            ),
            const SizedBox(height: 32),

            // ── Revenue Snapshot Cards ──
            _buildRevenueSnapshots(),
            const SizedBox(height: 32),

            // ── Charts Row ──
            LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return Column(children: [
                  _buildRevenueChart(),
                  const SizedBox(height: 24),
                  _buildCategoryDonut(),
                ]);
              }
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: _buildRevenueChart()),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildCategoryDonut()),
              ]);
            }),
            const SizedBox(height: 32),

            // ── Pharmacy Leaderboard ──
            _buildLeaderboard(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ['Today', 'This Week', 'Monthly'].map((label) {
          final isActive = _timeRange == label;
          return InkWell(
            onTap: () => setState(() => _timeRange = label),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isActive ? [
                  BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))
                ] : null,
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12, 
                  fontWeight: FontWeight.w700, 
                  color: isActive ? Colors.white : AppTheme.textSecondaryColor
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRevenueSnapshots() {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        _revenueCard('Platform Gross Revenue', '₦4.82M', '+12.4%', true, const Color(0xFF22C55E), [const Color(0xFF22C55E), const Color(0xFF16A34A)]),
        _revenueCard('Commission (VailMeds)', '₦482,000', '+8.1%', true, const Color(0xFF3B82F6), [const Color(0xFF3B82F6), const Color(0xFF2563EB)]),
        _revenueCard('Active Subscriptions', '47', '-2', false, const Color(0xFFEF4444), [const Color(0xFFEF4444), const Color(0xFFDC2626)]),
        _revenueCard('Avg. Checkout Value', '₦18,240', '+3.2%', true, const Color(0xFFF59E0B), [const Color(0xFFF59E0B), const Color(0xFFD97706)]),
      ],
    );
  }

  Widget _revenueCard(String label, String value, String trend, bool isUp, Color trendColor, List<Color> gradient) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 14, color: trendColor),
                    const SizedBox(width: 4),
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

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))
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
                  Text('Revenue Performance', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
                  const SizedBox(height: 4),
                  Text('Volume distribution across therapeutic categories', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondaryColor)),
                ],
              ),
              const Icon(Icons.show_chart_rounded, color: AppTheme.primaryColor),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25000,
                  getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.borderColor.withValues(alpha: 0.5), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) => Text(
                        '₦${(value/1000).toInt()}k',
                        style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textTertiaryColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < _mockRevenue.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(_mockRevenue[index].label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500)),
                          );
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
                    curveSmoothness: 0.35,
                    color: AppTheme.primaryColor,
                    barWidth: 4,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 5,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: AppTheme.primaryColor,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppTheme.primaryColor.withValues(alpha: 0.2), AppTheme.primaryColor.withValues(alpha: 0.0)],
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

  Widget _buildCategoryDonut() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Market Allocation', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
          const SizedBox(height: 4),
          Text('Top medication categories', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondaryColor)),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 60,
                sections: _mockCategories.map((cat) => PieChartSectionData(
                  color: cat['color'] as Color,
                  value: cat['pct'] as double,
                  title: '',
                  radius: 20,
                  badgeWidget: _Badge(cat['color'] as Color, size: 40),
                  badgePositionPercentageOffset: 1.0,
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ...(_mockCategories.map((cat) => _legendItem(cat['name'] as String, cat['pct'] as double, cat['color'] as Color))),
        ],
      ),
    );
  }

  Widget _legendItem(String name, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondaryColor)),
          const Spacer(),
          Text('${pct.toInt()}%', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor)),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Top Performing Nodes', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.file_download_outlined, size: 20),
                label: Text('Full Audit Log', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Scrollable table area
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    color: AppTheme.backgroundColor,
                    child: Row(children: [
                      _headerCell('RANK', flex: 1),
                      _headerCell('PHARMACY CORE', flex: 4),
                      _headerCell('TX VOLUME', flex: 2),
                      _headerCell('LATENCY', flex: 2),
                      _headerCell('REVENUE', flex: 2),
                    ]),
                  ),
                  ...List.generate(_mockLeaderboard.length, (i) {
                    final pharm = _mockLeaderboard[i];
                    final isTop = i == 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      decoration: BoxDecoration(
                        color: isTop ? AppTheme.primaryColor.withValues(alpha: 0.02) : Colors.white,
                        border: Border(bottom: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.5))),
                      ),
                      child: Row(children: [
                        Expanded(flex: 1, child: Text(
                          '0${i + 1}', 
                          style: GoogleFonts.inter(
                            fontSize: 14, 
                            fontWeight: FontWeight.w800, 
                            color: isTop ? AppTheme.primaryColor : AppTheme.textTertiaryColor
                          )
                        )),
                        Expanded(flex: 4, child: Row(
                          children: [
                            CircleAvatar(radius: 4, backgroundColor: isTop ? AppTheme.primaryColor : Colors.transparent),
                            SizedBox(width: isTop ? 10 : 0),
                            Text(pharm['name']!, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor)),
                          ],
                        )),
                        Expanded(flex: 2, child: Text(pharm['volume']!, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondaryColor))),
                        Expanded(flex: 2, child: Row(
                          children: [
                            Icon(Icons.bolt_rounded, size: 14, color: isTop ? const Color(0xFF22C55E) : AppTheme.textTertiaryColor),
                            const SizedBox(width: 4),
                            Text(pharm['speed']!, style: GoogleFonts.inter(fontSize: 14, color: isTop ? const Color(0xFF22C55E) : AppTheme.textSecondaryColor)),
                          ],
                        )),
                        Expanded(flex: 2, child: Text(
                          pharm['revenue']!, 
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)
                        )),
                      ]),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textTertiaryColor, letterSpacing: 1.5)),
    );
  }
}

class _Badge extends StatelessWidget {
  final Color color;
  final double size;
  const _Badge(this.color, {required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Center(child: Container(width: size * 0.4, height: size * 0.4, decoration: BoxDecoration(color: color, shape: BoxShape.circle))),
    );
  }
}
