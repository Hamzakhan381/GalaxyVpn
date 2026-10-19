import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class ShieldRouteApp extends StatelessWidget {
  const ShieldRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.splash,
      routes: AppRouter.routes,
    );
  }
}
