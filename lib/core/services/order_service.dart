import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/cart_provider.dart'; // Fixed path

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> placeOrder({
    required List<CartItem> items,
    required double totalAmount,
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
      }).toList(),
      'totalAmount': totalAmount,
      'status': 'Pending',
      'orderDate': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'pharmacyId': 'vail_main_branch', 
    };

    await orderRef.set(orderData);
  }
}