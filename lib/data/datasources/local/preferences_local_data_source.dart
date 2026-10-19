import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';

/// Local data source encapsulating persistent key-value storage via SharedPreferences
class PreferencesLocalDataSource {
  final SharedPreferences _prefs;

  PreferencesLocalDataSource(this._prefs);

  static Future<PreferencesLocalDataSource> create() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 2),
      );
      return PreferencesLocalDataSource(prefs);
    } catch (e) {
      debugPrint('PreferencesLocalDataSource init fallback: $e');
      final prefs = await SharedPreferences.getInstance();
      return PreferencesLocalDataSource(prefs);
    }
  }

  // VPN Consent
  bool get hasGrantedVpnConsent =>
      _prefs.getBool(AppConstants.keyVpnConsentGranted) ?? false;

  Future<bool> setVpnConsent(bool granted) =>
      _prefs.setBool(AppConstants.keyVpnConsentGranted, granted);

  // Authentication & Guest State
  bool get isAuthenticated =>
      _prefs.getBool(AppConstants.keyIsAuthenticated) ?? false;

  bool get isGuest => _prefs.getBool(AppConstants.keyIsGuest) ?? false;

  String? get userEmail => _prefs.getString(AppConstants.keyUserEmail);
  String? get userName => _prefs.getString(AppConstants.keyUserName);

  Future<void> saveAuth({
    required String email,
    required String name,
    required bool isGuest,
  }) async {
    await _prefs.setBool(AppConstants.keyIsAuthenticated, true);
    await _prefs.setBool(AppConstants.keyIsGuest, isGuest);
    await _prefs.setString(AppConstants.keyUserEmail, email);
    await _prefs.setString(AppConstants.keyUserName, name);
  }

  Future<void> clearAuth() async {
    await _prefs.remove(AppConstants.keyIsAuthenticated);
    await _prefs.remove(AppConstants.keyIsGuest);
    await _prefs.remove(AppConstants.keyUserEmail);
    await _prefs.remove(AppConstants.keyUserName);
  }

  // Favorites
  List<String> get favoriteServerIds =>
      _prefs.getStringList(AppConstants.keyFavorites) ?? [];

  Future<bool> toggleFavorite(String serverId) async {
    final list = List<String>.from(favoriteServerIds);
    if (list.contains(serverId)) {
      list.remove(serverId);
    } else {
      list.add(serverId);
    }
    return _prefs.setStringList(AppConstants.keyFavorites, list);
  }

  // Settings
  bool get autoConnect =>
      _prefs.getBool(AppConstants.keyAutoConnect) ?? false;

  Future<bool> setAutoConnect(bool val) =>
      _prefs.setBool(AppConstants.keyAutoConnect, val);

  bool get reconnectOnNetworkChange =>
      _prefs.getBool(AppConstants.keyReconnectOnNetwork) ?? true;

  Future<bool> setReconnectOnNetworkChange(bool val) =>
      _prefs.setBool(AppConstants.keyReconnectOnNetwork, val);

  String get preferredProtocol {
    final saved = _prefs.getString(AppConstants.keyPreferredProtocol);
    return saved ?? 'ShieldRoute Native (WireGuard-Optimized)';
  }

  Future<bool> setPreferredProtocol(String val) =>
      _prefs.setString(AppConstants.keyPreferredProtocol, val);

  bool get reduceMotion =>
      _prefs.getBool(AppConstants.keyReduceMotion) ?? false;

  Future<bool> setReduceMotion(bool val) =>
      _prefs.setBool(AppConstants.keyReduceMotion, val);

  bool get emulatorMode =>
      _prefs.getBool(AppConstants.keyEmulatorMode) ?? false;

  Future<bool> setEmulatorMode(bool val) =>
      _prefs.setBool(AppConstants.keyEmulatorMode, val);

  // Relay API Location & Custom Keys
  String get apiRegion =>
      _prefs.getString(AppConstants.keyApiRegion) ?? 'Global (Auto)';

  Future<bool> setApiRegion(String val) =>
      _prefs.setString(AppConstants.keyApiRegion, val);

  String? get customApiKey => _prefs.getString(AppConstants.keyCustomApiKey);

  Future<bool> setCustomApiKey(String? val) {
    if (val == null || val.trim().isEmpty) {
      return _prefs.remove(AppConstants.keyCustomApiKey);
    }
    return _prefs.setString(AppConstants.keyCustomApiKey, val.trim());
  }

  String? get customApiUrl => _prefs.getString(AppConstants.keyCustomApiUrl);

  Future<bool> setCustomApiUrl(String? val) {
    if (val == null || val.trim().isEmpty) {
      return _prefs.remove(AppConstants.keyCustomApiUrl);
    }
    return _prefs.setString(AppConstants.keyCustomApiUrl, val.trim());
  }

  bool get turboSpeedMode =>
      _prefs.getBool(AppConstants.keyTurboSpeed) ?? true;

  Future<bool> setTurboSpeedMode(bool val) =>
      _prefs.setBool(AppConstants.keyTurboSpeed, val);

  bool get autoFastestServer =>
      _prefs.getBool(AppConstants.keyAutoFastestServer) ?? true;

  Future<bool> setAutoFastestServer(bool val) =>
      _prefs.setBool(AppConstants.keyAutoFastestServer, val);

  bool get smartFailover =>
      _prefs.getBool(AppConstants.keySmartFailover) ?? true;

  Future<bool> setSmartFailover(bool val) =>
      _prefs.setBool(AppConstants.keySmartFailover, val);

  bool get killSwitch =>
      _prefs.getBool(AppConstants.keyKillSwitch) ?? false;

  Future<bool> setKillSwitch(bool val) =>
      _prefs.setBool(AppConstants.keyKillSwitch, val);

  // Sessions History
  List<Map<String, dynamic>> getSessionHistoryJson() {
    final raw = _prefs.getString(AppConstants.keySessionsHistory);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSessionHistoryJson(List<Map<String, dynamic>> sessions) async {
    final raw = jsonEncode(sessions);
    await _prefs.setString(AppConstants.keySessionsHistory, raw);
  }

  Future<void> clearHistory() async {
    await _prefs.remove(AppConstants.keySessionsHistory);
  }

  // Selected Server Cache
  String? get selectedServerJson =>
      _prefs.getString(AppConstants.keySelectedServer);

  Future<void> setSelectedServerJson(String json) =>
      _prefs.setString(AppConstants.keySelectedServer, json);
}
