# Galaxy VPN — Stitch Design System Reference (Quiet Bastion)

**Design Source of Truth:** Google Stitch Project `App Screen UI Design` (`projects/3821877934525041340`)  
**Design Theme:** Quiet Bastion  
**Target:** Android (Edge-to-Edge, Material 3 disciplined, High privacy focus)

---

## 1. Brand Philosophy & Aesthetic Persona

This design system embodies a calm, privacy-first Android experience designed to strip away the anxiety, synthetic urgency, and cyberpunk visual noise common to legacy utility and VPN products. Instead of militaristic shields, neon matrix grids, or fake radar animations, the identity projects clarity, transparency, and serene technical competence.

- **Style:** Disciplined Mateiral 3 infused with editorial restraint and purposeful minimalism.
- **Tone:** Authoritative, quiet, understated, and transparent. The interface never shouts; it demonstrates protection through steady, predictable states.
- **Emotional Response:** Confidence, decompression, and seamless control. Users feel unburdened by technical friction, knowing data routing is strictly utilitarian and their boundary is secure.
- **Visual Rules:**
  - **No Neon, No Glows:** Glow effects, matrix particles, and skeuomorphic dials are strictly disallowed.
  - **Generous Canvas:** Negative space around critical actions gives prominence to touch points without cognitive overload.
  - **System Authenticity:** Follows Android-native patterns (standard navigation bars, system sheets, predictable back behavior) executed with tailored tactile refinement.

---

## 2. Color Palette & Volumetric Discipline

The palette operates under strict volumetric discipline governed by two dominant anchors and one strictly capped functional accent:

### Core Tokens
| Token | Hex / Value | Allocation | Role & Usage |
|---|---|---|---|
| **Ink Navy** | `#172B4D` | 55–65% | The structural core. Typography, dominant interactive buttons, navigation indicators, key boundaries. Deep stability & institutional clarity. |
| **Mist Canvas** | `#F6F8FB` | 30–40% | The atmospheric envelope. Canvas background, page surface, calm baseline. |
| **Pure White** | `#FFFFFF` | — | Elevated cards substrate, modal dialog surfaces, input backgrounds. |
| **Signal Lime** | `#C7F000` | ≤ 5% | **Rare Accent.** Reserved exclusively as state verification: connection confirmation badge, protected status pips, active toggles. NEVER large fills or text. |
| **Error / Alert** | `#BA1A1A` / `#FFDAD6` | < 1% | Explicit connection error or authentication failure indicators. |

### Neutral Opacity Scales (Derived from Ink Navy `#172B4D`)
- **Navy 100% (`#172B4D`):** Primary headlines, primary buttons, critical icons.
- **Navy 70% (`rgba(23, 43, 77, 0.70)`):** Subheadings, supporting content, unselected navigation icons.
- **Navy 45% (`rgba(23, 43, 77, 0.45)`):** Captions, helper texts, inactive timestamps, metadata.
- **Navy 12% (`rgba(23, 43, 77, 0.12)`):** Inset borders, card outlines, list item dividers.
- **Navy 6% (`rgba(23, 43, 77, 0.06)`):** Hover, press, and ripple background tints, outer orb cushion rings.

---

## 3. Typography (Inter)

The typography scale utilizes **Inter** across all display, body, and micro-label tiers:

- **display-lg:** `32px` / Weight `700` (Bold) / Line Height `40px` / Letter Spacing `-0.02em`
- **headline-lg:** `26px` / Weight `700` (Bold) / Line Height `32px` / Letter Spacing `-0.015em`
- **headline-md:** `22px` / Weight `700` (Bold) / Line Height `28px` / Letter Spacing `-0.01em`
- **headline-sm:** `18px` / Weight `700` (Bold) / Line Height `24px` / Letter Spacing `-0.005em`
- **metric-lg:** `28px` / Weight `700` (Bold) / Line Height `32px` / Letter Spacing `-0.02em` (tabular data: ping, session time, bandwidth)
- **body-lg:** `16px` / Weight `400` (Regular) / Line Height `24px` / Letter Spacing `0em`
- **body-md:** `14px` / Weight `400` (Regular) / Line Height `20px` / Letter Spacing `0.01em`
- **label-lg:** `14px` / Weight `600` (SemiBold) / Line Height `20px` / Letter Spacing `0.01em`
- **label-md:** `12px` / Weight `500` (Medium) / Line Height `16px` / Letter Spacing `0.02em`
- **label-sm:** `11px` / Weight `600` (SemiBold) / Line Height `14px` / Letter Spacing `0.04em`

---

## 4. Layout, Spacing & Geometry

- **Base Grid:** 8-point base grid rooted in 4dp step increments.
- **Screen Margins:** Horizontal margin is locked to `20dp` (`1.25rem`) from viewport edges.
- **Component Gaps:**
  - Major content cards: `16dp` (`1rem`)
  - Inline metadata rows: `8dp` (`0.5rem`) or `12dp` (`0.75rem`)
- **Corner Radii:**
  - Primary Cards & Modals: `20dp`
  - Buttons & Input Containers: `16dp`
  - Status Chips, Latency Pills, Protocol Tags: `999dp` (Pill / Full curvature)
  - Custom Checkboxes: `4dp`
- **Interactive Touch Targets:** Enforce hard minimum `48dp × 48dp`.

---

## 5. Component Specifications

### 5.1 Buttons
- **Primary Button:** Solid Ink Navy (`#172B4D`), text in pure Mist/White (`#FFFFFF`), height `52dp`, radius `16dp`. Tap compression `scale: 0.98`.
- **Secondary Outlined Button:** Transparent fill, `1.5dp` border in Ink Navy 12% (`rgba(23, 43, 77, 0.12)`), text in Ink Navy 100%. Active state applies Navy 6%.
- **Text Button:** Frameless, minimal padding, label in Ink Navy 70%.

### 5.2 Connection Orb (Central Trigger)
A dedicated `112dp` circular action button centered on the Home screen:
- **Disconnected:** Ink Navy fill, white power/shield glyph, surrounded by a `12dp` outer cushion ring in Navy 6%.
- **Connecting:** Animated stroke outline cycling with a 360-degree sweep at `1.2s` cadence.
- **Connected:** Ink Navy fill accompanied by a dedicated `10dp` Signal Lime status pip and text explicitly stating `"Protected"`.

### 5.3 Cards & Containers
- White (`#FFFFFF`) surface backgrounds, `20dp` border radius, `1dp` stroke in Navy 12%, `16dp` to `20dp` inner padding.
- Hairline internal dividers: Navy 12%, inset by 16dp from card edges.
- Ambient card shadow: `0px 4px 16px rgba(23, 43, 77, 0.06)`. No colored glows.

### 5.4 Form Inputs & Text Fields
- Container height `52dp`, corner radius `16dp`, background `#FFFFFF`, border `1.5dp` Navy 12%.
- Focus state: border transitions to solid Ink Navy (`#172B4D`).
- Error state: border shifts to neutral contrast / Error Red (`#BA1A1A`) with inline helper text.

### 5.5 Status Chips & Badges
- **Status Badge (Connected):** Pill (`999dp`), surface in Ink Navy, leading dot in Signal Lime (`#C7F000`), label in white `label-md` reading `"PROTECTED"`.
- **Latency / Country Badge:** Two-letter ISO country code centered in an Ink Navy 6% tinted pill with Ink Navy 70% typography.

### 5.6 Bottom Navigation Bar
- 4 primary destinations: **Home** | **Servers** | **Activity** | **Settings**.
- Surface: Clean white (`#FFFFFF`) or subtle mist, top hairline divider in Navy 12%.
- Selected item: Ink Navy 100% icon and label with subtle indicator pill.
- Unselected item: Ink Navy 70% icon and label.

---

## 6. Stitch Project Screens Inventory

1. **S01 — Splash Screen (Animated):** Custom Galaxy VPN logo, subtle shield animation, 1.2–1.6s transition.
2. **S01 — Welcome & Entry:** Brand greeting, "Create Account", "Login", and prominent "Continue as Guest".
3. **S02 — Authentication:** Clean Login, Sign Up, Forgot Password flows with validation.
4. **S03 — VPN Permission Disclosure:** Educational dialog explaining Android VpnService usage, traffic routing, uninspected traffic, unchecked consent checkbox required before system permission prompt.
5. **S08 — Home (Disconnected):** App identity, current server card, connection orb, network info.
6. **S09 — Home (Connecting):** Progress pulse, "Connecting...", cancel action.
7. **S10 — Home (Connected):** "Protected" badge with Signal Lime pip, session duration, public IP, bandwidth in/out, disconnect action.
8. **S11 — Connection Success Sheet:** Confirmation drawer with server node details.
9. **S12 — Connection Error Screen:** Human-readable diagnosis, recovery action.
10. **S13 — Server Discovery / List:** Search, filters (Country, Latency, Protocol), sorting, latency badges, favorites toggle.
11. **S14 — Server Details Sheet:** Full technical specs (host, protocol, ping, location, availability).
12. **S17 — Activity History:** Total protected time, data transfer totals, session history list, clear history confirmation.
13. **S18 — Session Details:** Granular timestamp, duration, data received/sent, protocol, exit node.
14. **S19 — Settings:** Connection preferences (auto-connect, reconnect), Appearance, Privacy shortcuts, Account, Support.
15. **S20 — Profile:** User account details (Guest mode indicator or demo profile).
16. **S21 — Privacy Center:** Plain English explanations of data retention, routing, no traffic inspection.
17. **S22/S23 — Terms of Service & Privacy Policy:** Clear academic and transparent privacy documentation.
18. **S24/S25 — Help / FAQ & Report a Problem:** Interactive FAQ accordion and diagnostic feedback form.
19. **S26 — About:** University project declaration, build version, acknowledgments.
20. **S27 — Delete Account Confirmation:** Destructive action confirmation dialog.
21. **S28/S29 — Offline & Server List Unavailable States:** Polished retryable error screens.
