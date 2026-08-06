part of 'dass_cubit.dart';

enum DassStatus { initial, loading, ready, failure }

/// Layar aktif pada halaman DASS-21.
enum DassView { questionnaire, result, history }

class DassState extends Equatable {
  const DassState({
    this.status = DassStatus.initial,
    this.questionnaire = const DassQuestionnaire.empty(),
    this.history = const DassHistory.empty(),
    this.answers = const {},
    this.result,
    this.view = DassView.questionnaire,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final DassStatus status;
  final DassQuestionnaire questionnaire;
  final DassHistory history;

  /// Jawaban sementara, dikunci nomor soal. Belum dikirim sampai Simpan
  /// ditekan — mengisi kuesioner tidak sama dengan menyerahkan hasilnya.
  final Map<int, int> answers;

  final DassResult? result;
  final DassView view;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isLoading => status == DassStatus.loading || status == DassStatus.initial;

  int get totalQuestions => questionnaire.questions.length;
  int get answeredCount => answers.length;

  /// Skor DASS-21 hanya bermakna bila seluruh item terjawab; pengisian
  /// sebagian akan menghasilkan kategori yang terlihat sah padahal tidak.
  bool get isComplete => totalQuestions > 0 && answeredCount == totalQuestions;

  double get progress => totalQuestions == 0 ? 0 : answeredCount / totalQuestions;

  DassState copyWith({
    DassStatus? status,
    DassQuestionnaire? questionnaire,
    DassHistory? history,
    Map<int, int>? answers,
    DassResult? result,
    DassView? view,
    bool? isSubmitting,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return DassState(
      status: status ?? this.status,
      questionnaire: questionnaire ?? this.questionnaire,
      history: history ?? this.history,
      answers: answers ?? this.answers,
      result: clearResult ? null : (result ?? this.result),
      view: view ?? this.view,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        questionnaire,
        history,
        answers,
        result,
        view,
        isSubmitting,
        errorMessage,
      ];
}
