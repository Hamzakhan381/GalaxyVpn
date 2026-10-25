import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_vpn/data/models/vpn_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VpnServer — Model Tests', () {
    VpnServer makeServer({
      String id = 'srv_1',
      String country = 'Japan',
      String countryCode = 'JP',
      String city = 'Tokyo',
      String host = '10.0.0.1',
      int port = 1194,
      String protocol = 'UDP',
      int? pingMs = 24,
      int? loadPercent = 40,
      int? speedBps = 150000000,
      int score = 900000,
      String ovpnConfig = 'client\ndev tun\n',
      bool isFavorite = false,
      bool isAvailable = true,
    }) {
      return VpnServer(
        id: id,
        country: country,
        countryCode: countryCode,
        city: city,
        host: host,
        port: port,
        protocol: protocol,
        pingMs: pingMs,
        loadPercent: loadPercent,
        speedBps: speedBps,
        score: score,
        ovpnConfig: ovpnConfig,
        isFavorite: isFavorite,
        isAvailable: isAvailable,
        lastChecked: DateTime(2026, 1, 1),
      );
    }

    // ── pingDisplay ──────────────────────────────────────────────────────────

    group('pingDisplay', () {
      test('returns formatted ping when pingMs is set', () {
        expect(makeServer(pingMs: 45).pingDisplay, equals('45 ms'));
      });

      test('returns Not available when pingMs is null', () {
        expect(makeServer(pingMs: null).pingDisplay, equals('Not available'));
      });

      test('returns 0 ms for zero ping', () {
        expect(makeServer(pingMs: 0).pingDisplay, equals('0 ms'));
      });
    });

    // ── speedDisplay ─────────────────────────────────────────────────────────

    group('speedDisplay', () {
      test('returns formatted Mbps when speedBps is set', () {
        expect(makeServer(speedBps: 250000000).speedDisplay, equals('250.0 Mbps'));
        expect(makeServer(speedBps: 250000000).speedMbps, equals(250.0));
      });

      test('returns formatted Kbps when speedBps is sub-megabit', () {
        expect(makeServer(speedBps: 750000).speedDisplay, equals('750 Kbps'));
      });

      test('returns Not available when speedBps is null or zero', () {
        expect(makeServer(speedBps: null).speedDisplay, equals('Not available'));
        expect(makeServer(speedBps: 0).speedDisplay, equals('Not available'));
      });
    });

    // ── loadDisplay ──────────────────────────────────────────────────────────

    group('loadDisplay', () {
      test('returns formatted load when loadPercent is set', () {
        expect(makeServer(loadPercent: 65).loadDisplay, equals('65%'));
      });

      test('returns Not available when loadPercent is null', () {
        expect(makeServer(loadPercent: null).loadDisplay, equals('Not available'));
      });

      test('returns 0% for zero load', () {
        expect(makeServer(loadPercent: 0).loadDisplay, equals('0%'));
      });
    });

    // ── equality ─────────────────────────────────────────────────────────────

    group('equality', () {
      test('two servers with same id are equal', () {
        final a = makeServer(id: 'srv_1');
        final b = makeServer(id: 'srv_1', country: 'US');
        expect(a, equals(b));
      });

      test('two servers with different ids are not equal', () {
        final a = makeServer(id: 'srv_1');
        final b = makeServer(id: 'srv_2');
        expect(a, isNot(equals(b)));
      });

      test('hashCode is consistent with equality', () {
        final a = makeServer(id: 'srv_1');
        final b = makeServer(id: 'srv_1');
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    // ── copyWith ─────────────────────────────────────────────────────────────

    group('copyWith', () {
      test('copyWith isFavorite creates new server with updated favorite flag',
          () {
        final original = makeServer(isFavorite: false);
        final updated = original.copyWith(isFavorite: true);
        expect(updated.isFavorite, isTrue);
        expect(original.isFavorite, isFalse); // original unchanged
      });

      test('copyWith preserves all non-specified fields', () {
        final original = makeServer();
        final updated = original.copyWith(pingMs: 99);
        expect(updated.id, equals(original.id));
        expect(updated.country, equals(original.country));
        expect(updated.host, equals(original.host));
        expect(updated.pingMs, equals(99));
      });

      test('copyWith isAvailable marks server as unavailable', () {
        final original = makeServer(isAvailable: true);
        final unavailable = original.copyWith(isAvailable: false);
        expect(unavailable.isAvailable, isFalse);
      });
    });

    // ── toJson / fromJson ────────────────────────────────────────────────────

    group('toJson / fromJson', () {
      test('round-trip preserves all fields', () {
        final original = makeServer();
        final json = original.toJson();
        final restored = VpnServer.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.country, equals(original.country));
        expect(restored.countryCode, equals(original.countryCode));
        expect(restored.city, equals(original.city));
        expect(restored.host, equals(original.host));
        expect(restored.port, equals(original.port));
        expect(restored.protocol, equals(original.protocol));
        expect(restored.pingMs, equals(original.pingMs));
        expect(restored.loadPercent, equals(original.loadPercent));
        expect(restored.speedBps, equals(original.speedBps));
        expect(restored.score, equals(original.score));
        expect(restored.ovpnConfig, equals(original.ovpnConfig));
        expect(restored.isFavorite, equals(original.isFavorite));
        expect(restored.isAvailable, equals(original.isAvailable));
      });

      test('fromJson handles missing optional fields with defaults', () {
        final minimalJson = {
          'id': 'srv_min',
          'host': '192.168.1.1',
          'ovpnConfig': 'client',
          'lastChecked': DateTime.now().toIso8601String(),
        };
        final s = VpnServer.fromJson(minimalJson);
        expect(s.country, equals('Unknown'));
        expect(s.countryCode, equals('UN'));
        expect(s.port, equals(1194));
        expect(s.protocol, equals('UDP'));
        expect(s.pingMs, isNull);
        expect(s.loadPercent, isNull);
        expect(s.speedBps, isNull);
        expect(s.score, equals(0));
        expect(s.username, equals('vpn'));
        expect(s.password, equals('vpn'));
        expect(s.isFavorite, isFalse);
        expect(s.isAvailable, isTrue);
      });

      test('JSON serialization encodes to valid JSON string', () {
        final server = makeServer();
        final json = server.toJson();
        // Encode then decode to ensure it is fully JSON-serializable
        final encoded = jsonEncode(json);
        expect(encoded, isA<String>());
        expect(encoded, contains('"id":"srv_1"'));
      });
    });

    // ── default credentials ──────────────────────────────────────────────────

    group('Default credentials', () {
      test('default username is vpn', () {
        expect(makeServer().username, equals('vpn'));
      });

      test('default password is vpn', () {
        expect(makeServer().password, equals('vpn'));
      });
    });

    // ── ovpnConfig validation ────────────────────────────────────────────────

    group('ovpnConfig', () {
      test('hasClientCert is false for config without <cert> block', () {
        final server = makeServer(ovpnConfig: 'client\ndev tun\nremote 10.0.0.1');
        expect(server.ovpnConfig.contains('<cert>'), isFalse);
      });

      test('hasClientCert is true for config with <cert> block', () {
        final server = makeServer(ovpnConfig: 'client\ndev tun\n<cert>\n...\n</cert>');
        expect(server.ovpnConfig.contains('<cert>'), isTrue);
      });
    });
  });
}
