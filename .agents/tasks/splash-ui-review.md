# Animated splash screen and welcome UI overhaul

The change replaces a static splash with a fully animated entrance sequence: particles drifting upward, expanding glow rings, an elastic shield scale-in, and staggered text fade/slide. Navigation from splash now gates on both `isAuthenticated` and `hasGrantedVpnConsent`. `WelcomeView` gains a logo scale-in animation. `ConnectionOrb` picks up a `_glowController` for a connected-state heartbeat pulse. `AppColors` adds the dark palette (deepNavy / darkNavyMid / navyPurple / glowCyan) consumed by the splash background gradient.

Watch for: `_loadingDotsController` drives an opacity calculation inside `AnimatedBuilder.builder` that calls `math.pow` on every frame tick (confirmed). Not a crash risk, but the only allocation hot-path in the file and worth addressing for low-end devices.

**Verdict**: APPROVED

---

## High-level view

All four `AnimationController` instances in `_SplashViewState` are disposed in `dispose()` and `TickerProviderStateMixin` is used correctly. All `CurvedAnimation`/`Interval` construction happens in `initState`. The `_navigateNext` guard — `_hasNavigated` flag set before `pushReplacement`, safety timer cancelled on entry — is race-free between the server-load path and the 4500 ms safety timer, and both timers are cancelled in `dispose`.

The loading-dots animation calls `math.pow(math.sin(...), 2)` inside `AnimatedBuilder.builder` for each of three dots on every frame. `math.pow` returns `num`, so Dart boxes the result each time. At 60 fps that's ~180 boxing allocations per second for a decorative indicator. Pre-computing these as `Animation<double>` objects in `initState` would eliminate the overhead entirely.

`WelcomeView` and `ConnectionOrb` both dispose their controllers correctly. `ConnectionOrb.didUpdateWidget` handles all connecting/connected/idle transitions without gaps.

No new packages were added.

---

<details>
<summary>Issues (1)</summary>

1. **Per-frame `math.pow` boxing in dots builder** — `math.pow` and `math.sin` are called inside `AnimatedBuilder.builder` three times per frame (~180 boxed `num` allocations/sec at 60 fps). Move the opacity curves to pre-computed `Animation<double>` objects built in `initState`, or accept the overhead on mid/high-end targets. Not blocking.

</details>

<details>
<summary>Details</summary>

### Loading-dot opacity allocation in build

```dart
// AnimatedBuilder.builder — runs ~60×/sec per dot:
final raw = _loadingDotsController.value * 3 - i;
final t = raw.clamp(0.0, 1.0);
final opacity = 0.2 + 0.8 * math.pow(math.sin(math.pi * t), 2);
```

`math.pow` returns `num`, not `double`. Dart will box the result on every call. The `.toDouble()` cast on the next line confirms the author knew about the type, but the allocation still happens before the cast. Replacing this with a `TweenSequence` or `CurvedAnimation` per dot — built once in `initState` — costs zero per-frame allocations and keeps the same visual curve.

</details>

---

<details>
<summary>Files changed</summary>

- `lib/app/theme/app_colors.dart` — added dark palette tokens: `deepNavy`, `darkNavyMid`, `navyPurple`, `glowCyan`, `glowCyanDim`
- `lib/features/splash/splash_view.dart` — full rewrite: particle system, glow rings, four-controller entrance animation, corrected navigation guard
- `lib/features/common/connection_orb.dart` — added `_glowController` for connected-state heartbeat pulse; full `didUpdateWidget` lifecycle management
- `lib/features/onboarding/welcome_view.dart` — added `_scaleController` for logo entrance animation; guest-navigation path preserved

Full diff: `git diff main -- lib/app/theme/app_colors.dart lib/features/splash/splash_view.dart lib/features/common/connection_orb.dart lib/features/onboarding/welcome_view.dart`

</details>
