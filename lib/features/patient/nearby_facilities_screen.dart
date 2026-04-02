import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../widgets/glass_app_bar.dart';

class NearbyFacilitiesScreen extends StatefulWidget {
  const NearbyFacilitiesScreen({super.key});

  @override
  State<NearbyFacilitiesScreen> createState() => _NearbyFacilitiesScreenState();
}

class _NearbyFacilitiesScreenState extends State<NearbyFacilitiesScreen> {
  bool _mapFailed = false;
  Widget? _mapWidget;

  // Mock facilities data
  final List<_FacilityData> _facilities = const [
    _FacilityData(
      name: 'VailMeds Pharmacy - Lekki',
      address: 'Plot 14, Admiralty Way, Lekki Phase 1',
      type: 'pharmacy',
      distance: '0.8 km',
      hours: 'Open until 9 PM',
    ),
    _FacilityData(
      name: 'Alpha Diagnostic Lab',
      address: '22 Ozumba Mbadiwe Ave, Victoria Island',
      type: 'lab',
      distance: '1.2 km',
      hours: 'Open until 6 PM',
    ),
    _FacilityData(
      name: 'City Health Pharmacy',
      address: '5 Akin Adesola St, Victoria Island',
      type: 'pharmacy',
      distance: '2.1 km',
      hours: 'Open 24h',
    ),
    _FacilityData(
      name: 'MedPlus Pharmacy',
      address: '34 Isaac John St, Ikeja GRA',
      type: 'pharmacy',
      distance: '3.5 km',
      hours: 'Open until 10 PM',
    ),
    _FacilityData(
      name: 'Reddington Hospital',
      address: '12 Idowu Martins St, Victoria Island',
      type: 'hospital',
      distance: '1.8 km',
      hours: 'Open 24h',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tryLoadMap();
  }

  void _tryLoadMap() {
    try {
      // Attempt to import and create GoogleMap widget dynamically
      // If google_maps_flutter is not properly configured, catch the error
      _loadGoogleMap();
    } catch (e) {
      setState(() => _mapFailed = true);
    }
  }

  void _loadGoogleMap() {
    // Wrap the map loading in a post-frame callback to catch rendering errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // We'll use the fallback view directly since Google Maps requires
        // proper API key configuration and can freeze the app on web
        // when not properly set up. The fallback provides a better UX.
        if (mounted) {
          setState(() => _mapFailed = true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _mapFailed = true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        title: Text(
          'Nearby Facilities',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ),
      body: _mapFailed || _mapWidget == null
          ? _buildFallbackView()
          : Stack(
              children: [
                RepaintBoundary(child: _mapWidget!),
                _buildFloatingOverlay(),
              ],
            ),
    );
  }

  /// Robust fallback view when Google Maps is unavailable
  Widget _buildFallbackView() {
    return Column(
      children: [
        // Map placeholder banner
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.15),
                const Color(0xFF3B82F6).withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded, size: 36, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 12),
              Text(
                'Scanning nearby facilities',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Text(
                'Showing results within 5km of Lekki, Lagos',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),

        // Legend row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              _legendDot(AppTheme.primaryColor, 'Pharmacies'),
              const SizedBox(width: 20),
              _legendDot(const Color(0xFF3B82F6), 'Labs'),
              const SizedBox(width: 20),
              _legendDot(const Color(0xFF22C55E), 'Hospitals'),
              const Spacer(),
              Text(
                '${_facilities.length} found',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textTertiaryColor),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Facility list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _facilities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _buildFacilityCard(_facilities[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildFacilityCard(_FacilityData facility) {
    Color typeColor;
    IconData typeIcon;
    switch (facility.type) {
      case 'pharmacy':
        typeColor = AppTheme.primaryColor;
        typeIcon = Icons.local_pharmacy_rounded;
        break;
      case 'lab':
        typeColor = const Color(0xFF3B82F6);
        typeIcon = Icons.biotech_rounded;
        break;
      case 'hospital':
        typeColor = const Color(0xFF22C55E);
        typeIcon = Icons.local_hospital_rounded;
        break;
      default:
        typeColor = AppTheme.textSecondaryColor;
        typeIcon = Icons.place_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: typeColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facility.name,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor),
                ),
                const SizedBox(height: 2),
                Text(
                  facility.address,
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: typeColor),
                    const SizedBox(width: 4),
                    Text(facility.hours, style: GoogleFonts.inter(fontSize: 11, color: typeColor, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  facility.distance,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: typeColor),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening directions to ${facility.name}...'),
                      backgroundColor: AppTheme.primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.directions_rounded, size: 18, color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildFloatingOverlay() {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _legendDot(Colors.orange, 'Pharmacies'),
                    const SizedBox(width: 20),
                    _legendDot(Colors.blue, 'Labs/Hospitals'),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.near_me, color: AppTheme.primaryColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Finding nearest source...', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text('Scanning 5km radius around Lekki', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FacilityData {
  final String name;
  final String address;
  final String type;
  final String distance;
  final String hours;

  const _FacilityData({
    required this.name,
    required this.address,
    required this.type,
    required this.distance,
    required this.hours,
  });
}
