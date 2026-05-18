import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vail_meds_v2/core/app_router.dart';

// --- SERVICES ---
import 'package:vail_meds_v2/core/services/auth_service.dart';
import 'package:vail_meds_v2/core/services/pharmacy_service.dart';
import 'package:vail_meds_v2/core/services/ocr_service.dart';
import 'package:vail_meds_v2/core/services/chat_service.dart';
import 'package:vail_meds_v2/core/services/health_service.dart';
import 'package:vail_meds_v2/core/services/order_service.dart';
import 'package:vail_meds_v2/core/services/payment_service.dart';
import 'package:vail_meds_v2/core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

// --- MODELS (UNIFIED PATH) ---
// Note: Ensure you have deleted the duplicate files in lib/models/ 
// and kept only these ones in lib/core/models/
import 'package:vail_meds_v2/core/models/product_model.dart';
import 'package:vail_meds_v2/core/models/user_profile.dart';

// --- ONBOARDING & FLOW MANAGEMENT ---
// Stages: 'splash' -> 'welcome' -> 'auth'
final onboardingStageProvider = StateProvider<String>((ref) => 'splash');
final agreedToTermsProvider = StateProvider<bool>((ref) => false);
final agreedToPrivacyProvider = StateProvider<bool>((ref) => false);

// --- SERVICE PROVIDERS ---
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final routerProvider = Provider<AppRouter>((ref) => AppRouter());
final locationServiceProvider = Provider<LocationService>((ref) => LocationService());
final pharmacyServiceProvider = Provider<PharmacyService>((ref) => PharmacyService());
final ocrServiceProvider = Provider<OCRService>((ref) => OCRService());
final chatServiceProvider = Provider((ref) => ChatService());
final healthServiceProvider = Provider((ref) => HealthService());
final orderServiceProvider = Provider((ref) => OrderService());
final paymentServiceProvider = Provider((ref) => PaymentService());

final healthNewsProvider = FutureProvider<List<HealthArticle>>((ref) async {
  return ref.read(healthServiceProvider).fetchHealthNews();
});

// --- AUTH & ROLE MANAGEMENT ---
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges.map((state) => state.session?.user);
});

final authProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

// StreamProvider for real-time profile updates
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  
  return Supabase.instance.client
      .from('users')
      .stream(primaryKey: ['id'])
      .eq('id', user.id)
      .map((maps) => maps.isNotEmpty ? UserProfile.fromMap(maps.first, user.id) : null);
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

// --- CHAT PROVIDERS ---
final unreadChatCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(0);
  return ref.watch(chatServiceProvider).getTotalUnreadCount(user.id);
});

final conversationsProvider = StreamProvider<List<ChatConversation>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(chatServiceProvider).getConversations(user.id);
});

// --- PHARMACY DISCOVERY & CHAT ---
final verifiedPharmaciesProvider = StreamProvider<List<UserProfile>>((ref) {
  return Supabase.instance.client
      .from('users')
      .stream(primaryKey: ['id'])
      .eq('role', 'pharmacy')
      .map((maps) => maps
          .where((m) => m['isAdminApproved'] == true)
          .map((map) => UserProfile.fromMap(map, map['id']?.toString() ?? map['uid']?.toString()))
          .toList());
});

// --- GEOLOCATION & NEARBY PHARMACIES ---
final userLocationProvider = FutureProvider<Position?>((ref) async {
  try {
    return await ref.read(locationServiceProvider).getCurrentPosition();
  } catch (e) {
    // If permissions fail or user denies, we return null to use mock location fallback
    return null; 
  }
});

// A consolidated provider that attaches distance (km/minutes) to each verified pharmacy
final nearbyPharmaciesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final pharmaciesAsync = ref.watch(verifiedPharmaciesProvider);
  final userLocationAsync = ref.watch(userLocationProvider);

  // Wait for both to be available, or handle loading states here if we wanted complex streams.
  if (pharmaciesAsync.isLoading) return [];
  
  final pharmacies = pharmaciesAsync.value ?? [];
  final userPosition = userLocationAsync.value;

  // Mock patient coordinate (Center of Lekki Phase 1) if real location is unavailable or denied
  final finalLat = userPosition?.latitude ?? 6.4468;
  final finalLng = userPosition?.longitude ?? 3.4563;

  final locationService = ref.read(locationServiceProvider);

  // For each pharmacy, calculate distance. Use a dummy location for old pharmacies that lack data.
  final listWithDistance = pharmacies.map((pharmacy) {
    // Dummy coordinate for older pharmacies (somewhere nearby in Victoria Island, etc)
    // In production, we'll enforce registration of lat/lng.
    double pLat = pharmacy.latitude ?? (6.4285 + (pharmacy.uid.hashCode % 100) / 10000.0);
    double pLng = pharmacy.longitude ?? (3.4150 + (pharmacy.uid.hashCode % 100) / 10000.0);

    final distanceData = locationService.calculateDistanceAndDuration(
      finalLat, finalLng, pLat, pLng,
    );

    return {
      'profile': pharmacy,
      'distanceKm': distanceData.distanceInKm,
      'estimatedMinutes': distanceData.estimatedMinutes,
    };
  }).toList();

  // Sort by shortest distance first
  listWithDistance.sort((a, b) => (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));

  // Return Top 5 closest
  return listWithDistance.take(5).toList();
});

final pendingPharmaciesProvider = StreamProvider<List<UserProfile>>((ref) {
  return ref.watch(authServiceProvider).getPendingPharmacies();
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
final selectedCategoryProvider = StateProvider<String>((ref) => 'All Products');
final drugSearchQueryProvider = StateProvider<String>((ref) => '');

final drugDatabaseProvider = FutureProvider<List<Product>>((ref) async {
  final maps = await Supabase.instance.client.from('inventory').select();
  return maps.map((map) {
    final mappedData = {
      'id': map['id'],
      'pharmacyId': map['pharmacy_id'],
      'name': map['drug_name'],
      'price': map['price'],
      'createdAt': map['updated_at'] ?? map['created_at'],
    };
    return Product.fromMap(mappedData, map['id'].toString());
  }).toList();
});

final filteredByBrandProductsProvider = Provider<List<Product>>((ref) {
  final query = ref.watch(drugSearchQueryProvider).toLowerCase();
  final category = ref.watch(selectedCategoryProvider);
  final drugAsync = ref.watch(allProductsProvider); // Use all products for main marketplace

  return drugAsync.when(
    data: (products) {
      return products.where((product) {
        final matchesQuery = query.isEmpty || 
                            product.name.toLowerCase().contains(query) || 
                            product.description.toLowerCase().contains(query);
        final matchesCategory = category == 'All Products' || product.category == category;
        return matchesQuery && matchesCategory;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final isUploadingProvider = StateProvider<bool>((ref) => false);

// --- GLOBAL PRODUCT DISCOVERY ---
final allProductsProvider = StreamProvider<List<Product>>((ref) {
  final verifiedPharmaciesAsync = ref.watch(verifiedPharmaciesProvider);
  final approvedIds = verifiedPharmaciesAsync.value?.map((p) => p.uid).toList() ?? [];
  
  if (approvedIds.isEmpty) return Stream.value(<Product>[]);

  return Supabase.instance.client
      .from('inventory')
      .stream(primaryKey: ['id'])
      .inFilter('pharmacy_id', approvedIds)
      .map((maps) {
        return maps.map((map) {
          final mappedData = {
            'id': map['id'],
            'pharmacyId': map['pharmacy_id'],
            'name': map['drug_name'],
            'price': map['price'],
            'createdAt': map['updated_at'] ?? map['created_at'],
          };
          return Product.fromMap(mappedData, map['id'].toString());
        }).toList();
      });
});
