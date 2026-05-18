import 'dart:async';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_profile.dart';
import '../utils/audit_logger.dart';

class AuthResult {
  final User? user;
  final bool isNewUser;
  AuthResult({required this.user, this.isNewUser = false});
}

class AuthService {
  final _supabase = Supabase.instance.client;
  final _secureStorage = const FlutterSecureStorage();
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '870868324526-vegf2ge7ruvq3vtbdheohqgadisto6u9.apps.googleusercontent.com' : null,
    serverClientId: '870868324526-vegf2ge7ruvq3vtbdheohqgadisto6u9.apps.googleusercontent.com',
    scopes: ['email', 'openid'],
  );

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  User? get currentUser => _supabase.auth.currentUser;

  Future<void> _securelyStorePII(User user, String role) async {
    if (kIsWeb) return; 
    try {
      await _secureStorage.write(key: 'user_uid', value: user.id);
      await _secureStorage.write(key: 'user_email', value: user.email);
      await _secureStorage.write(key: 'user_role', value: role);
      developer.log('PII secured successfully', name: 'VailMedsAuth');
    } catch (e) {
      developer.log('PII Storage Failure: $e', name: 'VailMedsAuth');
    }
  }

  Future<AuthResult> signInWithGoogle({String role = 'patient'}) async {
    try {
      developer.log('Google Sign-In initiated...', name: 'VailMedsAuth');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult(user: null);
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        throw Exception("Failed to retrieve Auth Tokens from Google.");
      }

      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      
      if (response.user != null) {
        final doc = await _supabase.from('users').select().eq('id', response.user!.id).maybeSingle();
        String finalRole = role;
        
        if (doc == null) {
          finalRole = (response.user!.email?.endsWith('@vailmeds.com') ?? false) ? 'admin' : role;

          final profile = UserProfile(
            uid: response.user!.id,
            email: response.user!.email ?? '',
            name: response.user!.userMetadata?['full_name'] ?? 'New User',
            phone: response.user!.phone ?? '',
            role: finalRole,
            isVerified: finalRole == 'patient' || finalRole == 'admin',
          );
          await createUserProfile(profile);
          await _securelyStorePII(response.user!, finalRole);
          return AuthResult(user: response.user, isNewUser: true);
        } else {
          finalRole = doc['role'] ?? 'patient';
          await _securelyStorePII(response.user!, finalRole);
          return AuthResult(user: response.user, isNewUser: false);
        }
      }
      
      return AuthResult(user: response.user, isNewUser: false);
    } catch (e) {
      developer.log('Google Auth Error: $e', name: 'VailMedsAuth');
      throw Exception("Sign-in failed. Please try again.");
    }
  }

  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        final profile = await getUserProfile(response.user!.id);
        if (profile != null) {
          await _securelyStorePII(response.user!, profile.role);
        }
      }
      return AuthResult(user: response.user, isNewUser: false);
    } catch (e) {
      developer.log('Email Sign-In Error: $e', name: 'VailMedsAuth');
      rethrow;
    }
  }

  Future<AuthResult> registerWithEmail(String email, String password, String name, String phone, String role) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      
      if (response.user != null) {
        final String finalRole = (email.endsWith('@vailmeds.com')) ? 'admin' : role;

        final profile = UserProfile(
          uid: response.user!.id,
          email: email,
          name: name,
          phone: phone,
          role: finalRole,
          isVerified: finalRole == 'patient' || finalRole == 'admin',
        );
        await createUserProfile(profile);
        await _securelyStorePII(response.user!, finalRole);
      }
      return AuthResult(user: response.user, isNewUser: true);
    } catch (e) {
      developer.log('Email Registration Error: $e', name: 'VailMedsAuth');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      developer.log('Password Reset Error: $e', name: 'VailMedsAuth');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _supabase.auth.signOut();
      await _secureStorage.deleteAll(); 
      developer.log('Sign-out successful and PII purged.', name: 'VailMedsAuth');
    } catch (e) {
      developer.log('Sign-out Error: $e', name: 'VailMedsAuth');
    }
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _supabase.from('users').select().eq('id', uid).maybeSingle();
      if (doc != null) {
        return UserProfile.fromMap(doc, uid);
      }
    } catch (e) {
      developer.log('Profile Fetch Error: $e', name: 'VailMedsAuth');
    }
    return null;
  }

  Future<void> createUserProfile(UserProfile profile) async {
    try {
      final data = profile.toMap();
      data['id'] = profile.uid; // Supabase requires matching primary key
      await _supabase.from('users').upsert(data);
    } catch (e) {
      developer.log('Profile Creation Error: $e', name: 'VailMedsAuth');
    }
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _supabase.from('users').update(data).eq('id', uid);
    } catch (e) {
      developer.log('Profile Update Error: $e', name: 'VailMedsAuth');
      rethrow;
    }
  }

  Future<void> submitVerificationRequest(
      String uid, String licenseNumber, String accessToken,
      {String? storeName, String? npiNumber, String? licensePhotoUrl}) async {
    try {
      final updateData = <String, dynamic>{
        'licenseNumber': licenseNumber,
        'accessToken': accessToken,
        'verificationStatus': 'pending', 
        'isAdminApproved': false,       
        'isVerified': false,            
      };
      
      if (storeName != null) updateData['storeName'] = storeName;
      if (npiNumber != null) updateData['npiNumber'] = npiNumber;
      if (licensePhotoUrl != null) updateData['licensePhotoUrl'] = licensePhotoUrl;

      await updateProfile(uid, updateData);
    } catch (e) {
      developer.log('Verification Request Error: $e', name: 'VailMedsAuth');
      rethrow;
    }
  }

  Stream<List<UserProfile>> getPendingPharmacies() {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('role', 'pharmacy')
        .map((maps) => maps
            .where((m) => m['verificationStatus'] == 'pending')
            .map((map) => UserProfile.fromMap(map, map['id']?.toString() ?? map['uid']?.toString()))
            .toList());
  }

  Future<void> adminApprovePharmacy(String uid) async {
    try {
      await _supabase.from('users').update({
        'isAdminApproved': true,
        'isVerified': true,
        'verificationStatus': 'approved',
        'approvedBy': currentUser?.id,
      }).eq('id', uid);
      
      final pharmacyProfile = await getUserProfile(uid);
      await AuditLogger.logPharmacyApproval(
        licenseNumber: pharmacyProfile?.licenseNumber ?? 'N/A',
        adminName: currentUser?.userMetadata?['full_name'] ?? 'Admin',
        adminUid: currentUser!.id,
        pharmacyUid: uid,
      );
    } catch (e) {
      developer.log('Admin Approval Error: $e', name: 'VailMedsAuth');
      rethrow;
    }
  }

  Future<void> adminRejectPharmacy(String uid, String reason) async {
    try {
      await _supabase.from('users').update({
        'isAdminApproved': false,
        'isVerified': false,
        'verificationStatus': 'rejected',
        'rejectionReason': reason,
      }).eq('id', uid);
    } catch (e) {
      developer.log('Admin Rejection Error: $e', name: 'VailMedsAuth');
      rethrow;
    }
  }

  Future<String?> getAdminMasterKey() async {
    try {
      final doc = await _supabase.from('app_settings').select('master_access_code').eq('id', 'admin_config').maybeSingle();
      if (doc != null) {
        return doc['master_access_code'] as String?;
      }
    } catch (e) {
      developer.log('Error fetching Admin Master Key: $e', name: 'VailMedsAuth');
    }
    return 'VM-2026-NGR'.trim();
  }
}