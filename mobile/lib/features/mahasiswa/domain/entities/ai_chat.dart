import 'package:equatable/equatable.dart';

/// Entitas Terapis AI — selaras dengan dto/chat_dto.go di backend.
///
/// Catatan penting: seluruh keputusan "boleh chat atau tidak" datang dari
/// server lewat [AiConsentStatus.canChat]. Klien TIDAK menyimpulkannya sendiri
/// dan tidak menyimpan flag consent secara lokal — kalau klien boleh
/// memutuskan, consent bisa hilang saat ganti perangkat atau dipalsukan.

/// Status keputusan mahasiswa atas D-5.
enum AiConsentDecision {
  /// Belum pernah memutuskan — tampilkan layar consent.
  pending,

  /// Sudah setuju.
  granted,

  /// Menolak — tab tetap ada, isinya latihan mandiri saja.
  denied;

  static AiConsentDecision fromCode(String? code) => switch (code) {
        'GRANTED' => AiConsentDecision.granted,
        'DENIED' => AiConsentDecision.denied,
        _ => AiConsentDecision.pending,
      };
}

/// Teks pemberitahuan pihak ketiga. Datang dari server agar semua versi klien
/// menampilkan kalimat yang sama.
class AiConsentNotice extends Equatable {
  const AiConsentNotice({
    required this.noticeVersion,
    required this.title,
    required this.summary,
    required this.points,
    required this.providerName,
    required this.acceptLabel,
    required this.declineLabel,
  });

  factory AiConsentNotice.fromJson(Map<String, dynamic> json) => AiConsentNotice(
        noticeVersion: json['notice_version'] as String? ?? '',
        title: json['title'] as String? ?? 'Sebelum memakai Terapis AI',
        summary: json['summary'] as String? ?? '',
        points: (json['points'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
        providerName: json['provider_name'] as String? ?? '',
        acceptLabel: json['accept_label'] as String? ?? 'Saya setuju',
        declineLabel: json['decline_label'] as String? ?? 'Tidak, terima kasih',
      );

  const AiConsentNotice.empty()
      : noticeVersion = '',
        title = '',
        summary = '',
        points = const [],
        providerName = '',
        acceptLabel = 'Saya setuju',
        declineLabel = 'Tidak, terima kasih';

  final String noticeVersion;
  final String title;
  final String summary;
  final List<String> points;
  final String providerName;
  final String acceptLabel;
  final String declineLabel;

  @override
  List<Object?> get props =>
      [noticeVersion, title, summary, points, providerName, acceptLabel, declineLabel];
}

class AiConsentStatus extends Equatable {
  const AiConsentStatus({
    required this.decision,
    required this.canChat,
    required this.noticeVersion,
    required this.notice,
    this.needsRenewal = false,
    this.serviceAvailable = false,
    this.decidedAt,
    this.consentedAt,
  });

  factory AiConsentStatus.fromJson(Map<String, dynamic> json) => AiConsentStatus(
        decision: AiConsentDecision.fromCode(json['status'] as String?),
        canChat: json['can_chat'] as bool? ?? false,
        noticeVersion: json['notice_version'] as String? ?? '',
        needsRenewal: json['needs_renewal'] as bool? ?? false,
        serviceAvailable: json['service_available'] as bool? ?? false,
        decidedAt: json['decided_at'] as String?,
        consentedAt: json['consented_at'] as String?,
        notice: json['notice'] is Map<String, dynamic>
            ? AiConsentNotice.fromJson(json['notice'] as Map<String, dynamic>)
            : const AiConsentNotice.empty(),
      );

  const AiConsentStatus.unknown()
      : decision = AiConsentDecision.pending,
        canChat = false,
        noticeVersion = '',
        notice = const AiConsentNotice.empty(),
        needsRenewal = false,
        serviceAvailable = false,
        decidedAt = null,
        consentedAt = null;

  final AiConsentDecision decision;

  /// Jawaban gate dari server. Satu-satunya sumber kebenaran untuk UI.
  final bool canChat;

  final String noticeVersion;
  final AiConsentNotice notice;

  /// Pernah setuju, tapi atas teks pemberitahuan versi lama.
  final bool needsRenewal;

  /// Penyedia AI dikonfigurasi di server. Dipisah dari [canChat] supaya UI
  /// dapat menjelaskan sebab yang benar: "kamu belum setuju" berbeda dari
  /// "layanan sedang tidak tersedia".
  final bool serviceAvailable;

  final String? decidedAt;
  final String? consentedAt;

  /// Layar consent ditampilkan saat belum memutuskan, atau saat teks
  /// pemberitahuan sudah diperbarui.
  bool get mustShowConsent =>
      decision == AiConsentDecision.pending || needsRenewal;

  bool get hasDeclined => decision == AiConsentDecision.denied;

  @override
  List<Object?> get props => [
        decision,
        canChat,
        noticeVersion,
        notice,
        needsRenewal,
        serviceAvailable,
        decidedAt,
        consentedAt,
      ];
}

/// Satu pesan percakapan.
class AiChatMessage extends Equatable {
  const AiChatMessage({
    required this.id,
    required this.isFromStudent,
    required this.text,
    this.isCrisisFlagged = false,
    this.createdAt,
    this.isPending = false,
    this.isFallback = false,
  });

  factory AiChatMessage.fromJson(Map<String, dynamic> json) => AiChatMessage(
        id: json['id'] as String? ?? '',
        isFromStudent: (json['sender'] as String? ?? '') == 'USER',
        text: json['text'] as String? ?? '',
        isCrisisFlagged: json['is_crisis_flagged'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      );

  /// Pesan sementara yang ditampilkan sebelum server membalas, agar tulisan
  /// mahasiswa langsung terlihat di layar.
  const AiChatMessage.pendingFromStudent(this.text)
      : id = '',
        isFromStudent = true,
        isCrisisFlagged = false,
        createdAt = null,
        isPending = true,
        isFallback = false;

  final String id;
  final bool isFromStudent;
  final String text;
  final bool isCrisisFlagged;
  final DateTime? createdAt;

  /// Belum tersimpan di server.
  final bool isPending;

  /// Balasan dibuat server karena penyedia AI gagal — WAJIB ditandai di UI
  /// agar mahasiswa tidak mengira ini jawaban yang dipersonalisasi.
  final bool isFallback;

  AiChatMessage copyWith({bool? isFallback}) => AiChatMessage(
        id: id,
        isFromStudent: isFromStudent,
        text: text,
        isCrisisFlagged: isCrisisFlagged,
        createdAt: createdAt,
        isPending: isPending,
        isFallback: isFallback ?? this.isFallback,
      );

  @override
  List<Object?> get props =>
      [id, isFromStudent, text, isCrisisFlagged, createdAt, isPending, isFallback];
}

class AiChatHistory extends Equatable {
  const AiChatHistory({
    required this.sessionId,
    required this.messages,
    required this.turnLimit,
    this.isTruncated = false,
    this.crisisMessage = '',
  });

  factory AiChatHistory.fromJson(Map<String, dynamic> json) => AiChatHistory(
        sessionId: json['session_id'] as String? ?? '',
        messages: (json['messages'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AiChatMessage.fromJson)
            .toList(),
        turnLimit: json['turn_limit'] as int? ?? 100,
        isTruncated: json['is_truncated'] as bool? ?? false,
        crisisMessage: json['crisis_message'] as String? ?? '',
      );

  const AiChatHistory.empty()
      : sessionId = '',
        messages = const [],
        turnLimit = 100,
        isTruncated = false,
        crisisMessage = '';

  final String sessionId;
  final List<AiChatMessage> messages;

  /// Batas giliran yang dipangkas SERVER (M-AI-03). Ditampilkan apa adanya.
  final int turnLimit;
  final bool isTruncated;
  final String crisisMessage;

  /// Satu giliran = pesan mahasiswa + balasan AI.
  int get turnCount => (messages.length / 2).ceil();

  AiChatHistory copyWith({List<AiChatMessage>? messages}) => AiChatHistory(
        sessionId: sessionId,
        messages: messages ?? this.messages,
        turnLimit: turnLimit,
        isTruncated: isTruncated,
        crisisMessage: crisisMessage,
      );

  @override
  List<Object?> get props =>
      [sessionId, messages, turnLimit, isTruncated, crisisMessage];
}

/// Hasil pengiriman satu pesan.
class AiSendResult extends Equatable {
  const AiSendResult({
    required this.userMessage,
    required this.aiMessage,
    required this.isCrisisFlagged,
    required this.crisisMessage,
    required this.isFallback,
  });

  factory AiSendResult.fromJson(Map<String, dynamic> json) => AiSendResult(
        userMessage:
            AiChatMessage.fromJson(json['user_message'] as Map<String, dynamic>? ?? const {}),
        aiMessage:
            AiChatMessage.fromJson(json['ai_message'] as Map<String, dynamic>? ?? const {}),
        isCrisisFlagged: json['is_crisis_flagged'] as bool? ?? false,
        crisisMessage: json['crisis_message'] as String? ?? '',
        isFallback: json['is_fallback'] as bool? ?? false,
      );

  final AiChatMessage userMessage;
  final AiChatMessage aiMessage;

  /// Penanda krisis dihitung SERVER dengan leksikon yang sama dengan jurnal.
  /// Klien tidak punya daftar kata kunci sendiri — dua daftar pasti menyimpang.
  final bool isCrisisFlagged;
  final String crisisMessage;
  final bool isFallback;

  @override
  List<Object?> get props =>
      [userMessage, aiMessage, isCrisisFlagged, crisisMessage, isFallback];
}
