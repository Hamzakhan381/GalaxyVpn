import '../../entities/vpn_server.dart';
import '../../repositories/server_repository.dart';

class PickBestPerCountryUseCase {
  final ServerRepository repository;

  PickBestPerCountryUseCase(this.repository);

  List<VpnServer> call(List<VpnServer> servers) =>
      repository.bestPerCountry(servers);
}
