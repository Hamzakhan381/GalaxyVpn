import '../data/datasources/platform/openvpn_platform_data_source.dart';
import 'vpn_service.dart';

export '../data/datasources/platform/openvpn_platform_data_source.dart';

/// Legacy OpenVpnService adapting to OpenVpnPlatformDataSource
class OpenVpnService extends OpenVpnPlatformDataSource implements VpnService {
  OpenVpnService({super.prefs});

  static String optimizeConfig(
    String rawConfig, {
    bool turboMode = true,
    bool killSwitch = false,
  }) => OpenVpnPlatformDataSource.optimizeConfig(
    rawConfig,
    turboMode: turboMode,
    killSwitch: killSwitch,
  );
}
