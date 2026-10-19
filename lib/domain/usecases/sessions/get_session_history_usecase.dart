import '../../entities/vpn_session.dart';
import '../../repositories/session_repository.dart';

class GetSessionHistoryUseCase {
  final SessionRepository repository;

  GetSessionHistoryUseCase(this.repository);

  List<VpnSession> call() => repository.getSessions();
}
