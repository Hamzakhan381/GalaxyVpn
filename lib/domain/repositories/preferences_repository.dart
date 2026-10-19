/// Pure domain repository contract defining persistent configuration & preferences
abstract class PreferencesRepository {
  // VPN Consent
  bool get hasGrantedVpnConsent;
  Future<bool> setVpnConsent(bool granted);

  // Auth & Guest state
  bool get isAuthenticated;
  bool get isGuest;
  String? get userEmail;
  String? get userName;
  Future<void> saveAuth({
    required String email,
    required String name,
    required bool isGuest,
  });
  Future<void> clearAuth();

  // Favorites
  List<String> get favoriteServerIds;
  Future<bool> toggleFavorite(String serverId);

  // Connection settings
  bool get autoConnect;
  Future<bool> setAutoConnect(bool val);

  bool get reconnectOnNetworkChange;
  Future<bool> setReconnectOnNetworkChange(bool val);

  String get preferredProtocol;
  Future<bool> setPreferredProtocol(String val);

  bool get reduceMotion;
  Future<bool> setReduceMotion(bool val);

  bool get emulatorMode;
  Future<bool> setEmulatorMode(bool val);

  String get apiRegion;
  Future<bool> setApiRegion(String val);

  String? get customApiKey;
  Future<bool> setCustomApiKey(String? val);

  String? get customApiUrl;
  Future<bool> setCustomApiUrl(String? val);

  bool get turboSpeedMode;
  Future<bool> setTurboSpeedMode(bool val);

  bool get autoFastestServer;
  Future<bool> setAutoFastestServer(bool val);

  bool get smartFailover;
  Future<bool> setSmartFailover(bool val);

  bool get killSwitch;
  Future<bool> setKillSwitch(bool val);

  // Sessions history (raw JSON maps)
  List<Map<String, dynamic>> getSessionHistoryJson();
  Future<void> saveSessionHistoryJson(List<Map<String, dynamic>> sessions);
  Future<void> clearHistory();

  // Selected server cache
  String? get selectedServerJson;
  Future<void> setSelectedServerJson(String json);
}
