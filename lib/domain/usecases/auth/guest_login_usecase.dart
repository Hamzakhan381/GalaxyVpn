import '../../entities/auth_user.dart';
import '../../repositories/auth_repository.dart';

class GuestLoginUseCase {
  final AuthRepository repository;

  GuestLoginUseCase(this.repository);

  Future<AuthUser> call() => repository.continueAsGuest();
}
