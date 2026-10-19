import '../../entities/vpn_server.dart';
import '../../repositories/server_repository.dart';

class DetectFastestServerUseCase {
  final ServerRepository repository;

  DetectFastestServerUseCase(this.repository);

  VpnServer? call(List<VpnServer> servers) =>
      repository.findFastestServer(servers);
}
