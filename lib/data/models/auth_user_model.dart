import '../../domain/entities/auth_user.dart';

/// Data Transfer Object for AuthUser
class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.email,
    required super.name,
    required super.isGuest,
    required super.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'isGuest': isGuest,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      email: json['email'] as String,
      name: json['name'] as String,
      isGuest: json['isGuest'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  factory AuthUserModel.fromDomain(AuthUser user) {
    return AuthUserModel(
      email: user.email,
      name: user.name,
      isGuest: user.isGuest,
      createdAt: user.createdAt,
    );
  }
}
