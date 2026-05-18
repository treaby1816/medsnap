import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';

class PharmacyService {
  final _supabase = Supabase.instance.client;

  Future<String?> uploadProductImageBytes(Uint8List imageBytes, String pharmacyId, String fileExtension) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final path = '$pharmacyId/$fileName';
      
      debugPrint('Uploading to Supabase Storage: $path');
      
      await _supabase.storage.from('pharmacy_products').uploadBinary(
        path,
        imageBytes,
        fileOptions: FileOptions(contentType: 'image/$fileExtension'),
      );
      
      final downloadUrl = _supabase.storage.from('pharmacy_products').getPublicUrl(path);
      debugPrint('Upload successful: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Supabase Storage Error: $e');
      throw Exception('Failed to upload: $e');
    }
  }

  Future<String?> uploadProductImage(dynamic imageFile, String pharmacyId) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return await uploadProductImageBytes(bytes, pharmacyId, 'jpg');
    } catch (e) {
      debugPrint('Upload Error: $e');
      throw Exception('Failed to upload: $e');
    }
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      // Map legacy "products" fields to Supabase "inventory" schema
      final insertData = {
        'pharmacy_id': productData['pharmacyId'],
        'drug_name': productData['name'],
        'price': productData['price'] ?? 0.0,
        'quantity': 100, // Default for now
        // Keep original data in a metadata column if needed, or expand schema
      };

      await _supabase.from('inventory').insert(insertData);
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId, String? imageUrl) async {
    try {
      await _supabase.from('inventory').delete().eq('id', productId);
      
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          // Extract path from public URL and remove it from storage
          final uri = Uri.parse(imageUrl);
          final pathSegments = uri.pathSegments;
          // E.g., /storage/v1/object/public/pharmacy_products/pharmacyId/fileName
          if (pathSegments.length >= 2) {
            final path = '${pathSegments[pathSegments.length - 2]}/${pathSegments.length - 1}';
            await _supabase.storage.from('pharmacy_products').remove([path]);
          }
        } catch (e) {
          debugPrint('Error deleting image from storage: $e');
        }
      }
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }

  Stream<List<Product>> getPharmacyProducts(String pharmacyId) {
    return _supabase
        .from('inventory')
        .stream(primaryKey: ['id'])
        .eq('pharmacy_id', pharmacyId)
        .map((maps) {
          // Need to map the Supabase inventory columns back to the Product model
          return maps.map((map) {
            final mappedData = {
              'id': map['id'],
              'pharmacyId': map['pharmacy_id'],
              'name': map['drug_name'],
              'price': map['price'],
              'createdAt': map['updated_at'] ?? map['created_at'],
            };
            return Product.fromMap(mappedData, map['id'].toString());
          }).toList();
        });
  }
}
