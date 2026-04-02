import 'package:vail_meds_v2/core/models/facility_model.dart';

class HealthcareRepository {
  Future<List<MedicalFacility>> fetchNearby() async {
    // This simulates a 1-second delay like a real API call
    await Future.delayed(const Duration(seconds: 1)); 
    
    return [
      MedicalFacility(
        name: "Vail Memorial Hospital",
        type: FacilityType.hospital,
        rating: 4.8,
        reviewCount: 124,
        distanceMiles: 0.8,
        isOpen: true,
        imageUrl: "https://placehold.co/80x80",
      ),
    ];
  }
}
