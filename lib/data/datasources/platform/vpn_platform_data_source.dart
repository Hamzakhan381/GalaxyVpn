import '../../../domain/entities/vpn_connection_state.dart';
import '../../../domain/entities/vpn_live_metrics.dart';
import '../../../domain/entities/vpn_server.dart';

/// Contract for underlying platform VPN engines (Android native tunnel, OpenVPN engine)
abstract class VpnPlatformDataSource {
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
