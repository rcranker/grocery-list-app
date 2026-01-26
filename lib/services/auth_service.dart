import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'subscription_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      debugPrint('🔹 Step 1: Creating Firebase Auth user...');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        debugPrint('❌ No user returned from Firebase Auth');
        return null;
      }
      debugPrint('✅ Firebase Auth user created: ${user.uid}');

      debugPrint('🔹 Step 2: Updating display name...');
      await user.updateDisplayName(displayName);
      debugPrint('✅ Display name updated');

      final userModel = UserModel(
        uid: user.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
        householdId: null,
        isPremium: false,
      );

      debugPrint('🔹 Step 3: Creating Firestore document...');
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
      debugPrint('✅ Firestore document created');

      debugPrint('🔹 Step 4: Logging into RevenueCat...');
      await SubscriptionService().loginUser(user.uid);
      debugPrint('✅ RevenueCat login complete');

      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e, stackTrace) {
      debugPrint('❌ Registration error: $e');
      debugPrint('Stack trace: $stackTrace');
      throw 'Registration failed: $e';
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    
      // Check if Firestore document exists
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
    
      if (!userDoc.exists) {
        // Create Firestore document if it doesn't exist
        debugPrint('Creating missing Firestore document for ${userCredential.user!.uid}');
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          displayName: userCredential.user!.displayName ?? email.split('@')[0],
          createdAt: DateTime.now(),
          householdId: null,
          isPremium: false,
        );
        await _firestore.collection('users').doc(userCredential.user!.uid).set(userModel.toMap());
      }
    
      // Login to RevenueCat
      if (userCredential.user != null) {
        await SubscriptionService().loginUser(userCredential.user!.uid);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await rc.Purchases.logOut();  // Logout from RevenueCat too
    await _auth.signOut();
}

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}