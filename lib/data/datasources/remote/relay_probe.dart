import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// One `remote` endpoint of an OpenVPN profile.
class OpenVpnRemote {
  final String host;
  final int port;
  final bool udp;

  const OpenVpnRemote({
    required this.host,
    required this.port,
    required this.udp,
  });

  static final RegExp _remoteLine = RegExp(
    r'^\s*remote\s+(\S+)\s+(\d+)(?:\s+(\S+))?',
    multiLine: true,
  );

  /// The profile's endpoints in the order the engine tries them. A remote
  /// without its own protocol inherits the profile's `proto` (UDP by default).
  static List<OpenVpnRemote> parseAll(String config) {
    final defaultUdp = !RegExp(
      r'^\s*proto\s+tcp',
      multiLine: true,
    ).hasMatch(config);
    return [
      for (final m in _remoteLine.allMatches(config))
        OpenVpnRemote(
          host: m.group(1)!,
          port: int.parse(m.group(2)!),
          udp: m.group(3) == null
              ? defaultUdp
              : m.group(3)!.toLowerCase().startsWith('udp'),
        ),
    ];
  }

  /// Rewrites [config] so the engine tries [preferred] before its other
  /// remotes, e.g. TCP 443 first on a network that drops UDP 53.
  static String preferFirst(String config, OpenVpnRemote preferred) {
    final lines = config.split('\n');
    // One `remote` line per parsed endpoint, in the same order.
    final remoteLines = [
      for (var i = 0; i < lines.length; i++)
        if (_remoteLine.hasMatch(lines[i])) i,
    ];
    final index = parseAll(config).indexOf(preferred);
    if (index <= 0) return config;
    lines.insert(remoteLines.first, lines.removeAt(remoteLines[index]));
    return lines.join('\n');
  }

  @override
  bool operator ==(Object other) =>
      other is OpenVpnRemote &&
      other.host == host &&
      other.port == port &&
      other.udp == udp;

  @override
  int get hashCode => Object.hash(host, port, udp);

  @override
  String toString() => '$host:$port/${udp ? 'udp' : 'tcp'}';
}

/// On-device checks that speak each relay's real protocol, so a relay only
/// counts as working when this network lets its handshake through, not merely
/// when a TCP port accepts the connection. Some networks (including Pakistan's)
/// accept the TCP connection and then reset it the moment OpenVPN starts.
///
/// No credentials are sent: each probe stops at the server's first handshake
/// reply. Every probe returns the measured round trip in ms, or null.
class RelayProbe {
  RelayProbe._();

  static const String _sstpPath =
      '/sra_{BA195980-CD49-458b-9E23-C84EE0ADCD75}/';
  static const int _hardResetClientV2 = 7;
  static const int _hardResetServerV2 = 8;
  static final Random _random = Random.secure();

  /// TLS-verified SSTP call-connect, mirroring the native tunnel: TCP to the
  /// relay's [address], TLS checked against [hostname], then expect HTTP 200.
  /// Returns the TCP connect time.
  static Future<int?> sstp({
    required String address,
    required int port,
    required String hostname,
    Duration timeout = const Duration(milliseconds: 2500),
  }) async {
    Socket? raw;
    SecureSocket? secure;
    try {
      final stopwatch = Stopwatch()..start();
      raw = await Socket.connect(address, port, timeout: timeout);
      final rtt = stopwatch.elapsedMilliseconds;
      secure = await SecureSocket.secure(raw, host: hostname).timeout(timeout);
      secure.write(
        'SSTP_DUPLEX_POST $_sstpPath HTTP/1.1\r\n'
        'Host: $hostname\r\n'
        'Content-Length: 18446744073709551615\r\n'
        'SstpCorrelationID: {${_guid()}}\r\n\r\n',
      );
      final head = await secure.first.timeout(timeout);
      final ok = latin1
          .decode(head, allowInvalid: true)
          .startsWith('HTTP/1.1 200');
      return ok ? max(rtt, 1) : null;
    } catch (_) {
      return null;
    } finally {
      secure?.destroy();
      raw?.destroy();
    }
  }

  /// Whether OpenVPN handshakes need a shared HMAC key this probe lacks.
  static bool needsTlsAuthKey(String config) => RegExp(
    r'^\s*(<tls-auth>|<tls-crypt|tls-auth\s|tls-crypt\s)',
    multiLine: true,
  ).hasMatch(config);

  /// Sends OpenVPN's client hard reset and waits for the server's reply.
  static Future<int?> openVpn(
    OpenVpnRemote remote, {
    Duration timeout = const Duration(milliseconds: 2500),
  }) =>
      remote.udp ? _openVpnUdp(remote, timeout) : _openVpnTcp(remote, timeout);

  static Future<int?> _openVpnTcp(
    OpenVpnRemote remote,
    Duration timeout,
  ) async {
    Socket? socket;
    try {
      socket = await Socket.connect(remote.host, remote.port, timeout: timeout);
      final packet = _hardReset();
      final stopwatch = Stopwatch()..start();
      socket.add([packet.length >> 8, packet.length & 0xff, ...packet]);
      final reply = BytesBuilder();
      await for (final chunk in socket.timeout(timeout)) {
        reply.add(chunk);
        if (reply.length >= 3) break;
      }
      final bytes = reply.toBytes();
      // [2-byte length][opcode << 3 | key id]...
      return bytes.length >= 3 && bytes[2] >> 3 == _hardResetServerV2
          ? max(stopwatch.elapsedMilliseconds, 1)
          : null;
    } catch (_) {
      return null;
    } finally {
      socket?.destroy();
    }
  }

  static Future<int?> _openVpnUdp(
    OpenVpnRemote remote,
    Duration timeout,
  ) async {
    RawDatagramSocket? socket;
    try {
      final addresses = await InternetAddress.lookup(remote.host)
          .timeout(timeout);
      final target = addresses.firstWhere(
        (a) => a.type == InternetAddressType.IPv4,
        orElse: () => addresses.first,
      );
      socket = await RawDatagramSocket.bind(
        target.type == InternetAddressType.IPv6
            ? InternetAddress.anyIPv6
            : InternetAddress.anyIPv4,
        0,
      );
      final reply = Completer<int>();
      final stopwatch = Stopwatch();
      final bound = socket;
      bound.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = bound.receive();
        if (datagram == null || datagram.data.isEmpty) return;
        if (datagram.data[0] >> 3 == _hardResetServerV2 && !reply.isCompleted) {
          reply.complete(max(stopwatch.elapsedMilliseconds, 1));
        }
      }, onError: (_) {});
      // UDP may drop a datagram, so resend once before giving up.
      final packet = _hardReset();
      for (var attempt = 0; attempt < 2 && !reply.isCompleted; attempt++) {
        stopwatch
          ..reset()
          ..start();
        bound.send(packet, target, remote.port);
        await Future.any([reply.future, Future<void>.delayed(timeout ~/ 2)]);
      }
      return reply.isCompleted ? await reply.future : null;
    } catch (_) {
      return null;
    } finally {
      socket?.close();
    }
  }

  /// P_CONTROL_HARD_RESET_CLIENT_V2: opcode, session id, no acks, packet id 0.
  static Uint8List _hardReset() => Uint8List.fromList([
    _hardResetClientV2 << 3,
    for (var i = 0; i < 8; i++) _random.nextInt(256),
    0,
    0,
    0,
    0,
    0,
  ]);

  static String _guid() {
    String hex(int bytes) => [
      for (var i = 0; i < bytes; i++)
        _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
    return '${hex(4)}-${hex(2)}-${hex(2)}-${hex(2)}-${hex(6)}'.toUpperCase();
  }
}
