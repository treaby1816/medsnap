import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const _pharmacyBox = 'pharmacy_cache';
  static const _cacheExpiry = Duration(minutes: 15);

  static Future<void> initialize() async {
    await Hive.initFlutter();
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
}
