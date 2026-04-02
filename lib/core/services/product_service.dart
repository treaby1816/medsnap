import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Uses { } which means the UI MUST use labels like imageFile:
  Future<String?> uploadProductImage({
    required File imageFile, 
    required String productName,
  }) async {
    try {
      String extension = p.extension(imageFile.path);
      String fileName = '${productName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}$extension';
      Reference ref = _storage.ref().child('inventory/images/$fileName');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
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
    await _firestore.collection('products').add({
      'storeId': storeId,
      'name': name,
      'nameLower': name.toLowerCase(),
      'price': price,
      'stockQuantity': initialStock,
      'imageUrl': imageUrl ?? "",
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStock({required String productId, required int addedQuantity}) async {
    await _firestore.collection('products').doc(productId).update({
      'stockQuantity': FieldValue.increment(addedQuantity),
    });
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }
}
