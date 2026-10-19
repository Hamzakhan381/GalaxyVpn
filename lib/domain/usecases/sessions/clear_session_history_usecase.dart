import '../../repositories/session_repository.dart';

class ClearSessionHistoryUseCase {
  final SessionRepository repository;

  ClearSessionHistoryUseCase(this.repository);

  Future<void> call() => repository.clearHistory();
}
