/// Dynamic live metrics emitted during an active VPN session
class VpnLiveMetrics {
  /// Human-readable bit rate, e.g. "4.2 Mbps" or "860 Kbps".
  static String formatBitRate(double bitsPerSecond) {
    if (bitsPerSecond >= 1000000) {
      return '${(bitsPerSecond / 1000000).toStringAsFixed(1)} Mbps';
    }
    return '${(bitsPerSecond / 1000).round()} Kbps';
  }

  final int byteIn;
  final int byteOut;
  final String? duration;
  final String? publicIp;
  final int? pingMs;

  const VpnLiveMetrics({
    this.byteIn = 0,
    this.byteOut = 0,
    this.duration,
    this.publicIp,
    this.pingMs,
  });

  VpnLiveMetrics copyWith({
    int? byteIn,
    int? byteOut,
    String? duration,
    String? publicIp,
    int? pingMs,
  }) {
    return VpnLiveMetrics(
      byteIn: byteIn ?? this.byteIn,
      byteOut: byteOut ?? this.byteOut,
      duration: duration ?? this.duration,
      publicIp: publicIp ?? this.publicIp,
      pingMs: pingMs ?? this.pingMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VpnLiveMetrics &&
          runtimeType == other.runtimeType &&
          byteIn == other.byteIn &&
          byteOut == other.byteOut &&
          duration == other.duration &&
          publicIp == other.publicIp &&
          pingMs == other.pingMs;

  @override
  int get hashCode =>
      byteIn.hashCode ^
      byteOut.hashCode ^
      duration.hashCode ^
      publicIp.hashCode ^
      pingMs.hashCode;
}
