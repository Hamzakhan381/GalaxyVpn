import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../domain/entities/vpn_server.dart';

/// Login and OpenVPN server names published on VPNBook's free VPN page.
class VpnBookPage {
  final String username;
  final String password;
  final List<String> hostnames;

  const VpnBookPage({
    required this.username,
    required this.password,
    required this.hostnames,
  });
}

/// Free OpenVPN servers from VPNBook (https://www.vpnbook.com/freevpn), which
/// cover the countries VPN Gate's volunteer relays rarely do: Germany, France,
/// the UK, the US, Canada and Poland.
///
/// Every server shares one certificate set, bundled as [templateAsset], and
/// one login that VPNBook publishes on [pageUrl] and changes every one to two
/// weeks, so the login is read from that page at runtime, never shipped.
///
/// Each profile lists UDP 53 before TCP 443: networks that reset OpenVPN over
/// TCP, as in Pakistan, still let it through on UDP 53.
class VpnBookDataSource {
  static const String pageUrl = 'https://www.vpnbook.com/freevpn';
  static const String templateAsset = 'assets/servers/vpnbook_template.ovpn';
  static const String idPrefix = 'vpnbook_';

  /// Hostname prefix to (country, ISO code).
  static const Map<String, (String, String)> _countries = {
    'us': ('United States', 'US'),
    'ca': ('Canada', 'CA'),
    'uk': ('United Kingdom', 'GB'),
    'de': ('Germany', 'DE'),
    'fr': ('France', 'FR'),
    'pl': ('Poland', 'PL'),
  };

  /// OpenVPN servers listed when the page lists none (layout change).
  static const List<String> knownHostnames = [
    'us16.vpnbook.com',
    'us178.vpnbook.com',
    'ca149.vpnbook.com',
    'ca196.vpnbook.com',
    'uk205.vpnbook.com',
    'uk68.vpnbook.com',
    'de20.vpnbook.com',
    'de220.vpnbook.com',
    'fr200.vpnbook.com',
    'fr231.vpnbook.com',
    'pl134.vpnbook.com',
    'pl140.vpnbook.com',
  ];

  final http.Client _httpClient;
  final AssetBundle _bundle;

  VpnBookDataSource({http.Client? client, AssetBundle? bundle})
    : _httpClient = client ?? http.Client(),
      _bundle = bundle ?? rootBundle;

  /// Live VPNBook servers, or an empty list when the page or login is
  /// unavailable.
  Future<List<VpnServer>> fetchServers() async {
    try {
      final response = await _httpClient
          .get(Uri.parse(pageUrl), headers: const {'Accept': 'text/html'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return const [];
      final page = parsePage(response.body);
      if (page == null) return const [];
      final template = await _bundle.loadString(templateAsset);
      return buildServers(page, template);
    } catch (e) {
      debugPrint('VPNBook servers unavailable: $e');
      return const [];
    }
  }

  /// Reads the shared login and OpenVPN-capable servers from the page.
  static VpnBookPage? parsePage(String html) {
    final text = html
        .replaceAll(
          RegExp(r'<(script|style)[\s\S]*?</\1>', caseSensitive: false),
          ' ',
        )
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    final username = RegExp(r'Username:\s*([A-Za-z0-9]+)')
        .firstMatch(text)
        ?.group(1);
    final password = RegExp(r'Password:\s*([A-Za-z0-9]+)')
        .firstMatch(text)
        ?.group(1);
    if (username == null || password == null) return null;

    // A server offers OpenVPN when its listing names the protocol before the
    // next server name (PPTP/Outline-only servers are skipped).
    final names = RegExp(r'\b([a-z]{2})\d+\.vpnbook\.com\b')
        .allMatches(text)
        .toList();
    final hostnames = <String>{};
    for (var i = 0; i < names.length; i++) {
      final end = i + 1 < names.length ? names[i + 1].start : text.length;
      final listing = text.substring(names[i].end, min(end, names[i].end + 80));
      if (listing.contains('OpenVPN') &&
          _countries.containsKey(names[i].group(1))) {
        hostnames.add(names[i].group(0)!);
      }
    }

    return VpnBookPage(
      username: username,
      password: password,
      hostnames: hostnames.isEmpty
          ? knownHostnames
          : (hostnames.toList()..sort()),
    );
  }

  static List<VpnServer> buildServers(
    VpnBookPage page,
    String template, {
    DateTime? now,
  }) {
    final checked = now ?? DateTime.now();
    return [
      for (final host in page.hostnames)
        if (_countries[host.substring(0, 2)] case final country?)
          VpnServer(
            id: '$idPrefix$host',
            country: country.$1,
            countryCode: country.$2,
            city: host,
            host: host,
            port: 53,
            protocol: 'UDP',
            score: 0,
            ovpnConfig: profileFor(host, template),
            username: page.username,
            password: page.password,
            lastChecked: checked,
          ),
    ];
  }

  static String profileFor(String host, String template) =>
      'client\n'
      'dev tun\n'
      'remote $host 53 udp\n'
      'remote $host 443 tcp-client\n'
      '$template';

  static bool isVpnBook(VpnServer server) => server.id.startsWith(idPrefix);
}
