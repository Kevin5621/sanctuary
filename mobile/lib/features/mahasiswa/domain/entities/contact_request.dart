import 'package:equatable/equatable.dart';

/// Status tombol "minta dihubungi".
///
/// [explanation] datang dari server dan menjelaskan persis apa yang dilihat
/// dosen. Teks itu tidak ditulis ulang di klien: janji privasi hanya boleh
/// punya satu rumusan, dan rumusannya harus sama dengan yang ditegakkan API.
class ContactRequestState extends Equatable {
  const ContactRequestState({
    required this.hasOpenRequest,
    required this.request,
    required this.advisorName,
    required this.canRequest,
    required this.explanation,
  });

  factory ContactRequestState.fromJson(Map<String, dynamic> json) => ContactRequestState(
        hasOpenRequest: json['has_open_request'] as bool? ?? false,
        request: json['request'] == null
            ? null
            : ContactRequest.fromJson(json['request'] as Map<String, dynamic>),
        advisorName: json['advisor_name'] as String? ?? '',
        canRequest: json['can_request'] as bool? ?? false,
        explanation: json['explanation'] as String? ?? '',
      );

  const ContactRequestState.empty()
      : hasOpenRequest = false,
        request = null,
        advisorName = '',
        canRequest = false,
        explanation = '';

  final bool hasOpenRequest;
  final ContactRequest? request;
  final String advisorName;
  final bool canRequest;
  final String explanation;

  bool get hasAdvisor => advisorName.isNotEmpty;

  @override
  List<Object?> get props => [hasOpenRequest, request, advisorName, canRequest];
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
