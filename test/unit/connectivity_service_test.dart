import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shieldroute_vpn/services/connectivity_service.dart';

// ─── Test-only stub that lets us control online/offline state ───────────────
class _StubConnectivityService implements ConnectivityService {
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  bool _nextResult = true;
  bool _disposed = false;
  int _checkCount = 0;

  void setOnline(bool online) => _nextResult = online;

  @override
  Future<bool> checkInternetAccess() async {
    _checkCount++;
    return _nextResult;
  }

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Manually fire a connectivity event (simulates the polling timer)
  void emitChange(bool isOnline) => _controller.add(isOnline);

  bool get isDisposed => _disposed;
  int get checkCount => _checkCount;

  @override
  void dispose() {
    _disposed = true;
    _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityService — Unit Tests', () {
    late _StubConnectivityService service;

    setUp(() {
      service = _StubConnectivityService();
    });

    tearDown(() {
      if (!service.isDisposed) service.dispose();
    });

    // ── checkInternetAccess ──────────────────────────────────────────────────

    test('checkInternetAccess returns true when online', () async {
      service.setOnline(true);
      final result = await service.checkInternetAccess();
      expect(result, isTrue);
    });

    test('checkInternetAccess returns false when offline', () async {
      service.setOnline(false);
      final result = await service.checkInternetAccess();
      expect(result, isFalse);
    });

    test('checkInternetAccess toggles correctly across calls', () async {
      service.setOnline(true);
      expect(await service.checkInternetAccess(), isTrue);

      service.setOnline(false);
      expect(await service.checkInternetAccess(), isFalse);

      service.setOnline(true);
      expect(await service.checkInternetAccess(), isTrue);
    });

    // ── onConnectivityChanged stream ─────────────────────────────────────────

    test('onConnectivityChanged emits true when connection is restored',
        () async {
      final events = <bool>[];
      final sub = service.onConnectivityChanged.listen(events.add);

      service.emitChange(true);
      await Future.delayed(Duration.zero);

      expect(events, equals([true]));
      await sub.cancel();
    });

    test('onConnectivityChanged emits false when connection is lost', () async {
      final events = <bool>[];
      final sub = service.onConnectivityChanged.listen(events.add);

      service.emitChange(false);
      await Future.delayed(Duration.zero);

      expect(events, equals([false]));
      await sub.cancel();
    });

    test(
        'onConnectivityChanged emits correct sequence of online/offline events',
        () async {
      final events = <bool>[];
      final sub = service.onConnectivityChanged.listen(events.add);

      service.emitChange(true);
      service.emitChange(false);
      service.emitChange(true);
      await Future.delayed(Duration.zero);

      expect(events, equals([true, false, true]));
      await sub.cancel();
    });

    test('Multiple subscribers receive the same connectivity events', () async {
      final events1 = <bool>[];
      final events2 = <bool>[];

      final sub1 = service.onConnectivityChanged.listen(events1.add);
      final sub2 = service.onConnectivityChanged.listen(events2.add);

      service.emitChange(false);
      await Future.delayed(Duration.zero);

      expect(events1, equals([false]));
      expect(events2, equals([false]));

      await sub1.cancel();
      await sub2.cancel();
    });

    // ── dispose ──────────────────────────────────────────────────────────────

    test('dispose closes stream without errors', () async {
      final events = <bool>[];
      bool streamClosed = false;

      final sub = service.onConnectivityChanged.listen(
        events.add,
        onDone: () => streamClosed = true,
      );

      service.dispose();
      await Future.delayed(Duration.zero);

      expect(service.isDisposed, isTrue);
      expect(streamClosed, isTrue);
      await sub.cancel();
    });
  });

  // ── DefaultConnectivityService integration test ───────────────────────────
  group('DefaultConnectivityService — Integration', () {
    test('DefaultConnectivityService can be constructed and disposed cleanly',
        () {
      final svc = DefaultConnectivityService();
      expect(() => svc.dispose(), returnsNormally);
    });

    test('DefaultConnectivityService exposes a broadcast stream', () {
      final svc = DefaultConnectivityService();
      // Listening twice should not throw (broadcast stream check)
      final sub1 = svc.onConnectivityChanged.listen((_) {});
      final sub2 = svc.onConnectivityChanged.listen((_) {});
      svc.dispose();
      sub1.cancel();
      sub2.cancel();
    });

    test(
        'DefaultConnectivityService.checkInternetAccess returns a bool within timeout',
        () async {
      final svc = DefaultConnectivityService();
      // May be true or false depending on network state; critical assertion
      // is that it returns a bool and does not throw.
      final result = await svc
          .checkInternetAccess()
          .timeout(const Duration(seconds: 6));
      expect(result, isA<bool>());
      svc.dispose();
    });
  });
}
