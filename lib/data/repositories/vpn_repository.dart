import '../../presentation/controllers/vpn_controller.dart';
export '../../presentation/controllers/vpn_controller.dart';

/// Legacy adapter for VpnRepository inheriting from Clean Architecture VpnController
class VpnRepository extends VpnController {
  VpnRepository({
    required super.vpnService,
    required super.serverService,
    required super.prefs,
  });
}
