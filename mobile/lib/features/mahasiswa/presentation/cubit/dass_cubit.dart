import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/repositories/dass_repository.dart';
import '../../domain/entities/dass21.dart';

part 'dass_state.dart';

/// Cubit skrining DASS-21.
///
/// Klien hanya mengumpulkan jawaban. Skor dan kategori keparahan dihitung
/// server — tidak ada perhitungan klinis apa pun di sini, supaya ambangnya
/// mustahil berbeda antar versi aplikasi.
class DassCubit extends Cubit<DassState> {
  DassCubit(this._repository) : super(const DassState());

  final DassRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: DassStatus.loading, clearError: true));

    try {
      final questionnaire = await _repository.fetchQuestionnaire();
      final history = await _repository.fetchHistory();

      emit(state.copyWith(
        status: DassStatus.ready,
        questionnaire: questionnaire,
        history: history,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(status: DassStatus.failure, errorMessage: error.message));
    }
  }

  /// [number] adalah nomor soal (1-based), [value] jawaban 0..3.
  void answer(int number, int value) {
    final answers = Map<int, int>.from(state.answers)..[number] = value;
    emit(state.copyWith(answers: answers, clearError: true));
  }

  /// Mulai mengisi (dari layar hasil / riwayat).
  void startNewScreening() {
    emit(state.copyWith(
      answers: const {},
      clearResult: true,
      clearError: true,
      view: DassView.questionnaire,
    ));
  }

  void showHistory() => emit(state.copyWith(view: DassView.history, clearError: true));

  Future<bool> submit() async {
    if (!state.isComplete) {
      emit(state.copyWith(
        errorMessage: 'Lengkapi semua soal dulu — skor hanya bermakna bila terisi penuh.',
      ));
      return false;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      final answers = [
        for (final question in state.questionnaire.questions) state.answers[question.number] ?? 0,
      ];

      final result = await _repository.submit(answers);
      final history = await _repository.fetchHistory();

      emit(state.copyWith(
        result: result,
        history: history,
        isSubmitting: false,
        view: DassView.result,
      ));
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: error.message));
      return false;
    }
  }
}
