part of 'student_detail_cubit.dart';

enum StudentDetailStatus { initial, loading, ready, failure }

class StudentDetailState extends Equatable {
  const StudentDetailState({
    this.status = StudentDetailStatus.initial,
    this.indicator,
    this.errorMessage,
    this.isForbidden = false,
  });

  final StudentDetailStatus status;
  final StudentIndicator? indicator;
  final String? errorMessage;
  final bool isForbidden;

  bool get isLoading =>
      status == StudentDetailStatus.loading ||
      status == StudentDetailStatus.initial;

  /// Mahasiswa memilih Tertutup — indikator memang tidak dikirim server.
  /// Dibedakan dari kegagalan agar UI tidak menawarkan "Coba Lagi" untuk
  /// sesuatu yang tidak akan pernah berubah dengan mencoba ulang (L-BIM-05).
  bool get isClosed =>
      status == StudentDetailStatus.ready &&
      (indicator?.shareLevel.isClosed ?? false);

  StudentDetailState copyWith({
    StudentDetailStatus? status,
    StudentIndicator? indicator,
    String? errorMessage,
    bool? isForbidden,
    bool clearError = false,
  }) {
    return StudentDetailState(
      status: status ?? this.status,
      indicator: indicator ?? this.indicator,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isForbidden: isForbidden ?? this.isForbidden,
    );
  }

  @override
  List<Object?> get props => [status, indicator, errorMessage, isForbidden];
}
