import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;
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
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '870868324526-vegf2ge7ruvq3vtbdheohqgadisto6u9.apps.googleusercontent.com' : null,
    serverClientId: kIsWeb ? null : '870868324526-vegf2ge7ruvq3vtbdheohqgadisto6u9.apps.googleusercontent.com',
    scopes: ['email', 'openid'],
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> _securelyStorePII(User user, String role) async {
    if (kIsWeb) return; 
    await _secureStorage.write(key: 'user_uid', value: user.uid);
    await _secureStorage.write(key: 'user_email', value: user.email);
    await _secureStorage.write(key: 'user_role', value: role);
    developer.log('PII secured for: ${user.email}', name: 'AuthSecurity');
  }

  Future<AuthResult> signInWithGoogle({String role = 'patient'}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return AuthResult(user: null);

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        if (isNewUser) {
          final profile = UserProfile(
            uid: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? '',
            role: role,
            createdAt: DateTime.now(),
          );
          await _firestore.collection('users').doc(user.uid).set(profile.toMap());
          await AuditLogger.logEvent('USER_REGISTERED', metadata: {'uid': user.uid, 'role': role});
        }
        await _securelyStorePII(user, role);
        return AuthResult(user: user, isNewUser: isNewUser);
      }
      return AuthResult(user: null);
    } catch (e) {
      developer.log('Google Sign-In Error: $e', name: 'AuthSecurity');
      // Surface human-readable error for SHA-1 / Api10 mismatch
      final errorStr = e.toString();
      if (errorStr.contains('Api') || errorStr.contains('sign_in_failed') || errorStr.contains('ApiException')) {
        throw Exception(
          'Google Sign-In failed: SHA-1 fingerprint mismatch. '
          'The APK signing key does not match the one registered in Firebase Console. '
          'Please re-download google-services.json from Firebase after adding the correct SHA-1.',
        );
      }
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) {
      final profile = await getUserProfile(cred.user!.uid);
      if (profile != null) {
        await _securelyStorePII(cred.user!, profile.role);
      }
      await AuditLogger.logEvent('USER_LOGIN', metadata: {'uid': cred.user!.uid});
    }
    return cred;
  }

  Future<UserCredential> signUpWithEmail(String email, String password, String role) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) {
      final profile = UserProfile(
        uid: cred.user!.uid,
        email: email,
        role: role,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(cred.user!.uid).set(profile.toMap());
      await _securelyStorePII(cred.user!, role);
      await AuditLogger.logEvent('USER_REGISTERED', metadata: {'uid': cred.user!.uid, 'role': role});
    }
    return cred;
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _secureStorage.deleteAll();
    }
    await _googleSignIn.signOut();
    await _auth.signOut();
    await AuditLogger.logEvent('USER_LOGOUT');
  }

  /// Register a new user with email, name, phone and role.
  /// Called from RegistrationScreen.
  Future<AuthResult> registerWithEmail(
    String email,
    String password,
    String name,
    String phone,
    String role,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) {
      await cred.user!.updateDisplayName(name);
      final profile = UserProfile(
        uid: cred.user!.uid,
        email: email,
        name: name,
        phone: phone,
        role: role,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(cred.user!.uid).set(profile.toMap());
      await _securelyStorePII(cred.user!, role);
      await AuditLogger.logEvent('USER_REGISTERED', metadata: {'uid': cred.user!.uid, 'role': role});
      return AuthResult(user: cred.user, isNewUser: true);
    }
    return AuthResult(user: null);
  }

  /// Create or overwrite a user profile document in Firestore.
  /// Called from GatewayScreen when Google Sign-In creates a new user
  /// but the profile document was not created internally.
  Future<void> createUserProfile(UserProfile profile) async {
    await _firestore.collection('users').doc(profile.uid).set(profile.toMap());
    await AuditLogger.logEvent('USER_PROFILE_CREATED', metadata: {'uid': profile.uid, 'role': profile.role});
  }

  Stream<List<UserProfile>> getPendingPharmacies() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'pharmacy')
        .where('isAdminApproved', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserProfile.fromMap(doc.data()))
            .toList());
  }

  // --- UI Required Methods ---

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
    await AuditLogger.logEvent('USER_PROFILE_UPDATED', metadata: {'uid': uid, ...data});
  }

  Future<void> submitVerificationRequest(
    String uid, 
    String licenseNumber, 
    String token, 
    {String? storeName, String? licensePhotoUrl}
  ) async {
    await _firestore.collection('users').doc(uid).update({
      'licenseNumber': licenseNumber,
      'accessToken': token,
      'storeName': storeName,
      'licensePhotoUrl': licensePhotoUrl,
      'isVerificationPending': true,
      'verificationStatus': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
    });
    await AuditLogger.logEvent('PHARMACY_VERIFICATION_SUBMITTED', metadata: {'uid': uid, 'license': licenseNumber});
  }

  Future<void> adminApprovePharmacy(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isAdminApproved': true,
      'isVerificationPending': false,
      'verificationStatus': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
    });
    await AuditLogger.logEvent('PHARMACY_APPROVED_BY_ADMIN', metadata: {'uid': uid});
  }
}
