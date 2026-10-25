# Third-Party Software Notices and Licenses

This application incorporates open-source libraries and components. Below is the catalog of packages, versions, and respective licenses:

---

### 1. axevpn_flutter
- **Version:** `^3.1.0`
- **License:** GNU General Public License v3.0
- **Source:** [https://pub.dev/packages/axevpn_flutter](https://pub.dev/packages/axevpn_flutter)
- **Role:** OpenVPN fallback engine (ics-openvpn / OpenVPN 2.7, built for 16 KB page-size devices). Bundles OpenVPN (GPLv2) and OpenSSL; distributing the app must respect these licenses.

---

### 1a. VPN Gate relay catalog
- **Source:** [https://www.vpngate.net](https://www.vpngate.net) (University of Tsukuba)
- **Role:** Public relay list and OpenVPN profiles. `assets/servers/vpngate_snapshot.csv` is a snapshot of VPN Gate's official `public-vpn-*` relays, plus a few long-running volunteer relays, used as an offline fallback.

### 1b. VPNBook free VPN
- **Source:** [https://www.vpnbook.com/freevpn](https://www.vpnbook.com/freevpn)
- **Role:** Free OpenVPN servers in Germany, France, the UK, the US, Canada and Poland. The app reads the shared login VPNBook publishes on that page (it changes every one to two weeks); `assets/servers/vpnbook_template.ovpn` holds the certificates every VPNBook server shares. VPNBook publishes no terms for third-party clients, so check with VPNBook before distributing the app publicly.

The SSTP tunnel (`SstpTunnel.kt`) is original code implementing [MS-SSTP] and PPP (RFC 1661/1332/1334).

---

### 2. provider
- **Version:** `^6.1.5+1`
- **License:** MIT License
- **Source:** [https://pub.dev/packages/provider](https://pub.dev/packages/provider)
- **Role:** Reactive state management and dependency injection wrapper.

---

### 3. shared_preferences
- **Version:** `^2.5.6`
- **License:** BSD 3-Clause License
- **Source:** [https://pub.dev/packages/shared_preferences](https://pub.dev/packages/shared_preferences)
- **Role:** Local persistent storage for user preferences, consent flags, and session history.

---

### 4. http
- **Version:** `^1.6.0`
- **License:** BSD 3-Clause License
- **Source:** [https://pub.dev/packages/http](https://pub.dev/packages/http)
- **Role:** Composable HTTP client for querying dynamic public relay registries.

---

### 5. intl
- **Version:** `^0.20.3`
- **License:** BSD 3-Clause License
- **Source:** [https://pub.dev/packages/intl](https://pub.dev/packages/intl)
- **Role:** Date, time, and localized number formatting for session logs.

---

### 6. uuid
- **Version:** `^4.6.0`
- **License:** MIT License
- **Source:** [https://pub.dev/packages/uuid](https://pub.dev/packages/uuid)
- **Role:** Generation of cryptographically unique session identifiers.

---

### 7. crypto
- **Version:** `^3.0.7`
- **License:** BSD 3-Clause License
- **Source:** [https://pub.dev/packages/crypto](https://pub.dev/packages/crypto)
- **Role:** SHA-256 password hashing and payload digest verification.

---

### 8. google_fonts (Inter)
- **Version:** `^9.0.0`
- **Font License:** SIL Open Font License 1.1
- **Source:** [https://pub.dev/packages/google_fonts](https://pub.dev/packages/google_fonts)
- **Role:** Provides the Inter typeface specified by Google Stitch "Quiet Bastion".
