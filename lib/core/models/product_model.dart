import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String pharmacyId;
  final String pharmacyName;
  final int stockCount;
  final int maxStock;
  final String category;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.stockCount,
    required this.maxStock,
    required this.createdAt,
    this.category = 'General',
  });

  factory Product.fromMap(Map<String, dynamic> map, String documentId) {
    return Product(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] ?? '',
      pharmacyId: map['pharmacyId'] ?? '',
      pharmacyName: map['pharmacyName'] ?? 'Verified Pharmacy',
      stockCount: map['stockCount'] ?? 0,
      maxStock: map['maxStock'] ?? 0,
      category: map['category'] ?? 'General',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'stockCount': stockCount,
      'maxStock': maxStock,
      'category': category,
      'createdAt': createdAt,
    };
  }
}
