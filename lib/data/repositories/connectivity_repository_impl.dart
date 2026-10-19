import 'dart:async';
import 'dart:io';
import '../../domain/repositories/connectivity_repository.dart';

/// Concrete implementation of ConnectivityRepository
class ConnectivityRepositoryImpl implements ConnectivityRepository {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Timer? _pollingTimer;
  bool _lastStatus = true;

  ConnectivityRepositoryImpl() {
    _startMonitoring();
  }

  void _startMonitoring() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final isOnline = await checkInternetAccess();
      if (isOnline != _lastStatus) {
        _lastStatus = isOnline;
        _controller.add(isOnline);
      }
    });
  }

  @override
  Future<bool> checkInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('dns.google')
          .timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.close();
  }
}
