# Implementation Plan — Animated Splash Screen & UI Improvements
## ShieldRoute VPN (`shieldroute_vpn`)

Ordered by dependency. Each step leaves the codebase in a buildable state.

---

- [ ] 1. Add dark gradient color constants to `app_colors.dart`.
      Add six new `static const Color` fields inside `AppColors` (before the closing brace).
      Do NOT touch or remove any existing color. New fields:
      ```dart
      // Dark Splash Palette
      static const Color deepNavy      = Color(0xFF0A0E1A);
      static const Color darkNavyMid   = Color(0xFF0D1526);
      static const Color navyPurple    = Color(0xFF1A1040);
      static const Color glowCyan      = Color(0xFF00D4FF);
      static const Color glowCyanDim   = Color(0x3300D4FF); // 20% opacity
      static const Color splashGradientStart = deepNavy;
      static const Color splashGradientEnd   = navyPurple;
      ```
      Files: `lib/app/theme/app_colors.dart`
      Verify: `flutter analyze lib/app/theme/app_colors.dart` — no errors or warnings.

---

- [ ] 2. Rewrite `splash_view.dart` as a cinematic dark animated splash.
      Replace the entire file with a clean implementation. All of the following must be present:

      **Controllers (use `TickerProviderStateMixin`):**
      - `_entranceController` — 2500ms, runs once, drives all staggered entrance animations.
      - `_glowRingController` — 1800ms, repeats, drives the radar-ping glow ring.
      - `_particlesController` — 6000ms, repeats, drives floating dot particles.
      - `_dotsController` — 1200ms, repeats, drives loading-dots opacity.
      All four must be disposed in `dispose()`.

      **Background:**
      - `Container` with `BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.deepNavy, AppColors.navyPurple]))` as the first Stack child.

      **Floating particles (`_ParticlePainter`, a `CustomPainter`):**
      - Generates ~20 small circles (radius 1.5–3px) at pseudo-random fixed (x, fraction) positions using `List.generate` + `dart:math Random(42)` seeded for determinism.
      - In `paint()`, each particle's y-position = `(fixedFraction - progress * 0.3) % 1.0` so they drift upward slowly.
      - Color: `AppColors.glowCyanDim`. No alpha blending needed beyond the color's built-in 20% opacity.
      - Wrap in `AnimatedBuilder(animation: _particlesController)`.

      **Glow ring (`_GlowRingPainter`, a `CustomPainter`):**
      - Draws one expanding circle that pulses outward and fades: radius goes from `60` to `120` linearly with `_glowRingController.value`; opacity goes from `0.6` to `0.0`.
      - Paint: `color = AppColors.glowCyan.withValues(alpha: opacity)`, `style = PaintingStyle.stroke`, `strokeWidth = 2.0`.
      - Center at canvas center. Wrap in `AnimatedBuilder(animation: _glowRingController)`.

      **Entrance animations (all driven by `_entranceController`):**
      | Name | Tween | Interval | Curve |
      |---|---|---|---|
      | `_shieldScale` | 0.0 → 1.0 | 0.0 – 0.5 | `Curves.elasticOut` |
      | `_shieldFade`  | 0.0 → 1.0 | 0.0 – 0.3 | `Curves.easeIn` |
      | `_nameSlide`   | 30.0 → 0.0 | 0.16 – 0.6 | `Curves.easeOutCubic` |
      | `_nameFade`    | 0.0 → 1.0 | 0.16 – 0.55 | `Curves.easeIn` |
      | `_taglineFade` | 0.0 → 1.0 | 0.28 – 0.65 | `Curves.easeIn` |
      | `_dotsFade`    | 0.0 → 1.0 | 0.36 – 0.70 | `Curves.easeIn` |

      **Shield logo:**
      - `ScaleTransition(scale: _shieldScale)` wrapping `FadeTransition(opacity: _shieldFade)` wrapping `AppLogo(size: 96, showBadge: false)`.
      - Centered in the stack, no glow Container needed (the glow ring painter handles the halo).

      **App name text:**
      - `FadeTransition(opacity: _nameFade)` wrapping `AnimatedBuilder(_entranceController)` with `Transform.translate(offset: Offset(0, _nameSlide.value))`.
      - Text: `AppConstants.appName`, style `AppTextStyles.displayLg.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -0.6)`.

      **Tagline text:**
      - `FadeTransition(opacity: _taglineFade)`.
      - Text: `'Secure. Private. Free.'`, style `AppTextStyles.labelMd.copyWith(color: AppColors.glowCyan, letterSpacing: 2.0)`.

      **Loading dots (3 dots):**
      - `FadeTransition(opacity: _dotsFade)` wrapping a `Row` of 3 dots.
      - Each dot is an `AnimatedBuilder(animation: _dotsController)` that computes its own opacity via `Interval(i * 0.25, i * 0.25 + 0.5, curve: Curves.easeInOut).transform(_dotsController.value)` for `i ∈ {0, 1, 2}`.
      - Each dot: `Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.glowCyan.withValues(alpha: opacity), shape: BoxShape.circle))` with `SizedBox(width: 8)` spacing.
      - Positioned at bottom center: use `Positioned(bottom: 48)` inside the Stack.

      **`_startSequence()` (keep logic, simplify timing):**
      ```dart
      Future<void> _startSequence() async {
        final vpnRepo = context.read<VpnRepository>();
        final completer = Completer<void>();
        Timer(const Duration(milliseconds: 2400), () {
          if (!completer.isCompleted) completer.complete();
        });
        vpnRepo.loadServers()
            .then((_) { if (!completer.isCompleted) completer.complete(); })
            .catchError((_) { if (!completer.isCompleted) completer.complete(); });
        await completer.future;
        if (mounted && !_hasNavigated) _navigateNext();
      }
      ```

      **`_navigateNext()` — copy verbatim from the existing file, including:**
      - `_cachedPrefs` pattern (`didChangeDependencies` caching).
      - Guard `if (_hasNavigated || !mounted) return; _hasNavigated = true;`.
      - Cancel `_safetyTimer`.
      - `prefs.isAuthenticated` → `prefs.hasGrantedVpnConsent` branch logic.
      - `Navigator.of(context).pushReplacement(PageRouteBuilder(FadeTransition, 380ms))`.

      **Safety timer:** `Timer(const Duration(milliseconds: 4500), ...)` set in `initState`, cancelled in `_navigateNext` and `dispose`.

      **No skip button, no interactive hub, no stage cards, no progress bar, no Quick-Start button.**

      **Layout (outermost widget is `Scaffold(backgroundColor: AppColors.deepNavy, body: Stack(fit: StackFit.expand, ...))`):**
      ```
      Stack
        ├── gradient Container (fill)
        ├── particles CustomPaint (fill)
        ├── glow ring CustomPaint (centered, 240×240)
        ├── centered Column (MainAxisAlignment.center)
        │     ├── shield logo (ScaleTransition + FadeTransition)
        │     ├── SizedBox(height: 32)
        │     ├── app name (FadeTransition + Transform.translate)
        │     ├── SizedBox(height: 12)
        │     └── tagline (FadeTransition)
        └── loading dots (Positioned bottom: 48)
      ```

      Files: `lib/features/splash/splash_view.dart`
      Verify: `flutter analyze lib/features/splash/splash_view.dart` — zero errors.

---

- [ ] 3. Improve `connection_orb.dart` — add glow, pulse animation when connected.
      The existing single `AnimationController` (`_animController`, 1200ms) is used for connecting/checking spin. Add a second controller for the connected-state pulse.

      **New controller `_pulseController`:**
      ```dart
      late AnimationController _pulseController;
      // in initState:
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      );
      if (widget.state == VpnConnectionState.connected) _pulseController.repeat(reverse: true);
      ```
      Add to `didUpdateWidget`: start `_pulseController.repeat(reverse: true)` on connected, stop+reset otherwise.
      Dispose in `dispose()`.

      **Scale pulse:**
      - Declare `final _pulseScale = Tween<double>(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));`
      - Wrap the core 112dp orb `Container` in `AnimatedBuilder(animation: _pulseController, builder: (ctx, child) => Transform.scale(scale: isConnected ? _pulseScale.value : 1.0, child: child))`.

      **Glow behind orb when connected:**
      - Replace the existing `outerCushion` ring `Container` (which currently has `color: AppColors.navy06`) with a conditional decoration:
        ```dart
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isConnected
              ? RadialGradient(colors: [
                  AppColors.signalLime.withValues(alpha: 0.18),
                  AppColors.glowCyan.withValues(alpha: 0.08),
                  Colors.transparent,
                ])
              : null,
          color: isConnected ? null : AppColors.navy06,
        ),
        ```
      - When connected, add a `boxShadow` to the 112dp orb `Container`:
        ```dart
        BoxShadow(
          color: AppColors.signalLime.withValues(alpha: 0.30),
          blurRadius: 24,
          spreadRadius: 4,
        ),
        ```
        Keep existing `BoxShadow(color: AppColors.navy06, ...)` as a second shadow entry.

      Files: `lib/features/common/connection_orb.dart`
      Verify: `flutter analyze lib/features/common/connection_orb.dart` — zero errors.

---

- [ ] 4. Improve `welcome_view.dart` — gradient background, logo animation, feature card accent, button glow.
      Convert `WelcomeView` from `StatelessWidget` to `StatefulWidget` (rename state class `_WelcomeViewState`) because the logo scale-in needs an `AnimationController`.

      **Logo scale-in animation:**
      - `with SingleTickerProviderStateMixin`.
      - In `initState`: create `AnimationController(_logoCtr, 600ms)`, animate `_logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _logoCtr, curve: Curves.elasticOut))`. Call `_logoCtr.forward()`.
      - Dispose in `dispose()`.
      - Wrap `AppLogo(size: 88, showBadge: true)` in `ScaleTransition(scale: _logoScale)`.

      **Gradient background:**
      - Change `Scaffold(backgroundColor: AppColors.mistBase)` to `Scaffold(backgroundColor: Colors.transparent)`.
      - Wrap the `SafeArea` in a `Container` with:
        ```dart
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.mistBase, Color(0xFFEEF4FF)],
          ),
        ),
        ```

      **Feature pills card top-border accent:**
      - Add `border: Border(top: BorderSide(color: AppColors.signalLime, width: 2), ...)` to the pills `Container`'s `BoxDecoration`, keeping the existing `borderRadius` and side borders.
      - Because `Border.all` conflicts with `BorderRadius`, switch to `Border(top: BorderSide(color: AppColors.signalLime, width: 2), left: BorderSide(color: AppColors.surfaceBorder, width: 1), right: BorderSide(color: AppColors.surfaceBorder, width: 1), bottom: BorderSide(color: AppColors.surfaceBorder, width: 1))`.

      **Create Account button glow:**
      - Wrap `PrimaryButton(text: 'Create Account', ...)` in a `Container` with:
        ```dart
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.inkNavy.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        ```

      Files: `lib/features/onboarding/welcome_view.dart`
      Verify: `flutter analyze lib/features/onboarding/welcome_view.dart` — zero errors.

---

- [ ] 5. Run `flutter analyze` across the entire project and fix all reported errors.
      After completing steps 1–4, run the full analyzer. Fix every `error` and `warning`. Common issues to watch for:
      - Unused imports left from the splash rewrite (remove `dart:math`, `package:flutter/services.dart`, etc. if not used in the new splash).
      - Missing `glowCyan` / `deepNavy` references if the orb or welcome changes reference new colors before step 1 is applied (ordering handles this).
      - `withOpacity` deprecation — use `withValues(alpha: x)` throughout (existing code already does this; maintain the pattern).
      - The `Colors.transparent` reference in `welcome_view.dart` is from `package:flutter/material.dart`, already imported.

      Files: any file the analyzer flags.
      Verify: `flutter analyze` in `d:\Android Studio Projects\secure_VPN` — output ends with **"No issues found!"** (or only `info`-level hints, no errors or warnings).

---

## Dependency order summary

```
Step 1 (app_colors.dart)
  └─► Step 2 (splash_view.dart) — uses deepNavy, navyPurple, glowCyan, glowCyanDim
  └─► Step 3 (connection_orb.dart) — uses glowCyan (via AppColors)
  └─► Step 4 (welcome_view.dart) — uses mistBase (already exists); no new colors needed
Step 5 (flutter analyze) — depends on all prior steps being complete
```

Steps 2, 3, and 4 can be implemented in any order after step 1. Step 5 must come last.

---

## Key constraints (do not violate)

- **No new pub packages.** All animation uses Flutter's built-in `Animation` / `AnimationController` / `Tween` / `CustomPainter`. `google_fonts` is already available.
- **`_navigateNext()` logic is sacred.** Copy it exactly from the existing file — the `_cachedPrefs` pattern, `_hasNavigated` guard, timer cancellations, and the three-branch destination logic (`MainNavigationShell` / `VpnDisclosureView` / `WelcomeView`).
- **Safety timer is required.** Always 4500ms, always cancelled in both `_navigateNext` and `dispose`.
- **`AppLogo(size: 96, showBadge: false)` on the splash.** Dark background; badge clashes.
- **`withValues(alpha: x)` not `withOpacity(x)`.** Existing codebase pattern; Flutter 3.x deprecation.
- **Do not modify `app_theme.dart`, `router.dart`, `home_view.dart`, or any auth files.**
