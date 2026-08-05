part of 'dosen_profil_cubit.dart';

enum DosenProfilStatus { initial, loading, ready, failure }

class DosenProfilState extends Equatable {
  const DosenProfilState({
    this.status = DosenProfilStatus.initial,
    this.profile = const MentorProfile.empty(),
    this.errorMessage,
  });

  final DosenProfilStatus status;
  final MentorProfile profile;
  final String? errorMessage;

  bool get isLoading =>
      status == DosenProfilStatus.loading || status == DosenProfilStatus.initial;

  DosenProfilState copyWith({
    DosenProfilStatus? status,
    MentorProfile? profile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DosenProfilState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}
