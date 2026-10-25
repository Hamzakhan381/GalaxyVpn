import '../entities/server_sort_option.dart';
import '../entities/vpn_server.dart';

/// Pure domain repository contract defining server discovery & benchmarking
abstract class ServerRepository {
  Future<List<VpnServer>> getServers({bool forceRefresh = false});
  Future<void> toggleFavorite(String serverId);

  List<VpnServer> filterAndSort({
    required List<VpnServer> servers,
    String query = '',
    String? countryFilter,
    String? protocolFilter,
    ServerSortOption sortOption = ServerSortOption.bestAvailable,
  });

  VpnServer? findFastestServer(List<VpnServer> servers);

  /// The fastest relay of each country, as ranked by [findFastestServer].
  List<VpnServer> bestPerCountry(List<VpnServer> servers);

  Future<int?> measureLatency(
    String host,
    int port, {
    Duration timeout = const Duration(milliseconds: 1500),
  });

  Future<List<VpnServer>> probeServerLatencies(
    List<VpnServer> servers, {
    int maxConcurrent = 6,
    Duration timeout = const Duration(milliseconds: 1500),
  });
}
