import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeedData {
  static Future<void> seedHistory() async {
    final firestore = FirebaseFirestore.instance;
    final random = Random();
    final now = DateTime.now();

    final List<String> medications = ['Insulin', 'Metformin', 'Vitamins', 'Panadol'];

    // FIXED: Removed leading underscore to satisfy Dart's local identifier rules
    Future<void> generateBatch(DateTime monthRef) async {
      final batch = firestore.batch();
      for (int i = 0; i < 15; i++) {
        final day = random.nextInt(27) + 1;
        final date = DateTime(monthRef.year, monthRef.month, day, 10 + random.nextInt(5));
        final docRef = firestore.collection('orders').doc();
        batch.set(docRef, {
          'medicationName': medications[random.nextInt(medications.length)],
          'price': (random.nextInt(15) + 5) * 500.0,
          'status': 'Completed',
          'orderDate': Timestamp.fromDate(date),
        });
      }
      await batch.commit();
    }

    await generateBatch(now);
    await generateBatch(DateTime(now.year, now.month - 1, 1));
  }
}
