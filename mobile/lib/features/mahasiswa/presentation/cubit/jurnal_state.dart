part of 'jurnal_cubit.dart';

enum JurnalStatus { initial, loading, ready, failure }

class JurnalState extends Equatable {
  const JurnalState({
    this.status = JurnalStatus.initial,
    this.entries = const [],
    this.analysis,
    this.page = 1,
    this.hasNextPage = false,
    this.isSubmitting = false,
    this.isLoadingMore = false,
    this.analyzingId,
    this.errorMessage,
    this.successMessage,
  });

  final JurnalStatus status;
  final List<JournalListItem> entries;

  /// Hasil analisis terakhir, ditampilkan sebagai kartu di bawah form.
  /// Null berarti belum ada analisis yang perlu ditampilkan — bukan berarti
  /// hasilnya netral.
  final JournalAnalysis? analysis;

  final int page;
  final bool hasNextPage;
  final bool isSubmitting;
  final bool isLoadingMore;

  /// Id catatan yang sedang dianalisis ulang dari daftar.
  final String? analyzingId;

  final String? errorMessage;
  final String? successMessage;

  bool get isLoading => status == JurnalStatus.loading || status == JurnalStatus.initial;
  bool get isEmpty => status == JurnalStatus.ready && entries.isEmpty;

  /// Analisis terakhir menandai krisis — layar wajib memunculkan jalur bantuan.
  bool get showCrisisCard => analysis?.isCrisisFlagged ?? false;

  JurnalState copyWith({
    JurnalStatus? status,
    List<JournalListItem>? entries,
    JournalAnalysis? analysis,
    int? page,
    bool? hasNextPage,
    bool? isSubmitting,
    bool? isLoadingMore,
    String? analyzingId,
    String? errorMessage,
    String? successMessage,
    bool clearAnalysis = false,
    bool clearAnalyzingId = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return JurnalState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      analysis: clearAnalysis ? null : (analysis ?? this.analysis),
      page: page ?? this.page,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      analyzingId: clearAnalyzingId ? null : (analyzingId ?? this.analyzingId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        entries,
        analysis,
        page,
        hasNextPage,
        isSubmitting,
        isLoadingMore,
        analyzingId,
        errorMessage,
        successMessage,
      ];
}
