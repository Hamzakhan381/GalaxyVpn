import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android system screens and permissions outside the VPN engines, served by
/// MainActivity on the native engine channel.
class AndroidSystem {
  AndroidSystem._();

  static const MethodChannel _channel = MethodChannel(
    'com.galaxyvpn/native_engine',
  );

  /// Opens Android's VPN settings, where the user turns on Always-on VPN and
  /// "Block connections without VPN", the system-level kill switch.
  static Future<bool> openVpnSettings() => _call('openVpnSettings');

  /// Asks for the notification permission (Android 13+) so the connection
  /// notification and its Disconnect action can be shown. Android itself
  /// stops showing the prompt after the user declines it twice.
  static Future<bool> requestNotificationPermission() =>
      _call('requestNotificationPermission');

  /// Sends the app to the background like the Home button, keeping it alive
  /// so reopening is instant. Returns false where unsupported.
  static Future<bool> moveToBackground() => _call('moveToBackground');

  /// Whether this phone has little memory and should use lighter animations.
  static Future<bool> isLowEndDevice() => _call('isLowEndDevice');

  /// Completes once the OpenVPN plugin is attached. It loads its native
  /// libraries on a background thread after launch, so its channels do not
  /// exist for the first moments of the app's life.
  static Future<void> waitForVpnEngine() =>
      _call('waitForVpnEngine')
          .timeout(const Duration(seconds: 20), onTimeout: () => false);

  static Future<bool> _call(String method) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('AndroidSystem.$method failed: $e');
      return false;
    }
  }
}
