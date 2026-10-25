import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_vpn/data/datasources/remote/relay_probe.dart';
import 'package:galaxy_vpn/data/datasources/remote/server_remote_data_source.dart';
import 'package:galaxy_vpn/domain/entities/vpn_server.dart';

/// P_CONTROL_HARD_RESET_SERVER_V2 with one ack and packet id 0.
final List<int> _serverReset = [
  8 << 3,
  ...List.filled(8, 1),
  1,
  0,
  0,
  0,
  0,
  ...List.filled(8, 2),
  0,
  0,
  0,
  0,
];

/// TCP OpenVPN server that answers the client hard reset.
Future<ServerSocket> _fakeTcpOpenVpn() async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((client) {
    client.listen((data) {
      if (data.length >= 3 && data[2] >> 3 == 7) {
        client.add([0, _serverReset.length, ..._serverReset]);
      }
    }, onError: (_) {});
  });
  return server;
}

/// TCP server that drops the connection as soon as data arrives, the way a
/// firewall resets OpenVPN.
Future<ServerSocket> _fakeResettingTcp() async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((client) {
    client.listen((_) => client.destroy(), onError: (_) {});
  });
  return server;
}

/// UDP OpenVPN server that answers the client hard reset.
Future<RawDatagramSocket> _fakeUdpOpenVpn() async {
  final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
  socket.listen((event) {
    if (event != RawSocketEvent.read) return;
    final datagram = socket.receive();
    if (datagram != null && datagram.data[0] >> 3 == 7) {
      socket.send(_serverReset, datagram.address, datagram.port);
    }
  });
  return socket;
}

/// A loopback UDP port with nothing listening on it.
Future<int> _silentUdpPort() async {
  final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  socket.close();
  return port;
}

const _timeout = Duration(milliseconds: 800);

void main() {
  group('OpenVpnRemote', () {
    test('inherits the profile protocol, or reads it per remote', () {
      expect(
        OpenVpnRemote.parseAll('client\nproto tcp\nremote 1.2.3.4 1443\n'),
        [const OpenVpnRemote(host: '1.2.3.4', port: 1443, udp: false)],
      );
      expect(
        OpenVpnRemote.parseAll(
          'client\nremote de20.vpnbook.com 53 udp\n'
          'remote de20.vpnbook.com 443 tcp-client\n',
        ),
        [
          const OpenVpnRemote(host: 'de20.vpnbook.com', port: 53, udp: true),
          const OpenVpnRemote(host: 'de20.vpnbook.com', port: 443, udp: false),
        ],
      );
    });

    test('preferFirst moves the working endpoint ahead of the others', () {
      const config =
          'client\ndev tun\nremote h 53 udp\nremote h 443 tcp-client\nnobind';
      final reordered = OpenVpnRemote.preferFirst(
        config,
        const OpenVpnRemote(host: 'h', port: 443, udp: false),
      );
      expect(
        reordered,
        'client\ndev tun\nremote h 443 tcp-client\nremote h 53 udp\nnobind',
      );
      expect(
        OpenVpnRemote.preferFirst(
          config,
          const OpenVpnRemote(host: 'h', port: 53, udp: true),
        ),
        config,
      );
    });
  });

  group('RelayProbe', () {
    test('OpenVPN over TCP succeeds only when the server answers', () async {
      final good = await _fakeTcpOpenVpn();
      final reset = await _fakeResettingTcp();
      addTearDown(good.close);
      addTearDown(reset.close);

      final ok = await RelayProbe.openVpn(
        OpenVpnRemote(host: '127.0.0.1', port: good.port, udp: false),
        timeout: _timeout,
      );
      final blocked = await RelayProbe.openVpn(
        OpenVpnRemote(host: '127.0.0.1', port: reset.port, udp: false),
        timeout: _timeout,
      );

      expect(ok, isNotNull);
      expect(blocked, isNull);
    });

    test('OpenVPN over UDP succeeds only when the server answers', () async {
      final good = await _fakeUdpOpenVpn();
      addTearDown(good.close);

      final ok = await RelayProbe.openVpn(
        OpenVpnRemote(host: '127.0.0.1', port: good.port, udp: true),
        timeout: _timeout,
      );
      final silent = await RelayProbe.openVpn(
        OpenVpnRemote(
          host: '127.0.0.1',
          port: await _silentUdpPort(),
          udp: true,
        ),
        timeout: _timeout,
      );

      expect(ok, isNotNull);
      expect(silent, isNull);
    });

    test('SSTP fails against a server that does not speak TLS', () async {
      final plain = await _fakeResettingTcp();
      addTearDown(plain.close);

      final result = await RelayProbe.sstp(
        address: '127.0.0.1',
        port: plain.port,
        hostname: 'relay.opengw.net',
        timeout: _timeout,
      );
      expect(result, isNull);
    });

    test('flags profiles whose handshake needs a tls-auth key', () {
      expect(RelayProbe.needsTlsAuthKey('client\n<tls-auth>\nkey\n'), isTrue);
      expect(RelayProbe.needsTlsAuthKey('client\ntls-crypt ta.key\n'), isTrue);
      expect(RelayProbe.needsTlsAuthKey('client\nremote h 1194\n'), isFalse);
    });
  });

  group('ServerRemoteDataSource.probeServer', () {
    test('falls back to the TCP endpoint and puts it first', () async {
      final tcp = await _fakeTcpOpenVpn();
      addTearDown(tcp.close);
      final udpPort = await _silentUdpPort();
      final server = VpnServer(
        id: 'vpnbook_test',
        country: 'Germany',
        countryCode: 'DE',
        city: 'de20.vpnbook.com',
        host: '127.0.0.1',
        port: udpPort,
        protocol: 'UDP',
        score: 0,
        ovpnConfig:
            'client\ndev tun\n'
            'remote 127.0.0.1 $udpPort udp\n'
            'remote 127.0.0.1 ${tcp.port} tcp-client\n',
        username: 'vpnbook',
        password: 'secret',
        lastChecked: DateTime(2026),
      );

      final probed = await ServerRemoteDataSource().probeServer(
        server,
        timeout: _timeout,
      );

      expect(probed.isAvailable, isTrue);
      expect(probed.isVerified, isTrue);
      expect(probed.protocol, 'TCP');
      expect(probed.port, tcp.port);
      expect(
        OpenVpnRemote.parseAll(probed.ovpnConfig).first,
        OpenVpnRemote(host: '127.0.0.1', port: tcp.port, udp: false),
      );
    });

    test('marks a relay unavailable when no endpoint answers', () async {
      final reset = await _fakeResettingTcp();
      addTearDown(reset.close);
      final server = VpnServer(
        id: 'vpngate_blocked',
        country: 'Japan',
        countryCode: 'JP',
        city: 'public-vpn-1',
        host: '127.0.0.1',
        port: reset.port,
        protocol: 'TCP',
        score: 1,
        ovpnConfig: 'client\nproto tcp\nremote 127.0.0.1 ${reset.port}\n',
        lastChecked: DateTime(2026),
      );

      final probed = await ServerRemoteDataSource().probeServer(
        server,
        timeout: _timeout,
      );

      expect(probed.isAvailable, isFalse);
      expect(probed.isVerified, isFalse);
    });
  });
}
