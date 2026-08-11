import '../../domain/entities/app_user.dart';

/// Mapper JSON → entity domain.
/// Lapisan data adalah satu-satunya tempat yang tahu bentuk payload API.
class UserModel {
  const UserModel._();

  static AppUser fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: UserRole.fromCode(json['role'] as String?),
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        studentNumber: json['student_number'] as String?,
        lecturerNumber: json['lecturer_number'] as String?,
        cohortYear: json['cohort_year'] as int?,
        studyProgram: json['study_program'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );
}

/// Payload sesi hasil login/refresh.
class SessionModel {
  const SessionModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? const {}),
        accessToken: json['access_token'] as String? ?? '',
        refreshToken: json['refresh_token'] as String? ?? '',
      );

  final AppUser user;
  final String accessToken;
  final String refreshToken;
}
