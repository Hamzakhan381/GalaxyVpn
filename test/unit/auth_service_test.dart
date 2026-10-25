import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_vpn/core/storage/preferences_service.dart';
import 'package:galaxy_vpn/data/repositories/auth_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthRepositoryImpl — Full Coverage Tests', () {
    late PreferencesService prefs;
    late AuthRepositoryImpl auth;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await PreferencesService.create();
      auth = AuthRepositoryImpl(prefs);
    });

    // ── Initial State ────────────────────────────────────────────────────────

    group('Initial State', () {
      test('not authenticated on fresh start', () {
        expect(auth.isAuthenticated, isFalse);
        expect(auth.currentUser, isNull);
        expect(auth.isGuest, isFalse);
      });
    });

    // ── login() ──────────────────────────────────────────────────────────────

    group('login()', () {
      test('valid credentials authenticate successfully', () async {
        final user = await auth.login('test@example.com', 'password123');
        expect(auth.isAuthenticated, isTrue);
        expect(user.email, equals('test@example.com'));
        expect(user.isGuest, isFalse);
      });

      test('login capitalises name from email prefix', () async {
        final user = await auth.login('alice@example.com', 'password123');
        expect(user.name, equals('Alice'));
      });

      test('login persists auth to prefs', () async {
        await auth.login('user@test.com', 'secret123');
        expect(prefs.isAuthenticated, isTrue);
        expect(prefs.userEmail, equals('user@test.com'));
        expect(prefs.isGuest, isFalse);
      });

      test('invalid email (no @) throws exception', () async {
        expect(
          () async => auth.login('invalidemail', 'password123'),
          throwsException,
        );
      });

      test('invalid email (no .) throws exception', () async {
        expect(
          () async => auth.login('user@nodot', 'password123'),
          throwsException,
        );
      });

      test('short password (< 6 chars) throws exception', () async {
        expect(
          () async => auth.login('user@test.com', '12345'),
          throwsException,
        );
      });

      test('exactly 6-char password does not throw', () async {
        final user = await auth.login('user@test.com', '123456');
        expect(user, isNotNull);
      });

      test('login trims whitespace from email', () async {
        final user = await auth.login('  user@test.com  ', 'password123');
        expect(user.email, equals('user@test.com'));
      });
    });

    // ── signUp() ─────────────────────────────────────────────────────────────

    group('signUp()', () {
      test('valid signup creates authenticated user', () async {
        final user =
            await auth.signUp('Alice', 'alice@domain.com', 'strongPass');
        expect(auth.isAuthenticated, isTrue);
        expect(user.name, equals('Alice'));
        expect(user.email, equals('alice@domain.com'));
        expect(user.isGuest, isFalse);
      });

      test('empty name throws exception', () async {
        expect(
          () async => auth.signUp('', 'user@test.com', 'password'),
          throwsException,
        );
      });

      test('whitespace-only name throws exception', () async {
        expect(
          () async => auth.signUp('   ', 'user@test.com', 'password'),
          throwsException,
        );
      });

      test('invalid email throws exception', () async {
        expect(
          () async => auth.signUp('Bob', 'notanemail', 'password'),
          throwsException,
        );
      });

      test('short password throws exception', () async {
        expect(
          () async => auth.signUp('Bob', 'bob@test.com', '12345'),
          throwsException,
        );
      });

      test('signup persists to prefs', () async {
        await auth.signUp('Bob', 'bob@test.com', 'longpassword');
        expect(prefs.isAuthenticated, isTrue);
        expect(prefs.userName, equals('Bob'));
      });
    });

    // ── continueAsGuest() ────────────────────────────────────────────────────

    group('continueAsGuest()', () {
      test('continueAsGuest returns a guest user', () async {
        final user = await auth.continueAsGuest();
        expect(user.isGuest, isTrue);
        expect(auth.isGuest, isTrue);
        expect(auth.isAuthenticated, isTrue);
      });

      test('guest email is fixed internal address', () async {
        final user = await auth.continueAsGuest();
        expect(user.email, equals('guest@galaxyvpn.internal'));
      });

      test('guest name is Academic Guest', () async {
        final user = await auth.continueAsGuest();
        expect(user.name, equals('Academic Guest'));
      });

      test('guest session persisted to prefs', () async {
        await auth.continueAsGuest();
        expect(prefs.isAuthenticated, isTrue);
        expect(prefs.isGuest, isTrue);
      });
    });

    // ── requestPasswordReset() ───────────────────────────────────────────────

    group('requestPasswordReset()', () {
      test('valid email completes without error', () async {
        expect(
          () async => auth.requestPasswordReset('user@test.com'),
          returnsNormally,
        );
      });

      test('invalid email (no @) throws exception', () async {
        expect(
          () async => auth.requestPasswordReset('notanemail'),
          throwsException,
        );
      });
    });

    // ── updateProfile() ──────────────────────────────────────────────────────

    group('updateProfile()', () {
      test('updates name for authenticated user', () async {
        await auth.login('user@test.com', 'password');
        await auth.updateProfile(name: 'New Name');
        expect(auth.currentUser?.name, equals('New Name'));
        expect(prefs.userName, equals('New Name'));
      });

      test('empty name throws exception', () async {
        await auth.login('user@test.com', 'password');
        expect(
          () async => auth.updateProfile(name: ''),
          throwsException,
        );
      });

      test('update without authenticated user throws exception', () async {
        expect(
          () async => auth.updateProfile(name: 'New Name'),
          throwsException,
        );
      });
    });

    // ── signOut() ────────────────────────────────────────────────────────────

    group('signOut()', () {
      test('signOut clears user and prefs', () async {
        await auth.login('user@test.com', 'password');
        expect(auth.isAuthenticated, isTrue);

        await auth.signOut();
        expect(auth.isAuthenticated, isFalse);
        expect(auth.currentUser, isNull);
        expect(prefs.isAuthenticated, isFalse);
      });

      test('isGuest is false after signOut', () async {
        await auth.continueAsGuest();
        await auth.signOut();
        expect(auth.isGuest, isFalse);
      });
    });

    // ── deleteAccount() ──────────────────────────────────────────────────────

    group('deleteAccount()', () {
      test('deleteAccount clears user, history, and consent', () async {
        await auth.login('user@test.com', 'password');
        await prefs.setVpnConsent(true);

        await auth.deleteAccount();
        expect(auth.isAuthenticated, isFalse);
        expect(prefs.hasGrantedVpnConsent, isFalse);
      });
    });

    // ── Persistence across restart ───────────────────────────────────────────

    group('Persistence', () {
      test('auth state is reloaded on new AuthRepositoryImpl instance', () async {
        await auth.login('persist@test.com', 'password');
        // Simulate app restart with same SharedPreferences instance
        final auth2 = AuthRepositoryImpl(prefs);
        expect(auth2.isAuthenticated, isTrue);
        expect(auth2.currentUser?.email, equals('persist@test.com'));
      });

      test('guest state is reloaded after restart', () async {
        await auth.continueAsGuest();
        final auth2 = AuthRepositoryImpl(prefs);
        expect(auth2.isAuthenticated, isTrue);
        expect(auth2.isGuest, isTrue);
      });
    });
  });
}
