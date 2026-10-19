/// Explicit failure types for ShieldRoute VPN operations (PHASE 18 requirement)
enum VpnErrorType {
  noNetwork,
  permissionDenied,
  serverUnavailable,
  timeout,
  invalidConfig,
  authFailure,
  unknown,
}

class VpnException implements Exception {
  final VpnErrorType type;
  final String userMessage;
  final String? technicalDetail;

  const VpnException({
    required this.type,
    required this.userMessage,
    this.technicalDetail,
  });

  factory VpnException.fromType(VpnErrorType type, [String? detail]) {
    switch (type) {
      case VpnErrorType.noNetwork:
        return VpnException(
          type: type,
          userMessage: "You're offline",
          technicalDetail: detail ?? 'No internet connectivity detected.',
        );
      case VpnErrorType.permissionDenied:
        return VpnException(
          type: type,
          userMessage: 'VPN permission was not granted.',
          technicalDetail: detail ?? 'Android VpnService intent was rejected by the user.',
        );
      case VpnErrorType.serverUnavailable:
        return VpnException(
          type: type,
          userMessage: 'This server is currently unavailable.',
          technicalDetail: detail ?? 'Host is unreachable or node ping failed.',
        );
      case VpnErrorType.timeout:
        return VpnException(
          type: type,
          userMessage: 'The server took too long to respond.',
          technicalDetail: detail ?? 'Handshake or negotiation timed out.',
        );
      case VpnErrorType.invalidConfig:
        return VpnException(
          type: type,
          userMessage: 'This server configuration is unavailable.',
          technicalDetail: detail ?? 'Missing or malformed OpenVPN profile payload.',
        );
      case VpnErrorType.authFailure:
        return VpnException(
          type: type,
          userMessage: 'The server rejected the connection credentials.',
          technicalDetail: detail ?? 'Authentication mismatch or expired public cert.',
        );
      case VpnErrorType.unknown:
        return VpnException(
          type: type,
          userMessage: "We couldn't establish the VPN connection.",
          technicalDetail: detail ?? 'An unexpected engine error occurred.',
        );
    }
  }

  @override
  String toString() => 'VpnException($type): $userMessage ($technicalDetail)';
}
