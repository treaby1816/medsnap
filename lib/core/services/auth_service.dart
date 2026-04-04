import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // ONLY provide clientId directly on Web. On Android/iOS, it reads automatically from google-services.json.
    clientId: kIsWeb ? '870868324526-vegf2ge7ruvq3vtbdheohqgadisto6u9.apps.googleusercontent.com' : null,
    // serverClientId is not supported on Web. For iOS/Android it provides a server auth code.
    serverClientId: kIsWeb ? null : '870868324526-vegf2ge7ruvq3vtbdheohqgadisto6u9.apps.googleusercontent.com',
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
          // Professional Rule: Auto-assign admin role if email is from vailmeds.com
          final String finalRole = (userCredential.user!.email?.endsWith('@vailmeds.com') ?? false) 
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
          return AuthResult(user: userCredential.user, isNewUser: true);
        } else {
          // EXISTING USER: Update role to match the portal they signed in from.
          // This ensures a user entering the Patient Portal is routed as a Patient,
          // even if their previous session was as a Pharmacy user.
          final existingRole = doc.data()?['role'] ?? 'patient';
          debugPrint('Existing user found with role: $existingRole. Requested portal role: $role');
          
          // Only update if the role doesn't match AND user isn't admin
          if (existingRole != role && existingRole != 'admin') {
            await _firestore.collection('users').doc(userCredential.user!.uid).update({
              'role': role,
            });
            debugPrint('Role updated from $existingRole to $role to match portal selection.');
          }
          
          return AuthResult(user: userCredential.user, isNewUser: false);
        }
      }
      
      return AuthResult(user: userCredential.user, isNewUser: false);
    } catch (e, stack) {
      debugPrint('Error signing in with Google: $e');
      debugPrint('Stack trace: $stack');
      
      // Only catch the very specific People API permission error
      final errorStr = e.toString();
      if (errorStr.contains('People API has not been used') || 
          errorStr.contains('people.googleapis.com')) {
        throw Exception('Service temporarily unavailable. Please try again in a few minutes.');
      }
      
      rethrow;
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

        // Professional Rule: Auto-assign admin role if email is from vailmeds.com
        final String finalRole = (email.endsWith('@vailmeds.com')) ? 'admin' : role;

        // Create Firestore profile
        final profile = UserProfile(
          uid: userCredential.user!.uid,
          email: email,
          name: name,
          phone: phone,
          role: finalRole,
          isVerified: finalRole == 'patient' || finalRole == 'admin',
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

  Future<void> submitVerificationRequest(
      String uid, String licenseNumber, String accessToken,
      {String? storeName, String? npiNumber, String? licensePhotoUrl}) async {
    try {
      final updateData = <String, dynamic>{
        'licenseNumber': licenseNumber,
        'accessToken': accessToken,
        'verificationStatus': 'pending', // Marks for admin review
        'isAdminApproved': false,       // Explicitly false until admin review
        'isVerified': false,            // Not verified yet
        'submittedAt': FieldValue.serverTimestamp(),
      };
      
      if (storeName != null) updateData['storeName'] = storeName;
      if (npiNumber != null) updateData['npiNumber'] = npiNumber;
      if (licensePhotoUrl != null) updateData['licensePhotoUrl'] = licensePhotoUrl;

      await _firestore.collection('users').doc(uid).update(updateData);
      debugPrint('Verification request submitted for: $uid');
    } catch (e) {
      debugPrint('Error submitting verification request: $e');
      rethrow;
    }
  }

  // Admin-only method: Get all pharmacies awaiting verification
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

  // Admin-only method: Approve pharmacy
  Future<void> adminApprovePharmacy(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isAdminApproved': true,
        'isVerified': true,
        'verificationStatus': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': _auth.currentUser?.uid,
      });
      
      if (_auth.currentUser != null) {
        final adminProfile = await getUserProfile(_auth.currentUser!.uid);
        final pharmacyProfile = await getUserProfile(uid);
        
        await AuditLogger.logPharmacyApproval(
          licenseNumber: pharmacyProfile?.licenseNumber ?? 'N/A',
          adminName: adminProfile?.name ?? 'Unknown Admin',
          adminUid: _auth.currentUser!.uid,
          pharmacyUid: uid,
        );
      }
      
      debugPrint('Pharmacy approved by admin: $uid');
    } catch (e) {
      debugPrint('Error approving pharmacy: $e');
      rethrow;
    }
  }

  // Admin-only method: Reject pharmacy
  Future<void> adminRejectPharmacy(String uid, String reason) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isAdminApproved': false,
        'isVerified': false,
        'verificationStatus': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Pharmacy rejected by admin: $uid. Reason: $reason');
    } catch (e) {
      debugPrint('Error rejecting pharmacy: $e');
      rethrow;
    }
  }
}
