# ShieldRoute VPN — Privacy Notes & Data Boundary Declarations

## 1. Academic Scope & Integrity

ShieldRoute VPN is an academic research prototype engineered for a university Mobile App Development curriculum. Unlike commercial VPNs that make marketing claims such as "100% untraceable" or "military-grade absolute anonymity," ShieldRoute adheres to strict academic honesty:
- No software provides absolute invisibility across all network adversary models.
- VPN encryption protects network data between your device and the chosen relay gateway.
- Public relay operators may maintain standard server connection timestamps and access logs in according with their respective regional regulations.

---

## 2. Android VpnService Disclosure

Android requires explicit user disclosure prior to invoking `android.net.VpnService`:
- **Core Purpose:** Establishing an encrypted virtual network interface (TUN) to route device traffic through an OpenVPN endpoint.
- **Traffic Scope:** All outbound IP traffic is encapsulated into OpenVPN protocol datagrams directed toward the selected relay server.
- **User Consent:** The user is presented with the explicit in-app disclosure on screen `S03 - VPN Permission Disclosure` containing an unselected consent checkbox (`[ ] I understand how VPN access is used.`). System permission is only requested after active user agreement.

---

## 3. Data Processing & Inspection Boundaries

| Category | Policy | Implementation |
|---|---|---|
| **Browsing History** | **Never Collected** | No URL tracking, search tracking, or page analysis. |
| **Packet Payloads** | **Never Inspected** | No Deep Packet Inspection (DPI) or payload modification. |
| **Credential Storage** | **Secure / Salted** | Local authentication hashes are salted with SHA-256. |
| **Analytics & Trackers** | **Zero Third Parties** | Zero advertisement SDKs, analytics SDKs, or trackers. |
| **Local Metrics** | **Local Only** | Session durations and bandwidth counts reside in `SharedPreferences`. |

---

## 4. User Data Erasure Rights

Users maintain complete sovereignty over data stored on their device:
1. **Clear Local History:** Navigating to `Settings > Clear Local History` permanently purges all session records.
2. **Delete Account:** Navigating to `Settings > Delete Account` deletes the profile, revokes consent, and wipes all bookmarks and session logs.
