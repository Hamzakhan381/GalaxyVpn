import 'vpn_exception.dart';

/// Base Failure class in Clean Architecture
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}

class VpnFailure extends Failure {
  final VpnErrorType errorType;

  const VpnFailure({
    required String message,
    required this.errorType,
    String? code,
  }) : super(message, code);

  factory VpnFailure.fromException(VpnException exception) {
    return VpnFailure(
      message: exception.userMessage,
      errorType: exception.type,
      code: exception.technicalDetail,
    );
  }
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.code]);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, [super.code]);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message, [super.code]);
}
