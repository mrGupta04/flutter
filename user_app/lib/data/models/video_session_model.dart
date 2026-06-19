class VideoSessionModel {
  const VideoSessionModel({
    required this.bookingId,
    required this.role,
    required this.canJoin,
    required this.joinWindowStart,
    required this.joinWindowEnd,
    required this.slotStart,
    required this.slotEnd,
    required this.roomId,
    required this.provider,
    required this.displayName,
    required this.doctorName,
    required this.patientName,
    this.joinUrl,
    this.mockMode = false,
    this.message,
    this.label,
    this.videoCallStartedAt,
    this.videoCallEndedAt,
    this.agoraAppId,
    this.agoraToken,
    this.agoraChannel,
    this.agoraUid,
    this.agoraTokenExpiresAt,
    this.agoraTestingMode = false,
  });

  final String bookingId;
  final String role;
  final bool canJoin;
  final DateTime? joinWindowStart;
  final DateTime? joinWindowEnd;
  final DateTime? slotStart;
  final DateTime? slotEnd;
  final String roomId;
  final String provider;
  final String displayName;
  final String doctorName;
  final String patientName;
  final String? joinUrl;
  final bool mockMode;
  final String? message;
  final String? label;
  final DateTime? videoCallStartedAt;
  final DateTime? videoCallEndedAt;
  final String? agoraAppId;
  final String? agoraToken;
  final String? agoraChannel;
  final int? agoraUid;
  final DateTime? agoraTokenExpiresAt;
  final bool agoraTestingMode;

  bool get isJitsi => provider == 'jitsi' && joinUrl != null;

  bool get isAgora =>
      provider == 'agora' &&
      agoraAppId != null &&
      agoraChannel != null &&
      agoraUid != null;

  String get peerName => role == 'doctor' ? patientName : doctorName;

  factory VideoSessionModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    int? parseUid(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return VideoSessionModel(
      bookingId: json['bookingId']?.toString() ?? '',
      role: json['role']?.toString() ?? 'patient',
      canJoin: json['canJoin'] as bool? ?? false,
      joinWindowStart: parseDate(json['joinWindowStart']),
      joinWindowEnd: parseDate(json['joinWindowEnd']),
      slotStart: parseDate(json['slotStart']),
      slotEnd: parseDate(json['slotEnd']),
      roomId: json['roomId']?.toString() ?? '',
      provider: json['provider']?.toString() ?? 'mock',
      displayName: json['displayName']?.toString() ?? 'Participant',
      doctorName: json['doctorName']?.toString() ?? 'Doctor',
      patientName: json['patientName']?.toString() ?? 'Patient',
      joinUrl: json['joinUrl'] as String?,
      mockMode: json['mockMode'] as bool? ?? false,
      message: json['message'] as String?,
      label: json['label'] as String?,
      videoCallStartedAt: parseDate(json['videoCallStartedAt']),
      videoCallEndedAt: parseDate(json['videoCallEndedAt']),
      agoraAppId: json['agoraAppId'] as String?,
      agoraToken: json['agoraToken'] as String?,
      agoraChannel: json['agoraChannel'] as String?,
      agoraUid: parseUid(json['agoraUid']),
      agoraTokenExpiresAt: parseDate(json['agoraTokenExpiresAt']),
      agoraTestingMode: json['agoraTestingMode'] as bool? ?? false,
    );
  }
}
