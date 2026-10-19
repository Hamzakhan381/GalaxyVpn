/// Connection states strictly enforced by the ShieldRoute VPN state machine
enum VpnConnectionState {
  disconnected,
  checking,
  connecting,
  connected,
  disconnecting,
  error,
}
