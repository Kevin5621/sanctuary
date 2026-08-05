part of 'beranda_cubit.dart';

enum BerandaStatus { initial, loading, ready, failure }

class BerandaState extends Equatable {
  const BerandaState({
    this.status = BerandaStatus.initial,
    this.summary = const WeeklyMoodSummary.empty(),
    this.errorMessage,
  });

  final BerandaStatus status;
  final WeeklyMoodSummary summary;
  final String? errorMessage;

  bool get isLoading => status == BerandaStatus.loading;

  BerandaState copyWith({
    BerandaStatus? status,
    WeeklyMoodSummary? summary,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BerandaState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, summary, errorMessage];
}
