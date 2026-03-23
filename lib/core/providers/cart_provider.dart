import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/order_service.dart';

// 1. Data Model
class CartItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      name: name,
      price: price,
      imageUrl: imageUrl,
      quantity: quantity ?? this.quantity,
    );
  }
}

// 2. Logic Notifier
class CartNotifier extends StateNotifier<Map<String, CartItem>> {
  CartNotifier() : super({});
  
  final OrderService _orderService = OrderService();

  void addItem(Map<String, dynamic> product) {
    final String id = product['id']?.toString() ?? product['name'] ?? 'unknown_id';
    
    // We create a new map reference to ensure Riverpod detects the state change
    if (state.containsKey(id)) {
      state = {
        ...state,
        id: state[id]!.copyWith(quantity: state[id]!.quantity + 1),
      };
    } else {
      state = {
        ...state,
        id: CartItem(
          id: id,
          name: product['name'] ?? 'Medication',
          price: double.tryParse(product['price']?.toString() ?? '0.0') ?? 0.0,
          imageUrl: product['imageUrl'] ?? '',
          quantity: 1,
        ),
      };
    }
  }

  void decrementQuantity(String id) {
    if (!state.containsKey(id)) return;

    if (state[id]!.quantity > 1) {
      state = {
        ...state,
        id: state[id]!.copyWith(quantity: state[id]!.quantity - 1),
      };
    } else {
      removeItem(id);
    }
  }

  void removeItem(String id) {
    // Remove the item and update the state with a new map instance
    final newState = Map<String, CartItem>.from(state);
    newState.remove(id);
    state = newState;
  }

  void clearCart() => state = {};

  double get totalAmount => 
      state.values.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  // The Fixed Checkout Function
  Future<void> checkout() async {
    if (state.isEmpty) throw Exception("Cart is empty");

    try {
      final itemsList = state.values.toList();
      final total = totalAmount;

      // Calling with NAMED parameters to match the OrderService placeOrder method
      await _orderService.placeOrder(
        items: itemsList, 
        totalAmount: total,
      );

      clearCart();
    } catch (e) {
      // Allow the UI to handle the error (e.g., showing an alert)
      rethrow; 
    }
  }
}

// 3. The Global Provider
final cartProvider = StateNotifierProvider<CartNotifier, Map<String, CartItem>>((ref) {
  return CartNotifier();
});