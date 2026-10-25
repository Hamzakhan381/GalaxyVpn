import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/datasources/platform/vpn_platform_data_source.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../data/repositories/vpn_repository_impl.dart';
import '../../domain/entities/vpn_connection_state.dart';
import '../../domain/entities/vpn_live_metrics.dart';
import '../../domain/entities/vpn_server.dart';
import '../../domain/entities/vpn_session.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../../domain/repositories/server_repository.dart';
import '../../domain/repositories/vpn_repository.dart';
import '../../domain/usecases/servers/detect_fastest_server_usecase.dart';
import '../../domain/usecases/servers/get_servers_usecase.dart';
import '../../domain/usecases/servers/pick_best_per_country_usecase.dart';
import '../../domain/usecases/servers/probe_server_latencies_usecase.dart';
import '../../domain/usecases/servers/toggle_favorite_server_usecase.dart';
import '../../domain/usecases/sessions/clear_session_history_usecase.dart';
import '../../domain/usecases/sessions/get_session_history_usecase.dart';
import '../../domain/usecases/sessions/save_session_history_usecase.dart';
import '../../domain/usecases/vpn/connect_vpn_usecase.dart';
import '../../domain/usecases/vpn/disconnect_vpn_usecase.dart';
import '../../domain/usecases/vpn/get_vpn_metrics_stream_usecase.dart';
import '../../domain/usecases/vpn/get_vpn_state_stream_usecase.dart';

/// Clean Architecture Presentation Controller managing VPN state, active metrics,
/// server selection, and session history recording.
class VpnController extends ChangeNotifier {
  final VpnPlatformDataSource vpnService;
  final ServerRepository serverService;
  final PreferencesRepository prefs;

  // Domain Use cases
  late final ConnectVpnUseCase _connectVpnUseCase;
  late final DisconnectVpnUseCase _disconnectVpnUseCase;
  late final GetVpnStateStreamUseCase _getVpnStateStreamUseCase;
  late final GetVpnMetricsStreamUseCase _getVpnMetricsStreamUseCase;
  late final GetServersUseCase _getServersUseCase;
  late final ToggleFavoriteServerUseCase _toggleFavoriteUseCase;
  late final DetectFastestServerUseCase _detectFastestUseCase;
  late final PickBestPerCountryUseCase _pickBestPerCountryUseCase;
  late final ProbeServerLatenciesUseCase _probeServerLatenciesUseCase;
  late final GetSessionHistoryUseCase _getSessionHistoryUseCase;
  late final SaveSessionHistoryUseCase _saveSessionHistoryUseCase;
  late final ClearSessionHistoryUseCase _clearSessionHistoryUseCase;

  bool get _isTestEnvironment {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  VpnServer? _selectedServer;
  bool _hasUserSelectedServer = false;
  VpnServer? _fastestServer;
  bool _isDetectingFastest = false;
  DateTime? _lastFastestDetectionTime;
  List<VpnServer> _allServers = [];

  /// The fastest relay of each country: what the user picks from. The other
  /// relays in [_allServers] stay as same-country failover alternates.
  List<VpnServer> _countryServers = [];
  List<VpnSession> _sessions = [];
  bool _isLoadingServers = false;
  String? _serverLoadError;

  DateTime? _sessionStartTime;
  String? _activeSessionId;

  // IP rotation: while connected, periodically move to the fastest relay
  // with a different address.
  static const List<int> ipRotationIntervals = [1, 3, 5, 10, 15, 30];
  static const int _recentRotationLimit = 4;
  Timer? _rotationTimer;
  DateTime? _nextRotationAt;
  bool _rotationInProgress = false;
  bool _connectedByRotation = false;
  final List<String> _recentRotationHosts = [];

  late StreamSubscription<VpnConnectionState> _stateSub;
  late StreamSubscription<VpnLiveMetrics> _metricsSub;

  VpnController({
    required this.vpnService,
    required this.serverService,
    required this.prefs,
  }) {
    _initUseCases();
    _loadStoredSessions();
    _initStreams();
  }

  void _initUseCases() {
    final vpnRepo = vpnService is VpnRepository
        ? (vpnService as VpnRepository)
        : VpnRepositoryImpl(vpnService);
    _connectVpnUseCase = ConnectVpnUseCase(vpnRepo);
    _disconnectVpnUseCase = DisconnectVpnUseCase(vpnRepo);
    _getVpnStateStreamUseCase = GetVpnStateStreamUseCase(vpnRepo);
    _getVpnMetricsStreamUseCase = GetVpnMetricsStreamUseCase(vpnRepo);
    _getServersUseCase = GetServersUseCase(serverService);
    _toggleFavoriteUseCase = ToggleFavoriteServerUseCase(serverService);
    _detectFastestUseCase = DetectFastestServerUseCase(serverService);
    _pickBestPerCountryUseCase = PickBestPerCountryUseCase(serverService);
    _probeServerLatenciesUseCase = ProbeServerLatenciesUseCase(serverService);
    final sessionRepo = SessionRepositoryImpl(prefs);
    _getSessionHistoryUseCase = GetSessionHistoryUseCase(sessionRepo);
    _saveSessionHistoryUseCase = SaveSessionHistoryUseCase(sessionRepo);
    _clearSessionHistoryUseCase = ClearSessionHistoryUseCase(sessionRepo);
  }

  VpnConnectionState get connectionState => vpnService.currentState;
  VpnLiveMetrics get liveMetrics => vpnService.currentMetrics;
  VpnServer? get selectedServer => _selectedServer;
  VpnServer? get fastestServer => _fastestServer;
  bool get isDetectingFastest => _isDetectingFastest;
  DateTime? get lastFastestDetectionTime => _lastFastestDetectionTime;
  List<VpnServer> get allServers => _allServers;
  List<VpnServer> get countryServers => _countryServers;
  bool get ipRotationEnabled => prefs.ipRotationEnabled;
  int get ipRotationMinutes => prefs.ipRotationMinutes;
  bool get ipRotationSameCountry => prefs.ipRotationSameCountry;

  /// When the next automatic IP change is due, or null when none is pending.
  DateTime? get nextRotationAt => _nextRotationAt;

  /// True while rotation is swapping relays (the tunnel is briefly down).
  bool get isRotatingIp => _rotationInProgress;

  /// Whether the current connection came from an automatic IP change.
  bool get connectedByRotation => _connectedByRotation;
  List<VpnSession> get sessions => List.unmodifiable(_sessions);
  bool get isLoadingServers => _isLoadingServers;
  String? get serverLoadError => _serverLoadError;
  String? get vpnError => vpnService.lastError;

  void _loadStoredSessions() {
    try {
      _sessions = _getSessionHistoryUseCase();
    } catch (e) {
      debugPrint('VpnController _loadStoredSessions error: $e');
      _sessions = [];
    }
  }

  void _initStreams() {
    _stateSub = _getVpnStateStreamUseCase().listen((state) {
      _handleStateChange(state);
      notifyListeners();
    });

    _metricsSub = _getVpnMetricsStreamUseCase().listen((_) {
      notifyListeners();
    });
  }

  // Smart failover: after a failed attempt, try the next best relays.
  static const int _maxFailoverAttempts = 3;
  bool _failoverActive = false;
  final Set<String> _failoverTried = {};

  bool _failoverPending = false;

  void _maybeFailover() {
    if (_failoverPending) return;
    if (!_failoverActive ||
        !prefs.smartFailover ||
        _failoverTried.length > _maxFailoverAttempts) {
      _failoverActive = false;
      return;
    }
    final remaining = _allServers
        .where((s) => s.isAvailable && !_failoverTried.contains(s.id))
        .toList();
    // Stay in the country the user chose; only an automatic choice may move
    // on to the next fastest country.
    final country = _selectedServer?.countryCode;
    final sameCountry = remaining
        .where((s) => s.countryCode == country)
        .toList();
    final pool = sameCountry.isNotEmpty || _hasUserSelectedServer
        ? sameCountry
        : _pickBestPerCountryUseCase(remaining);
    if (pool.isEmpty) {
      _failoverActive = false;
      return;
    }
    final next = _detectFastestUseCase(pool)!;
    _failoverTried.add(next.id);
    _selectedServer = next;
    // Give the engine time to finish tearing down the failed tunnel.
    _failoverPending = true;
    Future<void>.delayed(const Duration(milliseconds: 800), () async {
      _failoverPending = false;
      if (!_failoverActive || _isDisposed) return;
      await _connectVpnUseCase(next);
    });
  }

  void _handleStateChange(VpnConnectionState state) {
    if (state == VpnConnectionState.connected) {
      _failoverActive = false;
    } else if (state == VpnConnectionState.error) {
      _maybeFailover();
    }
    _updateRotation(state);
    if (state == VpnConnectionState.connected && _sessionStartTime == null) {
      _sessionStartTime = DateTime.now();
      _activeSessionId = const Uuid().v4();
    } else if (state == VpnConnectionState.disconnected &&
        _sessionStartTime != null) {
      _recordCompletedSession(status: 'disconnected');
    } else if (state == VpnConnectionState.error && _sessionStartTime != null) {
      _recordCompletedSession(
        status: 'failed',
        reason: vpnService.lastError ?? 'Connection interrupted',
      );
    }
  }

  Future<void> _recordCompletedSession({
    required String status,
    String? reason,
  }) async {
    if (_sessionStartTime == null || _activeSessionId == null) return;

    final endedAt = DateTime.now();
    final durationSeconds = endedAt.difference(_sessionStartTime!).inSeconds;
    final metrics = vpnService.currentMetrics;

    final session = VpnSession(
      id: _activeSessionId!,
      serverId: _selectedServer?.id ?? 'unknown',
      serverName: _selectedServer?.country ?? 'Custom Relay',
      startedAt: _sessionStartTime!,
      endedAt: endedAt,
      durationSeconds: durationSeconds > 0 ? durationSeconds : 1,
      bytesReceived: metrics.byteIn,
      bytesSent: metrics.byteOut,
      status: status,
      failureReason: reason,
    );

    _sessions.insert(0, session);
    _sessionStartTime = null;
    _activeSessionId = null;

    await _saveSessionHistoryUseCase(_sessions);
    notifyListeners();
  }

  Future<void> loadServers({bool forceRefresh = false}) async {
    _isLoadingServers = true;
    _serverLoadError = null;
    notifyListeners();

    try {
      _allServers = await _getServersUseCase(forceRefresh: forceRefresh);
      if (_allServers.isNotEmpty) {
        _countryServers = _pickCountries();
        _fastestServer = _detectFastestUseCase(_countryServers);
        if (_selectedServer != null) {
          _selectedServer = _allServers.firstWhere(
            (server) => server.id == _selectedServer!.id,
            orElse: () => _allServers.first,
          );
        } else {
          final restoredId = _restoredServerId();
          final oldVpnGateHost =
              restoredId != null &&
                  restoredId.startsWith('vpngate_') &&
                  !restoredId.contains('_tcp') &&
                  !restoredId.contains('_udp')
              ? restoredId.substring('vpngate_'.length)
              : null;
          _selectedServer = restoredId == null
              ? _allServers.first
              : _allServers.firstWhere(
                  (server) =>
                      server.id == restoredId ||
                      (oldVpnGateHost != null && server.host == oldVpnGateHost),
                  orElse: () => _allServers.first,
                );
        }
        if (prefs.autoFastestServer && !_hasUserSelectedServer) {
          _selectedServer = _fastestServer;
        }
        _followCountryBest();
        if (!_isTestEnvironment) {
          unawaited(detectFastestServer());
        }
      }
    } catch (e) {
      _serverLoadError = e.toString();
    } finally {
      _isLoadingServers = false;
      notifyListeners();
    }
  }

  Future<VpnServer?> detectFastestServer({bool forceProbe = false}) async {
    if (_allServers.isEmpty) {
      return null;
    }

    if (_isDetectingFastest && !forceProbe) {
      return _fastestServer;
    }

    _isDetectingFastest = true;
    notifyListeners();

    try {
      _fastestServer ??= _detectFastestUseCase(_allServers);

      final probedResults = await _probeServerLatenciesUseCase(
        _probeCandidates(),
        maxConcurrent: 8,
        timeout: const Duration(milliseconds: 2500),
      );

      if (probedResults.isNotEmpty) {
        final probedMap = {for (final s in probedResults) s.id: s};
        _allServers = _allServers.map((s) => probedMap[s.id] ?? s).toList();
      }

      _countryServers = _pickCountries();
      final detected = _detectFastestUseCase(_countryServers);
      if (detected != null) {
        _fastestServer = detected;
        if (prefs.autoFastestServer && !_hasUserSelectedServer) {
          _selectedServer = detected;
        }
      }
      _followCountryBest();
      _lastFastestDetectionTime = DateTime.now();
    } catch (e) {
      debugPrint('detectFastestServer error: $e');
      _fastestServer ??= _detectFastestUseCase(_allServers);
    } finally {
      _isDetectingFastest = false;
      notifyListeners();
    }

    return _fastestServer;
  }

  /// Relays to probe: each country's strongest few by catalog speed. Probing
  /// every relay takes too long (Japan alone lists 50+), while probing only the
  /// global top would leave smaller countries unverified.
  static const int _probesPerCountry = 6;

  List<VpnServer> _probeCandidates() {
    final byCountry = <String, List<VpnServer>>{};
    for (final server in _allServers) {
      byCountry.putIfAbsent(server.countryCode, () => []).add(server);
    }
    return [
      for (final group in byCountry.values)
        ...(group..sort((a, b) {
              final speedA = a.speedBps ?? 0;
              final speedB = b.speedBps ?? 0;
              if (speedA != speedB) return speedB.compareTo(speedA);
              return b.score.compareTo(a.score);
            }))
            .take(_probesPerCountry),
    ];
  }

  /// One relay per country, leaving out countries where every relay failed its
  /// probe. If nothing is reachable at all (offline), all countries stay
  /// listed so the user can still try.
  List<VpnServer> _pickCountries() {
    final best = _pickBestPerCountryUseCase(_allServers);
    final reachable = best.where((s) => s.isAvailable).toList();
    return reachable.isEmpty ? best : reachable;
  }

  /// Moves an idle selection to its country's current best relay, so a probe
  /// that finds a faster relay in the same country is used on next connect.
  void _followCountryBest() {
    final selected = _selectedServer;
    final idle =
        connectionState == VpnConnectionState.disconnected ||
        connectionState == VpnConnectionState.error;
    if (selected == null || !idle) return;
    for (final best in _countryServers) {
      if (best.countryCode == selected.countryCode) {
        _selectedServer = best;
        return;
      }
    }
  }

  void selectServer(VpnServer server) {
    _hasUserSelectedServer = true;
    _selectedServer = server;
    unawaited(_saveSelectedServer(server));
    notifyListeners();
  }

  void selectFastestServer() {
    final target = _fastestServer ?? _detectFastestUseCase(_allServers);
    if (target != null) {
      _hasUserSelectedServer = true;
      _selectedServer = target;
      unawaited(_saveSelectedServer(target));
      notifyListeners();
    }
  }

  Future<void> connectToFastestServer() async {
    if (connectionState == VpnConnectionState.connecting ||
        connectionState == VpnConnectionState.disconnecting) {
      return;
    }

    if (_fastestServer == null) {
      if (_allServers.isEmpty) {
        await loadServers();
      }
      await detectFastestServer();
    }

    final target = _fastestServer ?? _detectFastestUseCase(_allServers);
    if (target != null) {
      if (connectionState == VpnConnectionState.connected &&
          _selectedServer?.id == target.id) {
        return;
      }
      if (connectionState == VpnConnectionState.connected) {
        await disconnect();
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
      _hasUserSelectedServer = true;
      _selectedServer = target;
      unawaited(_saveSelectedServer(target));
      notifyListeners();
      await connect();
    }
  }

  Future<void> toggleFavorite(String serverId) async {
    await _toggleFavoriteUseCase(serverId);
    _allServers = await _getServersUseCase();
    _countryServers = _pickCountries();
    if (_selectedServer != null && _selectedServer!.id == serverId) {
      _selectedServer = _allServers.firstWhere(
        (s) => s.id == serverId,
        orElse: () => _selectedServer!,
      );
    }
    notifyListeners();
  }

  Future<void> connect() async {
    if (connectionState == VpnConnectionState.connecting ||
        connectionState == VpnConnectionState.checking ||
        connectionState == VpnConnectionState.disconnecting) {
      return;
    }

    if (_selectedServer == null) {
      if (_fastestServer != null) {
        _selectedServer = _fastestServer;
      } else if (_allServers.isNotEmpty) {
        _selectedServer =
            _detectFastestUseCase(_allServers) ?? _allServers.first;
      } else {
        await loadServers();
        if (_allServers.isEmpty) return;
        _selectedServer = _fastestServer ?? _allServers.first;
      }
    }

    if (connectionState == VpnConnectionState.connected) {
      if (vpnService.currentServer?.id == _selectedServer!.id) return;
      await disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (connectionState == VpnConnectionState.disconnecting) return;
    }

    unawaited(_saveSelectedServer(_selectedServer!));
    _failoverActive = true;
    _failoverTried
      ..clear()
      ..add(_selectedServer!.id);
    await _connectVpnUseCase(_selectedServer!);
  }

  String? _restoredServerId() {
    final cached = prefs.selectedServerJson;
    if (cached == null || cached.isEmpty) return null;
    try {
      final decoded = jsonDecode(cached);
      return decoded is Map<String, dynamic> ? decoded['id'] as String? : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveSelectedServer(VpnServer server) async {
    await prefs.setSelectedServerJson(jsonEncode({'id': server.id}));
  }

  Future<void> disconnect() async {
    _failoverActive = false;
    _rotationInProgress = false;
    _cancelRotation();
    await _disconnectVpnUseCase();
  }

  Future<void> setIpRotationEnabled(bool enabled) async {
    await prefs.setIpRotationEnabled(enabled);
    _scheduleRotation();
    notifyListeners();
  }

  Future<void> setIpRotationMinutes(int minutes) async {
    await prefs.setIpRotationMinutes(minutes);
    _scheduleRotation();
    notifyListeners();
  }

  Future<void> setIpRotationSameCountry(bool sameCountry) async {
    await prefs.setIpRotationSameCountry(sameCountry);
    notifyListeners();
  }

  /// Switches now to the fastest relay with a different IP. Does nothing
  /// unless connected; when no other relay qualifies it retries next interval.
  Future<void> rotateIpNow() async {
    if (connectionState != VpnConnectionState.connected ||
        _rotationInProgress) {
      return;
    }
    final next = _nextRotationServer();
    if (next == null) {
      _scheduleRotation();
      notifyListeners();
      return;
    }

    final current = vpnService.currentServer ?? _selectedServer;
    if (current != null) {
      _recentRotationHosts
        ..remove(current.host)
        ..add(current.host);
      if (_recentRotationHosts.length > _recentRotationLimit) {
        _recentRotationHosts.removeAt(0);
      }
    }
    _cancelRotation();
    _rotationInProgress = true;
    _selectedServer = next;
    unawaited(_saveSelectedServer(next));
    notifyListeners();

    await _disconnectVpnUseCase();
    // Let the old tunnel finish closing before the next one starts.
    for (var i = 0; i < 30; i++) {
      if (connectionState != VpnConnectionState.disconnecting) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!_rotationInProgress || _isDisposed) return;
    _failoverActive = true;
    _failoverTried
      ..clear()
      ..add(next.id);
    await _connectVpnUseCase(next);
  }

  /// Next relay for IP rotation: the fastest reachable one whose address
  /// differs from the current and recently used ones, kept to the current
  /// country when the user asked for that.
  VpnServer? _nextRotationServer() {
    final current = vpnService.currentServer ?? _selectedServer;
    List<VpnServer> pool(Set<String> avoidHosts) => _allServers
        .where(
          (s) =>
              s.isAvailable &&
              !avoidHosts.contains(s.host) &&
              (!prefs.ipRotationSameCountry ||
                  s.countryCode == current?.countryCode),
        )
        .toList();

    final currentHost = current?.host;
    var candidates = pool({..._recentRotationHosts, ?currentHost});
    // Every alternative was used recently: allow them again, but still
    // never the address in use now.
    if (candidates.isEmpty) candidates = pool({?currentHost});
    return candidates.isEmpty ? null : _detectFastestUseCase(candidates);
  }

  void _updateRotation(VpnConnectionState state) {
    if (state == VpnConnectionState.connected) {
      _connectedByRotation = _rotationInProgress;
      _rotationInProgress = false;
      _scheduleRotation();
    } else if (state == VpnConnectionState.error &&
        !_failoverActive &&
        !_failoverPending) {
      // The new relay and its failover alternates all failed.
      _rotationInProgress = false;
      _cancelRotation();
    } else if (state == VpnConnectionState.disconnected &&
        !_rotationInProgress) {
      _cancelRotation();
    }
  }

  void _scheduleRotation() {
    _cancelRotation();
    if (!prefs.ipRotationEnabled ||
        connectionState != VpnConnectionState.connected) {
      return;
    }
    final interval = Duration(minutes: prefs.ipRotationMinutes);
    _nextRotationAt = DateTime.now().add(interval);
    _rotationTimer = Timer(interval, () => unawaited(rotateIpNow()));
  }

  void _cancelRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
    _nextRotationAt = null;
  }

  Future<void> clearHistory() async {
    _sessions.clear();
    await _clearSessionHistoryUseCase();
    notifyListeners();
  }

  int get totalSessionsCount => _sessions.length;

  int get totalProtectedSeconds =>
      _sessions.fold(0, (acc, s) => acc + s.durationSeconds);

  int get totalBytesTransferred =>
      _sessions.fold(0, (acc, s) => acc + (s.bytesReceived + s.bytesSent));

  String get formattedTotalProtectedTime {
    final totalSecs = totalProtectedSeconds;
    final hours = totalSecs ~/ 3600;
    final minutes = (totalSecs % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    // Short sessions read as "45s" rather than a misleading "0m".
    if (minutes == 0 && totalSecs > 0) return '${totalSecs}s';
    return '${minutes}m';
  }

  String get formattedTotalDataTransferred {
    final total = totalBytesTransferred;
    if (total < 1024) return '$total B';
    if (total < 1024 * 1024) return '${(total / 1024).toStringAsFixed(1)} KB';
    if (total < 1024 * 1024 * 1024) {
      return '${(total / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(total / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  bool _isDisposed = false;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelRotation();
    _stateSub.cancel();
    _metricsSub.cancel();
    vpnService.dispose();
    super.dispose();
  }
}
