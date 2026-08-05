import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../data/repositories/daily_metric_repository.dart';
import '../../domain/entities/daily_metric.dart';

part 'beranda_state.dart';

/// Cubit layar Beranda mahasiswa.
///
/// Mengambil ringkasan mood mingguan dan memproses check-in mood harian
/// real-time langsung ke backend DB.
class BerandaCubit extends Cubit<BerandaState> {
  BerandaCubit(this._repository) : super(const BerandaState());

  final DailyMetricRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: BerandaStatus.loading, clearError: true));

    try {
      final summary = await _repository.fetchWeeklySummary();
      emit(state.copyWith(status: BerandaStatus.ready, summary: summary));
    } on ApiException catch (error) {
      emit(state.copyWith(status: BerandaStatus.failure, errorMessage: error.message));
    }
  }

  Future<void> logQuickMood(MoodType mood) async {
    final (score, emotionLabel) = switch (mood) {
      MoodType.happiness => (5, 'JOY'),
      MoodType.disgust => (3, 'NEUTRAL'),
      MoodType.fear => (2, 'ANXIOUS'),
      MoodType.anger => (2, 'ANGRY'),
      MoodType.sadness => (1, 'SAD'),
    };

    try {
      await _repository.saveDailyMetric(
        moodScore: score,
        emotionLabel: emotionLabel,
      );
      await load();
    } on ApiException catch (error) {
      emit(state.copyWith(status: BerandaStatus.failure, errorMessage: error.message));
    }
  }

  Future<void> refresh() => load();
}

