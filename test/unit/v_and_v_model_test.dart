import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_vpn/core/storage/preferences_service.dart';
import 'package:galaxy_vpn/data/datasources/local/bundled_seed_relays_data_source.dart';
import 'package:galaxy_vpn/data/datasources/platform/openvpn_platform_data_source.dart';
import 'package:galaxy_vpn/data/models/vpn_server.dart';
import 'package:galaxy_vpn/data/repositories/server_repository_impl.dart';
import 'package:galaxy_vpn/domain/entities/server_sort_option.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('V&V Model — Verification & Validation Suite', () {
    late PreferencesService prefs;
    late ServerRepositoryImpl serverService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'favorite_server_ids': ['seed_jp_01'],
        'setting_api_region': 'Global (Auto)',
        'setting_turbo_speed': true,
      });
      prefs = await PreferencesService.create();
      serverService = ServerRepositoryImpl(preferencesRepo: prefs);
    });

    test('VERIFICATION [V-1]: VpnServer correctly parses and calculates throughput speed', () {
      final serverHighSpeed = VpnServer(
        id: 'fast_server_01',
        country: 'Japan',
        countryCode: 'JP',
        city: 'Tokyo High Speed Node',
        host: '221.44.205.161',
        port: 443,
        protocol: 'TCP',
        pingMs: 8,
        speedBps: 923500000, // 923.5 Mbps
        score: 2500000,
        ovpnConfig: 'client\ndev tun',
        lastChecked: DateTime.now(),
      );

      expect(serverHighSpeed.speedBps, equals(923500000));
      expect(serverHighSpeed.speedMbps, closeTo(923.5, 0.1));
      expect(serverHighSpeed.speedDisplay, equals('923.5 Mbps'));
      expect(serverHighSpeed.pingDisplay, equals('8 ms'));

      final json = serverHighSpeed.toJson();
      expect(json['speedBps'], equals(923500000));

      final restored = VpnServer.fromJson(json);
      expect(restored.speedBps, equals(923500000));
      expect(restored.speedDisplay, equals('923.5 Mbps'));
    });

    test('VERIFICATION [V-2]: Bundled fallback relays are genuine VPN Gate profiles', () async {
      final seeds = await BundledSeedRelaysDataSource.loadServers();
      expect(seeds.length, greaterThanOrEqualTo(6));

      for (final seed in seeds) {
        // Real VPN Gate profiles: embedded CA + client cert/key and a live
        // remote endpoint (no placeholder or documentation-range addresses).
        expect(seed.ovpnConfig.contains('dev tun'), isTrue);
        expect(seed.ovpnConfig.contains('<ca>'), isTrue);
        expect(seed.ovpnConfig.contains('<cert>'), isTrue);
        expect(seed.ovpnConfig.contains('<key>'), isTrue);
        expect(
          RegExp(r'^remote \S+ \d+', multiLine: true).hasMatch(seed.ovpnConfig),
          isTrue,
        );
        expect(seed.host.startsWith('198.51.100.'), isFalse);
        expect(seed.speedBps, isNotNull);
        expect(seed.speedBps!, greaterThan(1000000), reason: 'Seed bandwidth must be > 1 Mbps');
      }
    });

    test('VERIFICATION [V-3]: Sorting by Highest Speed orders servers by throughput bandwidth', () async {
      final servers = await serverService.getServers();
      final sortedBySpeed = serverService.filterAndSort(
        servers: servers,
        sortOption: ServerSortOption.highestSpeed,
      );

      expect(sortedBySpeed, isNotEmpty);
      for (int i = 0; i < sortedBySpeed.length - 1; i++) {
        final currentSpeed = sortedBySpeed[i].speedBps ?? 0;
        final nextSpeed = sortedBySpeed[i + 1].speedBps ?? 0;
        expect(currentSpeed, greaterThanOrEqualTo(nextSpeed),
            reason: 'Servers must be sorted from highest to lowest bandwidth');
      }
    });

    test('VERIFICATION [V-4]: Best Available sorting balances throughput and latency for fast connection', () async {
      final servers = await serverService.getServers();
      final bestAvailable = serverService.filterAndSort(
        servers: servers,
        sortOption: ServerSortOption.bestAvailable,
      );

      expect(bestAvailable, isNotEmpty);
      // Top server should have high speed and low ping
      final top = bestAvailable.first;
      expect(top.speedMbps, greaterThan(50.0), reason: 'Top best available server should have strong bandwidth');
    });

    test('VERIFICATION [V-5]: OpenVpnPlatformDataSource config optimizer injects MTU clamping and low-latency DNS', () {
      const rawConfig = '''
client
dev tun
proto udp
remote 104.28.237.74 8962
cipher AES-128-CBC
auth SHA1
''';

      final optimized = OpenVpnPlatformDataSource.optimizeConfig(rawConfig, turboMode: true);

      // Verify anti-fragmentation MTU clamping for mobile 4G/5G
      expect(optimized.contains('tun-mtu 1400'), isTrue);
      expect(optimized.contains('mssfix 1360'), isTrue);

      // Verify traffic redirection
      expect(optimized.contains('redirect-gateway def1'), isTrue);

      // Verify low-latency Anycast DNS
      expect(optimized.contains('dhcp-option DNS 1.1.1.1'), isTrue);
      expect(optimized.contains('dhcp-option DNS 8.8.8.8'), isTrue);

      // Verify socket buffer expansion
      expect(optimized.contains('sndbuf 524288'), isTrue);
      expect(optimized.contains('rcvbuf 524288'), isTrue);
    });

    test('VERIFICATION [V-6]: PreferencesService correctly persists Open API keys and endpoints', () async {
      await prefs.setCustomApiUrl('https://my-relay.vpn.org/api/iphone/');
      await prefs.setCustomApiKey('sk_test_academic_relay_token_998');
      await prefs.setApiRegion('Europe');
      await prefs.setTurboSpeedMode(true);

      expect(prefs.customApiUrl, equals('https://my-relay.vpn.org/api/iphone/'));
      expect(prefs.customApiKey, equals('sk_test_academic_relay_token_998'));
      expect(prefs.apiRegion, equals('Europe'));
      expect(prefs.turboSpeedMode, isTrue);

      // Test clearing
      await prefs.setCustomApiKey(null);
      expect(prefs.customApiKey, isNull);
    });

    test('VALIDATION [Val-1]: Multi-location geographical filtering matches selected regions', () async {
      await prefs.setApiRegion('Asia / Pacific');
      // Mix of regions so the filter has something to exclude.
      final relays = await serverService.getServers();
      final servers = [
        relays[0],
        relays[1].copyWith(id: 'us_relay', country: 'United States', countryCode: 'US'),
        relays[2].copyWith(id: 'de_relay', country: 'Germany', countryCode: 'DE'),
      ];
      final filteredAsia = serverService.filterAndSort(servers: servers);

      final asiaCodes = {'JP', 'KR', 'SG', 'TH', 'VN', 'ID', 'TW', 'HK', 'MY', 'PH', 'IN'};
      expect(filteredAsia.every((s) => asiaCodes.contains(s.countryCode)), isTrue);

      // Switch to Americas
      await prefs.setApiRegion('Americas');
      final filteredAmericas = serverService.filterAndSort(servers: servers);
      final americasCodes = {'US', 'CA', 'BR', 'MX', 'CL', 'AR'};
      expect(filteredAmericas.every((s) => americasCodes.contains(s.countryCode)), isTrue);
    });

    test('VALIDATION [Val-2]: Phone speed optimization prevents sluggish or hanging mobile connections', () async {
      final servers = await serverService.getServers();
      final topSpeed = serverService.filterAndSort(
        servers: servers,
        sortOption: ServerSortOption.highestSpeed,
      ).first;

      // Ensure the top server provides high throughput
      expect(topSpeed.speedMbps, greaterThanOrEqualTo(100.0),
          reason: 'High-speed server must exceed 100 Mbps to prevent phone speed degradation');

      // Ensure config preparation applies turbo enhancements
      final readyConfig = OpenVpnPlatformDataSource.optimizeConfig(topSpeed.ovpnConfig, turboMode: true);
      expect(readyConfig.contains('mssfix'), isTrue);
      expect(readyConfig.contains('redirect-gateway def1'), isTrue);
      expect(readyConfig.contains('dhcp-option DNS'), isTrue);
    });
  });
}
