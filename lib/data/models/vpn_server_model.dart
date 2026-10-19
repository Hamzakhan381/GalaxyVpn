import '../../domain/entities/vpn_server.dart';

/// Data Transfer Object for VpnServer with serialization support
class VpnServerModel extends VpnServer {
  const VpnServerModel({
    required super.id,
    required super.country,
    required super.countryCode,
    required super.city,
    required super.host,
    required super.port,
    required super.protocol,
    super.pingMs,
    super.loadPercent,
    super.speedBps,
    required super.score,
    required super.ovpnConfig,
    super.username = 'vpn',
    super.password = 'vpn',
    super.isFavorite = false,
    super.isAvailable = true,
    required super.lastChecked,
  });

  factory VpnServerModel.fromDomain(VpnServer server) {
    return VpnServerModel(
      id: server.id,
      country: server.country,
      countryCode: server.countryCode,
      city: server.city,
      host: server.host,
      port: server.port,
      protocol: server.protocol,
      pingMs: server.pingMs,
      loadPercent: server.loadPercent,
      speedBps: server.speedBps,
      score: server.score,
      ovpnConfig: server.ovpnConfig,
      username: server.username,
      password: server.password,
      isFavorite: server.isFavorite,
      isAvailable: server.isAvailable,
      lastChecked: server.lastChecked,
    );
  }

  factory VpnServerModel.fromJson(Map<String, dynamic> json) {
    final server = VpnServer.fromJson(json);
    return VpnServerModel.fromDomain(server);
  }
}
