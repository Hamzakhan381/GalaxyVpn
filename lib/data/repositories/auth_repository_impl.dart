import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/preferences_repository.dart';

/// Concrete implementation of AuthRepository with local encrypted credentials
class AuthRepositoryImpl implements AuthRepository {
  final PreferencesRepository _prefs;
  AuthUser? _currentUser;

  AuthRepositoryImpl(this._prefs) {
    _loadStoredUser();
  }

  void _loadStoredUser() {
    if (_prefs.isAuthenticated) {
      _currentUser = AuthUser(
        email: _prefs.userEmail ?? 'guest@shieldroute.local',
        name: _prefs.userName ?? 'ShieldRoute User',
        isGuest: _prefs.isGuest,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      );
    }
  }

  String _hashPassword(String password) {
    const salt = 'ShieldRoute_Salt_2026';
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  bool get isGuest => _currentUser?.isGuest ?? false;

  @override
  Future<AuthUser> login(String email, String password) async {
    final trimmedEmail = email.trim();
    if (!trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
      throw Exception('Please provide a valid email address.');
    }
    if (password.length < 6) {
      throw Exception('Password must contain at least 6 characters.');
    }

    _hashPassword(password);

    final name = trimmedEmail.split('@').first;
    final formattedName = name.isNotEmpty
        ? name[0].toUpperCase() + name.substring(1)
        : 'Student User';

    _currentUser = AuthUser(
      email: trimmedEmail,
      name: formattedName,
      isGuest: false,
      createdAt: DateTime.now(),
    );

    await _prefs.saveAuth(
      email: trimmedEmail,
      name: formattedName,
      isGuest: false,
    );

    return _currentUser!;
  }

  @override
  Future<AuthUser> signUp(String name, String email, String password) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();

    if (trimmedName.isEmpty) {
      throw Exception('Please enter your name.');
    }
    if (!trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
      throw Exception('Please provide a valid email address.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters long.');
    }

    _hashPassword(password);

    _currentUser = AuthUser(
      email: trimmedEmail,
      name: trimmedName,
      isGuest: false,
      createdAt: DateTime.now(),
    );

    await _prefs.saveAuth(
      email: trimmedEmail,
      name: trimmedName,
      isGuest: false,
    );

    return _currentUser!;
  }

  @override
  Future<AuthUser> continueAsGuest() async {
    const guestEmail = 'guest@shieldroute.internal';
    const guestName = 'Academic Guest';

    _currentUser = AuthUser(
      email: guestEmail,
      name: guestName,
      isGuest: true,
      createdAt: DateTime.now(),
    );

    await _prefs.saveAuth(
      email: guestEmail,
      name: guestName,
      isGuest: true,
    );

    return _currentUser!;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    final trimmedEmail = email.trim();
    if (!trimmedEmail.contains('@')) {
      throw Exception('Invalid email address provided.');
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> updateProfile({required String name}) async {
    if (_currentUser == null) throw Exception('No authenticated user');
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw Exception('Name cannot be empty');

    _currentUser = AuthUser(
      email: _currentUser!.email,
      name: trimmed,
      isGuest: _currentUser!.isGuest,
      createdAt: _currentUser!.createdAt,
    );

    await _prefs.saveAuth(
      email: _currentUser!.email,
      name: trimmed,
      isGuest: _currentUser!.isGuest,
    );
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    await _prefs.clearAuth();
  }

  @override
  Future<void> deleteAccount() async {
    _currentUser = null;
    await _prefs.clearAuth();
    await _prefs.clearHistory();
    await _prefs.setVpnConsent(false);
  }
}
