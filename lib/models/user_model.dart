import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final bool isLoggedIn;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    this.isLoggedIn = false,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    bool? isLoggedIn,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'isLoggedIn': isLoggedIn,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      photoUrl: map['photoUrl'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isLoggedIn: map['isLoggedIn'] as bool? ?? false,
    );
  }
}

/// Validate email format using a proper regex pattern.
bool isValidEmail(String email) {
  if (email.isEmpty) return false;
  final emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$",
  );
  return emailRegex.hasMatch(email);
}

/// Simple hash function for password storage.
String _hashPassword(String password) {
  final bytes = utf8.encode(password);
  final codeUnits = <int>[];
  int running = 0;
  for (int i = 0; i < bytes.length; i++) {
    running = ((running << 5) - running + bytes[i]) & 0xFFFFFFFF;
    codeUnits.add((running.abs() % 256));
  }
  for (int round = 0; round < 3; round++) {
    running = 0;
    for (int i = 0; i < codeUnits.length; i++) {
      running = ((running << 5) - running + codeUnits[i]) & 0xFFFFFFFF;
      codeUnits[i] = (running.abs() % 256);
    }
  }
  return base64.encode(codeUnits);
}

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _keyUser = 'current_user';
  static const _keyPassword = 'user_password_hash';

  Future<void> saveUser(UserModel user, {String? password}) async {
    await _storage.write(key: _keyUser, value: json.encode(user.toMap()));
    if (password != null && password.isNotEmpty) {
      await _storage.write(key: _keyPassword, value: _hashPassword(password));
    }
  }

  Future<UserModel?> getUser() async {
    final data = await _storage.read(key: _keyUser);
    if (data == null) return null;
    try {
      final decoded = json.decode(data);
      if (decoded is Map<String, dynamic>) {
        return UserModel.fromMap(decoded);
      }
      // If it was stored in old format (map.toString()) or is invalid
      return _parseOldFormat(data);
    } catch (_) {
      return _parseOldFormat(data);
    }
  }

  /// Verify a password against the stored hash.
  Future<bool> verifyPassword(String password) async {
    final storedHash = await _storage.read(key: _keyPassword);
    if (storedHash == null) return true; // Backwards compatibility
    return _hashPassword(password) == storedHash;
  }

  UserModel _parseOldFormat(String data) {
    String name = 'User';
    String email = 'user@example.com';
    try {
      final nameMatch = RegExp(r'name:\s*([^,}]+)').firstMatch(data);
      if (nameMatch != null) {
        name = nameMatch.group(1)?.trim() ?? 'User';
      }
      final emailMatch = RegExp(r'email:\s*([^,}]+)').firstMatch(data);
      if (emailMatch != null) {
        email = emailMatch.group(1)?.trim() ?? 'user@example.com';
      }
    } catch (_) {}
    return UserModel(
      id: 'user_1',
      name: name,
      email: email,
      createdAt: DateTime.now(),
      isLoggedIn: true,
    );
  }

  Future<void> logout() async {
    // Instead of deleting user, update isLoggedIn flag so credentials persist
    final user = await getUser();
    if (user != null) {
      await saveUser(user.copyWith(isLoggedIn: false));
    }
  }

  Future<bool> isLoggedIn() async {
    final user = await getUser();
    return user?.isLoggedIn ?? false;
  }

  /// Register a new user with email and password.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      createdAt: DateTime.now(),
      isLoggedIn: true,
    );
    await saveUser(user, password: password);
    return user;
  }

  /// Login with email and password verification.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final user = await getUser();
    if (user == null) {
      throw AuthException('No account found. Please sign up first.');
    }
    if (user.email.toLowerCase() != email.toLowerCase()) {
      throw AuthException('Invalid email or password.');
    }
    final valid = await verifyPassword(password);
    if (!valid) {
      throw AuthException('Invalid email or password.');
    }
    final updatedUser = user.copyWith(isLoggedIn: true);
    await saveUser(updatedUser);
    return updatedUser;
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}