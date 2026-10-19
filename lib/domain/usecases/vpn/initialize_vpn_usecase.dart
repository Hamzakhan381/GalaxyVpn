import '../../repositories/vpn_repository.dart';

class InitializeVpnUseCase {
  final VpnRepository repository;

  InitializeVpnUseCase(this.repository);

  Future<void> call() => repository.initialize();
}
