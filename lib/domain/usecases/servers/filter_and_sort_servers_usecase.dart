import '../../entities/server_sort_option.dart';
import '../../entities/vpn_server.dart';
import '../../repositories/server_repository.dart';

class FilterAndSortServersUseCase {
  final ServerRepository repository;

  FilterAndSortServersUseCase(this.repository);

  List<VpnServer> call({
    required List<VpnServer> servers,
    String query = '',
    String? countryFilter,
    String? protocolFilter,
    ServerSortOption sortOption = ServerSortOption.bestAvailable,
  }) {
    return repository.filterAndSort(
      servers: servers,
      query: query,
      countryFilter: countryFilter,
      protocolFilter: protocolFilter,
      sortOption: sortOption,
    );
  }
}
