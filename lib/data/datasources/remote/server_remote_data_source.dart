import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_constants.dart';
import '../../../domain/entities/vpn_server.dart';
import 'relay_probe.dart';
import 'vpnbook_data_source.dart';

/// Remote data source for fetching public VPN relays, parsing CSV, and measuring network latency
class ServerRemoteDataSource {
  final http.Client _httpClient;
  final VpnBookDataSource _vpnBook;

  ServerRemoteDataSource([http.Client? client, VpnBookDataSource? vpnBook])
    : _httpClient = client ?? http.Client(),
      _vpnBook = vpnBook ?? VpnBookDataSource(client: client);

  /// Multi-source relay fetcher with resilient mirror failover & custom API support
  Future<List<VpnServer>> fetchRelays({
    String? customUrl,
    String? customApiKey,
  }) async {
    // 1. Try Custom API endpoint and API Key if user configured one
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      try {
        final uri = Uri.parse(customUrl.trim());
        if (uri.scheme != 'https' || uri.host.isEmpty) {
          throw const FormatException(
            'Custom relay API must use a valid HTTPS URL.',
          );
        }
        final headers = <String, String>{};
        if (customApiKey != null && customApiKey.trim().isNotEmpty) {
          headers['Authorization'] = 'Bearer ${customApiKey.trim()}';
          headers['X-API-Key'] = customApiKey.trim();
        }
        final response = await _httpClient
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final servers = parseVpnGateCsv(response.body);
          if (servers.isNotEmpty) return servers;
          final jsonServers = parseVpnGateJson(response.body);
          if (jsonServers.isNotEmpty) return jsonServers;
        }
      } catch (e) {
        debugPrint('Custom API endpoint ($customUrl) failed: $e');
      }
    }

    // VPN Gate exposes the live catalog on two official HTTPS hosts. Merge
    // both responses so a partial list from one host does not hide countries
    // published by the other. VPNBook adds Europe and North America. Each
    // source can fail independently.
    final catalogs = await Future.wait([
      _fetchVpnGateCatalog(AppConstants.vpnGateApiUrl),
      _fetchVpnGateCatalog(AppConstants.vpnGateApiMirrorUrl),
      _vpnBook.fetchServers(),
    ]);
    final serversById = <String, VpnServer>{};
    for (final catalog in catalogs) {
      for (final server in catalog) {
        serversById.putIfAbsent(server.id, () => server);
      }
    }
    return serversById.values.toList(growable: false);
  }

  Future<List<VpnServer>> _fetchVpnGateCatalog(String endpoint) async {
    try {
      final response = await _httpClient
          .get(Uri.parse(endpoint), headers: const {'Accept': '*/*'})
          // The catalog is ~1 MB; slow mobile links need more than 15 s.
          .timeout(const Duration(seconds: 35));
      if (response.statusCode != 200 || response.body.isEmpty) return [];

      final csvServers = parseVpnGateCsv(response.body);
      if (csvServers.isNotEmpty) return csvServers;
      return parseVpnGateJson(response.body);
    } catch (e) {
      debugPrint('VPN Gate catalog unavailable at $endpoint: $e');
      return [];
    }
  }

  /// VPN Gate sorts by score, so rare countries sit near the end of the list.
  static const int _maxCatalogRows = 300;

  List<VpnServer> parseVpnGateJson(String jsonData) {
    final List<VpnServer> list = [];
    try {
      final decoded = json.decode(jsonData);
      final List items = decoded is List
          ? (decoded.isNotEmpty &&
                    decoded.first is Map &&
                    decoded.first['servers'] != null
                ? decoded.first['servers']
                : decoded)
          : [];

      for (final item in items) {
        if (item is! Map) continue;
        final ip = item['ip']?.toString() ?? '';
        final hostName = item['hostname']?.toString() ?? ip;
        final countryLong = item['countrylong']?.toString() ?? 'Global Relay';
        final countryShort = item['countryshort']?.toString() ?? 'GL';
        final base64Config =
            item['openvpn_configdata_base64']?.toString() ?? '';
        final score = int.tryParse(item['score']?.toString() ?? '0') ?? 0;
        final ping = int.tryParse(item['ping']?.toString() ?? '0');
        final speed = int.tryParse(item['speed']?.toString() ?? '0') ?? 0;

        if (ip.isEmpty || base64Config.isEmpty) continue;

        String ovpnDecoded = '';
        try {
          ovpnDecoded = utf8.decode(base64.decode(base64Config));
        } catch (_) {
          ovpnDecoded = base64Config;
        }

        String proto = 'UDP';
        int port = 1194;
        final protoMatch = RegExp(
          r'^\s*proto\s+([a-zA-Z0-9]+)',
          multiLine: true,
        ).firstMatch(ovpnDecoded);
        if (protoMatch != null) {
          proto = protoMatch.group(1)!.toLowerCase().startsWith('tcp')
              ? 'TCP'
              : 'UDP';
        }
        final remoteMatch = RegExp(
          r'^\s*remote\s+[^\s]+\s+(\d+)',
          multiLine: true,
        ).firstMatch(ovpnDecoded);
        if (remoteMatch != null) {
          port = int.tryParse(remoteMatch.group(1)!) ?? 1194;
        }

        list.add(
          VpnServer(
            id: 'vpngate_${ip}_${port}_${proto.toLowerCase()}',
            country: countryLong.isNotEmpty ? countryLong : 'Global Relay',
            countryCode: countryShort.toUpperCase(),
            city: hostName,
            host: ip,
            port: port,
            protocol: proto,
            pingMs: ping != null && ping > 0 ? ping : null,
            speedBps: speed > 0 ? speed : null,
            loadPercent: null,
            score: score,
            ovpnConfig: ovpnDecoded,
            sstpHostname: vpnGateSstpHostname(hostName),
            lastChecked: DateTime.now(),
          ),
        );
        if (list.length >= _maxCatalogRows) break;
      }
    } catch (_) {}
    return list;
  }

  /// VPN Gate relays answer SSTP as `<hostname>.opengw.net`, with a valid
  /// wildcard certificate for that domain.
  static String? vpnGateSstpHostname(String hostName) {
    final name = hostName.trim().toLowerCase();
    if (name.isEmpty || !RegExp(r'^[a-z0-9-]+$').hasMatch(name)) return null;
    return '$name.opengw.net';
  }

  List<VpnServer> parseVpnGateCsv(String csvData) =>
      parseVpnGateCsvData(csvData);

  /// Parses VPN Gate's CSV catalog format (also used for the bundled
  /// snapshot of official relays).
  static List<VpnServer> parseVpnGateCsvData(String csvData) {
    final List<VpnServer> list = [];
    final lines = const LineSplitter().convert(csvData);

    for (final line in lines) {
      if (line.startsWith('*') || line.startsWith('#') || line.trim().isEmpty) {
        continue;
      }
      final parts = line.split(',');
      if (parts.length < 15) continue;

      try {
        final hostName = parts[0];
        final ip = parts[1];
        final score = int.tryParse(parts[2]) ?? 0;
        final ping = int.tryParse(parts[3]);
        final speed = int.tryParse(parts[4]) ?? 0;
        final countryLong = parts[5];
        final countryShort = parts[6];
        final base64Config = parts[14];

        if (base64Config.isEmpty) continue;

        String ovpnDecoded = '';
        try {
          ovpnDecoded = utf8.decode(base64.decode(base64Config));
        } catch (_) {
          ovpnDecoded = base64Config;
        }

        // Dynamically detect actual protocol and port from configuration
        String proto = 'UDP';
        int port = 1194;
        final protoMatch = RegExp(
          r'^\s*proto\s+([a-zA-Z0-9]+)',
          multiLine: true,
        ).firstMatch(ovpnDecoded);
        if (protoMatch != null) {
          proto = protoMatch.group(1)!.toLowerCase().startsWith('tcp')
              ? 'TCP'
              : 'UDP';
        }
        final remoteMatch = RegExp(
          r'^\s*remote\s+[^\s]+\s+(\d+)',
          multiLine: true,
        ).firstMatch(ovpnDecoded);
        if (remoteMatch != null) {
          port = int.tryParse(remoteMatch.group(1)!) ?? 1194;
        }

        list.add(
          VpnServer(
            id: 'vpngate_${ip}_${port}_${proto.toLowerCase()}',
            country: countryLong.isNotEmpty ? countryLong : 'Global Relay',
            countryCode: countryShort.toUpperCase(),
            city: hostName,
            host: ip,
            port: port,
            protocol: proto,
            pingMs: ping != null && ping > 0 ? ping : null,
            speedBps: speed > 0 ? speed : null,
            loadPercent: null,
            score: score,
            ovpnConfig: ovpnDecoded,
            sstpHostname: vpnGateSstpHostname(hostName),
            lastChecked: DateTime.now(),
          ),
        );

        if (list.length >= _maxCatalogRows) {
          break;
        }
      } catch (_) {
        // Skip malformed individual rows
      }
    }

    return list;
  }

  Future<int?> measureLatency(
    String host,
    int port, {
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    final sw = Stopwatch()..start();
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      sw.stop();
      socket.destroy();
      return sw.elapsedMilliseconds;
    } catch (_) {
      sw.stop();
      return null;
    }
  }

  Future<List<VpnServer>> probeServerLatencies(
    List<VpnServer> servers, {
    int maxConcurrent = 6,
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    if (servers.isEmpty) return [];

    // A worker pool rather than fixed batches: one relay that times out on
    // every endpoint must not hold up the probes queued behind it.
    final results = List<VpnServer?>.filled(servers.length, null);
    var next = 0;
    Future<void> worker() async {
      while (next < servers.length) {
        final index = next++;
        results[index] = await probeServer(servers[index], timeout: timeout);
      }
    }

    await Future.wait([
      for (var w = 0; w < min(maxConcurrent, servers.length); w++) worker(),
    ]);
    return results.cast<VpnServer>();
  }

  /// Checks [server] the way the app will connect to it: SSTP first when the
  /// relay supports it, then each OpenVPN endpoint in order. The endpoint that
  /// answered is moved to the front of the profile, and the relay is marked
  /// verified with the measured latency; otherwise it is marked unavailable.
  Future<VpnServer> probeServer(
    VpnServer server, {
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    final checked = DateTime.now();
    VpnServer verified(int ms) => server.copyWith(
      pingMs: ms,
      isAvailable: true,
      isVerified: true,
      lastChecked: checked,
    );

    if (server.supportsSstp) {
      final ms = await RelayProbe.sstp(
        address: server.host,
        port: server.sstpPort,
        hostname: server.sstpHostname!,
        timeout: timeout,
      );
      if (ms != null) return verified(ms);
    }

    final config = server.ovpnConfig;
    final remotes = OpenVpnRemote.parseAll(config);
    if (remotes.isNotEmpty && !RelayProbe.needsTlsAuthKey(config)) {
      for (final remote in remotes) {
        final ms = await RelayProbe.openVpn(remote, timeout: timeout);
        if (ms == null) continue;
        return verified(ms).copyWith(
          protocol: remote.udp ? 'UDP' : 'TCP',
          port: remote.port,
          ovpnConfig: OpenVpnRemote.preferFirst(config, remote),
        );
      }
      return server.copyWith(
        isAvailable: false,
        isVerified: false,
        lastChecked: checked,
      );
    }

    // Profiles this probe cannot handshake with (tls-auth keys, custom
    // catalogs): fall back to plain TCP reachability, and leave UDP endpoints
    // as published since a TCP socket says nothing about them.
    if (!server.protocol.toLowerCase().startsWith('tcp')) {
      return server.copyWith(isAvailable: true, lastChecked: checked);
    }
    final measured = await measureLatency(
      server.host,
      server.port,
      timeout: timeout,
    );
    return measured != null && measured > 0
        ? server.copyWith(
            pingMs: measured,
            isAvailable: true,
            lastChecked: checked,
          )
        : server.copyWith(
            isAvailable: false,
            isVerified: false,
            lastChecked: checked,
          );
  }

  void dispose() {
    _httpClient.close();
  }
}
