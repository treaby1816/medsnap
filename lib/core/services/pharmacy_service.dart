import 'dart:io' show File;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;
import '../models/product_model.dart';

class PharmacyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 1a. Web-Compatible Image Upload (Uses raw bytes instead of dart:io File)
  Future<String?> uploadProductImageBytes(Uint8List imageBytes, String pharmacyId, String fileExtension) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final ref = _storage.ref()
          .child('pharmacy_products')
          .child(pharmacyId)
          .child(fileName);
      
      debugPrint('Uploading to: ${ref.fullPath}');
      
      final uploadTask = await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/$fileExtension'),
      );
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('Upload successful: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('Firebase Storage Error: [${e.code}] ${e.message}');
      throw Exception('Upload failed: [${e.code}] ${e.message}');
    } catch (e) {
      debugPrint('General Error uploading image: $e');
      throw Exception('Failed to upload: $e');
    }
  }

  // 1b. Image Compression & Upload (For Native iOS/Android/Desktop)
  Future<String?> uploadProductImage(dynamic imageFile, String pharmacyId) async {
    try {
      // NOTE: Compression requires native libraries (flutter_image_compress) which crashes Web Compiler.
      // For production parity, use uploadProductImageBytes on Web.
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref()
          .child('pharmacy_products')
          .child(pharmacyId)
          .child(fileName);
      
      debugPrint('Uploading to: ${ref.fullPath}');
      
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        await ref.putFile(
          File(imageFile.path),
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }
      
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('Upload successful: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('Firebase Storage Error: [${e.code}] ${e.message}');
      throw Exception('Upload failed: [${e.code}] ${e.message}');
    } catch (e) {
      debugPrint('General Error uploading image: $e');
      throw Exception('Failed to upload: $e');
    }
  }

  // 2. Add Product to Firestore
  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      await _firestore.collection('products').add({
        ...productData,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  // 3. Delete Product (Logic requested by user)
  Future<void> deleteProduct(String productId, String? imageUrl) async {
    try {
      // Delete from Firestore
      await _firestore.collection('products').doc(productId).delete();
      
      // Delete from Storage if imageUrl exists
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          debugPrint('Error deleting image from storage: $e');
        }
      }
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }

  // 4. Get Pharmacy Products Stream
  Stream<List<Product>> getPharmacyProducts(String pharmacyId) {
    return _firestore
        .collection('products')
        .where('pharmacyId', isEqualTo: pharmacyId)
        .snapshots()
        .map((snapshot) {
          final products = snapshot.docs
            .map((doc) => Product.fromMap(doc.data(), doc.id))
            .toList();
          // Sort client-side to avoid index requirement
          products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return products;
        });
  }
}
