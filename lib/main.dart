import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/storage/preferences_service.dart';
import 'data/repositories/vpn_repository.dart';
import 'domain/repositories/preferences_repository.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/server_service.dart';
import 'services/unified_vpn_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent GoogleFonts from attempting network downloads during startup or offline
  GoogleFonts.config.allowRuntimeFetching = false;

  debugPrint('ShieldRouteApp: main() initializing...');

  SharedPreferences sharedPreferences;
  try {
    sharedPreferences = await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        debugPrint('ShieldRouteApp: SharedPreferences timeout - continuing with fallback');
        return SharedPreferences.getInstance();
      },
    );
  } catch (e) {
    debugPrint('ShieldRouteApp: SharedPreferences init error: $e');
    sharedPreferences = await SharedPreferences.getInstance();
  }

  final prefsService = PreferencesService(sharedPreferences);

  // Instantiate Clean Architecture platform and domain services
  final vpnService = UnifiedVpnService(prefs: prefsService);
  unawaited(vpnService.initialize().catchError((e) {
    debugPrint('UnifiedVpnService background init error: $e');
  }));

  final serverService = DefaultServerService(prefsService);
  final authService = LocalAuthService(prefsService);
  final connectivityService = DefaultConnectivityService();

  // Instantiate presentation controller & repository
  final vpnRepository = VpnRepository(
    vpnService: vpnService,
    serverService: serverService,
    prefs: prefsService,
  );

  debugPrint('ShieldRouteApp: calling runApp()...');

  runApp(
    MultiProvider(
      providers: [
        Provider<PreferencesRepository>.value(value: prefsService),
        Provider<PreferencesService>.value(value: prefsService),
        Provider<AuthRepository>.value(value: authService),
        Provider<AuthService>.value(value: authService),
        Provider<ConnectivityRepository>.value(value: connectivityService),
        Provider<ConnectivityService>.value(value: connectivityService),
        ChangeNotifierProvider<VpnController>.value(value: vpnRepository),
        ChangeNotifierProvider<VpnRepository>.value(value: vpnRepository),
      ],
      child: const ShieldRouteApp(),
    ),
  );
}
