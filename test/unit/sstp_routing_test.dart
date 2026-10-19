import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shieldroute_vpn/data/datasources/platform/native_vpn_platform_data_source.dart';
import 'package:shieldroute_vpn/data/datasources/platform/openvpn_platform_data_source.dart';
import 'package:shieldroute_vpn/data/datasources/platform/unified_vpn_platform_data_source.dart';
import 'package:shieldroute_vpn/data/datasources/remote/server_remote_data_source.dart';
import 'package:shieldroute_vpn/domain/entities/vpn_connection_state.dart';
import 'package:shieldroute_vpn/domain/entities/vpn_server.dart';
import 'package:shieldroute_vpn/domain/repositories/preferences_repository.dart';

/// SSTP engine double: succeeds, or fails with a native error [failCode].
class _FakeSstp extends NativeVpnPlatformDataSource {
  _FakeSstp({this.failCode});

  final String? failCode;
  final _states = StreamController<VpnConnectionState>.broadcast();
  int connectCalls = 0;
  String? _code;

  @override
  Stream<VpnConnectionState> get stateStream => _states.stream;

  @override
  String? get lastErrorCode => _code;

  @override
  String? get lastError => _code == null ? null : 'SSTP failed ($_code)';

  @override
  Future<void> initialize() async {}

  @override
  Future<void> connect(VpnServer server) async {
    connectCalls++;
    _states.add(VpnConnectionState.connecting);
    if (failCode == null) {
      _states.add(VpnConnectionState.connected);
    } else {
      _code = failCode;
      _states.add(VpnConnectionState.error);
    }
  }

  @override
  Future<void> disconnect() async {}
}

class _FakeOpenVpn extends OpenVpnPlatformDataSource {
  final _states = StreamController<VpnConnectionState>.broadcast();
  int connectCalls = 0;

  @override
  Stream<VpnConnectionState> get stateStream => _states.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> connect(VpnServer server) async {
    connectCalls++;
    _states.add(VpnConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {}
}

class _NoPrefs implements PreferencesRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  final relay = VpnServer(
    id: 'vpngate_219.100.37.98_443_tcp',
    country: 'Japan',
    countryCode: 'JP',
    city: 'public-vpn-108',
    host: '219.100.37.98',
    port: 443,
    protocol: 'TCP',
    score: 1,
    ovpnConfig: 'client\ndev tun\nproto tcp\nremote 219.100.37.98 443\n',
    sstpHostname: ServerRemoteDataSource.vpnGateSstpHostname('public-vpn-108'),
    lastChecked: DateTime(2026),
  );

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  UnifiedVpnPlatformDataSource build(
    _FakeSstp sstp,
    _FakeOpenVpn openVpn, {
    bool sstpSupported = true,
  }) => UnifiedVpnPlatformDataSource(
    prefs: _NoPrefs(),
    sstpSupported: sstpSupported,
    nativeVpnSource: sstp,
    openVpnSource: openVpn,
  );

  test('VPN Gate hostnames map to their opengw.net SSTP endpoint', () {
    expect(relay.sstpHostname, 'public-vpn-108.opengw.net');
    expect(relay.sstpPort, 443);
    expect(ServerRemoteDataSource.vpnGateSstpHostname('219.100.37.98'), isNull);
    expect(relay.copyWith(protocol: 'UDP', port: 1194).sstpPort, 443);
  });

  test('connects over SSTP first when the relay supports it', () async {
    final sstp = _FakeSstp();
    final openVpn = _FakeOpenVpn();
    final unified = build(sstp, openVpn);

    await unified.connect(relay);
    await settle();

    expect(sstp.connectCalls, 1);
    expect(openVpn.connectCalls, 0);
    expect(unified.currentState, VpnConnectionState.connected);
  });

  test('falls back to OpenVPN when the SSTP handshake fails', () async {
    final sstp = _FakeSstp(failCode: 'tls');
    final openVpn = _FakeOpenVpn();
    final unified = build(sstp, openVpn);
    final states = <VpnConnectionState>[];
    unified.stateStream.listen(states.add);

    await unified.connect(relay);
    await settle();
    await settle();

    expect(openVpn.connectCalls, 1);
    expect(states, isNot(contains(VpnConnectionState.error)));
    expect(unified.currentState, VpnConnectionState.connected);
  });

  test('does not retry an unreachable TCP relay over OpenVPN', () async {
    final sstp = _FakeSstp(failCode: 'unreachable');
    final openVpn = _FakeOpenVpn();
    final unified = build(sstp, openVpn);

    await unified.connect(relay);
    await settle();

    expect(openVpn.connectCalls, 0);
    expect(unified.currentState, VpnConnectionState.error);
  });

  test('uses OpenVPN directly where SSTP is unavailable', () async {
    final sstp = _FakeSstp();
    final openVpn = _FakeOpenVpn();
    final unified = build(sstp, openVpn, sstpSupported: false);

    await unified.connect(relay);
    await settle();

    expect(sstp.connectCalls, 0);
    expect(openVpn.connectCalls, 1);
  });
}
