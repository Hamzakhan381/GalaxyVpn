import 'package:flutter/material.dart';

import '../../core/platform/haptics.dart';
import '../../domain/repositories/preferences_repository.dart';

/// How much the interface animates.
enum MotionLevel {
  /// Every effect, including always-running decorative loops.
  full,

  /// For low-end phones: decorative loops (star field, backgrounds, idle
  /// pulses) hold still and drop their blur; short transitions and progress
  /// spinners remain, so idle screens stop redrawing.
  lite,

  /// No animation beyond what shows progress.
  off;

  static MotionLevel? parse(String? name) {
    for (final level in values) {
      if (level.name == name) return level;
    }
    return null;
  }
}

/// The chosen [MotionLevel]: persisted, and observed through [MotionScope] so
/// every animation updates as soon as the setting changes.
class MotionSettings extends ChangeNotifier {
  final PreferencesRepository _prefs;
  MotionLevel _level;

  MotionSettings(this._prefs)
    : _level = MotionLevel.parse(_prefs.motionLevel) ?? MotionLevel.full;

  MotionLevel get level => _level;

  /// The user's own choice: kept from now on instead of the device default.
  Future<void> setLevel(MotionLevel level) async {
    await _prefs.setMotionLevelChosen(true);
    await _apply(level);
  }

  /// Picks the level for this device unless the user chose one: lite on
  /// low-end phones, full elsewhere. Checked on every launch, so a phone
  /// first judged wrongly (or by an older app version) is corrected.
  Future<void> applyDeviceDefault({required bool lowEndDevice}) async {
    if (_prefs.motionLevelChosen) return;
    await _apply(lowEndDevice ? MotionLevel.lite : MotionLevel.full);
  }

  Future<void> _apply(MotionLevel level) async {
    if (level != _level) {
      _level = level;
      notifyListeners();
    }
    await _prefs.setMotionLevel(level.name);
  }
}

/// Provides [MotionSettings] to the whole app.
class MotionScope extends InheritedNotifier<MotionSettings> {
  const MotionScope({
    super.key,
    required MotionSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static MotionSettings? settingsOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<MotionScope>()?.notifier;
}

/// Shared motion primitives so every screen moves with the same rhythm.
class Motion {
  Motion._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);

  /// Delay between consecutive items of a staggered entrance.
  static const int staggerStepMs = 55;

  static bool get isTestEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  /// The effective level: the in-app setting, or [MotionLevel.off] when the
  /// platform's "remove animations" accessibility flag is on. Widgets that
  /// read it rebuild when it changes.
  static MotionLevel levelOf(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return MotionLevel.off;
    }
    return context
            .dependOnInheritedWidgetOfExactType<MotionScope>()
            ?.notifier
            ?.level ??
        MotionLevel.full;
  }

  /// True when animations are off: skip transitions and entrances too.
  static bool isReduced(BuildContext context) =>
      levelOf(context) == MotionLevel.off;

  /// True below full quality: hold always-running decorative effects still.
  static bool isLite(BuildContext context) =>
      levelOf(context) != MotionLevel.full;

  /// [shadows] at full quality, none below it. Impeller keeps no raster cache,
  /// so every soft shadow on screen is blurred again on each frame, which
  /// budget GPUs feel the most; the surfaces' borders still separate them.
  static List<BoxShadow>? shadows(
    BuildContext context,
    List<BoxShadow> shadows,
  ) => isLite(context) ? null : shadows;
}

/// Lets a subtree replay its [AnimatedFadeSlide] entrances, e.g. each time a
/// bottom-navigation tab becomes visible again.
class EntranceReplay extends InheritedNotifier<ValueNotifier<int>> {
  const EntranceReplay({
    super.key,
    required ValueNotifier<int> trigger,
    required super.child,
  }) : super(notifier: trigger);

  static ValueNotifier<int>? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<EntranceReplay>()?.notifier;
}

/// Springy scale-down while a pointer is held on [child]. Uses a [Listener]
/// so it never competes with the child's own tap / ink handling.
class PressableScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;
  final bool haptic;
  final bool enabled;

  const PressableScale({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
    this.haptic = false,
    this.enabled = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (!widget.enabled || _pressed == value) return;
    if (value && widget.haptic) Haptics.tick();
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: _pressed ? Motion.fast : Motion.medium,
        curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// App-wide page transition: the incoming page rises, scales and fades in
/// while the outgoing page gently recedes.
class GalaxyPageTransitionsBuilder extends PageTransitionsBuilder {
  const GalaxyPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Motion.isReduced(context)) {
      return FadeTransition(opacity: animation, child: child);
    }

    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final exit = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 0.95).animate(exit),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.55).animate(exit),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(enter),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(enter),
            child: FadeTransition(opacity: enter, child: child),
          ),
        ),
      ),
    );
  }
}

/// Odometer-style text: only the characters that change roll vertically,
/// so ticking timers and counters feel alive without the whole value jumping.
class OdometerText extends StatelessWidget {
  final String value;
  final TextStyle style;
  final Duration duration;

  const OdometerText(
    this.value, {
    super.key,
    required this.style,
    this.duration = const Duration(milliseconds: 360),
  });

  @override
  Widget build(BuildContext context) {
    final tabular = style.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final chars = value.characters.toList();

    return Semantics(
      label: value,
      excludeSemantics: true,
      child: ClipRect(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < chars.length; i++)
              AnimatedSwitcher(
                // Below full quality digits change in place: the roll redraws
                // the screen for a third of every second while connected.
                duration: Motion.isLite(context) ? Duration.zero : duration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.center,
                  children: [...previous, ?current],
                ),
                transitionBuilder: (child, anim) {
                  final incoming = child.key == ValueKey('$i:${chars[i]}');
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, incoming ? 0.9 : -0.9),
                      end: Offset.zero,
                    ).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  );
                },
                child: Text(
                  chars[i],
                  key: ValueKey('$i:${chars[i]}'),
                  style: tabular,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small status dot that breathes with a soft halo.
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({super.key, required this.color, this.size = 6});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.isTestEnvironment || Motion.isLite(context)) {
      _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox.square(
      dimension: s * 2.6,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: s * (1 + 1.6 * t),
                height: s * (1 + 1.6 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.45 * (1 - t)),
                ),
              ),
              Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
