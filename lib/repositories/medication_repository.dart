import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medication_model.dart';

/// Real-time Firestore NoSQL connection for medications.
class MedicationRepository {
  static final MedicationRepository _instance = MedicationRepository._internal();
  factory MedicationRepository() => _instance;
  MedicationRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Retrieves a live stream of urgent medications from Firestore,
  /// seamlessly mapped to the Medication UI model.
  Stream<List<Medication>> getUrgentInventoryStream() {
    return _firestore
        .collection('medications')
        .where('isUrgent', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Medication.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Appends to the datastore
  Future<void> add(Medication med) async {
    await _firestore.collection('medications').add({
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
    await _firestore.collection('medications').doc(documentId).update({
      'stockCount': FieldValue.increment(qty),
      // Automatically removes from urgency filters
      'isUrgent': false, 
    });
  }
}
