part of 'jurnal_cubit.dart';

class JurnalState extends Equatable {
  const JurnalState({
    this.isAnalyzing = false,
    this.journal,
    this.analysis,
    this.showCrisisCard = false,
    this.isDateError = false,
    this.errorMessage,
  });

  final bool isAnalyzing;
  final Journal? journal;

  /// Hasil analisis terakhir. null = belum ada analisis pada sesi layar ini,
  /// sehingga UI tidak menampilkan kartu hasil sama sekali (bukan kartu
  /// berisi angka contoh).
  final JournalAnalysis? analysis;

  final bool showCrisisCard;

  /// Error berkaitan dengan tanggal (D-8), ditempelkan pada pemilih tanggal.
  final bool isDateError;

  final String? errorMessage;

  bool get hasAnalysis => analysis != null;

  JurnalState copyWith({
    bool? isAnalyzing,
    Journal? journal,
    JournalAnalysis? analysis,
    bool? showCrisisCard,
    bool? isDateError,
    String? errorMessage,
    bool clearError = false,
    bool clearAnalysis = false,
  }) {
    return JurnalState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      journal: journal ?? this.journal,
      analysis: clearAnalysis ? null : (analysis ?? this.analysis),
      showCrisisCard: clearAnalysis ? false : (showCrisisCard ?? this.showCrisisCard),
      isDateError: clearError ? false : (isDateError ?? this.isDateError),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [isAnalyzing, journal, analysis, showCrisisCard, isDateError, errorMessage];
}
