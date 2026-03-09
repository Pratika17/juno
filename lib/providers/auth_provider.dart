import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUserModel;
  bool _isLoading = false;
  String? _errorMessage;

  // StreamSubscription? _authSubscription; // If we needed to cancel, but Provider disposes us.
  // Actually, for a singleton-like AuthProvider provided at root, it lives as long as the app.
  // If it were scoped, we'd need to cancel subscription in dispose().

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authService.authStateChanges.listen((User? user) {
      if (user == null) {
        _currentUserModel = null;
        notifyListeners();
      } else {
        // User logged in, fetch their profile
        fetchCurrentUserModel(user: user);
      }
    });
  }

  UserModel? get currentUserModel => _currentUserModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  // Sign Up
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String department,
    required String phone,
  }) async {
    _setLoading(true);
    try {
      await _authService.signUp(
        email: email,
        password: password,
        name: name,
        department: department,
        phone: phone,
      );
      // fetchCurrentUserModel will be triggered by auth state change listener usually,
      // but waiting here ensures UI has data before navigating if we await this.
      // However, the listener is async.
      // Let's rely on the listener for consistency, or manually fetch if we need to wait.
      // Since signUp returns a Future<bool>, the UI waits.
      // The listener will fire. We might race.
      // Best to let the listener handle it to avoid double fetch?
      // Or explicitly fetch here and let early return in listener handle dupes?
      // Let's stick to explicit fetch here for immediate UI feedback loop if needed,
      // but the listener is the source of truth for "session restored".

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Sign In
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    try {
      await _authService.signIn(email: email, password: password);
      // Listener will pick this up.
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUserModel = null;
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  // Reset Password
  Future<bool> resetPassword({required String email}) async {
    _setLoading(true);
    try {
      await _authService.resetPassword(email: email);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Private helpers
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchCurrentUserModel({
    User? user,
    bool forceRefresh = false,
  }) async {
    final targetUser = user ?? _authService.currentUser;

    if (targetUser == null) {
      _currentUserModel = null;
      return;
    }

    // Prevent redundant fetch if we already have the correct user loaded
    if (!forceRefresh &&
        _currentUserModel != null &&
        _currentUserModel!.userId == targetUser.uid) {
      return;
    }

    print('DEBUG: fetchCurrentUserModel called for user: ${targetUser.uid}');
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUser.uid)
          .get();
      print('DEBUG: User doc exists: ${doc.exists}');
      if (doc.exists) {
        _currentUserModel = UserModel.fromFirestore(doc);
        print('DEBUG: User model loaded: ${_currentUserModel?.email}');
      } else {
        print(
          'DEBUG: User doc does not exist! Attempting to create fallback user doc.',
        );
        // Attempt to create a fallback user document
        UserModel newUser = UserModel(
          userId: targetUser.uid,
          name: targetUser.displayName ?? 'User',
          email: targetUser.email ?? '',
          phone: targetUser.phoneNumber ?? '',
          department: 'Pending', // Default or unknown
          createdAt: DateTime.now(),
        );

        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(targetUser.uid)
              .set(newUser.toFirestore());
          _currentUserModel = newUser;
          print('DEBUG: Fallback user model created and loaded.');
        } catch (createError) {
          print('DEBUG: Failed to create fallback user doc: $createError');
          _errorMessage =
              "Failed to load or create user profile. Please check your connection.";
        }
      }

      // Initialize Push Notifications if user is validated
      if (_currentUserModel != null) {
        _setupPushNotifications(targetUser.uid);
      }

      notifyListeners();
    } catch (e) {
      print('DEBUG: Error fetching user model: $e');
      _errorMessage = "Error fetching profile: $e";
      notifyListeners();
    }
  }

  Future<void> _setupPushNotifications(String userId) async {
    final notificationService = NotificationService();
    await notificationService.initNotifications();
    String? token = await notificationService.getFCMToken();
    if (token != null) {
      await notificationService.updateFCMToken(userId, token);
    }
  }
}
