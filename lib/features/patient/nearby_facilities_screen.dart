import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../widgets/glass_app_bar.dart';

class NearbyFacilitiesScreen extends StatefulWidget {
  const NearbyFacilitiesScreen({super.key});

  @override
  State<NearbyFacilitiesScreen> createState() => _NearbyFacilitiesScreenState();
}

class _NearbyFacilitiesScreenState extends State<NearbyFacilitiesScreen> {
  final MapController _mapController = MapController();

  // Center of Lekki, Lagos
  final LatLng _initialCenter = const LatLng(6.4526, 3.4475);

  // Mock facilities data with coordinates
  final List<_FacilityData> _facilities = const [
    _FacilityData(
      name: 'VailMeds Pharmacy - Lekki',
      address: 'Plot 14, Admiralty Way, Lekki Phase 1',
      type: 'pharmacy',
      distance: '0.8 km',
      hours: 'Open until 9 PM',
      location: LatLng(6.4468, 3.4563),
    ),
    _FacilityData(
      name: 'Alpha Diagnostic Lab',
      address: '22 Ozumba Mbadiwe Ave, Victoria Island',
      type: 'lab',
      distance: '1.2 km',
      hours: 'Open until 6 PM',
      location: LatLng(6.4347, 3.4244),
    ),
    _FacilityData(
      name: 'City Health Pharmacy',
      address: '5 Akin Adesola St, Victoria Island',
      type: 'pharmacy',
      distance: '2.1 km',
      hours: 'Open 24h',
      location: LatLng(6.4285, 3.4150),
    ),
    _FacilityData(
      name: 'MedPlus Pharmacy',
      address: '34 Isaac John St, Ikeja GRA',
      type: 'pharmacy',
      distance: '3.5 km',
      hours: 'Open until 10 PM',
      location: LatLng(6.5862, 3.3592),
    ),
    _FacilityData(
      name: 'Reddington Hospital',
      address: '12 Idowu Martins St, Victoria Island',
      type: 'hospital',
      distance: '1.8 km',
      hours: 'Open 24h',
      location: LatLng(6.4253, 3.4137),
    ),
  ];

  void _focusFacility(_FacilityData facility) {
    _mapController.move(facility.location, 16.0);
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
      body: Column(
        children: [
          // Top Half: OpenStreetMap (flutter_map)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.40,
            width: double.infinity,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: 13.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.vailmeds.app',
                ),
                MarkerLayer(
                  markers: _facilities.map((facility) {
                    Color markerColor;
                    switch (facility.type) {
                      case 'pharmacy': markerColor = AppTheme.primaryColor; break;
                      case 'lab': markerColor = const Color(0xFF3B82F6); break;
                      case 'hospital': markerColor = const Color(0xFF22C55E); break;
                      default: markerColor = Colors.red;
                    }

                    return Marker(
                      point: facility.location,
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(facility.name), duration: const Duration(seconds: 1)),
                          );
                        },
                        child: Icon(
                          Icons.location_on_rounded,
                          color: markerColor,
                          size: 40,
                        ),
                      ),
                    );
                  }).toList(),
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

          // Facility list (Clickable to focus on Map)
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _facilities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildFacilityCard(_facilities[index]),
            ),
          ),
        ],
      ),
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

    return InkWell(
      onTap: () => _focusFacility(facility),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.directions_rounded, size: 18, color: AppTheme.primaryColor),
                ),
              ],
            ),
          ],
        ),
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
}

class _FacilityData {
  final String name;
  final String address;
  final String type;
  final String distance;
  final String hours;
  final LatLng location;

  const _FacilityData({
    required this.name,
    required this.address,
    required this.type,
    required this.distance,
    required this.hours,
    required this.location,
  });
}
