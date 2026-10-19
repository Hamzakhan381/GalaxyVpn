import '../../repositories/server_repository.dart';

class ToggleFavoriteServerUseCase {
  final ServerRepository repository;

  ToggleFavoriteServerUseCase(this.repository);

  Future<void> call(String serverId) => repository.toggleFavorite(serverId);
}
