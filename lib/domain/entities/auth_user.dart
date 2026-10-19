/// Domain entity representing an authenticated user or guest
class AuthUser {
  final String email;
  final String name;
  final bool isGuest;
  final DateTime createdAt;

  const AuthUser({
    required this.email,
    required this.name,
    required this.isGuest,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          name == other.name &&
          isGuest == other.isGuest;

  @override
  int get hashCode => email.hashCode ^ name.hashCode ^ isGuest.hashCode;
}
