import 'package:flutter/foundation.dart';

import '../../domain/entities/server_sort_option.dart';
import '../../domain/entities/vpn_server.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../../domain/repositories/server_repository.dart';
import '../datasources/local/bundled_seed_relays_data_source.dart';
import '../datasources/remote/server_remote_data_source.dart';

/// Concrete implementation of ServerRepository
class ServerRepositoryImpl implements ServerRepository {
  final ServerRemoteDataSource remoteDataSource;
  final PreferencesRepository preferencesRepo;
  List<VpnServer> _cachedServers = [];

  ServerRepositoryImpl({
    required this.remoteDataSource,
    required this.preferencesRepo,
  });

  @override
  Future<List<VpnServer>> getServers({bool forceRefresh = false}) async {
    if (_cachedServers.isNotEmpty && !forceRefresh) {
      return _applyFavorites(_cachedServers);
    }

    final bundled = BundledSeedRelaysDataSource.getServers();

    try {
      final fetched = await remoteDataSource.fetchRelays(
        customUrl: preferencesRepo.customApiUrl,
        customApiKey: preferencesRepo.customApiKey,
      );
      if (fetched.isNotEmpty) {
        // Bundled seeds are unverified placeholders; never mix them into a
        // live catalog, where their inflated scores would win auto-selection.
        _cachedServers = fetched;
        return _applyFavorites(_cachedServers);
      }
    } catch (e) {
      debugPrint(
        'ServerRepositoryImpl: API fetch failed: $e. Falling back to bundled seeds.',
      );
    }

    _cachedServers = bundled;
    return _applyFavorites(_cachedServers);
  }

  List<VpnServer> _applyFavorites(List<VpnServer> servers) {
    final favIds = preferencesRepo.favoriteServerIds.toSet();
    return servers.map((server) {
      final legacyId = server.id.startsWith('vpngate_')
          ? 'vpngate_${server.host}'
          : null;
      return server.copyWith(
        isFavorite:
            favIds.contains(server.id) ||
            (legacyId != null && favIds.contains(legacyId)),
      );
    }).toList();
  }

  @override
  Future<void> toggleFavorite(String serverId) async {
    VpnServer? server;
    for (final candidate in _cachedServers) {
      if (candidate.id == serverId) {
        server = candidate;
        break;
      }
    }
    if (server == null) {
      await preferencesRepo.toggleFavorite(serverId);
      _cachedServers = _applyFavorites(_cachedServers);
      return;
    }
    final legacyId = server.id.startsWith('vpngate_')
        ? 'vpngate_${server.host}'
        : null;
    final favorites = preferencesRepo.favoriteServerIds.toSet();
    final wasFavorite =
        favorites.contains(serverId) ||
        (legacyId != null && favorites.contains(legacyId));
    if (wasFavorite) {
      if (favorites.contains(serverId)) {
        await preferencesRepo.toggleFavorite(serverId);
      }
      if (legacyId != null && favorites.contains(legacyId)) {
        await preferencesRepo.toggleFavorite(legacyId);
      }
    } else {
      await preferencesRepo.toggleFavorite(serverId);
    }
    _cachedServers = _applyFavorites(_cachedServers);
  }

  @override
  List<VpnServer> filterAndSort({
    required List<VpnServer> servers,
    String query = '',
    String? countryFilter,
    String? protocolFilter,
    ServerSortOption sortOption = ServerSortOption.bestAvailable,
  }) {
    var result = List<VpnServer>.from(servers);

    // Query Search
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((s) {
        return s.country.toLowerCase().contains(q) ||
            s.countryCode.toLowerCase().contains(q) ||
            s.city.toLowerCase().contains(q) ||
            s.host.toLowerCase().contains(q);
      }).toList();
    }

    // Country Filter
    if (countryFilter != null &&
        countryFilter.isNotEmpty &&
        countryFilter != 'All Countries') {
      result = result
          .where(
            (s) => s.country == countryFilter || s.countryCode == countryFilter,
          )
          .toList();
    }

    // Protocol Filter
    if (protocolFilter != null &&
        protocolFilter.isNotEmpty &&
        protocolFilter != 'All Protocols') {
      result = result
          .where(
            (s) => s.protocol.toUpperCase() == protocolFilter.toUpperCase(),
          )
          .toList();
    }

    // Region prioritization / filter if selected in Preferences
    final region = preferencesRepo.apiRegion;
    if (region != 'Global (Auto)') {
      final regionCodes = _getCountryCodesForRegion(region);
      if (regionCodes.isNotEmpty) {
        final matches = result
            .where((s) => regionCodes.contains(s.countryCode.toUpperCase()))
            .toList();
        if (matches.isNotEmpty) {
          result = matches;
        }
      }
    }

    // Sorting
    switch (sortOption) {
      case ServerSortOption.highestSpeed:
        result.sort((a, b) {
          final sA = a.speedBps ?? 0;
          final sB = b.speedBps ?? 0;
          if (sA != sB) return sB.compareTo(sA);
          final pingA = a.pingMs ?? 9999;
          final pingB = b.pingMs ?? 9999;
          return pingA.compareTo(pingB);
        });
        break;

      case ServerSortOption.bestAvailable:
        result.sort((a, b) {
          if (a.isFavorite != b.isFavorite) return b.isFavorite ? 1 : -1;
          final pingA = (a.pingMs != null && a.pingMs! > 0) ? a.pingMs! : 120;
          final pingB = (b.pingMs != null && b.pingMs! > 0) ? b.pingMs! : 120;
          final compA =
              (a.speedMbps * 10.0) - (pingA * 1.2) + (a.score / 50000.0);
          final compB =
              (b.speedMbps * 10.0) - (pingB * 1.2) + (b.score / 50000.0);
          return compB.compareTo(compA);
        });
        break;

      case ServerSortOption.lowestLatency:
        result.sort((a, b) {
          final pingA = a.pingMs ?? 9999;
          final pingB = b.pingMs ?? 9999;
          return pingA.compareTo(pingB);
        });
        break;

      case ServerSortOption.highestQuality:
        result.sort((a, b) => b.score.compareTo(a.score));
        break;

      case ServerSortOption.favoritesFirst:
        result.sort((a, b) {
          if (a.isFavorite != b.isFavorite) return b.isFavorite ? 1 : -1;
          return a.country.compareTo(b.country);
        });
        break;
    }

    return result;
  }

  Set<String> _getCountryCodesForRegion(String region) {
    switch (region) {
      case 'Asia / Pacific':
        return {
          'JP',
          'KR',
          'SG',
          'TH',
          'VN',
          'ID',
          'TW',
          'HK',
          'MY',
          'PH',
          'IN',
        };
      case 'Americas':
        return {'US', 'CA', 'BR', 'MX', 'CL', 'AR'};
      case 'Europe':
        return {
          'AL',
          'AD',
          'AT',
          'BA',
          'BE',
          'BG',
          'BY',
          'CY',
          'CZ',
          'DK',
          'DE',
          'EE',
          'ES',
          'FI',
          'FR',
          'GB',
          'GR',
          'HR',
          'HU',
          'IE',
          'IT',
          'IS',
          'LI',
          'LT',
          'LU',
          'LV',
          'MC',
          'MD',
          'ME',
          'MK',
          'MT',
          'NL',
          'NO',
          'PL',
          'PT',
          'RO',
          'RS',
          'RU',
          'SE',
          'SI',
          'SK',
          'SM',
          'TR',
          'UA',
          'VA',
        };
      default:
        return {};
    }
  }

  @override
  VpnServer? findFastestServer(List<VpnServer> servers) {
    if (servers.isEmpty) return null;

    final candidates = servers.where((s) => s.isAvailable).toList();
    if (candidates.isEmpty) return servers.first;

    candidates.sort((a, b) {
      final pingA = a.pingMs;
      final pingB = b.pingMs;

      if (pingA != null && pingB != null) {
        final pingDiff = (pingA - pingB).abs();
        if (pingDiff > 8) {
          return pingA.compareTo(pingB);
        }
        final speedA = a.speedBps ?? 0;
        final speedB = b.speedBps ?? 0;
        if (speedA != speedB) {
          return speedB.compareTo(speedA);
        }
        return pingA.compareTo(pingB);
      }

      if (pingA != null && pingB == null) return -1;
      if (pingA == null && pingB != null) return 1;

      final speedA = a.speedBps ?? 0;
      final speedB = b.speedBps ?? 0;
      if (speedA != speedB) {
        return speedB.compareTo(speedA);
      }

      return b.score.compareTo(a.score);
    });

    return candidates.first;
  }

  @override
  Future<int?> measureLatency(
    String host,
    int port, {
    Duration timeout = const Duration(milliseconds: 1500),
  }) => remoteDataSource.measureLatency(host, port, timeout: timeout);

  @override
  Future<List<VpnServer>> probeServerLatencies(
    List<VpnServer> servers, {
    int maxConcurrent = 6,
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    final updatedList = await remoteDataSource.probeServerLatencies(
      servers,
      maxConcurrent: maxConcurrent,
      timeout: timeout,
    );

    if (_cachedServers.isNotEmpty) {
      final probedMap = {for (final s in updatedList) s.id: s};
      _cachedServers = _cachedServers.map((s) => probedMap[s.id] ?? s).toList();
    } else {
      _cachedServers = updatedList;
    }
    return updatedList;
  }
}
