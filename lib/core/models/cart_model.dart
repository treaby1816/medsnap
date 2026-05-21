import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/cache_service.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;
  final String pharmacyId;
  final String pharmacyName;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.pharmacyId,
    required this.pharmacyName,
    this.quantity = 1,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      name: name,
      price: price,
      imageUrl: imageUrl,
      pharmacyId: pharmacyId,
      pharmacyName: pharmacyName,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] ?? '',
      quantity: map['quantity']?.toInt() ?? 1,
      pharmacyId: map['pharmacyId'] ?? '',
      pharmacyName: map['pharmacyName'] ?? '',
    );
  }
}

class CartNotifier extends Notifier<Map<String, CartItem>> {
  @override
  Map<String, CartItem> build() {
    final cachedCart = CacheService.getCart();
    if (cachedCart != null) {
      return cachedCart.map(
        (key, value) => MapEntry(key, CartItem.fromMap(Map<String, dynamic>.from(value))),
      );
    }
    return {};
  }

  void _persistState() {
    final cartData = state.map((key, value) => MapEntry(key, value.toMap()));
    CacheService.saveCart(cartData);
  }

  void addItem(Map<String, dynamic> product) {
    // Standardize ID from name or provided id
    final String id = product['id']?.toString() ?? product['name'] ?? 'unknown_id';
    
    if (state.containsKey(id)) {
      state = {
        ...state,
        id: state[id]!.copyWith(quantity: state[id]!.quantity + 1),
      };
    } else {
      // Clean price string if necessary (e.g. "₦4,500" -> 4500)
      final priceStr = product['price']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '0';
      final price = double.tryParse(priceStr) ?? 0.0;

      state = {
        ...state,
        id: CartItem(
          id: id,
          name: product['name'] ?? 'Medication',
          price: price,
          imageUrl: product['imageUrl'] ?? '',
          pharmacyId: product['pharmacyId'] ?? 'unknown_store',
          pharmacyName: product['pharmacyName'] ?? 'Verified Pharmacy',
          quantity: 1,
        ),
      };
    }
    _persistState();
  }

  void removeItem(String id) {
    final newState = Map<String, CartItem>.from(state);
    newState.remove(id);
    state = newState;
    _persistState();
  }

  void clearCart() {
    state = {};
    _persistState();
  }

  double get totalAmount => state.values.fold(0.0, (totalSum, item) => totalSum + (item.price * item.quantity));
  
  // Alias for compatibility
  double get total => totalAmount;

  Future<void> checkout() async {
    if (state.isEmpty) return;
    // Note: Actual persistence is handled in CheckoutScreen via OrderService
    await Future.delayed(const Duration(milliseconds: 500)); 
    clearCart();
  }
}
