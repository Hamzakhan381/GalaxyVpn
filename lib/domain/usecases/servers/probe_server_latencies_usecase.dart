import '../../entities/vpn_server.dart';
import '../../repositories/server_repository.dart';

class ProbeServerLatenciesUseCase {
  final ServerRepository repository;

  ProbeServerLatenciesUseCase(this.repository);

  Future<List<VpnServer>> call(
    List<VpnServer> servers, {
    int maxConcurrent = 6,
    Duration timeout = const Duration(milliseconds: 1500),
  }) {
    return repository.probeServerLatencies(
      servers,
      maxConcurrent: maxConcurrent,
      timeout: timeout,
    );
  }
}
