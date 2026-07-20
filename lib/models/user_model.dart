class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final bool isLoggedIn;
  final String authProvider; // 'email' or 'google'
  final String? googleId;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    this.isLoggedIn = false,
    this.authProvider = 'email',
    this.googleId,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    bool? isLoggedIn,
    String? authProvider,
    String? googleId,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      authProvider: authProvider ?? this.authProvider,
      googleId: googleId ?? this.googleId,
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
      'authProvider': authProvider,
      'googleId': googleId,
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
      authProvider: (map['authProvider'] as String?) ?? 'email',
      googleId: map['googleId'] as String?,
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