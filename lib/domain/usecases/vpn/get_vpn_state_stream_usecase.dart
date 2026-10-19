import '../../entities/vpn_connection_state.dart';
import '../../repositories/vpn_repository.dart';

class GetVpnStateStreamUseCase {
  final VpnRepository repository;

  GetVpnStateStreamUseCase(this.repository);

  Stream<VpnConnectionState> call() => repository.stateStream;
}
