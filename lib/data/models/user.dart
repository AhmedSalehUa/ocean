class User {
  final String id;
  final String fullName;
  final String username;
  final String role;
  final String? phone;
  final bool isActive;

  const User({
    required this.id,
    required this.fullName,
    required this.username,
    required this.role,
    this.phone,
    this.isActive = true,
  });

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  bool get isRepresentative => role == 'REPRESENTATIVE';

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        username: json['username'] as String,
        role: json['role'] as String,
        phone: json['phone'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );
}

class AuthResult {
  final String token;
  final User user;
  const AuthResult({required this.token, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        token: json['token'] as String,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );
}
