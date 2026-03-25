import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- SERVICES ---
import 'package:vail_meds_v2/core/services/auth_service.dart';
import 'package:vail_meds_v2/core/services/pharmacy_service.dart';
import 'package:vail_meds_v2/core/services/ocr_service.dart';
import 'package:vail_meds_v2/core/services/chat_service.dart';
import 'package:vail_meds_v2/core/services/health_service.dart';
import 'package:vail_meds_v2/core/services/order_service.dart';

// --- MODELS (UNIFIED PATH) ---
// Note: Ensure you have deleted the duplicate files in lib/models/ 
// and kept only these ones in lib/core/models/
import 'package:vail_meds_v2/core/models/product_model.dart';
import 'package:vail_meds_v2/core/models/user_profile.dart';

// --- ONBOARDING & FLOW MANAGEMENT ---
// Stages: 'splash' -> 'welcome' -> 'auth'
final onboardingStageProvider = StateProvider<String>((ref) => 'splash');

// --- SERVICE PROVIDERS ---
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final pharmacyServiceProvider = Provider<PharmacyService>((ref) => PharmacyService());
final ocrServiceProvider = Provider<OCRService>((ref) => OCRService());
final chatServiceProvider = Provider((ref) => ChatService());
final healthServiceProvider = Provider((ref) => HealthService());
final orderServiceProvider = Provider((ref) => OrderService());

final healthNewsProvider = FutureProvider<List<HealthArticle>>((ref) async {
  return ref.read(healthServiceProvider).fetchHealthNews();
});

// --- AUTH & ROLE MANAGEMENT ---
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final authProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

// Fixed: Explicitly using the UserProfile from core/models
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return null;
  return ref.watch(authServiceProvider).getUserProfile(user.uid);
});

// Fixed: Explicitly using the Product from core/models
final pharmacyProductsProvider = StreamProvider.family<List<Product>, String>((ref, pharmacyId) {
  return ref.watch(pharmacyServiceProvider).getPharmacyProducts(pharmacyId);
});

// --- ROLE NOTIFIER ---
class UserRoleNotifier extends Notifier<String?> {
  @override
  String? build() => 'patient'; 
  
  void setRole(String? role) => state = role;
  
  void toggleRole() {
    state = (state == 'patient') ? 'pharmacy' : 'patient';
  }
}

final userRoleProvider = NotifierProvider<UserRoleNotifier, String?>(UserRoleNotifier.new);

// --- PHARMACY DISCOVERY & CHAT ---
final verifiedPharmaciesProvider = StreamProvider<List<UserProfile>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'pharmacy')
      .where('isVerified', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
          .toList());
});

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
}

class CartNotifier extends StateNotifier<Map<String, CartItem>> {
  CartNotifier() : super({});

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
  }

  void removeItem(String id) {
    final newState = Map<String, CartItem>.from(state);
    newState.remove(id);
    state = newState;
  }

  void clearCart() => state = {};

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

final cartProvider = StateNotifierProvider<CartNotifier, Map<String, CartItem>>((ref) => CartNotifier());

// --- SEARCH & DRUG DISCOVERY ---
final drugSearchQueryProvider = StateProvider<String>((ref) => '');

final drugDatabaseProvider = FutureProvider<List<Product>>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('products').get();
  return snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList();
});

final filteredDrugsProvider = Provider<List<Product>>((ref) {
  final query = ref.watch(drugSearchQueryProvider).toLowerCase();
  final drugAsync = ref.watch(drugDatabaseProvider);

  return drugAsync.when(
    data: (products) {
      if (query.isEmpty) return []; 
      return products.where((product) {
        final name = product.name.toLowerCase();
        final description = product.description.toLowerCase();
        return name.contains(query) || description.contains(query);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final isUploadingProvider = StateProvider<bool>((ref) => false);

// --- GLOBAL PRODUCT DISCOVERY ---
final allProductsProvider = StreamProvider<List<Product>>((ref) {
  return FirebaseFirestore.instance
      .collection('products')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList());
});