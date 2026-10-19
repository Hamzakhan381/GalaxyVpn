import '../../domain/entities/vpn_connection_state.dart';
import '../../domain/entities/vpn_live_metrics.dart';
import '../../domain/entities/vpn_server.dart';
import '../../domain/repositories/vpn_repository.dart';
import '../datasources/platform/vpn_platform_data_source.dart';

/// Concrete implementation of the domain VpnRepository interfacing with platform data source
class VpnRepositoryImpl implements VpnRepository {
  final VpnPlatformDataSource platformDataSource;

  VpnRepositoryImpl(this.platformDataSource);

  @override
  VpnConnectionState get currentState => platformDataSource.currentState;

  @override
  Stream<VpnConnectionState> get stateStream => platformDataSource.stateStream;

  @override
  VpnLiveMetrics get currentMetrics => platformDataSource.currentMetrics;

  @override
  Stream<VpnLiveMetrics> get metricsStream => platformDataSource.metricsStream;

  @override
  VpnServer? get currentServer => platformDataSource.currentServer;

  @override
  String? get lastError => platformDataSource.lastError;

  @override
  Future<void> initialize() => platformDataSource.initialize();

  @override
  Future<bool> requestVpnPermission() =>
      platformDataSource.requestVpnPermission();

  @override
  Future<void> connect(VpnServer server) =>
      platformDataSource.connect(server);

  @override
  Future<void> disconnect() => platformDataSource.disconnect();

  @override
  void dispose() => platformDataSource.dispose();
}
