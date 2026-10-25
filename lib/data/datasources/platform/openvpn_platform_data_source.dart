import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:axevpn_flutter/openvpn_flutter.dart';

import '../../../core/platform/android_system.dart';
import '../../../domain/entities/vpn_connection_state.dart';
import '../../../domain/entities/vpn_live_metrics.dart';
import '../../../domain/entities/vpn_server.dart';
import '../../../domain/repositories/preferences_repository.dart';
import 'vpn_platform_data_source.dart';

/// OpenVPN tunnel implementation backed by the axevpn_flutter engine
/// (ics-openvpn / OpenVPN 2.7, built for 16 KB page-size devices).
class OpenVpnPlatformDataSource implements VpnPlatformDataSource {
  final PreferencesRepository? prefs;
  OpenVPN? _engine;
  final StreamController<VpnConnectionState> _stateController =
      StreamController<VpnConnectionState>.broadcast();
  final StreamController<VpnLiveMetrics> _metricsController =
      StreamController<VpnLiveMetrics>.broadcast();

  VpnConnectionState _currentState = VpnConnectionState.disconnected;
  VpnLiveMetrics _currentMetrics = const VpnLiveMetrics();
  VpnServer? _currentServer;
  String? _lastError;
  bool _isInitialized = false;
  Future<void>? _initializationFuture;

  Timer? _simulationTimer;
  Timer? _connectionWatchdog;
  int _simulationSeconds = 0;
  bool _isSimulating = false;

  OpenVpnPlatformDataSource({this.prefs});

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
  String? get lastError => _lastError;

  @override
  Future<void> initialize() {
    if (_isInitialized && _engine?.initialized == true) {
      return Future<void>.value();
    }
    return _initializationFuture ??= _initializeEngine();
  }

  Future<void> _initializeEngine() async {
    try {
      // The plugin attaches after launch, once its native libraries have
      // loaded off the main thread; its channels do not exist before that.
      await AndroidSystem.waitForVpnEngine();
      _engine = OpenVPN(
        onVpnStatusChanged: _handleStatusChanged,
        onVpnStageChanged: _handleStageChanged,
      );

      await _engine?.initialize(localizedDescription: 'Galaxy VPN Academic');
      _isInitialized = true;
      if (await _engine?.isConnected() ?? false) {
        _updateState(VpnConnectionState.connected);
        final status = await _engine?.status();
        _handleStatusChanged(status);
      }
    } catch (e) {
      debugPrint('OpenVpnPlatformDataSource initialize exception: $e');
      _isInitialized = true;
    } finally {
      _initializationFuture = null;
    }
  }

  void _handleStageChanged(VPNStage stage, String rawStage) {
    debugPrint('OpenVPN Stage Changed: $stage ($rawStage)');
    switch (stage) {
      case VPNStage.prepare:
      case VPNStage.connecting:
      case VPNStage.authenticating:
      case VPNStage.authentication:
      case VPNStage.tcp_connect:
      case VPNStage.udp_connect:
      case VPNStage.assign_ip:
      case VPNStage.resolve:
      case VPNStage.wait_connection:
      case VPNStage.vpn_generate_config:
      case VPNStage.get_config:
        if (!_isSimulating) {
          _updateState(VpnConnectionState.connecting);
        }
        break;

      case VPNStage.connected:
        _connectionWatchdog?.cancel();
        _isSimulating = false;
        _lastError = null;
        _updateState(VpnConnectionState.connected);
        break;

      case VPNStage.disconnecting:
      case VPNStage.exiting:
        // Teardown triggered by a failure must not overwrite the error state.
        if (!_isSimulating && _currentState != VpnConnectionState.error) {
          _updateState(VpnConnectionState.disconnecting);
        }
        break;

      case VPNStage.denied:
        _failConnection('VPN permission was not granted by Android.');
        break;

      case VPNStage.error:
        _failConnection(_describeOpenVpnError(rawStage));
        break;

      case VPNStage.disconnected:
      case VPNStage.unknown:
        if (!_isSimulating) {
          if (_currentState == VpnConnectionState.connected ||
              _currentState == VpnConnectionState.disconnecting) {
            _updateState(VpnConnectionState.disconnected);
          }
        }
        break;
    }
  }

  /// Records a failure and tears the engine down. Leaving a half-established
  /// tunnel running keeps Android's default route on a dead TUN interface,
  /// which cuts off the device's internet access.
  void _failConnection(String message) {
    _connectionWatchdog?.cancel();
    _lastError = message;
    _updateState(VpnConnectionState.error);
    try {
      if (_engine != null && _engine!.initialized) {
        _engine!.disconnect();
      }
    } catch (e) {
      debugPrint('OpenVpnPlatformDataSource teardown error: $e');
    }
  }

  String _describeOpenVpnError(String rawStage) {
    final detail = rawStage.toLowerCase();
    if (detail.contains('auth_failed') || detail.contains('authentication')) {
      return 'The relay rejected its login. Choose another relay or check its credentials.';
    }
    if (detail.contains('resolve') || detail.contains('dns')) {
      return 'The relay address could not be resolved. Check your internet connection.';
    }
    if (detail.contains('tls') || detail.contains('certificate')) {
      return 'The relay security handshake failed. Try a refreshed profile or another relay.';
    }
    if (detail.contains('timeout') || detail.contains('timed out')) {
      return 'The relay did not respond in time. Try another relay or network.';
    }
    return 'The OpenVPN connection failed. Try another relay.';
  }

  void _handleStatusChanged(VpnStatus? status) {
    if (status == null || _isSimulating) return;
    final int byteIn = int.tryParse(status.byteIn ?? '0') ?? 0;
    final int byteOut = int.tryParse(status.byteOut ?? '0') ?? 0;

    _currentMetrics = _currentMetrics.copyWith(
      byteIn: byteIn,
      byteOut: byteOut,
      duration: status.duration,
      pingMs: _currentServer?.pingMs,
      publicIp: _currentServer?.host,
    );
    _metricsController.add(_currentMetrics);
  }

  void _updateState(VpnConnectionState newState) {
    _currentState = newState;
    _stateController.add(_currentState);
  }

  @override
  Future<bool> requestVpnPermission() async {
    if (!_isInitialized) {
      await initialize();
    }
    try {
      return await _engine?.requestPermissionAndroid() ?? false;
    } catch (e) {
      debugPrint('OpenVpnPlatformDataSource requestVpnPermission error: $e');
      return false;
    }
  }

  @override
  Future<void> connect(VpnServer server) async {
    _currentServer = server;
    _lastError = null;
    _connectionWatchdog?.cancel();
    _simulationTimer?.cancel();
    _isSimulating = false;

    _updateState(VpnConnectionState.checking);

    if (!RegExp(
      r'^\s*(remote|connection)\b',
      multiLine: true,
    ).hasMatch(server.ovpnConfig)) {
      _lastError = 'This relay has no usable OpenVPN endpoint configuration.';
      _updateState(VpnConnectionState.error);
      return;
    }

    final isMobilePlatform = Platform.isAndroid || Platform.isIOS;
    if (!isMobilePlatform) {
      debugPrint(
        'OpenVpnPlatformDataSource: Non-mobile platform. Starting development simulation.',
      );
      _startSimulatedConnection(server);
      return;
    }

    if (!_isInitialized || _engine == null || !_engine!.initialized) {
      await initialize();
    }

    try {
      _updateState(VpnConnectionState.connecting);

      if (_engine != null && _engine!.initialized) {
        // The plugin requests VPN permission itself as part of connect().

        // With certIsRequired=false the plugin appends `client-cert-not-required`,
        // a server-only directive. Profiles that embed their own <cert>/<key>
        // (all VPN Gate relays) must be passed through untouched.
        final certIsRequired = server.ovpnConfig.contains('<cert>');
        final isTurbo = prefs?.turboSpeedMode ?? true;
        final preparedConfig = optimizeConfig(
          server.ovpnConfig,
          turboMode: isTurbo,
          killSwitch: prefs?.killSwitch ?? false,
        );

        _connectionWatchdog = Timer(const Duration(seconds: 25), () {
          if (_currentState == VpnConnectionState.connecting ||
              _currentState == VpnConnectionState.checking) {
            debugPrint('OpenVpnPlatformDataSource: Handshake timeout.');
            _failConnection(
              'Connection handshake timed out. Check your network or choose another relay.',
            );
          }
        });

        await _engine!.connect(
          preparedConfig,
          'Galaxy VPN - ${server.country}',
          username: server.username,
          password: server.password,
          certIsRequired: certIsRequired,
        );
      } else {
        _lastError = 'VPN engine is not initialized on this device.';
        _updateState(VpnConnectionState.error);
      }
    } catch (e) {
      debugPrint('OpenVpnPlatformDataSource connect failed: $e.');
      _failConnection('Connection initiation error: $e');
    }
  }

  /// Prepares a relay profile for the Android OpenVPN engine.
  ///
  /// Only conservative, widely supported directives are added: unknown options
  /// make older engine builds abort, and an oversized tunnel MTU makes the
  /// encapsulated packets fragment, which presents as "connected but no
  /// internet".
  static String optimizeConfig(
    String rawConfig, {
    bool turboMode = true,
    bool killSwitch = false,
  }) {
    // `persist-tun` keeps a dead TUN (and its default route) alive when the
    // relay drops, blackholing all traffic. Only honour it with the kill switch.
    var config = rawConfig
        .replaceAll('\r\n', '\n')
        .trim()
        .split('\n')
        .where((l) => killSwitch || l.trim() != 'persist-tun')
        .join('\n');

    bool has(String directive) =>
        RegExp('^\\s*$directive(\\s|\$)', multiLine: true).hasMatch(config);

    if (!has('client')) config = 'client\n$config';
    if (!has('dev')) config = 'dev tun\n$config';
    config += '\n';

    // Preserve the relay's route directives; add a full-tunnel route only
    // when the profile has none.
    final hasDefaultRoute = RegExp(
      r'^\s*(redirect-gateway|route\s+0\.0\.0\.0\s+0\.0\.0\.0)\b',
      multiLine: true,
      caseSensitive: false,
    ).hasMatch(config);
    if (!hasDefaultRoute) config += 'redirect-gateway def1\n';

    // Keep encapsulated packets well below the link MTU (mobile networks are
    // often under 1500).
    if (!has('tun-mtu')) config += 'tun-mtu 1400\n';
    if (!has('mssfix')) config += 'mssfix 1360\n';

    // Fallback DNS when the relay pushes none.
    if (!has('dhcp-option\\s+DNS')) {
      config += 'dhcp-option DNS 1.1.1.1\ndhcp-option DNS 8.8.8.8\n';
    }

    if (turboMode && !has('sndbuf')) {
      config += 'sndbuf 524288\nrcvbuf 524288\n';
    }

    if (!has('resolv-retry')) config += 'resolv-retry 10\n';
    if (!has('connect-timeout')) config += 'connect-timeout 10\n';

    return config;
  }

  void _startSimulatedConnection(VpnServer server) {
    _connectionWatchdog?.cancel();
    _simulationTimer?.cancel();
    _isSimulating = true;
    _simulationSeconds = 0;
    _lastError = null;
    _updateState(VpnConnectionState.connecting);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!_isSimulating) return;
      _updateState(VpnConnectionState.connected);

      int inBytes = 1024 * 380;
      int outBytes = 1024 * 140;

      _currentMetrics = VpnLiveMetrics(
        byteIn: inBytes,
        byteOut: outBytes,
        duration: '00:00',
        pingMs: server.pingMs ?? 36,
        publicIp: server.host,
      );
      _metricsController.add(_currentMetrics);

      _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isSimulating || _currentState != VpnConnectionState.connected) {
          timer.cancel();
          return;
        }
        _simulationSeconds++;
        final m = (_simulationSeconds ~/ 60).toString().padLeft(2, '0');
        final s = (_simulationSeconds % 60).toString().padLeft(2, '0');
        inBytes += 1024 * (14 + (_simulationSeconds % 16));
        outBytes += 1024 * (5 + (_simulationSeconds % 9));

        _currentMetrics = VpnLiveMetrics(
          byteIn: inBytes,
          byteOut: outBytes,
          duration: '$m:$s',
          pingMs: server.pingMs ?? 36,
          publicIp: server.host,
        );
        _metricsController.add(_currentMetrics);
      });
    });
  }

  @override
  Future<void> disconnect() async {
    _connectionWatchdog?.cancel();
    _isSimulating = false;
    _simulationTimer?.cancel();
    _simulationTimer = null;

    _updateState(VpnConnectionState.disconnecting);
    try {
      if (_engine != null && _engine!.initialized) {
        _engine!.disconnect();
      }
      await Future.delayed(const Duration(milliseconds: 400));
      _updateState(VpnConnectionState.disconnected);
      _currentMetrics = const VpnLiveMetrics();
      _metricsController.add(_currentMetrics);
    } catch (e) {
      debugPrint('OpenVpnPlatformDataSource disconnect error: $e');
      _updateState(VpnConnectionState.disconnected);
    }
  }

  @override
  void dispose() {
    _connectionWatchdog?.cancel();
    _simulationTimer?.cancel();
    _stateController.close();
    _metricsController.close();
  }
}
