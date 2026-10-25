import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/platform/android_system.dart';
import 'core/storage/preferences_service.dart';
import 'data/datasources/platform/unified_vpn_platform_data_source.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/connectivity_repository_impl.dart';
import 'data/repositories/server_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/connectivity_repository.dart';
import 'domain/repositories/preferences_repository.dart';
import 'features/common/motion.dart';
import 'presentation/controllers/vpn_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Last-resort handlers: an unexpected error is logged instead of taking the
  // app (and the user's view of their connection) down.
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('GalaxyVpnApp: uncaught error: $error\n$stack');
    return true;
  };
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Something went wrong showing this part of the screen.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
        ),
      ),
    );
  }

  debugPrint('GalaxyVpnApp: main() initializing...');

  SharedPreferences sharedPreferences;
  try {
    sharedPreferences = await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        debugPrint(
          'GalaxyVpnApp: SharedPreferences timeout - continuing with fallback',
        );
        return SharedPreferences.getInstance();
      },
    );
  } catch (e) {
    debugPrint('GalaxyVpnApp: SharedPreferences init error: $e');
    sharedPreferences = await SharedPreferences.getInstance();
  }

  final prefsService = PreferencesService(sharedPreferences);

  // First launch: start low-memory phones on lighter animations. The user can
  // change it any time under Settings › Animations.
  if (prefsService.motionLevel == null) {
    final lowEnd = await AndroidSystem.isLowEndDevice().timeout(
      const Duration(seconds: 1),
      onTimeout: () => false,
    );
    await prefsService.setMotionLevel(
      (lowEnd ? MotionLevel.lite : MotionLevel.full).name,
    );
  }
  final motionSettings = MotionSettings(prefsService);

  // Instantiate Clean Architecture platform and domain services
  final vpnService = UnifiedVpnPlatformDataSource(prefs: prefsService);
  unawaited(
    vpnService.initialize().catchError((e) {
      debugPrint('UnifiedVpnPlatformDataSource background init error: $e');
    }),
  );

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
      child: MotionScope(settings: motionSettings, child: const GalaxyVpnApp()),
    ),
  );
}
