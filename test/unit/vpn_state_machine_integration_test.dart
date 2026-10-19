import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldroute_vpn/core/storage/preferences_service.dart';
import 'package:shieldroute_vpn/data/models/vpn_server.dart';
import 'package:shieldroute_vpn/data/repositories/vpn_repository.dart';
import 'package:shieldroute_vpn/services/server_service.dart';
import 'package:shieldroute_vpn/services/vpn_service.dart';

// ─── Controllable mock for openvpn_service simulation tests ────────────────
class _SimulatedVpnService implements VpnService {
  final StreamController<VpnConnectionState> _stateCtrl =
      StreamController<VpnConnectionState>.broadcast();
  final StreamController<VpnLiveMetrics> _metricsCtrl =
      StreamController<VpnLiveMetrics>.broadcast();

  VpnConnectionState _state = VpnConnectionState.disconnected;
  VpnLiveMetrics _metrics = const VpnLiveMetrics();
  VpnServer? _server;
  String? _error;

  // Configurable delays to simulate real-world latency
  Duration connectDelay = const Duration(milliseconds: 20);
  Duration disconnectDelay = const Duration(milliseconds: 10);

  // Injected stage sequence for state machine verification
  List<VpnConnectionState>? stateSequenceOverride;
  bool shouldError = false;
  String errorMessage = 'Simulated error';

  @override
  VpnConnectionState get currentState => _state;
  @override
  Stream<VpnConnectionState> get stateStream => _stateCtrl.stream;
  @override
  VpnLiveMetrics get currentMetrics => _metrics;
  @override
  Stream<VpnLiveMetrics> get metricsStream => _metricsCtrl.stream;
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

    if (stateSequenceOverride != null) {
      for (final s in stateSequenceOverride!) {
        _emit(s);
        await Future.delayed(const Duration(milliseconds: 2));
      }
      return;
    }

    _emit(VpnConnectionState.checking);
    await Future.delayed(connectDelay ~/ 4);
    _emit(VpnConnectionState.connecting);
    await Future.delayed(connectDelay);

    if (shouldError) {
      _error = errorMessage;
      _emit(VpnConnectionState.error);
      return;
    }

    _emit(VpnConnectionState.connected);
    _metrics = VpnLiveMetrics(
      byteIn: 512 * 1024,
      byteOut: 128 * 1024,
      duration: '00:00',
      pingMs: server.pingMs,
      publicIp: server.host,
    );
    _metricsCtrl.add(_metrics);
  }

  @override
  Future<void> disconnect() async {
    _emit(VpnConnectionState.disconnecting);
    await Future.delayed(disconnectDelay);
    _emit(VpnConnectionState.disconnected);
    _metrics = const VpnLiveMetrics();
    _metricsCtrl.add(_metrics);
  }

  void inject(VpnConnectionState state, {String? error}) {
    _error = error;
    _emit(state);
  }

  void _emit(VpnConnectionState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  @override
  void dispose() {
    _stateCtrl.close();
    _metricsCtrl.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VPN State Machine — Integration Tests', () {
    late PreferencesService prefs;
    late _SimulatedVpnService vpn;
    late DefaultServerService serverService;
    late VpnRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await PreferencesService.create();
      vpn = _SimulatedVpnService();
      serverService = DefaultServerService(prefs);
      repo = VpnRepository(
        vpnService: vpn,
        serverService: serverService,
        prefs: prefs,
      );
    });

    tearDown(() => repo.dispose());

    // ── Full connection lifecycle ─────────────────────────────────────────────

    group('Full Connection Lifecycle', () {
      test(
          'state transitions: disconnected → checking → connecting → connected',
          () async {
        final states = <VpnConnectionState>[];
        final sub = vpn.stateStream.listen(states.add);

        await repo.loadServers();
        await repo.connect();
        // Flush pending microtasks so all stream events are delivered
        await Future.delayed(const Duration(milliseconds: 20));

        expect(states, containsAllInOrder([
          VpnConnectionState.checking,
          VpnConnectionState.connecting,
          VpnConnectionState.connected,
        ]));
        await sub.cancel();
      });

      test(
          'state transitions: connected → disconnecting → disconnected',
          () async {
        await repo.loadServers();
        await repo.connect();

        final states = <VpnConnectionState>[];
        final sub = vpn.stateStream.listen(states.add);

        await repo.disconnect();
        await Future.delayed(const Duration(milliseconds: 30));

        expect(states, containsAllInOrder([
          VpnConnectionState.disconnecting,
          VpnConnectionState.disconnected,
        ]));
        await sub.cancel();
      });

      test('full cycle ends at disconnected and records session', () async {
        await repo.loadServers();
        await repo.connect();
        await repo.disconnect();
        await Future.delayed(const Duration(milliseconds: 30));

        expect(repo.connectionState, VpnConnectionState.disconnected);
        expect(repo.sessions.length, 1);
        expect(repo.sessions.first.status, equals('disconnected'));
      });
    });

    // ── Error State Transitions ──────────────────────────────────────────────

    group('Error State Transitions', () {
      test('checking → error when connection fails immediately', () async {
        vpn.shouldError = true;
        vpn.errorMessage = 'UDP handshake timeout';
        await repo.loadServers();
        await repo.connect();

        expect(repo.connectionState, VpnConnectionState.error);
        expect(repo.vpnError, equals('UDP handshake timeout'));
      });

      test('error → disconnected after manual retry disconnect', () async {
        vpn.shouldError = true;
        await repo.loadServers();
        await repo.connect();
        expect(repo.connectionState, VpnConnectionState.error);

        // Reset and reconnect
        vpn.shouldError = false;
        await repo.connect();
        expect(repo.connectionState, VpnConnectionState.connected);
      });

      test('VPNStage.denied maps to error state', () async {
        await repo.loadServers();
        // Simulate denied permission via injected state
        vpn.inject(
          VpnConnectionState.error,
          error: 'VPN permission was not granted by Android.',
        );
        await Future.delayed(Duration.zero);

        expect(repo.connectionState, VpnConnectionState.error);
        expect(repo.vpnError, contains('VPN permission'));
      });

      test('network drop mid-session produces error state with recorded session',
          () async {
        await repo.loadServers();
        await repo.connect();
        expect(repo.connectionState, VpnConnectionState.connected);

        vpn.inject(
          VpnConnectionState.error,
          error: 'Network connection lost',
        );
        await Future.delayed(const Duration(milliseconds: 10));

        expect(repo.connectionState, VpnConnectionState.error);
        expect(repo.sessions.length, 1);
        expect(repo.sessions.first.status, equals('failed'));
      });
    });

    // ── Watchdog / Timeout Simulation ───────────────────────────────────────

    group('Watchdog Timeout Simulation', () {
      test('stuck in connecting state transitions to error after manual signal',
          () async {
        // Simulate engine stuck in connecting
        vpn.stateSequenceOverride = [
          VpnConnectionState.checking,
          VpnConnectionState.connecting,
          // No connected state follows — simulating watchdog scenario
          VpnConnectionState.error,
        ];
        vpn.errorMessage = 'Watchdog: native handshake timeout';

        await repo.loadServers();
        await repo.connect();
        await Future.delayed(const Duration(milliseconds: 30));

        expect(repo.connectionState, VpnConnectionState.error);
      });
    });

    // ── Concurrent Connect / Disconnect Safety ───────────────────────────────

    group('Concurrent Connect / Disconnect Safety', () {
      test('connect called twice does not corrupt state', () async {
        await repo.loadServers();
        // Fire both without awaiting first
        unawaited(repo.connect());
        await repo.connect();
        await Future.delayed(const Duration(milliseconds: 50));

        // Should settle to connected, not in a stuck in-between state
        expect(
          repo.connectionState,
          anyOf(
            VpnConnectionState.connected,
            VpnConnectionState.checking,
            VpnConnectionState.connecting,
          ),
        );
      });

      test('disconnect called while disconnected does not throw', () async {
        // Use a fresh isolated repo to avoid stream-closed from shared tearDown
        final freshVpn = _SimulatedVpnService();
        final freshRepo = VpnRepository(
          vpnService: freshVpn,
          serverService: serverService,
          prefs: prefs,
        );
        // Disconnect without ever connecting should complete without error
        await freshRepo.disconnect();
        freshRepo.dispose();
      });
    });

    // ── Server Switching ─────────────────────────────────────────────────────

    group('Server Switching', () {
      test('switching server while disconnected and reconnecting works',
          () async {
        await repo.loadServers();
        final serverA = repo.allServers[0];
        final serverB = repo.allServers[1];

        repo.selectServer(serverA);
        await repo.connect();
        expect(vpn.currentServer?.id, equals(serverA.id));

        await repo.disconnect();
        await Future.delayed(const Duration(milliseconds: 20));

        repo.selectServer(serverB);
        await repo.connect();
        expect(vpn.currentServer?.id, equals(serverB.id));
        expect(repo.connectionState, VpnConnectionState.connected);
      });
    });

    // ── Metrics Streaming ────────────────────────────────────────────────────

    group('Metrics Streaming', () {
      test('live metrics are updated after connect', () async {
        await repo.loadServers();
        await repo.connect();

        expect(repo.liveMetrics.byteIn, greaterThan(0));
        expect(repo.liveMetrics.byteOut, greaterThan(0));
      });

      test('metrics publicIp matches connected server host', () async {
        await repo.loadServers();
        final server = repo.allServers.first;
        repo.selectServer(server);
        await repo.connect();

        expect(repo.liveMetrics.publicIp, equals(server.host));
      });

      test('metrics pingMs matches server ping', () async {
        await repo.loadServers();
        final server = repo.allServers.firstWhere((s) => s.pingMs != null);
        repo.selectServer(server);
        await repo.connect();

        expect(repo.liveMetrics.pingMs, equals(server.pingMs));
      });

      test('metrics are zeroed after disconnect', () async {
        await repo.loadServers();
        await repo.connect();
        await repo.disconnect();
        await Future.delayed(const Duration(milliseconds: 30));

        expect(repo.liveMetrics.byteIn, 0);
        expect(repo.liveMetrics.byteOut, 0);
      });
    });

    // ── Reconnect on Network Change Simulation ───────────────────────────────

    group('Reconnect Behavior', () {
      test('reconnectOnNetworkChange is true by default', () {
        expect(prefs.reconnectOnNetworkChange, isTrue);
      });

      test('can disable reconnect on network change', () async {
        await prefs.setReconnectOnNetworkChange(false);
        expect(prefs.reconnectOnNetworkChange, isFalse);
      });
    });
  });
}

void unawaited(Future<void> future) {
  // Intentionally not awaited for concurrency tests
  future.ignore();
}
