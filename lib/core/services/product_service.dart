import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProductImage({
    required dynamic imageFile, 
    required String productName,
  }) async {
    try {
      String extension = '.jpg'; // Fallback
      try { extension = p.extension(imageFile.path ?? imageFile.name); } catch(_) {}
      String fileName = '${productName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}$extension';
      Reference ref = _storage.ref().child('inventory/images/$fileName');
      
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        await ref.putData(bytes);
      } else {
        await ref.putFile(imageFile);
      }
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
