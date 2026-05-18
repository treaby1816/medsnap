import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class SeedData {
  static Future<void> seedHistory() async {

    final random = Random();
    final now = DateTime.now();

    final List<String> medications = ['Insulin', 'Metformin', 'Vitamins', 'Panadol'];

    // FIXED: Removed leading underscore to satisfy Dart's local identifier rules
    Future<void> generateBatch(DateTime monthRef) async {
      final supabase = Supabase.instance.client;
      final List<Map<String, dynamic>> records = [];
      for (int i = 0; i < 15; i++) {
        final day = random.nextInt(27) + 1;
        final date = DateTime(monthRef.year, monthRef.month, day, 10 + random.nextInt(5));
        records.add({
          'medicationName': medications[random.nextInt(medications.length)],
          'price': (random.nextInt(15) + 5) * 500.0,
          'status': 'Completed',
          'orderDate': date.toIso8601String(),
        });
      }
      await supabase.from('orders').insert(records);
    }

    await generateBatch(now);
    await generateBatch(DateTime(now.year, now.month - 1, 1));
  }
}
