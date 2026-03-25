import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class AuthResult {
  final User? user;
  final bool isNewUser;
  AuthResult({required this.user, this.isNewUser = false});
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'openid',
    ],
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<AuthResult> signInWithGoogle({String role = 'patient'}) async {
    try {
      debugPrint('Google Sign-In initiated...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google Sign-In cancelled by user.');
        return AuthResult(user: null);
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      debugPrint('Google Sign-In successful: ${userCredential.user?.email}');
      
      if (userCredential.user != null) {
        // Sync Firestore
        final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        if (!doc.exists) {
          final profile = UserProfile(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            name: userCredential.user!.displayName ?? 'New User',
            phone: userCredential.user!.phoneNumber,
            role: role,
            isVerified: role == 'patient',
          );
          await createUserProfile(profile);
          return AuthResult(user: userCredential.user, isNewUser: true);
        }
      }
      
      return AuthResult(user: userCredential.user, isNewUser: false);
    } catch (e, stack) {
      debugPrint('Error signing in with Google: $e');
      debugPrint('Stack trace: $stack');
      
      // Specifically catch 403 / People API Permission Errors
      final errorStr = e.toString();
      if (errorStr.contains('403') || errorStr.contains('People API')) {
        throw Exception('Service temporarily unavailable. Please try again in a few minutes.');
      }
      
      rethrow; // Rethrow to allow UI to show the error
    }
  }

  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthResult(user: userCredential.user, isNewUser: false);
    } catch (e) {
      debugPrint('Error signing in with email: $e');
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
        // Update auth profile
        await userCredential.user!.updateDisplayName(name);

        // Create Firestore profile
        final profile = UserProfile(
          uid: userCredential.user!.uid,
          email: email,
          name: name,
          phone: phone,
          role: role,
          isVerified: role == 'patient', // Patients are verified by default for now
        );
        await createUserProfile(profile);
      }
      
      return AuthResult(user: userCredential.user, isNewUser: true);
    } catch (e) {
      debugPrint('Error registering with email: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      debugPrint('Signed out successfully.');
    } catch (e) {
      debugPrint('Error signing out: $e');
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
      debugPrint('Error fetching user profile: $e');
    }
    return null;
  }

  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(profile.uid).set(profile.toMap());
      debugPrint('User profile created: ${profile.email}');
    } catch (e) {
      debugPrint('Error creating user profile: $e');
    }
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      debugPrint('User profile updated for: $uid');
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  Future<void> updateVerificationStatus(String uid, String licenseNumber, String accessToken) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'licenseNumber': licenseNumber,
        'accessToken': accessToken,
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Pharmacy verification updated for: $uid');
    } catch (e) {
      debugPrint('Error updating verification status: $e');
      rethrow;
    }
  }
}
