import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  /// Request permission and get the current position securely.
  /// Throws an exception if permissions are denied.
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    } 

    return await Geolocator.getCurrentPosition();
  }

  /// Calculates the driving distance and estimated time in a human readable record.
  /// For now, we simulate an average urban driving speed of 30 km/h (500m / min).
  ({double distanceInKm, int estimatedMinutes}) calculateDistanceAndDuration(
      double startLat, double startLng, double endLat, double endLng) {
    
    const Distance distanceCalculator = Distance();
    
    // Distance in meters
    final double meter = distanceCalculator(
        LatLng(startLat, startLng),
        LatLng(endLat, endLng)
    );
    
    final double distanceInKm = meter / 1000;
    
    // Assume average inner-city speed of 30 km/h -> 0.5 km per minute
    final int estimatedMinutes = (distanceInKm / 0.5).ceil();
    
    return (
      distanceInKm: distanceInKm,
      estimatedMinutes: estimatedMinutes == 0 ? 1 : estimatedMinutes, // Minimum 1 min
    );
  }
}
