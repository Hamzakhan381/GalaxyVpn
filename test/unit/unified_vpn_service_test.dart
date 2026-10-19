import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldroute_vpn/core/storage/preferences_service.dart';
import 'package:shieldroute_vpn/data/models/vpn_server.dart';
import 'package:shieldroute_vpn/services/native_vpn_service.dart';
import 'package:shieldroute_vpn/services/unified_vpn_service.dart';
import 'package:shieldroute_vpn/services/vpn_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesService prefs;
  late UnifiedVpnService unifiedService;

  final testServer = VpnServer(
    id: 'test_node_01',
    country: 'United States',
    countryCode: 'US',
    city: 'Ashburn Fast Relay',
    host: '104.28.16.1',
    port: 443,
    protocol: 'NATIVE',
    pingMs: 24,
    speedBps: 850000000,
    score: 999999,
    ovpnConfig: 'client\ndev tun\nproto udp\nremote 104.28.16.1 443\n',
    lastChecked: DateTime.now(),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    prefs = PreferencesService(sp);
    unifiedService = UnifiedVpnService(prefs: prefs);
  });

  tearDown(() {
    unifiedService.dispose();
  });

  group('UnifiedVpnService & NativeVpnService Suite', () {
    test('initial state is disconnected', () {
      expect(unifiedService.currentState, equals(VpnConnectionState.disconnected));
      expect(unifiedService.currentMetrics.byteIn, equals(0));
      expect(unifiedService.currentMetrics.byteOut, equals(0));
    });

    test('initialize completes without error', () async {
      await unifiedService.initialize();
      expect(unifiedService.currentState, equals(VpnConnectionState.disconnected));
    });

    test('requestVpnPermission returns boolean', () async {
      final perm = await unifiedService.requestVpnPermission();
      expect(perm, isA<bool>());
    });

    test('connects via OpenVPN engine and transitions to connected', () async {
      final states = <VpnConnectionState>[];
      final sub = unifiedService.stateStream.listen(states.add);

      await unifiedService.connect(testServer);

      // Allow mock stream timer to tick
      await Future.delayed(const Duration(milliseconds: 1200));

      expect(unifiedService.currentServer, equals(testServer));
      expect(unifiedService.currentState, equals(VpnConnectionState.connected));

      await sub.cancel();
    });

    test('disconnect cleanly transitions back to disconnected', () async {
      await unifiedService.connect(testServer);
      await Future.delayed(const Duration(milliseconds: 1200));
      expect(unifiedService.currentState, equals(VpnConnectionState.connected));

      await unifiedService.disconnect();
      expect(unifiedService.currentState, equals(VpnConnectionState.disconnected));
    });

    test('NativeVpnService standalone connects and emits metrics', () async {
      final nativeService = NativeVpnService();
      await nativeService.initialize();

      await nativeService.connect(testServer);
      await Future.delayed(const Duration(milliseconds: 400));

      expect(nativeService.currentState, equals(VpnConnectionState.connected));

      await nativeService.disconnect();
      expect(nativeService.currentState, equals(VpnConnectionState.disconnected));
      nativeService.dispose();
    });
  });
}
