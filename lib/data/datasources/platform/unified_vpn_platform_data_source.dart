import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/vpn_connection_state.dart';
import '../../../domain/entities/vpn_live_metrics.dart';
import '../../../domain/entities/vpn_server.dart';
import '../../../domain/repositories/preferences_repository.dart';
import 'native_vpn_platform_data_source.dart';
import 'openvpn_platform_data_source.dart';
import 'vpn_platform_data_source.dart';

/// Coordinates OpenVPN and Native tunnel implementations.
class UnifiedVpnPlatformDataSource implements VpnPlatformDataSource {
  final PreferencesRepository prefs;
  final OpenVpnPlatformDataSource _openVpnSource;
  final NativeVpnPlatformDataSource _nativeVpnSource;

  final StreamController<VpnConnectionState> _stateController =
      StreamController<VpnConnectionState>.broadcast();
  final StreamController<VpnLiveMetrics> _metricsController =
      StreamController<VpnLiveMetrics>.broadcast();

  VpnPlatformDataSource? _activeSource;
  StreamSubscription? _activeStateSub;
  StreamSubscription? _activeMetricsSub;

  VpnConnectionState _currentState = VpnConnectionState.disconnected;
  VpnLiveMetrics _currentMetrics = const VpnLiveMetrics();
  VpnServer? _currentServer;
  String? _lastError;

  UnifiedVpnPlatformDataSource({
    required this.prefs,
    OpenVpnPlatformDataSource? openVpnSource,
    NativeVpnPlatformDataSource? nativeVpnSource,
  }) : _openVpnSource =
           openVpnSource ?? OpenVpnPlatformDataSource(prefs: prefs),
       _nativeVpnSource = nativeVpnSource ?? NativeVpnPlatformDataSource();

  @override
  VpnConnectionState get currentState => _currentState;

  @override
  Stream<VpnConnectionState> get stateStream => _stateController.stream;

  @override
  VpnLiveMetrics get currentMetrics => _currentMetrics;

  @override
  Stream<VpnLiveMetrics> get metricsStream => _metricsController.stream;

  @override
  VpnServer? get currentServer => _currentServer;

  @override
  String? get lastError => _activeSource?.lastError ?? _lastError;

  @override
  Future<void> initialize() async {
    await Future.wait([
      _openVpnSource.initialize(),
      _nativeVpnSource.initialize(),
    ]);
    // Adopt a tunnel that is still up from a previous app session so the UI
    // reflects it and the user can disconnect it.
    if (_openVpnSource.currentState == VpnConnectionState.connected) {
      _bindSource(_openVpnSource);
      _currentState = VpnConnectionState.connected;
      _currentMetrics = _openVpnSource.currentMetrics;
      return;
    }
    _currentState = VpnConnectionState.disconnected;
    _currentMetrics = const VpnLiveMetrics();
  }

  void _bindSource(VpnPlatformDataSource source) {
    _activeStateSub?.cancel();
    _activeMetricsSub?.cancel();
    _activeSource = source;

    _activeStateSub = source.stateStream.listen((state) {
      _currentState = state;
      _lastError = source.lastError;
      _stateController.add(state);
    });

    _activeMetricsSub = source.metricsStream.listen((metrics) {
      _currentMetrics = metrics;
      _metricsController.add(metrics);
    });
  }

  @override
  Future<bool> requestVpnPermission() async {
    if (_activeSource != null) {
      return _activeSource!.requestVpnPermission();
    }
    return _openVpnSource.requestVpnPermission();
  }

  @override
  Future<void> connect(VpnServer server) async {
    _currentServer = server;
    _lastError = null;

    // The native stub tunnel installs a default route but forwards no packets,
    // which would cut off the device's internet. All relays use OpenVPN.
    final targetSource = _openVpnSource;

    debugPrint(
      'UnifiedVpnPlatformDataSource: Routing ${server.country} (${server.host}) to OpenVPN engine...',
    );
    _bindSource(targetSource);

    try {
      await targetSource.connect(server);
    } catch (e) {
      debugPrint('UnifiedVpnPlatformDataSource: Connection error: $e');
      _lastError = 'VPN connection error: $e';
      _currentState = VpnConnectionState.error;
      _stateController.add(_currentState);
    }
  }

  @override
  Future<void> disconnect() async {
    if (_activeSource != null) {
      await _activeSource!.disconnect();
      _activeSource = null;
    } else {
      await Future.wait([
        _openVpnSource.disconnect(),
        _nativeVpnSource.disconnect(),
      ]);
    }
    _currentState = VpnConnectionState.disconnected;
    _stateController.add(_currentState);
  }

  @override
  void dispose() {
    _activeStateSub?.cancel();
    _activeMetricsSub?.cancel();
    _openVpnSource.dispose();
    _nativeVpnSource.dispose();
    _stateController.close();
    _metricsController.close();
  }
}
