import 'package:equatable/equatable.dart';

/// Program studi — data referensi kampus, bukan data pengguna.
///
/// Dipakai dua tempat: dropdown formulir pendaftaran mahasiswa (dibaca tanpa
/// sesi) dan formulir kelola akun Admin. Daftarnya selalu berasal dari server
/// supaya tidak ada salinan yang menyimpang di klien.
class StudyProgram extends Equatable {
  const StudyProgram({
    required this.id,
    required this.code,
    required this.name,
    this.faculty = '',
  });

  factory StudyProgram.fromJson(Map<String, dynamic> json) => StudyProgram(
        id: json['id'] as String? ?? '',
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        faculty: json['faculty'] as String? ?? '',
      );

  final String id;
  final String code;
  final String name;
  final String faculty;

  /// Label dropdown: "Teknik Informatika · TI".
  String get label => code.isEmpty ? name : '$name · $code';

  @override
  List<Object?> get props => [id, code, name, faculty];
}
