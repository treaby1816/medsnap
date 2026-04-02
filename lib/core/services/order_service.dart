import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../providers.dart';
import '../utils/transaction_receipt.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> placeOrder({
    required List<CartItem> items,
    required double totalAmount,
    required String deliveryAddress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User must be logged in to place an order.");

    final orderRef = _db.collection('orders').doc();

    final orderData = {
      'orderId': orderRef.id,
      'userId': user.uid,
      'userEmail': user.email,
      'items': items.map((item) => {
        'id': item.id,
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'imageUrl': item.imageUrl,
        'pharmacyId': item.pharmacyId,
        'pharmacyName': item.pharmacyName,
      }).toList(),
      'totalAmount': totalAmount,
      'deliveryAddress': deliveryAddress,
      'status': 'Pending',
      'orderDate': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'globalPharmacyId': items.isNotEmpty ? items[0].pharmacyId : 'multiple', 
    };

    await orderRef.set(orderData);
  }

  Stream<QuerySnapshot> getPharmacyOrders(String pharmacyId) {
    return _db.collection('orders')
        .where('globalPharmacyId', isEqualTo: pharmacyId)
        .snapshots();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _db.collection('orders').doc(orderId).update({'status': newStatus});

    // Automated Receipt Logic (Auditing)
    if (newStatus.toLowerCase() == 'completed') {
      try {
        final orderDoc = await _db.collection('orders').doc(orderId).get();
        if (orderDoc.exists) {
          final receipt = await TransactionReceipt.fromOrderDoc(orderDoc);
          if (receipt != null) {
            final receiptUrl = await receipt.generateAndStore();
            if (receiptUrl != null) {
              await _db.collection('orders').doc(orderId).update({
                'receiptUrl': receiptUrl,
                'ledgerStatus': 'recorded',
              });
            }
          }
        }
      } catch (e) {
        // Log error but do not fail the status update
        debugPrint('Error generating automated receipt: $e');
      }
    }
  }
}
