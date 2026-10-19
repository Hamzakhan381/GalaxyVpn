import '../../repositories/vpn_repository.dart';

class RequestVpnPermissionUseCase {
  final VpnRepository repository;

  RequestVpnPermissionUseCase(this.repository);

  Future<bool> call() => repository.requestVpnPermission();
}
