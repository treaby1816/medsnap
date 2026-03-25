import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../widgets/glass_app_bar.dart';

class NearbyFacilitiesScreen extends StatefulWidget {
  const NearbyFacilitiesScreen({super.key});

  @override
  State<NearbyFacilitiesScreen> createState() => _NearbyFacilitiesScreenState();
}

class _NearbyFacilitiesScreenState extends State<NearbyFacilitiesScreen> {
  // ignore: unused_field
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  
  // Initial position: Lagos, Nigeria (approx)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(6.5244, 3.3792),
    zoom: 13.0,
  );

  @override
  void initState() {
    super.initState();
    _loadMockFacilities();
  }

  void _loadMockFacilities() {
    // In a real app, these would come from the Google Places API
    final mockFacilities = [
      _FacilityMarker(
        id: '1',
        name: 'VailMeds Pharmacy - Lekki',
        position: const LatLng(6.4281, 3.4400),
        type: 'pharmacy',
      ),
      _FacilityMarker(
        id: '2',
        name: 'Alpha Diagnostic Lab',
        position: const LatLng(6.4400, 3.4200),
        type: 'lab',
      ),
      _FacilityMarker(
        id: '3',
        name: 'City Health Pharmacy',
        position: const LatLng(6.4500, 3.4600),
        type: 'pharmacy',
      ),
    ];

    setState(() {
      for (var facility in mockFacilities) {
        _markers.add(
          Marker(
            markerId: MarkerId(facility.id),
            position: facility.position,
            infoWindow: InfoWindow(title: facility.name),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              facility.type == 'pharmacy' ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueAzure,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Nearby Facilities',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),
          
          // Floating Info Overlay (Glassmorphism)
          Positioned(
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
                      const Row(
                        children: [
                          _LegendItem(color: Colors.orange, label: 'Pharmacies'),
                          SizedBox(width: 20),
                          _LegendItem(color: Colors.blue, label: 'Labs/Hospitals'),
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
          ),
        ],
      ),
    );
  }
}


class _FacilityMarker {
  final String id;
  final String name;
  final LatLng position;
  final String type;

  _FacilityMarker({required this.id, required this.name, required this.position, required this.type});
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}