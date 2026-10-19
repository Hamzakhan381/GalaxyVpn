import '../../entities/vpn_server.dart';
import '../../repositories/vpn_repository.dart';

class ConnectVpnUseCase {
  final VpnRepository repository;

  ConnectVpnUseCase(this.repository);

  Future<void> call(VpnServer server) => repository.connect(server);
}
