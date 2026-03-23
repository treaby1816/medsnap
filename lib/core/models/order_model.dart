import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String patientId;
  final String pharmacyId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status; // 'pending', 'processing', 'out_for_delivery', 'delivered'
  final DateTime createdAt;
  final String? deliveryAddress;

  OrderModel({
    required this.id,
    required this.patientId,
    required this.pharmacyId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.deliveryAddress,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String documentId) {
    return OrderModel(
      id: documentId,
      patientId: map['patientId'] ?? '',
      pharmacyId: map['pharmacyId'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item))
              .toList() ?? [],
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveryAddress: map['deliveryAddress'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'pharmacyId': pharmacyId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt,
      'deliveryAddress': deliveryAddress,
    };
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 1,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
    };
  }
}
