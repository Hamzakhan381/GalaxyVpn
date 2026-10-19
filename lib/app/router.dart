import 'package:flutter/material.dart';
import '../features/auth/login_view.dart';
import '../features/auth/signup_view.dart';
import '../features/home/main_navigation_shell.dart';
import '../features/onboarding/vpn_disclosure_view.dart';
import '../features/onboarding/welcome_view.dart';
import '../features/privacy/privacy_center_view.dart';
import '../features/settings/profile_view.dart';
import '../features/splash/splash_view.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String disclosure = '/disclosure';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String privacy = '/privacy';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashView(),
        welcome: (_) => const WelcomeView(),
        login: (_) => const LoginView(),
        signup: (_) => const SignUpView(),
        disclosure: (_) => const VpnDisclosureView(),
        home: (_) => const MainNavigationShell(),
        profile: (_) => const ProfileView(),
        privacy: (_) => const PrivacyCenterView(),
      };
}
