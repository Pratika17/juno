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
    } catch (e) {
      rethrow;
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
    } catch (e) {
      rethrow;
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
