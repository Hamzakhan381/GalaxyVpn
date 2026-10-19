import '../../entities/vpn_session.dart';
import '../../repositories/session_repository.dart';

class SaveSessionHistoryUseCase {
  final SessionRepository repository;

  SaveSessionHistoryUseCase(this.repository);

  Future<void> call(List<VpnSession> sessions) =>
      repository.saveSessions(sessions);
}
