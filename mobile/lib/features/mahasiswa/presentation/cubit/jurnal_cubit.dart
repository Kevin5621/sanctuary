import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/repositories/journal_repository.dart';
import '../../domain/entities/journal.dart';

part 'jurnal_state.dart';

/// Cubit layar Jurnal (M-JUR-02, M-JUR-04, M-JUR-05).
///
/// Deteksi krisis TIDAK dilakukan di sini. Sebelumnya layar ini memeriksa kata
/// kunci sendiri sambil mahasiswa mengetik; daftar itu dihapus karena backend
/// sudah punya leksikon tunggal (core/crisis) yang juga dipakai Terapis AI.
/// Dua daftar di dua tempat akan menyimpang, dan yang menyimpang di klien akan
/// diam pada kalimat yang justru ditandai server.
class JurnalCubit extends Cubit<JurnalState> {
  JurnalCubit(this._repository) : super(const JurnalState());

  final JournalRepository _repository;

  /// Menyimpan jurnal lalu langsung menganalisisnya.
  Future<void> saveAndAnalyze({
    required String content,
    String title = '',
    DateTime? journalDate,
  }) async {
    if (content.trim().isEmpty || state.isAnalyzing) return;

    emit(state.copyWith(
      isAnalyzing: true,
      clearError: true,
      clearAnalysis: true,
    ));

    try {
      final result = await _repository.createJournal(
        content: content.trim(),
        title: title.trim(),
        journalDate: journalDate == null ? null : _formatDate(journalDate),
      );

      final analysis = result.analysis;
      emit(state.copyWith(
        isAnalyzing: false,
        journal: result.journal,
        analysis: analysis,
        // Kartu krisis muncul HANYA berdasarkan penanda dari server.
        showCrisisCard: analysis?.isCrisisFlagged ?? false,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(
        isAnalyzing: false,
        errorMessage: error.message,
        // Pesan backdate/tanggal perlu ditempelkan pada pemilih tanggal,
        // bukan sekadar muncul sebagai error umum.
        isDateError: error.code == ApiErrorCode.backdateLimitExceeded ||
            error.code == ApiErrorCode.futureDateNotAllowed,
      ));
    }
  }

  /// Menganalisis ulang jurnal yang sudah tersimpan.
  Future<void> analyzeExisting(String journalId) async {
    emit(state.copyWith(isAnalyzing: true, clearError: true));

    try {
      final analysis = await _repository.analyze(journalId);
      emit(state.copyWith(
        isAnalyzing: false,
        analysis: analysis,
        showCrisisCard: analysis.isCrisisFlagged,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(isAnalyzing: false, errorMessage: error.message));
    }
  }

  void dismissCrisisCard() => emit(state.copyWith(showCrisisCard: false));

  void clearError() => emit(state.copyWith(clearError: true));

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
