import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '870868324526-vegf2ge7ruvq3vtbdheohqgadisto6u9.apps.googleusercontent.com',
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithGoogle() async {
    try {
      debugPrint('Google Sign-In initiated...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google Sign-In cancelled by user.');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      debugPrint('Google Sign-In successful: ${userCredential.user?.email}');
      return userCredential.user;
    } catch (e, stack) {
      debugPrint('Error signing in with Google: $e');
      debugPrint('Stack trace: $stack');
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint('Error signing in with email: $e');
      rethrow;
    }
  }

  Future<User?> registerWithEmail(String email, String password, String name, String phone, String role) async {
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
      
      return userCredential.user;
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
