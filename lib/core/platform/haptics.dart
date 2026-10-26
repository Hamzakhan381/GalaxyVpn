import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// What an interaction feels like, from lightest to strongest.
enum HapticKind {
  /// A selection changed: tabs, switches, list choices.
  tick,

  /// A button or row that acts.
  click,

  /// The connect button.
  heavy,

  /// The tunnel came up.
  success,

  /// The connection failed.
  error,
}

/// Haptic feedback for the app's interactions. On Android MainActivity plays
/// it on the vibrator itself: Flutter's [HapticFeedback] goes through view
/// haptic constants that many budget phones play too faintly to feel. It is
/// the fallback elsewhere.
class Haptics {
  Haptics._();

  static const MethodChannel _channel = MethodChannel(
    'com.galaxyvpn/native_engine',
  );

  /// Follows Settings › Haptic Feedback.
  static bool enabled = true;

  /// Taps closer together than this (a fast double tap, a burst of switches)
  /// play once instead of blurring into one long buzz.
  static const Duration _minGap = Duration(milliseconds: 40);
  static DateTime _lastPlayed = DateTime.fromMillisecondsSinceEpoch(0);

  static void tick() => play(HapticKind.tick);
  static void click() => play(HapticKind.click);
  static void heavy() => play(HapticKind.heavy);
  static void success() => play(HapticKind.success);
  static void error() => play(HapticKind.error);

  static void play(HapticKind kind) {
    if (!enabled) return;
    // Connection changes also arrive while the app is in the background;
    // the phone should not buzz in the user's pocket for those.
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    if (now.difference(_lastPlayed) < _minGap) return;
    _lastPlayed = now;

    if (kIsWeb || !Platform.isAndroid) {
      unawaited(_fallback(kind));
      return;
    }
    unawaited(
      _channel
          .invokeMethod<bool>('haptic', kind.name)
          .then<void>((_) {}, onError: (Object _) => _fallback(kind)),
    );
  }

  static Future<void> _fallback(HapticKind kind) => switch (kind) {
    HapticKind.tick => HapticFeedback.selectionClick(),
    HapticKind.click => HapticFeedback.lightImpact(),
    HapticKind.heavy => HapticFeedback.mediumImpact(),
    HapticKind.success => HapticFeedback.heavyImpact(),
    HapticKind.error => HapticFeedback.vibrate(),
  };
}
