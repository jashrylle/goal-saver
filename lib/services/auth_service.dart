import 'package:flutter/foundation.dart';
import '../data/auth_store.dart' show AuthStore, AuthStoreException;
import '../models/user_model.dart';

/// Local storage-based authentication service.
///
/// Stores user credentials and accounts locally using Hive.
/// Supports multiple local user accounts and secure password hashing.
///
/// This replaces the old FlutterSecureStorage-based implementation.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final AuthStore _store = AuthStore();

  /// Whether init() has been called at least once.
  bool _ready = false;

  /// Initialize the auth store. Must be called after Hive is initialized.
  /// Safe to call multiple times.
  Future<void> init() async {
    if (_ready) return;
    await _store.init();
    _ready = true;
    debugPrint('[AuthService] Initialized.');
  }

  /// Ensure the store is initialized before any operation.
  Future<void> _ensureReady() async {
    if (!_ready) {
      debugPrint('[AuthService] Auto-initializing before operation...');
      await init();
    }
  }

  /// Whether a user is currently signed in (cached in memory).
  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;

  /// Check if a user is currently logged in (has an active session).
  Future<bool> isLoggedIn() async {
    await _ensureReady();
    final hasSession = await _store.hasActiveSession();
    _isSignedIn = hasSession;
    debugPrint('[AuthService] isLoggedIn: $hasSession');
    return hasSession;
  }

  /// Synchronize the in-memory sign-in state with Hive.
  Future<void> syncState() async {
    await _ensureReady();
    final user = await _store.getCurrentUser();
    _isSignedIn = user != null;
    debugPrint('[AuthService] syncState: user=${user?.email}');
  }

  /// Sign up a new user with email and password.
  /// Returns the newly created [UserModel].
  Future<UserModel> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    await _ensureReady();
    debugPrint('[AuthService] SignUp: name=$name, email=$email');
    try {
      final user = await _store.registerAccount(
        name: name,
        email: email,
        password: password,
      );
      // Auto-login after signup
      await _store.setCurrentUser(user.id);
      _isSignedIn = true;
      debugPrint('[AuthService] SignUp SUCCESS: user.id=${user.id}');
      return user;
    } on AuthStoreException catch (e) {
      debugPrint('[AuthService] SignUp FAILED: ${e.message}');
      throw AuthServiceException(e.message);
    } catch (e) {
      debugPrint('[AuthService] SignUp UNEXPECTED ERROR: $e');
      rethrow;
    }
  }

  /// Sign in with email and password.
  /// Returns the authenticated [UserModel].
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _ensureReady();
    debugPrint('[AuthService] SignIn: email=$email');
    try {
      final user = await _store.authenticate(
        email: email,
        password: password,
      );
      await _store.setCurrentUser(user.id);
      _isSignedIn = true;
      debugPrint('[AuthService] SignIn SUCCESS: user.id=${user.id}');
      return user;
    } on AuthStoreException catch (e) {
      debugPrint('[AuthService] SignIn FAILED: ${e.message}');
      throw AuthServiceException(e.message);
    } catch (e) {
      debugPrint('[AuthService] SignIn UNEXPECTED ERROR: $e');
      rethrow;
    }
  }

  /// Sign out the current user and clear the session.
  /// Does NOT delete the account.
  Future<void> signOut() async {
    await _ensureReady();
    await _store.clearCurrentUser();
    _isSignedIn = false;
    debugPrint('[AuthService] Signed out.');
  }

  /// Delete the current user's account entirely.
  Future<void> deleteAccount() async {
    await _ensureReady();
    final user = await _store.getCurrentUser();
    if (user != null) {
      await _store.deleteAccount(user.id);
    }
    _isSignedIn = false;
    debugPrint('[AuthService] Account deleted.');
  }

  /// Get the current user's profile from Hive.
  Future<UserModel?> getUser() async {
    await _ensureReady();
    return _store.getCurrentUser();
  }

  /// Save/update the current user's profile in Hive.
  Future<void> saveUser(UserModel user, {String? password}) async {
    await _ensureReady();
    await _store.updateUser(user);
    _isSignedIn = user.isLoggedIn;
    debugPrint('[AuthService] User saved: ${user.email}');
  }

  /// Verify a password against the stored hash.
  Future<bool> verifyPassword(String password) async {
    await _ensureReady();
    final user = await _store.getCurrentUser();
    if (user == null) return false;
    try {
      await _store.authenticate(email: user.email, password: password);
      return true;
    } catch (e) {
      debugPrint('[AuthService] verifyPassword FAILED: $e');
      return false;
    }
  }

  /// Get all registered user accounts.
  List<UserModel> getAllAccounts() {
    return _store.getAllAccounts();
  }

  /// Check if an email is already registered.
  bool isEmailRegistered(String email) {
    return _store.isEmailRegistered(email);
  }

  /// Get the current user ID, or null if no user is logged in.
  Future<String?> getCurrentUserId() async {
    await _ensureReady();
    return _store.getCurrentUserId();
  }
}

/// Exception thrown by authentication operations.
class AuthServiceException implements Exception {
  final String message;
  const AuthServiceException(this.message);

  @override
  String toString() => message;
}
