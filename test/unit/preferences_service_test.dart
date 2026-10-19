import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldroute_vpn/core/storage/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreferencesService — Full Coverage Tests', () {
    late PreferencesService prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await PreferencesService.create();
    });

    // ── VPN Consent ──────────────────────────────────────────────────────────

    group('VPN Consent', () {
      test('hasGrantedVpnConsent is false by default', () {
        expect(prefs.hasGrantedVpnConsent, isFalse);
      });

      test('setVpnConsent(true) persists consent', () async {
        await prefs.setVpnConsent(true);
        expect(prefs.hasGrantedVpnConsent, isTrue);
      });

      test('setVpnConsent(false) revokes consent', () async {
        await prefs.setVpnConsent(true);
        await prefs.setVpnConsent(false);
        expect(prefs.hasGrantedVpnConsent, isFalse);
      });
    });

    // ── Authentication ───────────────────────────────────────────────────────

    group('Authentication', () {
      test('isAuthenticated is false by default', () {
        expect(prefs.isAuthenticated, isFalse);
      });

      test('isGuest is false by default', () {
        expect(prefs.isGuest, isFalse);
      });

      test('userEmail is null by default', () {
        expect(prefs.userEmail, isNull);
      });

      test('userName is null by default', () {
        expect(prefs.userName, isNull);
      });

      test('saveAuth persists all fields correctly', () async {
        await prefs.saveAuth(
          email: 'test@example.com',
          name: 'Test User',
          isGuest: false,
        );
        expect(prefs.isAuthenticated, isTrue);
        expect(prefs.isGuest, isFalse);
        expect(prefs.userEmail, equals('test@example.com'));
        expect(prefs.userName, equals('Test User'));
      });

      test('saveAuth with isGuest=true persists guest flag', () async {
        await prefs.saveAuth(
          email: 'guest@shieldroute.internal',
          name: 'Academic Guest',
          isGuest: true,
        );
        expect(prefs.isGuest, isTrue);
        expect(prefs.isAuthenticated, isTrue);
      });

      test('clearAuth removes all auth fields', () async {
        await prefs.saveAuth(
          email: 'test@example.com',
          name: 'Test User',
          isGuest: false,
        );
        await prefs.clearAuth();
        expect(prefs.isAuthenticated, isFalse);
        expect(prefs.userEmail, isNull);
        expect(prefs.userName, isNull);
        expect(prefs.isGuest, isFalse);
      });
    });

    // ── Favorites ────────────────────────────────────────────────────────────

    group('Favorites', () {
      test('favoriteServerIds is empty by default', () {
        expect(prefs.favoriteServerIds, isEmpty);
      });

      test('toggleFavorite adds a server id', () async {
        await prefs.toggleFavorite('srv_1');
        expect(prefs.favoriteServerIds, contains('srv_1'));
      });

      test('toggleFavorite removes server id on second call', () async {
        await prefs.toggleFavorite('srv_1');
        await prefs.toggleFavorite('srv_1');
        expect(prefs.favoriteServerIds, isNot(contains('srv_1')));
      });

      test('multiple favorites are stored independently', () async {
        await prefs.toggleFavorite('srv_1');
        await prefs.toggleFavorite('srv_2');
        expect(prefs.favoriteServerIds, containsAll(['srv_1', 'srv_2']));
      });

      test('removing one favorite does not affect others', () async {
        await prefs.toggleFavorite('srv_1');
        await prefs.toggleFavorite('srv_2');
        await prefs.toggleFavorite('srv_1'); // remove srv_1
        expect(prefs.favoriteServerIds, contains('srv_2'));
        expect(prefs.favoriteServerIds, isNot(contains('srv_1')));
      });
    });

    // ── Settings ─────────────────────────────────────────────────────────────

    group('Settings', () {
      test('autoConnect is false by default', () {
        expect(prefs.autoConnect, isFalse);
      });

      test('setAutoConnect persists true', () async {
        await prefs.setAutoConnect(true);
        expect(prefs.autoConnect, isTrue);
      });

      test('setAutoConnect can be toggled back to false', () async {
        await prefs.setAutoConnect(true);
        await prefs.setAutoConnect(false);
        expect(prefs.autoConnect, isFalse);
      });

      test('reconnectOnNetworkChange is true by default', () {
        expect(prefs.reconnectOnNetworkChange, isTrue);
      });

      test('setReconnectOnNetworkChange persists false', () async {
        await prefs.setReconnectOnNetworkChange(false);
        expect(prefs.reconnectOnNetworkChange, isFalse);
      });

      test('preferredProtocol defaults to ShieldRoute Native (WireGuard-Optimized)', () {
        expect(
          prefs.preferredProtocol,
          equals('ShieldRoute Native (WireGuard-Optimized)'),
        );
      });

      test('setPreferredProtocol persists custom protocol', () async {
        await prefs.setPreferredProtocol('OpenVPN (TCP)');
        expect(prefs.preferredProtocol, equals('OpenVPN (TCP)'));
      });

      test('reduceMotion is false by default', () {
        expect(prefs.reduceMotion, isFalse);
      });

      test('setReduceMotion persists true', () async {
        await prefs.setReduceMotion(true);
        expect(prefs.reduceMotion, isTrue);
      });

      test('emulatorMode is false by default', () {
        expect(prefs.emulatorMode, isFalse);
      });

      test('setEmulatorMode persists true', () async {
        await prefs.setEmulatorMode(true);
        expect(prefs.emulatorMode, isTrue);
      });
    });

    // ── Session History ──────────────────────────────────────────────────────

    group('Session History', () {
      test('getSessionHistoryJson returns empty list by default', () {
        expect(prefs.getSessionHistoryJson(), isEmpty);
      });

      test('saveSessionHistoryJson persists and retrieves sessions', () async {
        final sessions = [
          {
            'id': 'sess_1',
            'serverId': 'srv_1',
            'serverName': 'Japan',
            'startedAt': DateTime.now().toIso8601String(),
            'durationSeconds': 120,
            'bytesReceived': 1024,
            'bytesSent': 512,
            'status': 'completed',
          }
        ];
        await prefs.saveSessionHistoryJson(sessions);
        final retrieved = prefs.getSessionHistoryJson();
        expect(retrieved.length, equals(1));
        expect(retrieved.first['id'], equals('sess_1'));
      });

      test('saveSessionHistoryJson handles multiple sessions', () async {
        final sessions = List.generate(5, (i) => {
          'id': 'sess_$i',
          'serverId': 'srv_$i',
          'serverName': 'Country $i',
          'startedAt': DateTime.now().toIso8601String(),
          'durationSeconds': 60 + i,
          'bytesReceived': 1024 * (i + 1),
          'bytesSent': 512 * (i + 1),
          'status': 'completed',
        });
        await prefs.saveSessionHistoryJson(sessions);
        final retrieved = prefs.getSessionHistoryJson();
        expect(retrieved.length, equals(5));
      });

      test('clearHistory removes all sessions', () async {
        await prefs.saveSessionHistoryJson([
          {
            'id': 'sess_1',
            'serverId': 'srv_1',
            'serverName': 'Japan',
            'startedAt': DateTime.now().toIso8601String(),
            'durationSeconds': 60,
            'bytesReceived': 1024,
            'bytesSent': 512,
            'status': 'completed',
          }
        ]);
        await prefs.clearHistory();
        expect(prefs.getSessionHistoryJson(), isEmpty);
      });

      test('getSessionHistoryJson returns empty list for malformed JSON',
          () async {
        // Manually set corrupted JSON to simulate corruption scenario
        final sp = await SharedPreferences.getInstance();
        await sp.setString('sessions_history_json', 'NOT_VALID_JSON');
        // Should return empty list, not throw
        expect(prefs.getSessionHistoryJson(), isEmpty);
      });
    });

    // ── Selected Server Cache ────────────────────────────────────────────────

    group('Selected Server Cache', () {
      test('selectedServerJson is null by default', () {
        expect(prefs.selectedServerJson, isNull);
      });

      test('setSelectedServerJson persists json string', () async {
        await prefs.setSelectedServerJson('{"id":"srv_1"}');
        expect(prefs.selectedServerJson, equals('{"id":"srv_1"}'));
      });
    });
  });
}
