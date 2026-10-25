import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_vpn/core/storage/preferences_service.dart';
import 'package:galaxy_vpn/data/models/vpn_server.dart';
import 'package:galaxy_vpn/data/repositories/server_repository_impl.dart';
import 'package:galaxy_vpn/domain/entities/server_sort_option.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Server Parsing, Filtering, and Sorting Tests', () {
    late PreferencesService prefs;
    late ServerRepositoryImpl serverService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'favorite_server_ids': ['vpngate_219.100.37.98_443_tcp'],
      });
      prefs = await PreferencesService.create();
      serverService = ServerRepositoryImpl(preferencesRepo: prefs);
    });

    test('Falls back to bundled VPN Gate relays when the catalog is unreachable', () async {
      final servers = await serverService.getServers();
      expect(servers.length, greaterThanOrEqualTo(6));

      final relay = servers.firstWhere((s) => s.id == 'vpngate_219.100.37.98_443_tcp');
      expect(relay.country, equals('Japan'));
      expect(relay.countryCode, equals('JP'));
      expect(relay.isFavorite, isTrue);
      expect(relay.pingMs, isNotNull);
      expect(relay.sstpHostname, equals('public-vpn-108.opengw.net'));
      expect(relay.sstpPort, equals(443));
      expect(servers.every((s) => s.supportsSstp), isTrue);
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
        query: 'public-vpn-108',
      );

      expect(filtered.length, equals(1));
      expect(filtered.single.city, equals('public-vpn-108'));
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
      await serverService.getServers();
      await serverService.toggleFavorite('vpngate_219.100.37.49_443_tcp');
      final updatedServers = await serverService.getServers();
      final relay = updatedServers.firstWhere((s) => s.id == 'vpngate_219.100.37.49_443_tcp');
      expect(relay.isFavorite, isTrue);
      expect(prefs.favoriteServerIds.contains('vpngate_219.100.37.49_443_tcp'), isTrue);
    });
  });
}
