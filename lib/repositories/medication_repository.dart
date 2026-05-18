import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vail_meds_v2/core/models/medication_model.dart';

/// Real-time Supabase connection for medications.
class MedicationRepository {
  static final MedicationRepository _instance = MedicationRepository._internal();
  factory MedicationRepository() => _instance;
  MedicationRepository._internal();

  final _supabase = Supabase.instance.client;

  /// Retrieves a live stream of urgent medications from Supabase,
  /// seamlessly mapped to the Medication UI model.
  Stream<List<Medication>> getUrgentInventoryStream() {
    return _supabase
        .from('medications')
        .stream(primaryKey: ['id'])
        .eq('isUrgent', true)
        .map((maps) {
      return maps.map((doc) {
        // Assume Medication.fromFirestore is adapted to map or we provide a new factory
        return Medication.fromMap(doc, doc['id'].toString());
      }).toList();
    });
  }

  /// Appends to the datastore
  Future<void> add(Medication med) async {
    await _supabase.from('medications').insert({
      'name': med.name,
      'brand': med.brand,
      'price': med.price,
      'category': med.category,
      'isAvailable': med.isAvailable,
      'imagePath': med.imagePath,
      'stockCount': med.stockCount,
      'isUrgent': med.isUrgent,
    });
  }
  
  /// Helper to restock
  Future<void> restock(String documentId, int qty) async {
    final data = await _supabase.from('medications').select('stockCount').eq('id', documentId).single();
    int current = data['stockCount'] ?? 0;
    
    await _supabase.from('medications').update({
      'stockCount': current + qty,
      'isUrgent': false, 
    }).eq('id', documentId);
  }
}
