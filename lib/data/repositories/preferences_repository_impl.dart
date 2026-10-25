import '../../domain/repositories/preferences_repository.dart';
import '../datasources/local/preferences_local_data_source.dart';

/// Concrete implementation of PreferencesRepository delegating to PreferencesLocalDataSource
class PreferencesRepositoryImpl implements PreferencesRepository {
  final PreferencesLocalDataSource _dataSource;

  PreferencesRepositoryImpl(this._dataSource);

  @override
  bool get hasGrantedVpnConsent => _dataSource.hasGrantedVpnConsent;

  @override
  Future<bool> setVpnConsent(bool granted) =>
      _dataSource.setVpnConsent(granted);

  @override
  bool get isAuthenticated => _dataSource.isAuthenticated;

  @override
  bool get isGuest => _dataSource.isGuest;

  @override
  String? get userEmail => _dataSource.userEmail;

  @override
  String? get userName => _dataSource.userName;

  @override
  Future<void> saveAuth({
    required String email,
    required String name,
    required bool isGuest,
  }) => _dataSource.saveAuth(email: email, name: name, isGuest: isGuest);

  @override
  Future<void> clearAuth() => _dataSource.clearAuth();

  @override
  List<String> get favoriteServerIds => _dataSource.favoriteServerIds;

  @override
  Future<bool> toggleFavorite(String serverId) =>
      _dataSource.toggleFavorite(serverId);

  @override
  bool get autoConnect => _dataSource.autoConnect;

  @override
  Future<bool> setAutoConnect(bool val) => _dataSource.setAutoConnect(val);

  @override
  bool get reconnectOnNetworkChange => _dataSource.reconnectOnNetworkChange;

  @override
  Future<bool> setReconnectOnNetworkChange(bool val) =>
      _dataSource.setReconnectOnNetworkChange(val);

  @override
  String get preferredProtocol => _dataSource.preferredProtocol;

  @override
  Future<bool> setPreferredProtocol(String val) =>
      _dataSource.setPreferredProtocol(val);

  @override
  bool get reduceMotion => _dataSource.reduceMotion;

  @override
  Future<bool> setReduceMotion(bool val) => _dataSource.setReduceMotion(val);

  @override
  String? get motionLevel => _dataSource.motionLevel;

  @override
  Future<bool> setMotionLevel(String level) =>
      _dataSource.setMotionLevel(level);

  @override
  bool get emulatorMode => _dataSource.emulatorMode;

  @override
  Future<bool> setEmulatorMode(bool val) => _dataSource.setEmulatorMode(val);

  @override
  String get apiRegion => _dataSource.apiRegion;

  @override
  Future<bool> setApiRegion(String val) => _dataSource.setApiRegion(val);

  @override
  String? get customApiKey => _dataSource.customApiKey;

  @override
  Future<bool> setCustomApiKey(String? val) => _dataSource.setCustomApiKey(val);

  @override
  String? get customApiUrl => _dataSource.customApiUrl;

  @override
  Future<bool> setCustomApiUrl(String? val) => _dataSource.setCustomApiUrl(val);

  @override
  bool get turboSpeedMode => _dataSource.turboSpeedMode;

  @override
  Future<bool> setTurboSpeedMode(bool val) =>
      _dataSource.setTurboSpeedMode(val);

  @override
  bool get autoFastestServer => _dataSource.autoFastestServer;

  @override
  Future<bool> setAutoFastestServer(bool val) =>
      _dataSource.setAutoFastestServer(val);

  @override
  bool get smartFailover => _dataSource.smartFailover;

  @override
  Future<bool> setSmartFailover(bool val) => _dataSource.setSmartFailover(val);

  @override
  bool get killSwitch => _dataSource.killSwitch;

  @override
  Future<bool> setKillSwitch(bool val) => _dataSource.setKillSwitch(val);

  @override
  bool get ipRotationEnabled => _dataSource.ipRotationEnabled;

  @override
  Future<bool> setIpRotationEnabled(bool val) =>
      _dataSource.setIpRotationEnabled(val);

  @override
  int get ipRotationMinutes => _dataSource.ipRotationMinutes;

  @override
  Future<bool> setIpRotationMinutes(int minutes) =>
      _dataSource.setIpRotationMinutes(minutes);

  @override
  bool get ipRotationSameCountry => _dataSource.ipRotationSameCountry;

  @override
  Future<bool> setIpRotationSameCountry(bool val) =>
      _dataSource.setIpRotationSameCountry(val);

  @override
  List<Map<String, dynamic>> getSessionHistoryJson() =>
      _dataSource.getSessionHistoryJson();

  @override
  Future<void> saveSessionHistoryJson(List<Map<String, dynamic>> sessions) =>
      _dataSource.saveSessionHistoryJson(sessions);

  @override
  Future<void> clearHistory() => _dataSource.clearHistory();

  @override
  String? get selectedServerJson => _dataSource.selectedServerJson;

  @override
  String? get cachedRelayCatalog => _dataSource.cachedRelayCatalog;

  @override
  Future<void> setCachedRelayCatalog(String json) =>
      _dataSource.setCachedRelayCatalog(json);

  @override
  Future<void> setSelectedServerJson(String json) =>
      _dataSource.setSelectedServerJson(json);
}
