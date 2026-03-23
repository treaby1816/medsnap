// lib/models/facility_model.dart
enum FacilityType { hospital, lab, pharmacy, gynaecologist }

class MedicalFacility {
  final String name;
  final FacilityType type;
  final double rating;
  final int reviewCount;
  final double distanceMiles;
  final bool isOpen;
  final String imageUrl;

  MedicalFacility({
    required this.name,
    required this.type,
    required this.rating,
    required this.reviewCount,
    required this.distanceMiles,
    required this.isOpen,
    required this.imageUrl,
  });
}