import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldroute_vpn/app/theme/app_theme.dart';
import 'package:shieldroute_vpn/core/storage/preferences_service.dart';
import 'package:shieldroute_vpn/data/repositories/vpn_repository.dart';
import 'package:shieldroute_vpn/domain/repositories/connectivity_repository.dart';
import 'package:shieldroute_vpn/features/splash/splash_view.dart';
import 'package:shieldroute_vpn/services/auth_service.dart';
import 'package:shieldroute_vpn/services/server_service.dart';

import 'unit/vpn_state_machine_test.dart';

class _MockConnectivityRepository implements ConnectivityRepository {
  final _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> checkInternetAccess() async => true;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  void dispose() {
    _controller.close();
  }
}

void main() {
  late PreferencesService prefs;
  late LocalAuthService auth;
  late MockVpnService mockVpn;
  late DefaultServerService serverService;
  late VpnRepository repository;
  late _MockConnectivityRepository connectivity;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await PreferencesService.create();
    auth = LocalAuthService(prefs);
    mockVpn = MockVpnService();
    serverService = DefaultServerService(prefs);
    connectivity = _MockConnectivityRepository();
    repository = VpnRepository(
      vpnService: mockVpn,
      serverService: serverService,
      prefs: prefs,
    );
  });

  tearDown(() {
    connectivity.dispose();
  });

  Widget buildSplashApp() {
    return MultiProvider(
      providers: [
        Provider<PreferencesService>.value(value: prefs),
        Provider<AuthService>.value(value: auth),
        Provider<ConnectivityRepository>.value(value: connectivity),
        ChangeNotifierProvider<VpnRepository>.value(value: repository),
      ],
      child: MaterialApp(theme: AppTheme.lightTheme, home: const SplashView()),
    );
  }

  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('SplashView animates in brand, tagline and status', (
    tester,
  ) async {
    useTallScreen(tester);

    await tester.pumpWidget(buildSplashApp());
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pump(const Duration(milliseconds: 850));

    expect(find.text('Shark VPN'), findsOneWidget);
    expect(find.text('SECURE  •  PRIVATE  •  FAST'), findsOneWidget);
    expect(find.textContaining('relay'), findsOneWidget);

    // Let the splash finish and hand off so no timers are left pending.
    await tester.pump(const Duration(seconds: 7));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('SplashView stays on screen for at least five seconds', (
    tester,
  ) async {
    useTallScreen(tester);

    await tester.pumpWidget(buildSplashApp());
    for (int i = 0; i < 49; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(SplashView), findsOneWidget);
    expect(find.text('Create Account'), findsNothing);

    await tester.pump(const Duration(seconds: 7));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('SplashView hands off to WelcomeView for signed-out users', (
    tester,
  ) async {
    useTallScreen(tester);

    await tester.pumpWidget(buildSplashApp());
    await tester.pump(const Duration(seconds: 7));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });

  testWidgets(
    'SplashView renders without overflow on compact screen and high font scale',
    (tester) async {
      // Compact screen height (e.g. 520px height) and high text scale
      tester.view.physicalSize = const Size(1080, 1560);
      tester.view.devicePixelRatio = 3.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await tester.pumpWidget(buildSplashApp());
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 1200));

      expect(find.text('Shark VPN'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 7));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'SplashView hands off to VpnDisclosureView when authenticated without consent',
    (tester) async {
      useTallScreen(tester);
      await prefs.saveAuth(
        email: 'test@example.com',
        name: 'Test User',
        isGuest: false,
      );
      await prefs.setVpnConsent(false);

      await tester.pumpWidget(buildSplashApp());
      await tester.pump(const Duration(seconds: 7));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('VpnService'), findsWidgets);
    },
  );

  testWidgets(
    'SplashView hands off to MainNavigationShell when authenticated with consent',
    (tester) async {
      useTallScreen(tester);
      await prefs.saveAuth(
        email: 'test@example.com',
        name: 'Test User',
        isGuest: false,
      );
      await prefs.setVpnConsent(true);

      await tester.pumpWidget(buildSplashApp());
      await tester.pump(const Duration(seconds: 7));
      await tester.pump(const Duration(seconds: 1));

      // Home screen has the main connection orb / status
      expect(find.text('UNPROTECTED'), findsOneWidget);
    },
  );
}
