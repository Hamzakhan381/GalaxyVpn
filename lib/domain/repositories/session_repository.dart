import '../entities/vpn_session.dart';

/// Pure domain repository contract defining VPN session logging & history
abstract class SessionRepository {
  List<VpnSession> getSessions();
  Future<void> saveSessions(List<VpnSession> sessions);
  Future<void> clearHistory();
}
