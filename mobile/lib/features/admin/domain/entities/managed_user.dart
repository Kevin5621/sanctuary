import 'package:equatable/equatable.dart';

/// Satu akun dosen / kaprodi pada halaman kelola akun Admin.
///
/// Sengaja tidak memuat satu pun atribut kondisi mahasiswa: halaman ini murni
/// administratif, dan Admin memang tidak berhak melihat data klinis siapa pun.
class ManagedUser extends Equatable {
  const ManagedUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.roleLabel,
    this.phone = '',
    this.lecturerNumber = '',
    this.studyProgramId,
    this.studyProgram,
    this.isActive = true,
    this.lastLoginAt,
    this.createdAt = '',
  });

  factory ManagedUser.fromJson(Map<String, dynamic> json) => ManagedUser(
        id: json['id'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? '',
        roleLabel: json['role_label'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        lecturerNumber: json['lecturer_number'] as String? ?? '',
        studyProgramId: json['study_program_id'] as String?,
        studyProgram: json['study_program'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        lastLoginAt: json['last_login_at'] as String?,
        createdAt: json['created_at'] as String? ?? '',
      );

  final String id;
  final String fullName;
  final String email;
  final String role;
  final String roleLabel;
  final String phone;
  final String lecturerNumber;
  final String? studyProgramId;
  final String? studyProgram;
  final bool isActive;
  final String? lastLoginAt;
  final String createdAt;

  /// Inisial untuk avatar placeholder.
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Akun yang belum pernah dipakai masuk. Ditandai di kartu supaya Admin
  /// tahu kredensial awalnya kemungkinan belum sampai ke pemiliknya.
  bool get hasNeverSignedIn => lastLoginAt == null || lastLoginAt!.isEmpty;

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        role,
        roleLabel,
        phone,
        lecturerNumber,
        studyProgramId,
        studyProgram,
        isActive,
        lastLoginAt,
        createdAt,
      ];
}

/// Pilihan peran yang boleh dibuat Admin (`GET /admin/user-options`).
/// Berasal dari server supaya daftarnya tidak ditulis ulang di klien dan
/// berisiko menawarkan peran yang sebenarnya ditolak backend.
class RoleOption extends Equatable {
  const RoleOption({required this.value, required this.label});

  factory RoleOption.fromJson(Map<String, dynamic> json) => RoleOption(
        value: json['value'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );

  final String value;
  final String label;

  @override
  List<Object?> get props => [value, label];
}

/// Payload pembuatan / perubahan akun staf.
class StaffAccountDraft {
  const StaffAccountDraft({
    required this.fullName,
    required this.role,
    required this.studyProgramId,
    this.email = '',
    this.password = '',
    this.lecturerNumber = '',
    this.phone = '',
    this.isActive = true,
  });

  final String fullName;
  final String role;
  final String studyProgramId;
  final String email;
  final String password;
  final String lecturerNumber;
  final String phone;
  final bool isActive;

  /// Body pembuatan akun baru — email & kata sandi wajib ikut.
  Map<String, dynamic> toCreateBody() => {
        'full_name': fullName,
        'email': email,
        'password': password,
        'role': role,
        'study_program_id': studyProgramId,
        'lecturer_number': lecturerNumber,
        'phone': phone,
        'is_active': isActive,
      };

  /// Body perubahan akun.
  ///
  /// Email sengaja tidak ikut: ia adalah identitas login sekaligus kunci jejak
  /// audit yang sudah tercatat atas nama akun tersebut. Kata sandi hanya
  /// dikirim bila Admin benar-benar mengisinya, sehingga menyimpan perubahan
  /// nama tidak diam-diam mengeluarkan pemiliknya dari sesi yang sedang aktif.
  Map<String, dynamic> toUpdateBody() => {
        'full_name': fullName,
        'study_program_id': studyProgramId,
        'lecturer_number': lecturerNumber,
        'phone': phone,
        'is_active': isActive,
        if (password.isNotEmpty) 'password': password,
      };
}
