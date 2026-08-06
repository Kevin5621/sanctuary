part of 'study_program_cubit.dart';

enum StudyProgramStatus { initial, loading, ready, failure }

class StudyProgramState extends Equatable {
  const StudyProgramState({
    this.status = StudyProgramStatus.initial,
    this.programs = const [],
    this.errorMessage,
  });

  final StudyProgramStatus status;
  final List<StudyProgram> programs;
  final String? errorMessage;

  bool get isLoading =>
      status == StudyProgramStatus.loading || status == StudyProgramStatus.initial;

  /// Server menjawab, tetapi kampus belum punya program studi terdaftar.
  /// Dibedakan dari kegagalan jaringan supaya pesannya tidak menyuruh
  /// pengguna "coba lagi" atas sesuatu yang tidak akan berubah dengan retry.
  bool get isEmpty =>
      status == StudyProgramStatus.ready && programs.isEmpty;

  StudyProgramState copyWith({
    StudyProgramStatus? status,
    List<StudyProgram>? programs,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StudyProgramState(
      status: status ?? this.status,
      programs: programs ?? this.programs,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, programs, errorMessage];
}
