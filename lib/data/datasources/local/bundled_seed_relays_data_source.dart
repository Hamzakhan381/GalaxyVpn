import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/vpn_server.dart';
import '../remote/server_remote_data_source.dart';

/// Offline fallback relays: a bundled snapshot of VPN Gate's official,
/// long-running `public-vpn-*` relays (operated by the VPN Gate project at
/// the University of Tsukuba).
///
/// The profiles are genuine VPN Gate OpenVPN configs taken from the public
/// catalog, so they can actually connect. They are only used when neither the
/// live catalog nor the cached last-good catalog is available.
class BundledSeedRelaysDataSource {
  BundledSeedRelaysDataSource._();

  static const String assetPath = 'assets/servers/vpngate_snapshot.csv';

  static Future<List<VpnServer>> loadServers({AssetBundle? bundle}) async {
    try {
      final csv = await (bundle ?? rootBundle).loadString(assetPath);
      return ServerRemoteDataSource.parseVpnGateCsvData(csv);
    } catch (e) {
      debugPrint('BundledSeedRelaysDataSource: snapshot unavailable: $e');
      return const [];
    }
  }
}
