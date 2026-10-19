# ShieldRoute VPN — Android Flutter Client

> **Academic Project:** University Mobile App Development  
> **Target Platform:** Android (Android 7.0 / API 24 through Android 16 / API 36)  
> **Design Source of Truth:** Google Stitch Project *App Screen UI Design* (`Quiet Bastion`)

---

## 1. Project Overview

**ShieldRoute VPN** is an Android VPN client application built with Flutter, Dart, and OpenVPN. Developed for university coursework, the app emphasizes:
- Clean modular architecture isolating UI from VPN protocol primitives.
- Strict visual adherence to the Google Stitch design system (**Quiet Bastion**).
- Educational transparency, clear VPN permission disclosures, and honest privacy assurances.
- Dynamic relay discovery with fail-safe academic seed servers.

---

## 2. Technical Specifications & Toolchain

- **Flutter SDK:** 3.47.3 (Channel stable)
- **Dart SDK:** 3.13.3
- **Android Target API:** 36 (Android 16 Ready)
- **Android Compile API:** 36
- **Android Min SDK:** 24 (Android 7.0 Nougat)
- **State Management:** Provider / ChangeNotifier
- **VPN Core:** OpenVPN 2.5 protocol via `openvpn_flutter`
- **Typography:** Inter (Google Fonts)

---

## 3. Design System Integration (Google Stitch)

The application design is derived from Google Stitch project `App Screen UI Design` (`projects/3821877934525041340`), implementing the **Quiet Bastion** theme:

- **Dominant Core (55–65%):** Ink Navy (`#172B4D`) for typography, primary buttons, boundaries, and app bars.
- **Atmospheric Canvas (30–40%):** Mist Canvas (`#F6F8FB`) for background surfaces and screens.
- **Elevated Substrate:** Pure White (`#FFFFFF`) for cards with `20dp` border radius and `1dp` stroke in Ink Navy 12% (`rgba(23, 43, 77, 0.12)`).
- **Rare Verification Accent (≤ 5%):** Signal Lime (`#C7F000`) used strictly for state indicators (e.g. connection status pips, active toggles). Never used for large backgrounds or body text.
- **Central Connection Trigger (The Orb):** Dedicated `112dp` action button with an outer `12dp` cushion ring, animated 360-degree sweep during negotiation, and Signal Lime pip upon verification.

Detailed token mappings are preserved in [`.stitch/DESIGN.md`](.stitch/DESIGN.md).

---

## 4. Architecture

ShieldRoute strictly decouples the UI layer from underlying VPN protocols:

```
UI Layer (Widgets & Views)
        ↓
Controller & Repository Layer (VpnRepository, ServerService, AuthService)
        ↓
Service Abstraction Layer (VpnService contract)
        ↓
Protocol Implementation (OpenVpnService via openvpn_flutter)
        ↓
Android VpnService Subsystem (TUN interface)
```

For diagrams and flowcharts, see [`ARCHITECTURE.md`](ARCHITECTURE.md).

---

## 5. Key Features

1. **Animated Interactive Splash:** Custom vector ShieldRoute shield and route path with smooth tween curves.
2. **Flexible Entry Options:** Create Account, Sign In, or full-featured **Guest Mode** requiring zero registration.
3. **Transparent Permission Disclosure (Phase 9):** Explains VpnService, traffic encapsulation, and uninspected packets with an unchecked consent checkbox.
4. **Real Connection State Machine:** States `DISCONNECTED`, `CHECKING`, `CONNECTING`, `CONNECTED`, `DISCONNECTING`, and `ERROR`. The UI never fakes a connected state.
5. **Dynamic Server Discovery:** Real-time fetching from public relay directories, CSV parser, latency badge sorting, protocol filters, and bookmarking.
6. **Session History & Analytics:** Local storage of session duration, throughput data (bytes in/out), exit node identity, and one-tap history purging.
7. **Connection and Privacy Controls:** Auto-connect, recovery after internet returns, relay selection, reduced motion, diagnostics, Terms, and Privacy Policy.

The Android app uses the OpenVPN profiles published by VPN Gate. Its bundled profiles are offline fallbacks with unknown current availability; live relay metadata is preferred. The experimental native TUN demonstration was removed because it did not carry user traffic. WireGuard is not selectable because this relay source does not provide WireGuard peer configurations.

---

## 6. Setup & Running

### Prerequisites
- Android Studio with Android SDK 36 (or command-line tools).
- Java 17 / Kotlin Gradle plugin.
- Flutter 3.47.x.

### Steps
1. Fetch dependencies:
   ```bash
   flutter pub get
   ```
2. Verify static analysis:
   ```bash
   flutter analyze
   ```
3. Run test suite:
   ```bash
   flutter test
   ```
4. Run on a connected Android device or emulator:
   ```bash
   flutter run -d <device_id>
   ```
5. Build Android APK:
   ```bash
   flutter build apk --debug
   ```

---

## 7. Documentation Index

- [`.stitch/DESIGN.md`](.stitch/DESIGN.md) — Stitch Quiet Bastion visual guidelines
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — Application flow and component interaction
- [`PRIVACY_NOTES.md`](PRIVACY_NOTES.md) — Privacy boundaries and data safety
- [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) — Third-party libraries and licenses
