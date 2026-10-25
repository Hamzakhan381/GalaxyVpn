import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_vpn/core/storage/preferences_service.dart';
import 'package:galaxy_vpn/data/datasources/platform/vpn_platform_data_source.dart';
import 'package:galaxy_vpn/data/repositories/server_repository_impl.dart';
import 'package:galaxy_vpn/domain/entities/vpn_connection_state.dart';
import 'package:galaxy_vpn/domain/entities/vpn_live_metrics.dart';
import 'package:galaxy_vpn/domain/entities/vpn_server.dart';
import 'package:galaxy_vpn/presentation/controllers/vpn_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

VpnServer _relay(
  String id,
  String countryCode, {
  int? pingMs,
  int? speedBps,
  bool verified = false,
  bool available = true,
}) => VpnServer(
  id: id,
  country: countryCode,
  countryCode: countryCode,
  city: id,
  host: '10.0.0.1',
  port: 443,
  protocol: 'TCP',
  pingMs: pingMs,
  speedBps: speedBps,
  score: 0,
  ovpnConfig: 'client\n',
  isVerified: verified,
  isAvailable: available,
  lastChecked: DateTime(2026),
);

/// Every connection attempt fails, so the controller keeps failing over.
class _FailingVpn implements VpnPlatformDataSource {
  final attempts = <VpnServer>[];
  final _states = StreamController<VpnConnectionState>.broadcast();
  final _metrics = StreamController<VpnLiveMetrics>.broadcast();
  VpnConnectionState _state = VpnConnectionState.disconnected;
  VpnServer? _server;

  void _set(VpnConnectionState s) {
    _state = s;
    _states.add(s);
  }

  @override
  Future<void> connect(VpnServer server) async {
    attempts.add(server);
    _server = server;
    _set(VpnConnectionState.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    _set(VpnConnectionState.error);
  }

  @override
  Future<void> disconnect() async => _set(VpnConnectionState.disconnected);
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestVpnPermission() async => true;
  @override
  VpnConnectionState get currentState => _state;
  @override
  Stream<VpnConnectionState> get stateStream => _states.stream;
  @override
  VpnLiveMetrics get currentMetrics => const VpnLiveMetrics();
  @override
  Stream<VpnLiveMetrics> get metricsStream => _metrics.stream;
  @override
  VpnServer? get currentServer => _server;
  @override
  String? get lastError => 'unreachable';
  @override
  void dispose() {
    _states.close();
    _metrics.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesService prefs;
  late ServerRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await PreferencesService.create();
    repository = ServerRepositoryImpl(preferencesRepo: prefs);
  });

  group('bestPerCountry', () {
    test('keeps exactly one relay per country', () {
      final best = repository.bestPerCountry([
        _relay('jp1', 'JP', pingMs: 200),
        _relay('jp2', 'JP', pingMs: 180),
        _relay('de1', 'DE', pingMs: 150),
        _relay('us1', 'US', pingMs: 230),
      ]);
      expect(best.map((s) => s.id).toSet(), {'jp2', 'de1', 'us1'});
    });

    test('a relay verified from this device beats catalog figures', () {
      // VPN Gate publishes ping measured from Japan (1 ms there), which says
      // nothing about the user's network.
      final best = repository.bestPerCountry([
        _relay('catalog', 'JP', pingMs: 1, speedBps: 900000000),
        _relay('measured', 'JP', pingMs: 178, verified: true),
      ]);
      expect(best.single.id, 'measured');
    });

    test('an unreachable relay never wins its country', () {
      final best = repository.bestPerCountry([
        _relay('down', 'FR', pingMs: 20, verified: true, available: false),
        _relay('up', 'FR', pingMs: 160, verified: true),
      ]);
      expect(best.single.id, 'up');
    });
  });

  group('VpnController', () {
    test('lists one server per country from the bundled relays', () async {
      final controller = VpnController(
        vpnService: _FailingVpn(),
        serverService: repository,
        prefs: prefs,
      );
      addTearDown(controller.dispose);

      await controller.loadServers();

      final codes = controller.countryServers.map((s) => s.countryCode);
      expect(codes.length, codes.toSet().length);
      expect(codes, containsAll(['JP', 'KR', 'US']));
      expect(
        controller.allServers.length,
        greaterThan(controller.countryServers.length),
      );
    });

    test('failover stays in the country the user chose', () async {
      final vpn = _FailingVpn();
      final controller = VpnController(
        vpnService: vpn,
        serverService: repository,
        prefs: prefs,
      );
      addTearDown(controller.dispose);
      await controller.loadServers();
      final korea = controller.countryServers.firstWhere(
        (s) => s.countryCode == 'KR',
      );
      final koreanRelays = controller.allServers
          .where((s) => s.countryCode == 'KR')
          .length;

      controller.selectServer(korea);
      await controller.connect();
      // Each failover waits 800 ms for the failed tunnel to tear down.
      await Future<void>.delayed(
        Duration(milliseconds: 900 * (koreanRelays + 1)),
      );

      expect(vpn.attempts.length, koreanRelays);
      expect(vpn.attempts.map((s) => s.countryCode).toSet(), {'KR'});
    });
  });
}
