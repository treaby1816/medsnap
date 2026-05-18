import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class ProductService {
  final _supabase = Supabase.instance.client;

  Future<String?> uploadProductImage({
    required dynamic imageFile, 
    required String productName,
  }) async {
    try {
      String extension = '.jpg'; // Fallback
      try { extension = p.extension(imageFile.path ?? imageFile.name); } catch(_) {}
      String fileName = '${productName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}$extension';
      String path = 'inventory/images/$fileName';
      
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        await _supabase.storage.from('products').uploadBinary(path, bytes);
      } else {
        await _supabase.storage.from('products').upload(path, imageFile);
      }
      return _supabase.storage.from('products').getPublicUrl(path);
    } catch (e) {
      return null;
    }
  }

  Future<void> addNewProduct({
    required String storeId,
    required String name,
    required double price,
    required int initialStock,
    String? imageUrl,
  }) async {
    await _supabase.from('products').insert({
      'storeId': storeId,
      'name': name,
      'nameLower': name.toLowerCase(),
      'price': price,
      'stockQuantity': initialStock,
      'imageUrl': imageUrl ?? "",
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateStock({required String productId, required int addedQuantity}) async {
    // In Supabase we typically use an RPC to increment, or we fetch and update.
    // For simplicity, assuming there's an RPC or we use a basic update.
    final data = await _supabase.from('products').select('stockQuantity').eq('id', productId).single();
    int current = data['stockQuantity'] ?? 0;
    await _supabase.from('products').update({
      'stockQuantity': current + addedQuantity,
    }).eq('id', productId);
  }

  Future<void> deleteProduct(String productId) async {
    await _supabase.from('products').delete().eq('id', productId);
  }
}
