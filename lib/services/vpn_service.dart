import '../data/datasources/platform/vpn_platform_data_source.dart';
export '../domain/entities/vpn_connection_state.dart';
export '../domain/entities/vpn_live_metrics.dart';

/// Legacy VpnService abstract contract extending platform data source contract
abstract class VpnService implements VpnPlatformDataSource {}
