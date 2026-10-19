import '../entities/vpn_connection_state.dart';
import '../entities/vpn_live_metrics.dart';
import '../entities/vpn_server.dart';

/// Pure domain repository contract defining VPN tunnel capabilities
abstract class VpnRepository {
  Future<void> initialize();
  Future<bool> requestVpnPermission();
  Future<void> connect(VpnServer server);
  Future<void> disconnect();

  VpnConnectionState get currentState;
  Stream<VpnConnectionState> get stateStream;

  VpnLiveMetrics get currentMetrics;
  Stream<VpnLiveMetrics> get metricsStream;

  VpnServer? get currentServer;
  String? get lastError;

  void dispose();
}
