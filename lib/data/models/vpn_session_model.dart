import '../../domain/entities/vpn_session.dart';

/// Data Transfer Object for VpnSession with serialization support
class VpnSessionModel extends VpnSession {
  const VpnSessionModel({
    required super.id,
    required super.serverId,
    required super.serverName,
    required super.startedAt,
    super.endedAt,
    required super.durationSeconds,
    required super.bytesReceived,
    required super.bytesSent,
    required super.status,
    super.failureReason,
  });

  factory VpnSessionModel.fromDomain(VpnSession session) {
    return VpnSessionModel(
      id: session.id,
      serverId: session.serverId,
      serverName: session.serverName,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      durationSeconds: session.durationSeconds,
      bytesReceived: session.bytesReceived,
      bytesSent: session.bytesSent,
      status: session.status,
      failureReason: session.failureReason,
    );
  }

  factory VpnSessionModel.fromJson(Map<String, dynamic> json) {
    final session = VpnSession.fromJson(json);
    return VpnSessionModel.fromDomain(session);
  }
}
