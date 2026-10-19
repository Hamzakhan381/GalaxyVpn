import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldroute_vpn/core/errors/vpn_exception.dart';
import 'package:shieldroute_vpn/core/storage/preferences_service.dart';
import 'package:shieldroute_vpn/data/models/vpn_server.dart';
import 'package:shieldroute_vpn/data/models/vpn_session.dart';
import 'package:shieldroute_vpn/data/repositories/vpn_repository.dart';
import 'package:shieldroute_vpn/services/server_service.dart';
import 'package:shieldroute_vpn/services/vpn_service.dart';

class MockVpnService implements VpnService {
  final StreamController<VpnConnectionState> _stateController =
      StreamController<VpnConnectionState>.broadcast();
  final StreamController<VpnLiveMetrics> _metricsController =
      StreamController<VpnLiveMetrics>.broadcast();

  VpnConnectionState _state = VpnConnectionState.disconnected;
  VpnLiveMetrics _metrics = const VpnLiveMetrics();
  VpnServer? _server;
  String? _error;

  @override
  VpnConnectionState get currentState => _state;

  @override
  Stream<VpnConnectionState> get stateStream => _stateController.stream;

  @override
  VpnLiveMetrics get currentMetrics => _metrics;

  @override
  Stream<VpnLiveMetrics> get metricsStream => _metricsController.stream;

  @override
  VpnServer? get currentServer => _server;

  @override
  String? get lastError => _error;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestVpnPermission() async => true;

  @override
  Future<void> connect(VpnServer server) async {
    _server = server;
    _error = null;
    _setState(VpnConnectionState.connecting);
    await Future.delayed(const Duration(milliseconds: 10));
    _setState(VpnConnectionState.connected);
    _metrics = VpnLiveMetrics(
      byteIn: 1024 * 500,
      byteOut: 1024 * 200,
      duration: '01:30',
      pingMs: server.pingMs,
      publicIp: server.host,
    );
    _metricsController.add(_metrics);
  }

  @override
  Future<void> disconnect() async {
    _setState(VpnConnectionState.disconnecting);
    await Future.delayed(const Duration(milliseconds: 10));
    _setState(VpnConnectionState.disconnected);
  }

  void simulateError(String err) {
    _error = err;
    _setState(VpnConnectionState.error);
  }

  void _setState(VpnConnectionState s) {
    _state = s;
    _stateController.add(s);
  }

  @override
  void dispose() {
    _stateController.close();
    _metricsController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VPN State Machine and Session History Tests', () {
    late PreferencesService prefs;
    late MockVpnService mockVpn;
    late DefaultServerService serverService;
    late VpnRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await PreferencesService.create();
      mockVpn = MockVpnService();
      serverService = DefaultServerService(prefs);
      repository = VpnRepository(
        vpnService: mockVpn,
        serverService: serverService,
        prefs: prefs,
      );
    });

    tearDown(() {
      repository.dispose();
    });

    test('Initial connection state is disconnected', () {
      expect(repository.connectionState, equals(VpnConnectionState.disconnected));
      expect(repository.sessions, isEmpty);
    });

    test('Connecting transitions through connecting to connected state', () async {
      await repository.loadServers();
      expect(repository.allServers, isNotEmpty);

      await repository.connect();
      expect(repository.connectionState, equals(VpnConnectionState.connected));
      expect(mockVpn.currentServer, isNotNull);
      expect(repository.liveMetrics.byteIn, greaterThan(0));
    });

    test('Disconnecting records session history accurately', () async {
      await repository.loadServers();
      await repository.connect();
      expect(repository.connectionState, equals(VpnConnectionState.connected));

      await repository.disconnect();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(repository.connectionState, equals(VpnConnectionState.disconnected));

      // Session record should be stored in repository and prefs
      expect(repository.sessions.length, equals(1));
      final recorded = repository.sessions.first;
      expect(recorded.status, equals('disconnected'));
      expect(recorded.durationSeconds, greaterThanOrEqualTo(0));
      expect(recorded.bytesReceived, greaterThan(0));
      expect(repository.totalSessionsCount, equals(1));
    });

    test('VpnSession model formats duration and data metrics cleanly', () {
      final session = VpnSession(
        id: 'sess_1',
        serverId: 'srv_1',
        serverName: 'Japan Relay',
        startedAt: DateTime.now().subtract(const Duration(minutes: 5, seconds: 20)),
        endedAt: DateTime.now(),
        durationSeconds: 320,
        bytesReceived: 1024 * 1024 * 25, // 25 MB
        bytesSent: 1024 * 1024 * 5, // 5 MB
        status: 'completed',
      );

      expect(session.formattedDuration, equals('05:20'));
      expect(session.formattedDataTransferred, equals('30.00 MB'));
    });

    test('Error mapping produces accurate user messages (PHASE 18 requirement)', () {
      final offlineErr = VpnException.fromType(VpnErrorType.noNetwork);
      expect(offlineErr.userMessage, equals("You're offline"));

      final permErr = VpnException.fromType(VpnErrorType.permissionDenied);
      expect(permErr.userMessage, equals("VPN permission was not granted."));

      final unavailErr = VpnException.fromType(VpnErrorType.serverUnavailable);
      expect(unavailErr.userMessage, equals("This server is currently unavailable."));

      final timeoutErr = VpnException.fromType(VpnErrorType.timeout);
      expect(timeoutErr.userMessage, equals("The server took too long to respond."));

      final configErr = VpnException.fromType(VpnErrorType.invalidConfig);
      expect(configErr.userMessage, equals("This server configuration is unavailable."));

      final authErr = VpnException.fromType(VpnErrorType.authFailure);
      expect(authErr.userMessage, equals("The server rejected the connection credentials."));

      final unknownErr = VpnException.fromType(VpnErrorType.unknown);
      expect(unknownErr.userMessage, equals("We couldn't establish the VPN connection."));
    });
  });
}
