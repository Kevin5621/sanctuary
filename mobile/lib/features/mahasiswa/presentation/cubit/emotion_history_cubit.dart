import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/repositories/journal_repository.dart';
import '../../domain/entities/journal.dart';

part 'emotion_history_state.dart';

/// Cubit menu "Riwayat Analisis Emosi" di tab Profil.
class EmotionHistoryCubit extends Cubit<EmotionHistoryState> {
  EmotionHistoryCubit(this._repository) : super(const EmotionHistoryState());

  final JournalRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: EmotionHistoryStatus.loading, clearError: true));

    try {
      final history = await _repository.fetchEmotionHistory();
      emit(state.copyWith(status: EmotionHistoryStatus.ready, history: history));
    } on ApiException catch (error) {
      emit(state.copyWith(status: EmotionHistoryStatus.failure, errorMessage: error.message));
    }
  }

  Future<void> refresh() => load();
}
