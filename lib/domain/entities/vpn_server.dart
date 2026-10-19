/// Domain entity representing a VPN endpoint
class VpnServer {
  final String id;
  final String country;
  final String countryCode;
  final String city;
  final String host;
  final int port;
  final String protocol;
  final int? pingMs;
  final int? loadPercent;
  final int? speedBps;
  final int score;
  final String ovpnConfig;

  /// TLS hostname for SSTP (`<relay>.opengw.net` for VPN Gate), if supported.
  final String? sstpHostname;
  final String username;
  final String password;
  final bool isFavorite;
  final bool isAvailable;
  final DateTime lastChecked;

  const VpnServer({
    required this.id,
    required this.country,
    required this.countryCode,
    required this.city,
    required this.host,
    required this.port,
    required this.protocol,
    this.pingMs,
    this.loadPercent,
    this.speedBps,
    required this.score,
    required this.ovpnConfig,
    this.sstpHostname,
    this.username = 'vpn',
    this.password = 'vpn',
    this.isFavorite = false,
    this.isAvailable = true,
    required this.lastChecked,
  });

  VpnServer copyWith({
    String? id,
    String? country,
    String? countryCode,
    String? city,
    String? host,
    int? port,
    String? protocol,
    int? pingMs,
    int? loadPercent,
    int? speedBps,
    int? score,
    String? ovpnConfig,
    String? sstpHostname,
    String? username,
    String? password,
    bool? isFavorite,
    bool? isAvailable,
    DateTime? lastChecked,
  }) {
    return VpnServer(
      id: id ?? this.id,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      city: city ?? this.city,
      host: host ?? this.host,
      port: port ?? this.port,
      protocol: protocol ?? this.protocol,
      pingMs: pingMs ?? this.pingMs,
      loadPercent: loadPercent ?? this.loadPercent,
      speedBps: speedBps ?? this.speedBps,
      score: score ?? this.score,
      ovpnConfig: ovpnConfig ?? this.ovpnConfig,
      sstpHostname: sstpHostname ?? this.sstpHostname,
      username: username ?? this.username,
      password: password ?? this.password,
      isFavorite: isFavorite ?? this.isFavorite,
      isAvailable: isAvailable ?? this.isAvailable,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'country': country,
      'countryCode': countryCode,
      'city': city,
      'host': host,
      'port': port,
      'protocol': protocol,
      'pingMs': pingMs,
      'loadPercent': loadPercent,
      'speedBps': speedBps,
      'score': score,
      'ovpnConfig': ovpnConfig,
      'sstpHostname': sstpHostname,
      'username': username,
      'password': password,
      'isFavorite': isFavorite,
      'isAvailable': isAvailable,
      'lastChecked': lastChecked.toIso8601String(),
    };
  }

  factory VpnServer.fromJson(Map<String, dynamic> json) {
    return VpnServer(
      id: json['id'] as String,
      country: json['country'] as String? ?? 'Unknown',
      countryCode: json['countryCode'] as String? ?? 'UN',
      city: json['city'] as String? ?? '',
      host: json['host'] as String,
      port: (json['port'] as num?)?.toInt() ?? 1194,
      protocol: json['protocol'] as String? ?? 'UDP',
      pingMs: (json['pingMs'] as num?)?.toInt(),
      loadPercent: (json['loadPercent'] as num?)?.toInt(),
      speedBps: (json['speedBps'] as num?)?.toInt(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      ovpnConfig: json['ovpnConfig'] as String? ?? '',
      sstpHostname: json['sstpHostname'] as String?,
      username: json['username'] as String? ?? 'vpn',
      password: json['password'] as String? ?? 'vpn',
      isFavorite: json['isFavorite'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      lastChecked: json['lastChecked'] != null
          ? DateTime.parse(json['lastChecked'] as String)
          : DateTime.now(),
    );
  }

  /// Whether this relay can be reached over SSTP (TLS on a TCP port).
  bool get supportsSstp => sstpHostname != null && sstpHostname!.isNotEmpty;

  /// VPN Gate serves SSTP on the same TCP listener it publishes for OpenVPN;
  /// UDP-only relays fall back to the standard HTTPS port.
  int get sstpPort => protocol.toUpperCase() == 'TCP' ? port : 443;

  /// Display string for latency
  String get pingDisplay => pingMs != null ? '$pingMs ms' : 'Not available';

  /// Display string for load percentage
  String get loadDisplay =>
      loadPercent != null ? '$loadPercent%' : 'Not available';

  /// Bandwidth throughput speed in Mbps
  double get speedMbps =>
      (speedBps != null && speedBps! > 0) ? (speedBps! / 1000000.0) : 0.0;

  /// User-facing formatted speed string (e.g. "450 Mbps")
  String get speedDisplay {
    if (speedBps == null || speedBps! <= 0) return 'Not available';
    final mbps = speedBps! / 1000000.0;
    if (mbps >= 1.0) {
      return '${mbps.toStringAsFixed(1)} Mbps';
    }
    final kbps = speedBps! / 1000.0;
    return '${kbps.toStringAsFixed(0)} Kbps';
  }

  /// Relay operator attribution
  String get operator => '';

  /// Active connection estimate based on server load/score
  int get numVpnSessions => (score > 0 ? (score / 15).round() : 12);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is VpnServer && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
