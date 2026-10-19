import '../../domain/entities/vpn_server.dart';
import '../datasources/local/bundled_seed_relays_data_source.dart';
export '../datasources/local/bundled_seed_relays_data_source.dart';

class BundledSeedRelays {
  BundledSeedRelays._();

  static Future<List<VpnServer>> getServers() =>
      BundledSeedRelaysDataSource.loadServers();
}
