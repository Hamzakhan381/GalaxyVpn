/// Global constants for Shark VPN
class AppConstants {
  AppConstants._();

  static const String appName = 'Shark VPN';
  static const String appTagline = 'Apex Privacy & High-Speed Encrypted Tunnel';
  static const String appVersion = '1.0.0';
  static const String academicContext =
      'University Mobile App Development Project';

  // VPN Gate API & fallback endpoints
  static const String vpnGateApiUrl = 'https://www.vpngate.net/api/iphone/';
  static const String vpnGateApiMirrorUrl =
      'https://download.vpngate.jp/api/iphone/';
  static const String publicRelayDisclaimer =
      'Public relay. Availability and performance may vary.';

  // Storage Keys
  static const String keyVpnConsentGranted = 'vpn_consent_granted';
  static const String keyIsAuthenticated = 'is_authenticated';
  static const String keyIsGuest = 'is_guest';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_name';
  static const String keyFavorites = 'favorite_server_ids';
  static const String keyAutoConnect = 'setting_auto_connect';
  static const String keyReconnectOnNetwork = 'setting_reconnect_network';
  static const String keyPreferredProtocol = 'setting_preferred_protocol';
  static const String keyReduceMotion = 'setting_reduce_motion';
  static const String keyEmulatorMode = 'setting_emulator_mode';
  static const String keySelectedServer = 'selected_server_cache';
  static const String keySessionsHistory = 'sessions_history_json';
  static const String keyApiRegion = 'setting_api_region';
  static const String keyCustomApiKey = 'setting_custom_api_key';
  static const String keyCustomApiUrl = 'setting_custom_api_url';
  static const String keyTurboSpeed = 'setting_turbo_speed';
  static const String keyAutoFastestServer = 'setting_auto_fastest_server';
  static const String keySmartFailover = 'setting_smart_failover';
  static const String keyKillSwitch = 'setting_kill_switch';

  // Permission Disclosure Strings (PHASE 9 requirement)
  static const String vpnDisclosureTitle = 'VPN Permission Disclosure';
  static const String vpnDisclosureCore =
      'Shark VPN uses Android\'s VPN service to route your device traffic through the VPN server you choose.';
  static const String vpnDisclosurePurpose =
      'To provide high-speed privacy routing and traffic encapsulation, Shark VPN creates an encrypted tunnel for your network packets.';
  static const String vpnDisclosureScope =
      'Traffic from your installed applications is encapsulated and transmitted directly to the selected VPN endpoint.';
  static const String vpnDisclosurePrivacy =
      'Shark VPN does NOT inspect your web payloads, monitor your browsing history, inject advertisements, or sell your data. No packet payload logging is ever conducted on this client.';
  static const String vpnConsentCheckbox =
      'I understand how VPN access is used.';
}
