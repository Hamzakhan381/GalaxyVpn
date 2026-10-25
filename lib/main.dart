import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'core/storage/preferences_service.dart';
import 'data/datasources/platform/unified_vpn_platform_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/connectivity_repository_impl.dart';
import 'data/repositories/server_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/connectivity_repository.dart';
import 'domain/repositories/preferences_repository.dart';
import 'presentation/controllers/vpn_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent GoogleFonts from attempting network downloads during startup or offline
  GoogleFonts.config.allowRuntimeFetching = false;

  debugPrint('GalaxyVpnApp: main() initializing...');

  SharedPreferences sharedPreferences;
  try {
    sharedPreferences = await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        debugPrint('GalaxyVpnApp: SharedPreferences timeout - continuing with fallback');
        return SharedPreferences.getInstance();
      },
    );
  } catch (e) {
    debugPrint('GalaxyVpnApp: SharedPreferences init error: $e');
    sharedPreferences = await SharedPreferences.getInstance();
  }

  final prefsService = PreferencesService(sharedPreferences);

  // Instantiate Clean Architecture platform and domain services
  final vpnService = UnifiedVpnPlatformDataSource(prefs: prefsService);
  unawaited(vpnService.initialize().catchError((e) {
    debugPrint('UnifiedVpnPlatformDataSource background init error: $e');
  }));

  final serverRepository = ServerRepositoryImpl(preferencesRepo: prefsService);
  final authRepository = AuthRepositoryImpl(prefsService);
  final connectivityRepository = ConnectivityRepositoryImpl();

  // Instantiate presentation controller
  final vpnController = VpnController(
    vpnService: vpnService,
    serverService: serverRepository,
    prefs: prefsService,
  );

  debugPrint('GalaxyVpnApp: calling runApp()...');

  runApp(
    MultiProvider(
      providers: [
        Provider<PreferencesRepository>.value(value: prefsService),
        Provider<PreferencesService>.value(value: prefsService),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<ConnectivityRepository>.value(value: connectivityRepository),
        ChangeNotifierProvider<VpnController>.value(value: vpnController),
      ],
      child: const GalaxyVpnApp(),
    ),
  );
}
