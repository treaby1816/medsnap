import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/pharmacy_service.dart';
import 'services/ocr_service.dart';
import 'services/chat_service.dart';
import 'models/product_model.dart';
import 'models/user_profile.dart';

// --- AUTH & ROLE MANAGEMENT ---

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final pharmacyServiceProvider = Provider<PharmacyService>((ref) => PharmacyService());

final ocrServiceProvider = Provider<OCRService>((ref) => OCRService());

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

final pharmacyProductsProvider = StreamProvider.family<List<Product>, String>((ref, pharmacyId) {
  return ref.watch(pharmacyServiceProvider).getPharmacyProducts(pharmacyId);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Set to the actual Firebase User, but can be overridden for dev
final authProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null) return null;
  return ref.watch(authServiceProvider).getUserProfile(user.uid);
});

class UserRoleNotifier extends Notifier<String?> {
  @override
  String? build() => 'patient'; // Default to patient for the dashboard build

  void setRole(String? role) => state = role;

  // Handy for testing: Toggle between Patient and Pharmacy views
  void toggleRole() {
    state = (state == 'patient') ? 'pharmacy' : 'patient';
  }
}

final userRoleProvider = NotifierProvider<UserRoleNotifier, String?>(UserRoleNotifier.new);

// --- SEARCH & DRUG DISCOVERY ---

// Holds the raw text from the search bar
final drugSearchQueryProvider = StateProvider<String>((ref) => '');

// FutureProvider to fetch drugs from Firestore
final drugDatabaseProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('medications').get();
  return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
});

// The "Agentic" logic: Automatically filters the database as the user types
final filteredDrugsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final query = ref.watch(drugSearchQueryProvider).toLowerCase();
  final drugAsync = ref.watch(drugDatabaseProvider);

  return drugAsync.when(
    data: (drugs) {
      if (query.isEmpty) return []; // Hide suggestions if search is empty
      return drugs.where((drug) {
        final name = drug['name']?.toString().toLowerCase() ?? '';
        final category = drug['category']?.toString().toLowerCase() ?? '';
        return name.contains(query) || category.contains(query);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// --- PRESCRIPTION UPLOAD STATE ---

// Tracks if a file is currently being uploaded to Firebase Storage
final isUploadingProvider = StateProvider<bool>((ref) => false);