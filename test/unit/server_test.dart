import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldroute_vpn/core/storage/preferences_service.dart';
import 'package:shieldroute_vpn/data/models/vpn_server.dart';
import 'package:shieldroute_vpn/services/server_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Server Parsing, Filtering, and Sorting Tests', () {
    late PreferencesService prefs;
    late DefaultServerService serverService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'favorite_server_ids': ['seed_jp_01'],
      });
      prefs = await PreferencesService.create();
      serverService = DefaultServerService(prefs);
    });

    test('Loads academic seed servers with valid attributes', () async {
      final servers = await serverService.getServers();
      expect(servers, isNotEmpty);
      expect(servers.length, greaterThanOrEqualTo(5));

      final jpServer = servers.firstWhere((s) => s.id == 'seed_jp_01');
      expect(jpServer.country, equals('Japan'));
      expect(jpServer.countryCode, equals('JP'));
      expect(jpServer.isFavorite, isTrue);
      expect(jpServer.pingMs, isNotNull);
      expect(jpServer.pingDisplay, equals('24 ms'));
    });

    test('Never invents fake metrics when ping is missing', () {
      final server = VpnServer(
        id: 'no_ping',
        country: 'Iceland',
        countryCode: 'IS',
        city: 'Reykjavik',
        host: '192.0.2.1',
        port: 1194,
        protocol: 'UDP',
        pingMs: null,
        loadPercent: null,
        score: 100,
        ovpnConfig: 'client\ndev tun',
        lastChecked: DateTime.now(),
      );

      expect(server.pingDisplay, equals('Not available'));
      expect(server.loadDisplay, equals('Not available'));
    });

    test('Filters servers correctly by query', () async {
      final servers = await serverService.getServers();
      final filtered = serverService.filterAndSort(
        servers: servers,
        query: 'germany',
      );

      expect(filtered.every((s) => s.country.toLowerCase().contains('germany')), isTrue);
      expect(filtered.length, equals(1));
    });

    test('Filters servers correctly by protocol', () async {
      final servers = await serverService.getServers();
      final tcpOnly = serverService.filterAndSort(
        servers: servers,
        protocolFilter: 'TCP',
      );

      expect(tcpOnly.every((s) => s.protocol == 'TCP'), isTrue);
      expect(tcpOnly, isNotEmpty);
    });

    test('Sorts servers by lowest latency', () async {
      final servers = await serverService.getServers();
      final sorted = serverService.filterAndSort(
        servers: servers,
        sortOption: ServerSortOption.lowestLatency,
      );

      for (int i = 0; i < sorted.length - 1; i++) {
        final currentPing = sorted[i].pingMs ?? 9999;
        final nextPing = sorted[i + 1].pingMs ?? 9999;
        expect(currentPing, lessThanOrEqualTo(nextPing));
      }
    });

    test('Toggles server favorite status persistently', () async {
      await serverService.toggleFavorite('seed_us_01');
      final updatedServers = await serverService.getServers();
      final usServer = updatedServers.firstWhere((s) => s.id == 'seed_us_01');
      expect(usServer.isFavorite, isTrue);
      expect(prefs.favoriteServerIds.contains('seed_us_01'), isTrue);
    });
  });
}
