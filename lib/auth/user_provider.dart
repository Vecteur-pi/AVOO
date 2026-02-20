import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'user_profile.dart';

enum AuthStatus {
  initial,
  loading,
  unauthenticated,
  authenticated,
  error,
}

class UserProvider extends ChangeNotifier {
  UserProvider() {
    _init();
  }

  AuthStatus _status = AuthStatus.initial;
  User? _user;
  UserProfile? _profile;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;

  AuthStatus get status => _status;
  User? get user => _user;
  UserProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;

  bool get isLoading =>
      _status == AuthStatus.initial || _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void _init() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _onAuthStateChanged,
    );
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      _profile = null;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _status = AuthStatus.loading;
    _user = firebaseUser;
    notifyListeners();

    try {
      final profile = await UserProfileService.load(firebaseUser);
      _profile = profile;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
    } catch (e) {
      _status = AuthStatus.error;
      _profile = null;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    if (_user == null) return;
    await _onAuthStateChanged(_user);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
