import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/repositories/daily_metric_repository.dart';
import '../../domain/entities/daily_metric.dart';

part 'mood_history_state.dart';

/// Cubit tab Mood — MURNI RIWAYAT.
///
/// Tab ini tidak lagi memuat form check-in; pengisian dipindah ke Beranda.
/// Yang tersisa di sini adalah tempat melihat pola: kalender bulanan, ritme
/// mood, dan sebaran emosi.
class MoodHistoryCubit extends Cubit<MoodHistoryState> {
  MoodHistoryCubit(this._repository) : super(const MoodHistoryState());

  final DailyMetricRepository _repository;

  /// Periode yang boleh dipilih pengguna untuk grafik & sebaran.
  static const availablePeriods = [30, 90, 120];

  Future<void> load() async {
    emit(state.copyWith(status: MoodHistoryStatus.loading, clearError: true));

    try {
      final monthly = await _repository.fetchMonthly(month: state.month);
      final stats = await _repository.fetchStats(periodDays: state.periodDays);

      emit(state.copyWith(
        status: MoodHistoryStatus.ready,
        monthly: monthly,
        stats: stats,
        month: monthly.month,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(status: MoodHistoryStatus.failure, errorMessage: error.message));
    }
  }

  Future<void> refresh() => load();

  /// Pindah bulan pada kalender. Hanya kalender yang dimuat ulang — statistik
  /// periode tidak bergantung pada bulan yang sedang dilihat.
  Future<void> changeMonth(int offset) async {
    final current = state.monthly.firstDate;
    if (current == null) return;

    final target = DateTime(current.year, current.month + offset);
    if (offset > 0 && !state.monthly.hasNextMonth) return;

    emit(state.copyWith(isMonthLoading: true, clearError: true));

    try {
      final monthly = await _repository.fetchMonthly(month: _formatMonth(target));
      emit(state.copyWith(monthly: monthly, month: monthly.month, isMonthLoading: false));
    } on ApiException catch (error) {
      emit(state.copyWith(isMonthLoading: false, errorMessage: error.message));
    }
  }

  Future<void> changePeriod(int periodDays) async {
    if (periodDays == state.periodDays) return;

    emit(state.copyWith(periodDays: periodDays, isStatsLoading: true, clearError: true));

    try {
      final stats = await _repository.fetchStats(periodDays: periodDays);
      emit(state.copyWith(stats: stats, isStatsLoading: false));
    } on ApiException catch (error) {
      emit(state.copyWith(isStatsLoading: false, errorMessage: error.message));
    }
  }

  static String _formatMonth(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
}
