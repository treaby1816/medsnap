import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _secureStorage = const FlutterSecureStorage();
  
  // FIXED: serverClientId is mandatory for Android to receive an idToken for Firebase.
  // This must match the "Web Client ID" in your Firebase Google Auth settings.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '870868324526-vegf2ge7ruvq3vtbdheohqgadisto6u9.apps.googleusercontent.com' : null,
    serverClientId: '870868324526-vegf2ge7ruvq3vtbdheohqgadisto6u9.apps.googleusercontent.com',
    scopes: ['email', 'openid'],
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Securely stores PII on the device's hardware keystore/keychain.
  Future<void> _securelyStorePII(User user, String role) async {
    if (kIsWeb) return; 
    try {
      await _secureStorage.write(key: 'user_uid', value: user.uid);
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
      
      // ERROR GUARD: Verify tokens exist before hitting Firebase
      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        throw Exception("Failed to retrieve Auth Tokens from Google.");
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        String finalRole = role;
        
        if (!doc.exists) {
          // Auto-assign Admin based on corporate email domain
          finalRole = (userCredential.user!.email?.endsWith('@vailmeds.com') ?? false) 
              ? 'admin' 
              : role;

          final profile = UserProfile(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            name: userCredential.user!.displayName ?? 'New User',
            phone: userCredential.user!.phoneNumber,
            role: finalRole,
            isVerified: finalRole == 'patient' || finalRole == 'admin',
          );
          await createUserProfile(profile);
          await _securelyStorePII(userCredential.user!, finalRole);
          return AuthResult(user: userCredential.user, isNewUser: true);
        } else {
          finalRole = doc.data()?['role'] ?? 'patient';
          await _securelyStorePII(userCredential.user!, finalRole);
          return AuthResult(user: userCredential.user, isNewUser: false);
        }
      }
      
      return AuthResult(user: userCredential.user, isNewUser: false);
    } catch (e) {
      developer.log('Google Auth Error: $e', name: 'VailMedsAuth');
      
      // FRIENDLY ERROR HANDLING: Prevents abrupt crashes
      String errorMsg = "Sign-in failed. Please try again.";
      final String eStr = e.toString();
      
      if (eStr.contains('10') || eStr.contains('DEVELOPER_ERROR')) {
        errorMsg = "Security Signature Mismatch (Api10). Please ensure your SHA-1 fingerprint is registered in Firebase Console.";
      } else if (eStr.contains('redirect_uri_mismatch')) {
        errorMsg = "Auth Configuration Error: Redirect URI Mismatch. Check Google Cloud Console Authorized URIs.";
      } else if (eStr.contains('network_error')) {
        errorMsg = "Network error. Please check your internet connection.";
      } else if (eStr.contains('popup_closed_by_user')) {
        errorMsg = "Sign-in cancelled.";
      }
      
      throw Exception(errorMsg);
    }
  }

  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        final profile = await getUserProfile(userCredential.user!.uid);
        if (profile != null) {
          await _securelyStorePII(userCredential.user!, profile.role);
        }
      }
      return AuthResult(user: userCredential.user, isNewUser: false);
    } catch (e) {
      developer.log('Email Sign-In Error: $e', name: 'VailMedsAuth');
      rethrow;
    }
  }

  Future<AuthResult> registerWithEmail(String email, String password, String name, String phone, String role) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        final String finalRole = (email.endsWith('@vailmeds.com')) ? 'admin' : role;

        final profile = UserProfile(
          uid: userCredential.user!.uid,
          email: email,
          name: name,
          phone: phone,
          role: finalRole,
          isVerified: finalRole == 'patient' || finalRole == 'admin',
        );
        await createUserProfile(profile);
        await _securelyStorePII(userCredential.user!, finalRole);
      }
      return AuthResult(user: userCredential.user, isNewUser: true);
    } catch (e) {
      developer.log('Email Registration Error: $e', name: 'VailMedsAuth');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      await _secureStorage.deleteAll(); // Mandatory: Clear PII on Logout
      developer.log('Sign-out successful and PII purged.', name: 'VailMedsAuth');
    } catch (e) {
      developer.log('Sign-out Error: $e', name: 'VailMedsAuth');
    }
  }

  // --- Firestore Profile Management ---

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!);
      }
    } catch (e) {
      developer.log('Profile Fetch Error: $e', name: 'VailMedsAuth');
    }
    return null;
  }

  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(profile.uid).set(profile.toMap());
    } catch (e) {
      developer.log('Profile Creation Error: $e', name: 'VailMedsAuth');
    }
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
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
        'submittedAt': FieldValue.serverTimestamp(),
      };
      
      if (storeName != null) updateData['storeName'] = storeName;
      if (npiNumber != null) updateData['npiNumber'] = npiNumber;
      if (licensePhotoUrl != null) updateData['licensePhotoUrl'] = licensePhotoUrl;

      await _firestore.collection('users').doc(uid).update(updateData);
    } catch (e) {
      developer.log('Verification Request Error: $e', name: 'VailMedsAuth');
      rethrow;
    }
  }

  // Admin Methods

  Stream<List<UserProfile>> getPendingPharmacies() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'pharmacy')
        .where('verificationStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> adminApprovePharmacy(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isAdminApproved': true,
        'isVerified': true,
        'verificationStatus': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': _auth.currentUser?.uid,
      });
      
      // Log the event for security audit
      final pharmacyProfile = await getUserProfile(uid);
      await AuditLogger.logPharmacyApproval(
        licenseNumber: pharmacyProfile?.licenseNumber ?? 'N/A',
        adminName: _auth.currentUser?.displayName ?? 'Admin',
        adminUid: _auth.currentUser!.uid,
        pharmacyUid: uid,
      );
    } catch (e) {
      developer.log('Admin Approval Error: $e', name: 'VailMedsAuth');
      rethrow;
    }
  }

  Future<void> adminRejectPharmacy(String uid, String reason) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isAdminApproved': false,
        'isVerified': false,
        'verificationStatus': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      developer.log('Admin Rejection Error: $e', name: 'VailMedsAuth');
      rethrow;
    }
  Future<String?> getAdminMasterKey() async {
    try {
      final doc = await _firestore.collection('app_settings').doc('security').get();
      if (doc.exists) {
        return doc.data()?['adminMasterKey'] as String?;
      }
    } catch (e) {
      developer.log('Error fetching Admin Master Key: $e', name: 'VailMedsAuth');
    }
    return null;
  }
}