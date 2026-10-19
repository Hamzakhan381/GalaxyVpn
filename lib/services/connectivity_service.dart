import '../data/repositories/connectivity_repository_impl.dart';
import '../domain/repositories/connectivity_repository.dart';

export '../domain/repositories/connectivity_repository.dart';
export '../data/repositories/connectivity_repository_impl.dart';

/// Legacy ConnectivityService adapting to domain ConnectivityRepository
abstract class ConnectivityService implements ConnectivityRepository {}

/// Legacy DefaultConnectivityService adapting to ConnectivityRepositoryImpl
class DefaultConnectivityService extends ConnectivityRepositoryImpl
    implements ConnectivityService {}
