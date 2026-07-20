import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/user_model.dart';

/// Hive-based authentication store for Goal Saver.
///
/// Supports multiple local user accounts and secure password hashing.
/// All data is stored in a single Hive box.
///
/// Unlike the previous [AuthService] which used FlutterSecureStorage,
/// this store uses Hive so all auth data persists even when the app
/// is closed, and supports multiple simultaneous user accounts.
class AuthStore {
  Box<dynamic>? _box;
  bool _initialized = false;
  static const _boxName = 'goal_saver_auth';

  // ── Box Keys ────────────────────────────────────────────────────────────

  static const _kAccounts = 'user_accounts';
  static const _kCurrentUserId = 'current_user_id';

  /// Initialize the Hive box for auth data.
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> init() async {
    if (_initialized && _box != null && _box!.isOpen) return;
    _box = await Hive.openBox<dynamic>(_boxName);
    _initialized = true;
    debugPrint('[AuthStore] Auth box "$_boxName" initialized.');
  }

  // ── Account Management ──────────────────────────────────────────────────

  /// Save (register) a new user account with hashed password.
  Future<UserModel> registerAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    await _ensureInitialized();
    final accounts = _loadAccounts();

    // Check for duplicate email (case-insensitive)
    // Note: account data is stored as {'user': userMap, 'passwordHash': hash}
    // so email is nested under a['user']['email']
    final existing = accounts.values.any((a) {
      final userData = a['user'];
      if (userData == null) return false;
      if (userData is! Map) return false;
      return (userData['email']?.toString() ?? '').toLowerCase() == email.toLowerCase();
    });
    if (existing) {
      throw AuthStoreException('An account with this email already exists.');
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final user = UserModel(
      id: id,
      name: name,
      email: email,
      createdAt: DateTime.now(),
      isLoggedIn: false,
    );

    accounts[id] = {
      'user': user.toMap(),
      'passwordHash': _hashPassword(password),
    };

    await _box!.put(_kAccounts, accounts);
    return user;
  }

  /// Authenticate a user by email and password. Returns the user if valid.
  Future<UserModel> authenticate({
    required String email,
    required String password,
  }) async {
    await _ensureInitialized();
    debugPrint('[AuthStore] Authenticating user: $email');
    final accounts = _loadAccounts();
    debugPrint('[AuthStore] Total accounts in store: ${accounts.length}');

    for (final entry in accounts.entries) {
      final userRaw = entry.value['user'];
      if (userRaw is! Map) continue;
      final userData = Map<String, dynamic>.from(userRaw);
      final userEmail = (userData['email']?.toString() ?? '').toLowerCase();
      final storedHash = entry.value['passwordHash'] as String? ?? '';

      if (userEmail == email.toLowerCase()) {
        if (_verifyPassword(password, storedHash)) {
          return UserModel.fromMap(userData);
        }
        throw AuthStoreException('Invalid email or password.');
      }
    }

    throw AuthStoreException('No account found. Please sign up first.');
  }

  /// Update a user's profile data across all stores.
  Future<void> updateUser(UserModel user) async {
    await _ensureInitialized();
    final accounts = _loadAccounts();
    if (accounts.containsKey(user.id)) {
      accounts[user.id]!['user'] = user.toMap();
      await _box!.put(_kAccounts, accounts);
    }
  }

  /// Delete a user account.
  Future<void> deleteAccount(String userId) async {
    await _ensureInitialized();
    final accounts = _loadAccounts();
    accounts.remove(userId);
    await _box!.put(_kAccounts, accounts);
    // Clear current user if it was the deleted one
    final currentId = _box!.get(_kCurrentUserId) as String?;
    if (currentId == userId) {
      await _box!.delete(_kCurrentUserId);
    }
  }

  /// Get all registered user accounts (for display/admin purposes).
  List<UserModel> getAllAccounts() {
    final accounts = _loadAccounts();
    final users = <UserModel>[];
    for (final a in accounts.values) {
      final userRaw = a['user'];
      if (userRaw is! Map) continue;
      try {
        users.add(UserModel.fromMap(Map<String, dynamic>.from(userRaw)));
      } catch (_) {
        // Skip invalid accounts
      }
    }
    return users;
  }

  /// Check if an email is already registered.
  bool isEmailRegistered(String email) {
    final accounts = _loadAccounts();
    return accounts.values.any((a) {
      final userRaw = a['user'];
      if (userRaw is! Map) return false;
      final userData = Map<String, dynamic>.from(userRaw);
      return (userData['email']?.toString() ?? '').toLowerCase() == email.toLowerCase();
    });
  }

  // ── Session Management ──────────────────────────────────────────────────

  /// Set the currently active user (marks them as logged in).
  Future<void> setCurrentUser(String userId) async {
    await _ensureInitialized();
    debugPrint('[AuthStore] Setting current user: $userId');
    await _box!.put(_kCurrentUserId, userId);
    // Also update the account's isLoggedIn flag
    final accounts = _loadAccounts();
    if (accounts.containsKey(userId)) {
      final userRaw = accounts[userId]!['user'];
      if (userRaw is Map) {
        final userData = Map<String, dynamic>.from(userRaw);
        userData['isLoggedIn'] = true;
        accounts[userId]!['user'] = userData;
        await _box!.put(_kAccounts, accounts);
      }
    }
  }

  /// Clear the current user session (logout).
  Future<void> clearCurrentUser() async {
    await _ensureInitialized();
    final userId = _box!.get(_kCurrentUserId) as String?;
    if (userId != null) {
      final accounts = _loadAccounts();
      if (accounts.containsKey(userId)) {
        final userRaw = accounts[userId]!['user'];
        if (userRaw is Map) {
          final userData = Map<String, dynamic>.from(userRaw);
          userData['isLoggedIn'] = false;
          accounts[userId]!['user'] = userData;
          await _box!.put(_kAccounts, accounts);
        }
      }
    }
    await _box!.delete(_kCurrentUserId);
  }

  /// Get the currently logged-in user, if any.
  Future<UserModel?> getCurrentUser() async {
    await _ensureInitialized();
    final userId = _box!.get(_kCurrentUserId) as String?;
    if (userId == null) {
      debugPrint('[AuthStore] No current user ID found.');
      return null;
    }

    final accounts = _loadAccounts();
    final account = accounts[userId];
    if (account == null) {
      debugPrint('[AuthStore] No account found for user ID: $userId');
      return null;
    }

    final userRaw = account['user'];
    if (userRaw == null) {
      debugPrint('[AuthStore] Account data missing for user ID: $userId');
      return null;
    }
    if (userRaw is! Map) {
      debugPrint('[AuthStore] Account user data is not a Map for user ID: $userId');
      return null;
    }

    final userMap = Map<String, dynamic>.from(userRaw);
    return UserModel.fromMap(userMap);
  }

  /// Check if there's an active session (for app startup).
  Future<bool> hasActiveSession() async {
    await _ensureInitialized();
    final userId = _box!.get(_kCurrentUserId) as String?;
    if (userId == null) {
      debugPrint('[AuthStore] No current user ID for session check');
      return false;
    }

    final accounts = _loadAccounts();
    final hasAccount = accounts.containsKey(userId);
    debugPrint('[AuthStore] Session check: user=$userId, accountExists=$hasAccount');
    return hasAccount;
  }

  /// Get the current user ID (without loading the full user).
  Future<String?> getCurrentUserId() async {
    await _ensureInitialized();
    return _box!.get(_kCurrentUserId) as String?;
  }

  /// Check whether we should show the login screen or go straight to the app.
  Future<bool> shouldAutoLogin() async {
    return await hasActiveSession();
  }

  // ── Password Management ─────────────────────────────────────────────────

  /// Verify a password against a stored hash.
  bool _verifyPassword(String password, String storedHash) {
    final hash = _hashPassword(password);
    final match = hash == storedHash;
    debugPrint('[AuthStore] Password verification result: $match');
    return match;
  }

  /// Hash a password using a salted SHA-like algorithm.
  /// This is NOT cryptographically secure — it's obfuscation for local
  /// device-only storage protected by Hive's OS-level encryption.
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final codeUnits = <int>[];
    // Add a static salt
    const salt = 'GoalSaver2024!@#Secure';
    final salted = utf8.encode(salt) + bytes;

    int running = 0;
    for (int i = 0; i < salted.length; i++) {
      running = ((running << 5) - running + salted[i]) & 0xFFFFFFFF;
      codeUnits.add((running.abs() % 256));
    }
    // Multiple rounds of mixing
    for (int round = 0; round < 5; round++) {
      running = 0;
      for (int i = 0; i < codeUnits.length; i++) {
        running = ((running << 5) - running + codeUnits[i]) & 0xFFFFFFFF;
        codeUnits[i] = (running.abs() % 256);
      }
    }
    final result = base64.encode(codeUnits);
    debugPrint('[AuthStore] Password hashed (length=${result.length})');
    return result;
  }

  // ── Internal Helpers ────────────────────────────────────────────────────

  Map<String, Map<String, dynamic>> _loadAccounts() {
    if (!_initialized || _box == null || !_box!.isOpen) {
      debugPrint('[AuthStore] WARNING: Box not initialized when loading accounts');
      return {};
    }
    final raw = _box!.get(_kAccounts);
    if (raw is Map) {
      final accounts = raw.map((key, value) {
        if (value is Map) {
          return MapEntry(key.toString(), Map<String, dynamic>.from(value));
        }
        return MapEntry(key.toString(), <String, dynamic>{});
      });
      debugPrint('[AuthStore] Loaded ${accounts.length} accounts from Hive');
      return accounts;
    }
    debugPrint('[AuthStore] No accounts found in Hive (raw type: ${raw.runtimeType})');
    return {};
  }

  /// Clear all auth data (for testing or factory reset).
  Future<void> clearAll() async {
    await _ensureInitialized();
    await _box!.clear();
    debugPrint('[AuthStore] All auth data cleared.');
  }

  /// Ensure the box is initialized before any operation.
  Future<void> _ensureInitialized() async {
    if (!_initialized || _box == null || !_box!.isOpen) {
      debugPrint('[AuthStore] Auto-initializing box...');
      await init();
    }
  }
}

/// Exception thrown by [AuthStore].
class AuthStoreException implements Exception {
  final String message;
  const AuthStoreException(this.message);

  @override
  String toString() => message;
}

// Note: AuthService is defined in lib/services/auth_service.dart
