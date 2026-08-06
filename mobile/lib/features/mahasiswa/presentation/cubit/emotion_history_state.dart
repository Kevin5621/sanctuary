part of 'emotion_history_cubit.dart';

enum EmotionHistoryStatus { initial, loading, ready, failure }

class EmotionHistoryState extends Equatable {
  const EmotionHistoryState({
    this.status = EmotionHistoryStatus.initial,
    this.history = const EmotionHistory.empty(),
    this.errorMessage,
  });

  final EmotionHistoryStatus status;
  final EmotionHistory history;
  final String? errorMessage;

  bool get isLoading =>
      status == EmotionHistoryStatus.loading || status == EmotionHistoryStatus.initial;

  bool get isEmpty => status == EmotionHistoryStatus.ready && history.isEmpty;

  EmotionHistoryState copyWith({
    EmotionHistoryStatus? status,
    EmotionHistory? history,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EmotionHistoryState(
      status: status ?? this.status,
      history: history ?? this.history,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, history, errorMessage];
}
