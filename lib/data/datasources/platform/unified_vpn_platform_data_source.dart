import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/vpn_connection_state.dart';
import '../../../domain/entities/vpn_live_metrics.dart';
import '../../../domain/entities/vpn_server.dart';
import '../../../domain/repositories/preferences_repository.dart';
import 'native_vpn_platform_data_source.dart';
import 'openvpn_platform_data_source.dart';
import 'vpn_platform_data_source.dart';

/// Coordinates the SSTP (native) and OpenVPN tunnel implementations.
///
/// SSTP is tried first on Android because it survives networks that block
/// OpenVPN; if it fails, the same relay is retried over OpenVPN before the
/// error is reported.
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

  /// Retry hook armed while an SSTP attempt may still fall back to OpenVPN.
  /// Returns false when retrying is pointless and the error should surface.
  bool Function()? _pendingFallback;

  /// Whether the native SSTP engine exists on this platform.
  final bool _sstpSupported;

  UnifiedVpnPlatformDataSource({
    bool? sstpSupported,
    required this.prefs,
    OpenVpnPlatformDataSource? openVpnSource,
    NativeVpnPlatformDataSource? nativeVpnSource,
  }) : _openVpnSource =
           openVpnSource ?? OpenVpnPlatformDataSource(prefs: prefs),
       _nativeVpnSource = nativeVpnSource ?? NativeVpnPlatformDataSource(),
       _sstpSupported = sstpSupported ?? Platform.isAndroid;

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
    for (final source in [_nativeVpnSource, _openVpnSource]) {
      if (source.currentState == VpnConnectionState.connected) {
        _bindSource(source);
        _currentState = VpnConnectionState.connected;
        _currentMetrics = source.currentMetrics;
        return;
      }
    }
    _currentState = VpnConnectionState.disconnected;
    _currentMetrics = const VpnLiveMetrics();
  }

  void _bindSource(VpnPlatformDataSource source) {
    _activeStateSub?.cancel();
    _activeMetricsSub?.cancel();
    _activeSource = source;

    _activeStateSub = source.stateStream.listen((state) {
      if (state == VpnConnectionState.error && _pendingFallback != null) {
        final fallback = _pendingFallback!;
        _pendingFallback = null;
        if (fallback()) return;
      }
      if (state == VpnConnectionState.connected) _pendingFallback = null;
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
    _pendingFallback = null;

    if (_sstpSupported && server.supportsSstp) {
      debugPrint(
        'UnifiedVpnPlatformDataSource: ${server.country} '
        '(${server.sstpHostname}:${server.sstpPort}) via SSTP...',
      );
      if (server.ovpnConfig.isNotEmpty) {
        _pendingFallback = () {
          // A TCP relay that could not be reached over SSTP is just as
          // unreachable over OpenVPN-TCP; let failover move to another relay.
          if (_nativeVpnSource.lastErrorCode == 'unreachable' &&
              server.protocol.toUpperCase() == 'TCP') {
            return false;
          }
          debugPrint(
            'UnifiedVpnPlatformDataSource: SSTP failed '
            '(${_nativeVpnSource.lastError}); retrying over OpenVPN.',
          );
          unawaited(_connectWith(_openVpnSource, server));
          return true;
        };
      }
      await _connectWith(_nativeVpnSource, server);
      return;
    }

    debugPrint(
      'UnifiedVpnPlatformDataSource: ${server.country} (${server.host}) via OpenVPN...',
    );
    await _connectWith(_openVpnSource, server);
  }

  Future<void> _connectWith(
    VpnPlatformDataSource source,
    VpnServer server,
  ) async {
    _bindSource(source);
    try {
      await source.connect(server);
    } catch (e) {
      debugPrint('UnifiedVpnPlatformDataSource: Connection error: $e');
      _pendingFallback = null;
      _lastError = 'VPN connection error: $e';
      _currentState = VpnConnectionState.error;
      _stateController.add(_currentState);
    }
  }

  @override
  Future<void> disconnect() async {
    _pendingFallback = null;
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
