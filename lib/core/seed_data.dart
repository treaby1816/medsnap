import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> seedProducts() async {
  final supabase = Supabase.instance.client;
  
  final products = [
    {
      'name': 'Panadol Extra',
      'description': 'Effective pain relief for headaches and fever.',
      'price': 1200.0,
      'imageUrl': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=500',
      'pharmacyId': 'pharmacy_123',
      'pharmacyName': 'Lekki City Pharmacy',
      'stockCount': 50,
      'maxStock': 100,
      'category': 'Pain Relief',
      'createdAt': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Vitamin C 1000mg',
      'description': 'Daily supplement for immune support.',
      'price': 2500.0,
      'imageUrl': 'https://images.unsplash.com/photo-1471864190281-ad5fe9bb0724?q=80&w=500',
      'pharmacyId': 'pharmacy_123',
      'pharmacyName': 'Lekki City Pharmacy',
      'stockCount': 30,
      'maxStock': 50,
      'category': 'Supplements',
      'createdAt': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Cod Liver Oil',
      'description': 'Rich in Omega-3 fatty acids.',
      'price': 4500.0,
      'imageUrl': 'https://images.unsplash.com/photo-1550573105-df2dc6e28892?q=80&w=500',
      'pharmacyId': 'pharmacy_456',
      'pharmacyName': 'Alpha Health Care',
      'stockCount': 20,
      'maxStock': 30,
      'category': 'Supplements',
      'createdAt': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Vicks VapoRub',
      'description': 'Relief from cough and cold symptoms.',
      'price': 1500.0,
      'imageUrl': 'https://images.unsplash.com/photo-1631549916768-4119b2e5f926?q=80&w=500',
      'pharmacyId': 'pharmacy_456',
      'pharmacyName': 'Alpha Health Care',
      'stockCount': 40,
      'maxStock': 60,
      'category': 'Cold & Flu',
      'createdAt': DateTime.now().toIso8601String(),
    },
  ];

  await supabase.from('products').insert(products);
  
  debugPrint('Successfully seeded ${products.length} products.');
}
