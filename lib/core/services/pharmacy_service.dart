import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;
import '../models/product_model.dart';

class PharmacyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 1. Image Compression & Upload
  Future<String?> uploadProductImage(File imageFile, String pharmacyId) async {
    try {
      final tempDir = await path_provider.getTemporaryDirectory();
      final targetPath = p.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Compress image to under 500KB if possible
      var result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 70, // Start with 70% quality
        minWidth: 1024,
        minHeight: 1024,
      );

      if (result == null) return null;

      final fileToUpload = File(result.path);
      
      // If file is still over 500KB, compress further (aggressive)
      if (await fileToUpload.length() > 500 * 1024) {
         result = await FlutterImageCompress.compressAndGetFile(
          imageFile.absolute.path,
          targetPath,
          quality: 50,
        );
      }

      final ref = _storage.ref().child('pharmacy_products').child(pharmacyId).child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = await ref.putFile(File(result!.path));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.data(), doc.id))
            .toList());
  }
}
