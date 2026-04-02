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
  Future<String?> uploadProductImage(File imageFile, String pharmacyId) async {
    try {
      final tempDir = await path_provider.getTemporaryDirectory();
      final targetPath = p.join(tempDir.path, 'comp_${DateTime.now().millisecondsSinceEpoch}.jpg');

      debugPrint('Starting compression for: ${imageFile.path}');
      
      // Compress image to under 500KB if possible
      XFile? result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      if (result == null) {
        debugPrint('Compression returned null, using original file');
        result = XFile(imageFile.path);
      }

      final fileToUpload = File(result.path);
      final fileSize = await fileToUpload.length();
      debugPrint('File size after compression: ${fileSize / 1024} KB');
      
      // If file is still over 500KB, compress further (aggressive)
      if (fileSize > 500 * 1024) {
         debugPrint('File too large, compressing further...');
         final secondResult = await FlutterImageCompress.compressAndGetFile(
          imageFile.absolute.path,
          targetPath,
          quality: 50,
        );
        if (secondResult != null) {
          result = secondResult;
        }
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref()
          .child('pharmacy_products')
          .child(pharmacyId)
          .child(fileName);
      
      debugPrint('Uploading to: ${ref.fullPath}');
      
      final uploadTask = await ref.putFile(
        File(result.path),
        SettableMetadata(contentType: 'image/jpeg'),
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
