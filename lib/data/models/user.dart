/// Mobile-app user roles. Only these two may use the app; any other role
/// (e.g. ADMIN) is rejected at sign-in.
enum UserRole { representative, subLogisticsOfficer, other }

extension UserRoleX on UserRole {
  static UserRole parse(String? value) {
    return switch (value?.toUpperCase()) {
      'REPRESENTATIVE' => UserRole.representative,
      'SUB_LOGISTICS_OFFICER' => UserRole.subLogisticsOfficer,
      _ => UserRole.other,
    };
  }
}

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

  UserRole get roleKind => UserRoleX.parse(role);
  bool get isRepresentative => roleKind == UserRole.representative;
  bool get isSubLogisticsOfficer => roleKind == UserRole.subLogisticsOfficer;

  /// True for any role the mobile app supports (primary rep or assistant).
  bool get canUseMobileApp => isRepresentative || isSubLogisticsOfficer;

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
