import '../data/datasources/platform/native_vpn_platform_data_source.dart';
import '../data/datasources/platform/unified_vpn_platform_data_source.dart';
import 'openvpn_service.dart';
import 'vpn_service.dart';

export '../data/datasources/platform/unified_vpn_platform_data_source.dart';

/// Legacy UnifiedVpnService adapting to UnifiedVpnPlatformDataSource
class UnifiedVpnService extends UnifiedVpnPlatformDataSource
    implements VpnService {
  UnifiedVpnService({
    required super.prefs,
    OpenVpnService? openVpnService,
    NativeVpnPlatformDataSource? nativeVpnService,
  }) : super(
         openVpnSource: openVpnService,
         nativeVpnSource: nativeVpnService,
       );
}
