import 'package:flutter/material.dart';

class AuthUser {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;

  AuthUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
  });
}

class AuthService extends ChangeNotifier {
  AuthUser? _currentUser;

  AuthUser? get currentUser => _currentUser;

  // Mock sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = AuthUser(
      uid: '123456',
      displayName: 'Test User',
      email: email,
      photoURL: null,
    );
    notifyListeners();
  }

  // Mock register with email and password
  Future<void> registerWithEmailAndPassword(
    String name,
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = AuthUser(
      uid: '123456',
      displayName: name,
      email: email,
      photoURL: null,
    );
    notifyListeners();
  }

  // Mock sign in with Google
  Future<void> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = AuthUser(
      uid: '789012',
      displayName: 'Google User',
      email: 'google@example.com',
      photoURL: 'https://source.unsplash.com/random/100x100?face',
    );
    notifyListeners();
  }

  // Mock sign out
  Future<void> signOut() async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = null;
    notifyListeners();
  }

  // Mock create test user
  Future<void> createTestUser() async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = AuthUser(
      uid: '123456',
      displayName: 'Demo User',
      email: 'demo@example.com',
      photoURL: null,
    );
    notifyListeners();
  }
}
