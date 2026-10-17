import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthViewModel extends ChangeNotifier {
  final AuthService _service = AuthService();

  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;
  bool isGuest = false;
  bool loading = false;
  String? error;

  void bootstrap() {
    _service.authStateChanges().listen((User? u) async {
      if (u == null) {
        // Don't clobber guest mode if we explicitly set it.
        if (!isGuest) {
          currentUser = null;
          status = AuthStatus.unauthenticated;
        }
        notifyListeners();
      } else {
        try {
          final profile = await _service.fetchProfile(u.uid);
          if (profile == null) {
            await _service.signOut();
            currentUser = null;
            status = AuthStatus.unauthenticated;
          } else {
            currentUser = profile;
            isGuest = false;
            status = AuthStatus.authenticated;
          }
        } catch (_) {
          currentUser = null;
          status = AuthStatus.unauthenticated;
        }
        notifyListeners();
      }
    });
  }

  /// Enter guest browsing.
  void continueAsGuest() {
    isGuest = true;
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> signUpCustomer({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      currentUser = await _service.signUpCustomer(
          name: name, phone: phone, email: email, password: password);
      isGuest = false;
      status = AuthStatus.authenticated;
      return true;
    } catch (e) {
      error = _pretty(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInCustomer(
      {required String email, required String password}) async {
    _setLoading(true);
    try {
      currentUser =
      await _service.signInCustomer(email: email, password: password);
      isGuest = false;
      status = AuthStatus.authenticated;
      return true;
    } catch (e) {
      error = _pretty(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInAdmin(
      {required String email, required String password}) async {
    _setLoading(true);
    try {
      currentUser =
      await _service.signInAdmin(email: email, password: password);
      isGuest = false;
      status = AuthStatus.authenticated;
      return true;
    } catch (e) {
      error = _pretty(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    currentUser = null;
    isGuest = false;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Replaces the in-memory current user after a successful profile update.
  /// Call this from any screen that writes new user data to Firestore.
  void updateLocalUser(AppUser user) {
    currentUser = user;
    notifyListeners();
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      await _service.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        email: currentUser!.email,
      );
      return true;
    } catch (e) {
      error = _pretty(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    loading = v;
    if (v) error = null;
    notifyListeners();
  }

  String _pretty(Object e) {
    if (e is FirebaseAuthException) return e.message ?? e.code;
    return e.toString().replaceFirst('Exception: ', '');
  }
}