import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/cart_model.dart';
class OrderService {
  final _supabase = Supabase.instance.client;

  Future<void> placeOrder({
    required List<CartItem> items,
    required double totalAmount,
    required String deliveryAddress,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User must be logged in to place an order.");

    // Note: The Supabase schema handles multiple items differently if strictly following master prompt.
    // For now, we serialize the list to a JSON array for compatibility or insert individual rows if needed.
    // Assuming 'orders' table supports an 'items' JSONB array or we insert a composite representation.
    
    final orderData = {
      'patient_id': user.id,
      'pharmacy_id': items.isNotEmpty ? items[0].pharmacyId : null,
      'drug_name': items.map((e) => '${e.name} (x${e.quantity})').join(', '),
      'quantity': items.fold<int>(0, (sum, item) => sum + item.quantity),
      'total_amount': totalAmount,
      'status': 'pending',
      'fulfillment_type': 'delivery',
      'payment_status': 'unpaid',
      'items': items.map((e) => e.toMap()).toList(),
    };

    await _supabase.from('orders').insert(orderData);
  }

  // Uses Supabase Realtime to stream orders
  Stream<List<Map<String, dynamic>>> getPharmacyOrders(String pharmacyId) {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('pharmacy_id', pharmacyId);
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _supabase.from('orders').update({'status': newStatus}).eq('id', orderId);

    if (newStatus.toLowerCase() == 'completed') {
      try {
        final orderDoc = await _supabase.from('orders').select().eq('id', orderId).maybeSingle();
        if (orderDoc != null) {
          // TransactionReceipt.fromOrderDoc needs to be updated to support Map instead of DocumentSnapshot
          // We will invoke the updated utility in a following step.
          debugPrint('Order completed, ready for receipt generation');
        }
      } catch (e) {
        debugPrint('Error generating automated receipt: $e');
      }
    }
  }
}
