import '../../entities/auth_user.dart';
import '../../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<AuthUser> call(String email, String password) =>
      repository.login(email, password);
}
