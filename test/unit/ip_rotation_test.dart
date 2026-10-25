import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_vpn/core/storage/preferences_service.dart';
import 'package:galaxy_vpn/data/datasources/platform/vpn_platform_data_source.dart';
import 'package:galaxy_vpn/data/repositories/server_repository_impl.dart';
import 'package:galaxy_vpn/domain/entities/vpn_connection_state.dart';
import 'package:galaxy_vpn/domain/entities/vpn_live_metrics.dart';
import 'package:galaxy_vpn/domain/entities/vpn_server.dart';
import 'package:galaxy_vpn/features/common/ip_rotation_card.dart';
import 'package:galaxy_vpn/presentation/controllers/vpn_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Connects successfully to whatever relay it is given.
class _WorkingVpn implements VpnPlatformDataSource {
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
    _server = server;
    _set(VpnConnectionState.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    _set(VpnConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {
    _set(VpnConnectionState.disconnecting);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    _server = null;
    _set(VpnConnectionState.disconnected);
  }

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
  String? get lastError => null;
  @override
  void dispose() {
    _states.close();
    _metrics.close();
  }
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 60));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesService prefs;
  late _WorkingVpn vpn;
  late VpnController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await PreferencesService.create();
    vpn = _WorkingVpn();
    controller = VpnController(
      vpnService: vpn,
      serverService: ServerRepositoryImpl(preferencesRepo: prefs),
      prefs: prefs,
    );
    await controller.loadServers();
  });

  tearDown(() => controller.dispose());

  Future<void> connected() async {
    await controller.connect();
    await _settle();
    expect(controller.connectionState, VpnConnectionState.connected);
  }

  test('rotation is off by default and schedules nothing', () async {
    expect(controller.ipRotationEnabled, isFalse);
    expect(controller.ipRotationMinutes, 5);
    await connected();
    expect(controller.nextRotationAt, isNull);
  });

  test('enabling while connected schedules the next change', () async {
    await connected();
    await controller.setIpRotationEnabled(true);

    final due = controller.nextRotationAt!.difference(DateTime.now());
    expect(due.inSeconds, inInclusiveRange(4 * 60 + 50, 5 * 60));

    await controller.setIpRotationMinutes(1);
    expect(
      controller.nextRotationAt!.difference(DateTime.now()).inSeconds,
      lessThanOrEqualTo(60),
    );
  });

  test('rotating moves to a different IP and reconnects', () async {
    await controller.setIpRotationEnabled(true);
    await connected();
    final before = vpn.currentServer!.host;

    await controller.rotateIpNow();
    await _settle();

    expect(controller.connectionState, VpnConnectionState.connected);
    expect(vpn.currentServer!.host, isNot(before));
    expect(controller.selectedServer!.host, vpn.currentServer!.host);
    expect(controller.connectedByRotation, isTrue);
    expect(controller.isRotatingIp, isFalse);
    expect(controller.nextRotationAt, isNotNull);
  });

  test('does not bounce back to recently used IPs', () async {
    await connected();
    final hosts = [vpn.currentServer!.host];
    for (var i = 0; i < 4; i++) {
      await controller.rotateIpNow();
      await _settle();
      hosts.add(vpn.currentServer!.host);
    }
    expect(hosts.toSet().length, hosts.length);
  });

  test('keep-same-country rotates within the current country', () async {
    await controller.setIpRotationSameCountry(true);
    final japan = controller.countryServers.firstWhere(
      (s) => s.countryCode == 'JP',
    );
    controller.selectServer(japan);
    await connected();

    for (var i = 0; i < 3; i++) {
      await controller.rotateIpNow();
      await _settle();
      expect(vpn.currentServer!.countryCode, 'JP');
    }
  });

  test('does nothing while disconnected, and disconnect cancels', () async {
    await controller.rotateIpNow();
    expect(vpn.currentServer, isNull);

    await controller.setIpRotationEnabled(true);
    await connected();
    expect(controller.nextRotationAt, isNotNull);

    await controller.disconnect();
    await _settle();
    expect(controller.nextRotationAt, isNull);
  });

  testWidgets('home card turns rotation on and off', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<VpnController>.value(
        value: controller,
        child: const MaterialApp(home: Scaffold(body: IpRotationCard())),
      ),
    );

    expect(find.text('AUTO IP ROTATION'), findsOneWidget);
    expect(find.textContaining('new IP every 5 minutes'), findsOneWidget);
    expect(find.text('Rotate now'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(controller.ipRotationEnabled, isTrue);
    expect(find.text('Starts once connected'), findsOneWidget);
    expect(find.text('Rotate now'), findsOneWidget);
    expect(find.text('Every 5 minutes'), findsOneWidget);
  });
}
