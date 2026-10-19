import '../../entities/vpn_server.dart';
import '../../repositories/server_repository.dart';

class GetServersUseCase {
  final ServerRepository repository;

  GetServersUseCase(this.repository);

  Future<List<VpnServer>> call({bool forceRefresh = false}) =>
      repository.getServers(forceRefresh: forceRefresh);
}
