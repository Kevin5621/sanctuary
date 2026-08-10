import 'package:equatable/equatable.dart';

import 'advisor.dart';

/// Status tombol "minta dihubungi".
///
/// [explanation] datang dari server dan menjelaskan persis apa yang dilihat
/// dosen. Teks itu tidak ditulis ulang di klien: janji privasi hanya boleh
/// punya satu rumusan, dan rumusannya harus sama dengan yang ditegakkan API.
///
/// [advisors] berisi SELURUH pembimbing yang akan melihat permintaan — satu
/// permintaan memang tidak ditujukan ke satu orang.
class ContactRequestState extends Equatable {
  const ContactRequestState({
    required this.hasOpenRequest,
    required this.request,
    required this.advisors,
    required this.canRequest,
    required this.explanation,
  });

  factory ContactRequestState.fromJson(Map<String, dynamic> json) => ContactRequestState(
        hasOpenRequest: json['has_open_request'] as bool? ?? false,
        request: json['request'] == null
            ? null
            : ContactRequest.fromJson(json['request'] as Map<String, dynamic>),
        advisors: Advisor.listFromJson(json['advisors']),
        canRequest: json['can_request'] as bool? ?? false,
        explanation: json['explanation'] as String? ?? '',
      );

  const ContactRequestState.empty()
      : hasOpenRequest = false,
        request = null,
        advisors = const [],
        canRequest = false,
        explanation = '';

  final bool hasOpenRequest;
  final ContactRequest? request;
  final List<Advisor> advisors;
  final bool canRequest;
  final String explanation;

  bool get hasAdvisor => advisors.isNotEmpty;
  bool get hasMultipleAdvisors => advisors.length > 1;

  /// Ringkasan penerima untuk judul kartu: satu nama saat tunggal, jumlahnya
  /// saat lebih dari satu (nama lengkapnya tetap tampil sebagai chip di bawah).
  String get advisorSummary {
    if (advisors.isEmpty) return '';
    if (advisors.length == 1) return advisors.first.fullName;
    return '${advisors.length} pembimbingmu';
  }

  @override
  List<Object?> get props => [hasOpenRequest, request, advisors, canRequest];
}

class ContactRequest extends Equatable {
  const ContactRequest({
    required this.id,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.isOpen,
  });

  factory ContactRequest.fromJson(Map<String, dynamic> json) => ContactRequest(
        id: json['id'] as String? ?? '',
        status: json['status'] as String? ?? '',
        note: json['note'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        isOpen: json['is_open'] as bool? ?? false,
      );

  final String id;
  final String status;

  /// Catatan milik mahasiswa sendiri — dikembalikan ke pemiliknya, tetapi
  /// tidak pernah dikirim ke dosen.
  final String note;
  final DateTime createdAt;
  final bool isOpen;

  @override
  List<Object?> get props => [id, status, createdAt, isOpen];
}
