import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/vpn_connection_state.dart';
import '../../../domain/entities/vpn_live_metrics.dart';
import '../../../domain/entities/vpn_server.dart';
import 'vpn_platform_data_source.dart';

/// SSTP tunnel driven by the app's own Android VpnService (`ShieldRouteVpnService`).
///
/// SSTP runs inside an ordinary TLS session, so it connects on networks whose
/// deep packet inspection resets OpenVPN handshakes.
class NativeVpnPlatformDataSource implements VpnPlatformDataSource {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.shieldroute.vpn/native_engine',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.shieldroute.vpn/events',
  );

  final StreamController<VpnConnectionState> _stateController =
      StreamController<VpnConnectionState>.broadcast();
  final StreamController<VpnLiveMetrics> _metricsController =
      StreamController<VpnLiveMetrics>.broadcast();

  VpnConnectionState _currentState = VpnConnectionState.disconnected;
  VpnLiveMetrics _currentMetrics = const VpnLiveMetrics();
  VpnServer? _currentServer;
  String? _lastError;
  String? _lastErrorCode;
  bool _isInitialized = false;

  StreamSubscription? _eventSubscription;
  Timer? _mockFallbackTimer;
  int _mockSeconds = 0;

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

  /// Native failure category: `unreachable`, `tls`, `timeout`, `rejected`, ...
  String? get lastErrorCode => _lastErrorCode;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        _handleNativeEvent,
        onError: (err) {
          debugPrint('NativeVpnPlatformDataSource event channel error: $err');
        },
      );

      final state = await _methodChannel
          .invokeMethod<String>('getState')
          .timeout(const Duration(seconds: 2), onTimeout: () => 'disconnected');
      if (state == 'connected') {
        _updateState(VpnConnectionState.connected);
      }
      _isInitialized = true;
    } on MissingPluginException {
      debugPrint(
        'NativeVpnPlatformDataSource running in test / non-Android environment.',
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('NativeVpnPlatformDataSource initialize exception: $e');
      _isInitialized = true;
    }
  }

  void _handleNativeEvent(dynamic event) {
    if (event is! Map) return;

    final type = event['type'] as String?;
    if (type == 'state') {
      final stateStr = event['state'] as String?;
      final errorStr = event['error'] as String?;

      switch (stateStr) {
        case 'connecting':
          _updateState(VpnConnectionState.connecting);
          break;
        case 'connected':
          _lastError = null;
          _updateState(VpnConnectionState.connected);
          break;
        case 'disconnecting':
          _updateState(VpnConnectionState.disconnecting);
          break;
        case 'disconnected':
          _updateState(VpnConnectionState.disconnected);
          break;
        case 'error':
          _lastError = errorStr ?? 'Native tunnel connection failed';
          _lastErrorCode = event['code'] as String?;
          _updateState(VpnConnectionState.error);
          break;
      }
    } else if (type == 'metrics') {
      final byteIn =
          (event['byteIn'] as num?)?.toInt() ?? _currentMetrics.byteIn;
      final byteOut =
          (event['byteOut'] as num?)?.toInt() ?? _currentMetrics.byteOut;
      final duration = event['duration'] as String? ?? _currentMetrics.duration;

      _currentMetrics = _currentMetrics.copyWith(
        byteIn: byteIn,
        byteOut: byteOut,
        duration: duration,
        pingMs: _currentServer?.pingMs ?? 28,
        publicIp: _currentServer?.host ?? '1.1.1.1',
      );
      _metricsController.add(_currentMetrics);
    }
  }

  void _updateState(VpnConnectionState state) {
    _currentState = state;
    _stateController.add(_currentState);
  }

  @override
  Future<bool> requestVpnPermission() async {
    if (!_isInitialized) await initialize();
    try {
      final result = await _methodChannel.invokeMethod<bool>('prepare');
      return result ?? false;
    } on MissingPluginException {
      return true;
    } catch (e) {
      debugPrint('NativeVpnPlatformDataSource requestVpnPermission error: $e');
      return false;
    }
  }

  @override
  Future<void> connect(VpnServer server) async {
    _currentServer = server;
    _lastError = null;
    _lastErrorCode = null;
    _mockFallbackTimer?.cancel();
    _updateState(VpnConnectionState.checking);

    if (!_isInitialized) await initialize();

    try {
      _updateState(VpnConnectionState.connecting);

      // Request VPN permission. prepare() may show the system dialog and
      // return false while waiting; we use a short poll + timeout to handle it.
      bool prepared =
          await _methodChannel.invokeMethod<bool>('prepare') ?? false;

      if (!prepared) {
        debugPrint(
          'NativeVpnPlatformDataSource: Permission dialog shown – waiting for grant...',
        );
        // Poll for up to 60 s while the user decides
        const pollInterval = Duration(milliseconds: 500);
        const maxWait = Duration(seconds: 60);
        final deadline = DateTime.now().add(maxWait);
        while (!prepared && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(pollInterval);
          try {
            prepared =
                await _methodChannel.invokeMethod<bool>('prepare') ?? false;
          } catch (_) {
            break;
          }
        }
        if (!prepared) {
          debugPrint(
            'NativeVpnPlatformDataSource: VPN permission not granted.',
          );
          _lastError = 'VPN permission was not granted.';
          _updateState(VpnConnectionState.error);
          return;
        }
      }

      final hostname = server.sstpHostname;
      if (hostname == null || hostname.isEmpty) {
        _lastError = 'This relay does not support SSTP.';
        _updateState(VpnConnectionState.error);
        return;
      }
      await _methodChannel.invokeMethod('connect', {
        'serverName': server.country,
        'hostname': hostname,
        'address': server.host,
        'port': server.sstpPort,
        'username': server.username,
        'password': server.password,
      });
    } on MissingPluginException {
      _startMockTunnel(server);
    } catch (e) {
      debugPrint('NativeVpnPlatformDataSource connect failed: $e');
      _lastError = 'Connection failed: $e';
      _updateState(VpnConnectionState.error);
    }
  }

  void _startMockTunnel(VpnServer server) {
    _mockFallbackTimer?.cancel();
    _mockSeconds = 0;
    _updateState(VpnConnectionState.connecting);

    Future.delayed(const Duration(milliseconds: 300), () {
      _updateState(VpnConnectionState.connected);
      int inB = 1024 * 250;
      int outB = 1024 * 80;

      _mockFallbackTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_currentState != VpnConnectionState.connected) {
          t.cancel();
          return;
        }
        _mockSeconds++;
        final m = (_mockSeconds ~/ 60).toString().padLeft(2, '0');
        final s = (_mockSeconds % 60).toString().padLeft(2, '0');
        inB += 1024 * 16;
        outB += 1024 * 6;

        _currentMetrics = VpnLiveMetrics(
          byteIn: inB,
          byteOut: outB,
          duration: '$m:$s',
          pingMs: server.pingMs ?? 32,
          publicIp: server.host,
        );
        _metricsController.add(_currentMetrics);
      });
    });
  }

  @override
  Future<void> disconnect() async {
    _mockFallbackTimer?.cancel();
    _mockFallbackTimer = null;
    _updateState(VpnConnectionState.disconnecting);

    try {
      await _methodChannel.invokeMethod('disconnect');
    } on MissingPluginException {
      // Ignored in test environment
    } catch (e) {
      debugPrint('NativeVpnPlatformDataSource disconnect exception: $e');
    }

    await Future.delayed(const Duration(milliseconds: 200));
    _updateState(VpnConnectionState.disconnected);
    _currentMetrics = const VpnLiveMetrics();
    _metricsController.add(_currentMetrics);
  }

  @override
  void dispose() {
    _mockFallbackTimer?.cancel();
    _eventSubscription?.cancel();
    _stateController.close();
    _metricsController.close();
  }
}
