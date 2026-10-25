/// Connection states strictly enforced by the Galaxy VPN state machine
enum VpnConnectionState {
  disconnected,
  checking,
  connecting,
  connected,
  disconnecting,
  error,
}
