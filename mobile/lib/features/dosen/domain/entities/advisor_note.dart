class AdvisorNote {
  const AdvisorNote({
    required this.id,
    required this.mentorId,
    required this.studentId,
    required this.interactionDate,
    required this.channel,
    required this.status,
    required this.remark,
    required this.createdAt,
  });

  factory AdvisorNote.fromJson(Map<String, dynamic> json) {
    return AdvisorNote(
      id: json['id'] as String? ?? '',
      mentorId: json['mentor_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      interactionDate: json['interaction_date'] as String? ?? '',
      channel: json['channel'] as String? ?? 'TATAP_MUKA',
      status: json['status'] as String? ?? 'DISAPA',
      remark: json['remark'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  final String id;
  final String mentorId;
  final String studentId;
  final String interactionDate;
  final String channel;
  final String status;
  final String remark;
  final String createdAt;

  String get channelLabel {
    switch (channel) {
      case 'TATAP_MUKA':
        return 'Tatap Muka';
      case 'WHATSAPP':
        return 'WhatsApp';
      case 'EMAIL':
        return 'Email';
      case 'TELEPON':
        return 'Telepon';
      default:
        return 'Lainnya';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'DISAPA':
        return 'Telah Disapa';
      case 'KONSULTASI':
        return 'Konsultasi';
      case 'DIRUJUK':
        return 'Dirujuk Kampus';
      case 'STABIL':
        return 'Kondisi Membaik';
      default:
        return status;
    }
  }
}
