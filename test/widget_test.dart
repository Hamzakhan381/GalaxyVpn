import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_vpn/app/theme/app_theme.dart';
import 'package:galaxy_vpn/core/storage/preferences_service.dart';
import 'package:galaxy_vpn/data/repositories/auth_repository_impl.dart';
import 'package:galaxy_vpn/data/repositories/server_repository_impl.dart';
import 'package:galaxy_vpn/domain/entities/vpn_connection_state.dart';
import 'package:galaxy_vpn/domain/entities/vpn_server.dart';
import 'package:galaxy_vpn/domain/repositories/auth_repository.dart';
import 'package:galaxy_vpn/features/auth/login_view.dart';
import 'package:galaxy_vpn/features/common/connection_orb.dart';
import 'package:galaxy_vpn/features/common/connection_status_badge.dart';
import 'package:galaxy_vpn/features/common/cyber_background.dart';
import 'package:galaxy_vpn/features/common/fastest_server_card.dart';
import 'package:galaxy_vpn/features/common/galaxy_starfield.dart';
import 'package:galaxy_vpn/features/common/server_list_tile.dart';
import 'package:galaxy_vpn/features/onboarding/vpn_disclosure_view.dart';
import 'package:galaxy_vpn/features/onboarding/welcome_view.dart';
import 'package:galaxy_vpn/presentation/controllers/vpn_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'unit/vpn_state_machine_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesService prefs;
  late AuthRepositoryImpl auth;
  late MockVpnService mockVpn;
  late ServerRepositoryImpl serverService;
  late VpnController repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await PreferencesService.create();
    auth = AuthRepositoryImpl(prefs);
    mockVpn = MockVpnService();
    serverService = ServerRepositoryImpl(preferencesRepo: prefs);
    repository = VpnController(
      vpnService: mockVpn,
      serverService: serverService,
      prefs: prefs,
    );
  });

  Widget buildTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        Provider<PreferencesService>.value(value: prefs),
        Provider<AuthRepository>.value(value: auth),
        ChangeNotifierProvider<VpnController>.value(value: repository),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  group('Widget and UI Interaction Tests', () {
    testWidgets('Welcome view displays brand title and action triggers',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget(const WelcomeView()));
      await tester.pumpAndSettle();

      expect(find.text('Galaxy VPN'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);
    });

    testWidgets(
        'VPN disclosure checkbox is UNCHECKED on start and disables Continue button (PHASE 9 requirement)',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget(const VpnDisclosureView()));
      await tester.pumpAndSettle();

      // Verify core disclosure text
      expect(
        find.textContaining("Galaxy VPN uses Android's VPN service"),
        findsOneWidget,
      );

      // Verify consent checkbox text
      expect(
        find.text('I understand how VPN access is used.'),
        findsOneWidget,
      );

      // Checkbox must NOT be preselected
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);
      Checkbox checkbox = tester.widget<Checkbox>(checkboxFinder);
      expect(checkbox.value, isFalse);

      // Continue button must be disabled when checkbox is unchecked
      final continueButton = find.widgetWithText(ElevatedButton, 'Continue to Galaxy VPN');
      expect(continueButton, findsOneWidget);
      ElevatedButton btn = tester.widget<ElevatedButton>(continueButton);
      expect(btn.onPressed, isNull);

      // Tap checkbox to give consent
      await tester.ensureVisible(checkboxFinder);
      await tester.pumpAndSettle();
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Checkbox is now checked and button is enabled
      checkbox = tester.widget<Checkbox>(checkboxFinder);
      expect(checkbox.value, isTrue);

      btn = tester.widget<ElevatedButton>(continueButton);
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('Login view validates email and password inputs',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginView()));
      await tester.pumpAndSettle();

      // Tap Sign In without filling inputs
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email.'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters.'), findsOneWidget);
    });

    testWidgets('ConnectionStatusBadge renders correct labels and states',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Column(
            children: [
              ConnectionStatusBadge(state: VpnConnectionState.disconnected),
              ConnectionStatusBadge(state: VpnConnectionState.connected),
              ConnectionStatusBadge(state: VpnConnectionState.connecting),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('UNPROTECTED'), findsOneWidget);
      expect(find.text('PROTECTED'), findsOneWidget);
      expect(find.text('CONNECTING...'), findsOneWidget);
    });

    testWidgets('ConnectionOrb reacts to user tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestableWidget(
          ConnectionOrb(
            state: VpnConnectionState.disconnected,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONNECT'), findsOneWidget);
      await tester.tap(find.byType(ConnectionOrb));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('CyberBackground renders dynamic VPN video effect and child content', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CyberBackground(
            vpnState: VpnConnectionState.connected,
            child: Text('Protected Surface'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Protected Surface'), findsOneWidget);
    });

    testWidgets('ConnectionOrb renders CONNECTING state with gyroscopic radar and telemetry', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          ConnectionOrb(
            state: VpnConnectionState.connecting,
            onTap: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('CONNECTING'), findsOneWidget);
    });

    testWidgets('ConnectionOrb surrounds itself with a galaxy starfield once connected', (tester) async {
      Widget orb(VpnConnectionState state) =>
          buildTestableWidget(ConnectionOrb(state: state, onTap: () {}));

      await tester.pumpWidget(orb(VpnConnectionState.connecting));
      await tester.pump();
      expect(
        tester.widget<GalaxyStarfield>(find.byType(GalaxyStarfield)).active,
        isFalse,
      );

      await tester.pumpWidget(orb(VpnConnectionState.connected));
      await tester.pumpAndSettle();
      expect(find.text('DISCONNECT'), findsOneWidget);
      expect(
        tester.widget<GalaxyStarfield>(find.byType(GalaxyStarfield)).active,
        isTrue,
      );
    });

    testWidgets('FastestServerCard renders safely without visual or test regressions', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          FastestServerCard(
            vpnRepo: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FastestServerCard), findsOneWidget);
    });

    testWidgets('ServerListTile keeps the country visible and only says Connected when connected', (tester) async {
      final server = VpnServer(
        id: 'srv_jp',
        country: 'Japan',
        countryCode: 'JP',
        city: 'public-vpn-147',
        host: '219.100.37.119',
        port: 443,
        protocol: 'TCP',
        pingMs: 9,
        score: 900000,
        ovpnConfig: 'client\ndev tun\n',
        lastChecked: DateTime(2026, 1, 1),
      );
      Widget tile({required bool connected}) => buildTestableWidget(
        Scaffold(
          body: ServerListTile(
            server: server,
            isSelected: true,
            isConnected: connected,
            isFastest: true,
            onTap: () {},
            onFavoriteTap: () {},
          ),
        ),
      );

      await tester.pumpWidget(tile(connected: false));
      await tester.pumpAndSettle();
      expect(find.text('Japan'), findsOneWidget);
      expect(find.text('public-vpn-147'), findsOneWidget);
      expect(find.text('Connected'), findsNothing);
      // Merged into the tile's tap target, so TalkBack reads it with the tile.
      expect(find.bySemanticsLabel(RegExp('Fastest server')), findsOneWidget);

      await tester.pumpWidget(tile(connected: true));
      await tester.pumpAndSettle();
      expect(find.text('Japan'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
    });
  });
}
