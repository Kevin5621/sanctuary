import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/repositories/journal_repository.dart';
import '../../domain/entities/journal.dart';

part 'jurnal_state.dart';

/// Cubit tab Jurnal.
///
/// Jurnal adalah konten privat: tidak ada satu pun jalur di sini yang mengirim
/// atau menerima tulisan milik orang lain. Analisis emosi dijalankan server
/// atas permintaan eksplisit mahasiswa, bukan otomatis di belakang layar.
class JurnalCubit extends Cubit<JurnalState> {
  JurnalCubit(this._repository) : super(const JurnalState());

  final JournalRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: JurnalStatus.loading, clearError: true));

    try {
      final page = await _repository.fetchPage();
      emit(state.copyWith(
        status: JurnalStatus.ready,
        entries: page.items,
        page: page.page,
        hasNextPage: page.hasNextPage,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(status: JurnalStatus.failure, errorMessage: error.message));
    }
  }

  Future<void> refresh() => load();

  Future<void> loadMore() async {
    if (!state.hasNextPage || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true, clearError: true));

    try {
      final page = await _repository.fetchPage(page: state.page + 1);
      emit(state.copyWith(
        entries: [...state.entries, ...page.items],
        page: page.page,
        hasNextPage: page.hasNextPage,
        isLoadingMore: false,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: error.message));
    }
  }

  /// Menyimpan catatan baru, sekaligus menganalisisnya bila diminta.
  ///
  /// Bila analisis gagal, catatan TETAP tersimpan — kegagalan model tidak
  /// boleh menghilangkan tulisan seseorang.
  Future<bool> submit({
    required String content,
    String title = '',
    DateTime? date,
    bool analyzeNow = true,
  }) async {
    if (content.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Tulis dulu isi catatanmu sebelum menyimpan.'));
      return false;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true, clearAnalysis: true));

    try {
      final result = await _repository.create(
        content: content.trim(),
        title: title.trim(),
        journalDate: date == null ? null : _formatDate(date),
        analyzeNow: analyzeNow,
      );

      final page = await _repository.fetchPage();
      emit(state.copyWith(
        status: JurnalStatus.ready,
        entries: page.items,
        page: page.page,
        hasNextPage: page.hasNextPage,
        isSubmitting: false,
        analysis: result.analysis,
        successMessage: 'Catatan tersimpan.',
      ));
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: error.message));
      return false;
    }
  }

  /// Menganalisis catatan yang sudah tersimpan (misalnya dulu disimpan tanpa
  /// analisis, lalu pemiliknya berubah pikiran).
  Future<void> analyzeExisting(String journalId) async {
    emit(state.copyWith(analyzingId: journalId, clearError: true, clearAnalysis: true));

    try {
      final analysis = await _repository.analyze(journalId);
      final page = await _repository.fetchPage();

      emit(state.copyWith(
        entries: page.items,
        page: page.page,
        hasNextPage: page.hasNextPage,
        analysis: analysis,
        clearAnalyzingId: true,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(clearAnalyzingId: true, errorMessage: error.message));
    }
  }

  Future<void> delete(String journalId) async {
    emit(state.copyWith(clearError: true, clearSuccess: true));

    try {
      await _repository.delete(journalId);
      emit(state.copyWith(
        entries: state.entries.where((entry) => entry.id != journalId).toList(),
        successMessage: 'Catatan dihapus.',
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(errorMessage: error.message));
    }
  }

  /// Menutup kartu hasil analisis tanpa menghapus catatannya.
  void dismissAnalysis() => emit(state.copyWith(clearAnalysis: true));

  void clearMessages() => emit(state.copyWith(clearError: true, clearSuccess: true));

  static String _formatDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
