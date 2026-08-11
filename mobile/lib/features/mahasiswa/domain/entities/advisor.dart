import 'package:equatable/equatable.dart';

/// Seorang dosen pembimbing milik mahasiswa yang sedang login.
///
/// Satu mahasiswa dapat memiliki lebih dari satu pembimbing, dan semuanya
/// memiliki hak baca yang sama atas data yang mahasiswa izinkan.
class Advisor extends Equatable {
  const Advisor({
    required this.id,
    required this.fullName,
    this.lecturerNumber = '',
    this.email = '',
  });

  factory Advisor.fromJson(Map<String, dynamic> json) => Advisor(
        id: json['advisor_id'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        lecturerNumber: json['lecturer_number'] as String? ?? '',
        email: json['email'] as String? ?? '',
      );

  static List<Advisor> listFromJson(dynamic data) =>
      (data as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Advisor.fromJson)
          .toList();

  final String id;
  final String fullName;
  final String lecturerNumber;
  final String email;

  /// Inisial untuk avatar placeholder.
  String get initial =>
      fullName.trim().isEmpty ? '?' : fullName.trim()[0].toUpperCase();

  @override
  List<Object?> get props => [id, fullName, lecturerNumber, email];
}

/// Isi kartu "Pembimbingmu" di tab Profil.
///
/// [notice] datang dari server: sama seperti penjelasan "minta dihubungi",
/// janji privasi hanya boleh punya satu rumusan.
class MyAdvisors extends Equatable {
  const MyAdvisors({required this.advisors, required this.notice});

  factory MyAdvisors.fromJson(Map<String, dynamic> json) => MyAdvisors(
        advisors: Advisor.listFromJson(json['advisors']),
        notice: json['notice'] as String? ?? '',
      );

  const MyAdvisors.empty()
      : advisors = const [],
        notice = '';

  final List<Advisor> advisors;
  final String notice;

  int get total => advisors.length;
  bool get isEmpty => advisors.isEmpty;
  bool get hasMultiple => advisors.length > 1;

  @override
  List<Object?> get props => [advisors, notice];
}
