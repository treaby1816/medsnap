import 'package:supabase_flutter/supabase_flutter.dart';


class GeoService {
  final _supabase = Supabase.instance.client;

  Future<List<dynamic>> getNearbyPharmacies({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
    required String drugName,
  }) async {
    // PostGIS query — searches Supabase directly, zero Google API cost
    final response = await _supabase.rpc('get_nearby_pharmacies', params: {
      'user_lat': lat,
      'user_lng': lng,
      'radius_km': radiusKm,
      'drug_search': drugName,
    });

    return response as List;
  }
}
