import '../entities/auth_user.dart';

/// Pure domain repository contract defining authentication & account management
abstract class AuthRepository {
  AuthUser? get currentUser;
  bool get isAuthenticated;
  bool get isGuest;

  Future<AuthUser> login(String email, String password);
  Future<AuthUser> signUp(String name, String email, String password);
  Future<AuthUser> continueAsGuest();
  Future<void> requestPasswordReset(String email);
  Future<void> updateProfile({required String name});
  Future<void> signOut();
  Future<void> deleteAccount();
}
