import 'package:equatable/equatable.dart';

/// Peran pengguna — selaras dengan constants.Role di backend.
/// Jumlah tab tiap peran juga didefinisikan di sini agar shell navigasi
/// dan router memakai satu sumber kebenaran.
enum UserRole {
  student('STUDENT', 'Mahasiswa', 4),
  lecturer('LECTURER', 'Dosen Pembimbing', 3),
  headOfProgram('HEAD_OF_PROGRAM', 'Kaprodi', 4),
  admin('ADMIN', 'Admin', 2),
  unknown('UNKNOWN', 'Tidak dikenal', 0);

  const UserRole(this.code, this.label, this.tabCount);

  final String code;
  final String label;
  final int tabCount;

  static UserRole fromCode(String? code) => UserRole.values.firstWhere(
        (role) => role.code == code,
        orElse: () => UserRole.unknown,
      );

  /// Rute awal setelah login — dipakai gerbang navigasi berbasis peran.
  String get homeRoute => switch (this) {
        UserRole.student => '/student/home',
        UserRole.lecturer => '/lecturer/advisees',
        UserRole.headOfProgram => '/kaprodi/dashboard',
        UserRole.admin => '/admin/support',
        UserRole.unknown => '/login',
      };
}

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.studentNumber,
    this.lecturerNumber,
    this.cohortYear,
    this.advisorId,
    this.studyProgram,
    this.isActive = true,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;
  final String? studentNumber;
  final String? lecturerNumber;
  final int? cohortYear;
  final String? advisorId;
  final String? studyProgram;
  final bool isActive;

  /// Inisial untuk avatar placeholder.
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  List<Object?> get props => [id, fullName, email, role, isActive];
}
