/// Domain entity representing a completed or active VPN session
class VpnSession {
  final String id;
  final String serverId;
  final String serverName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final int bytesReceived;
  final int bytesSent;
  final String status; // 'completed', 'disconnected', 'failed'
  final String? failureReason;

  const VpnSession({
    required this.id,
    required this.serverId,
    required this.serverName,
    required this.startedAt,
    this.endedAt,
    required this.durationSeconds,
    required this.bytesReceived,
    required this.bytesSent,
    required this.status,
    this.failureReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serverId': serverId,
      'serverName': serverName,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'durationSeconds': durationSeconds,
      'bytesReceived': bytesReceived,
      'bytesSent': bytesSent,
      'status': status,
      'failureReason': failureReason,
    };
  }

  factory VpnSession.fromJson(Map<String, dynamic> json) {
    DateTime parsedStartedAt;
    try {
      parsedStartedAt = DateTime.parse(json['startedAt'] as String);
    } catch (_) {
      parsedStartedAt = DateTime.now();
    }

    DateTime? parsedEndedAt;
    if (json['endedAt'] != null) {
      try {
        parsedEndedAt = DateTime.parse(json['endedAt'] as String);
      } catch (_) {
        parsedEndedAt = null;
      }
    }

    return VpnSession(
      id: json['id']?.toString() ?? '',
      serverId: json['serverId']?.toString() ?? 'unknown',
      serverName: json['serverName']?.toString() ?? 'Relay Node',
      startedAt: parsedStartedAt,
      endedAt: parsedEndedAt,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      bytesReceived: (json['bytesReceived'] as num?)?.toInt() ?? 0,
      bytesSent: (json['bytesSent'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'completed',
      failureReason: json['failureReason']?.toString(),
    );
  }

  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get durationFormatted => formattedDuration;

  String get formattedDataTransferred {
    final total = bytesReceived + bytesSent;
    if (total < 1024) return '$total B';
    if (total < 1024 * 1024) return '${(total / 1024).toStringAsFixed(1)} KB';
    if (total < 1024 * 1024 * 1024) {
      return '${(total / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(total / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get bytesTransferredFormatted => formattedDataTransferred;

  String? get errorMessage => failureReason;


  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is VpnSession && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
