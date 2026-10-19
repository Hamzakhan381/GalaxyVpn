import '../../repositories/vpn_repository.dart';

class DisconnectVpnUseCase {
  final VpnRepository repository;

  DisconnectVpnUseCase(this.repository);

  Future<void> call() => repository.disconnect();
}
