import '../data/datasources/platform/native_vpn_platform_data_source.dart';
import 'vpn_service.dart';

export '../data/datasources/platform/native_vpn_platform_data_source.dart';

/// Legacy NativeVpnService adapting to NativeVpnPlatformDataSource
class NativeVpnService extends NativeVpnPlatformDataSource
    implements VpnService {}
