import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const _pharmacyBox = 'pharmacy_cache';
  static const _cartBox = 'cart_cache';
  static const _cacheExpiry = Duration(minutes: 15);

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(_cartBox);
  }

  // Cache pharmacy search results — avoids re-querying Supabase
  Future<void> cachePharmacies(String key, List data) async {
    final box = await Hive.openBox(_pharmacyBox);
    await box.put(key, {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List?> getCachedPharmacies(String key) async {
    final box = await Hive.openBox(_pharmacyBox);
    final cached = box.get(key);
    if (cached == null) return null;

    final timestamp = DateTime.fromMillisecondsSinceEpoch(cached['timestamp']);
    if (DateTime.now().difference(timestamp) > _cacheExpiry) {
      await box.delete(key); // Expired
      return null;
    }
    return cached['data'];
  }

  // Cart Persistence Methods
  static Future<void> saveCart(Map<String, dynamic> cartData) async {
    final box = Hive.box(_cartBox);
    await box.put('cart', cartData);
  }

  static Map<String, dynamic>? getCart() {
    final box = Hive.box(_cartBox);
    return box.get('cart') != null ? Map<String, dynamic>.from(box.get('cart')) : null;
  }
}
