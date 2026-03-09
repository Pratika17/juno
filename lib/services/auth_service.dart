import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String department,
    required String phone,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Create user document in Firestore
        UserModel newUser = UserModel(
          userId: user.uid,
          name: name,
          email: email,
          phone: phone,
          department: department,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newUser.toFirestore());
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('The account already exists for that email.');
      } else if (e.code == 'network-request-failed') {
        throw Exception('Network error, please check your connection.');
      }
      throw Exception(e.message ?? 'An error occurred during sign up.');
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  // Sign In
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        throw Exception('Invalid credentials. Please try again.');
      } else if (e.code == 'network-request-failed') {
        throw Exception('Network error, please check your connection.');
      }
      throw Exception(e.message ?? 'An error occurred during sign in.');
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Reset Password
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Get Current User
  User? get currentUser {
    return _auth.currentUser;
  }

  // Auth State Changes
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }
}
