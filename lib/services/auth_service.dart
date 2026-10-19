import '../core/storage/preferences_service.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';

export '../domain/entities/auth_user.dart';
export '../domain/repositories/auth_repository.dart';
export '../data/repositories/auth_repository_impl.dart';

/// Legacy AuthService interface adapting to domain AuthRepository
abstract class AuthService implements AuthRepository {}

/// Legacy LocalAuthService adapting to AuthRepositoryImpl
class LocalAuthService extends AuthRepositoryImpl implements AuthService {
  LocalAuthService(PreferencesService super.prefs);
}
