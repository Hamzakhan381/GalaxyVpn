import '../core/storage/preferences_service.dart';
import '../data/datasources/remote/server_remote_data_source.dart';
import '../data/repositories/server_repository_impl.dart';
import '../domain/repositories/server_repository.dart';

export '../domain/entities/server_sort_option.dart';
export '../domain/repositories/server_repository.dart';
export '../data/repositories/server_repository_impl.dart';

/// Legacy service interface adapting to domain ServerRepository
abstract class ServerService implements ServerRepository {}

/// Legacy DefaultServerService adapting to ServerRepositoryImpl
class DefaultServerService extends ServerRepositoryImpl implements ServerService {
  DefaultServerService(PreferencesService prefs)
      : super(
          remoteDataSource: ServerRemoteDataSource(),
          preferencesRepo: prefs,
        );
}
