import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/repositories/daily_metric_repository.dart';
import '../../domain/entities/daily_metric.dart';

part 'mood_history_state.dart';

/// Cubit tab Mood — riwayat, plus pengisian lewat kalender.
///
/// Tab ini terutama tempat melihat pola: kalender bulanan, ritme mood, dan
/// sebaran emosi. Namun tanggal yang belum terisi bisa diketuk langsung dari
/// kalender: saat melihat celah pada riwayat, jalan terdekat untuk menutupnya
/// harus ada di tempat celah itu terlihat, bukan di layar lain.
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

      // Pilihan check-in bersifat pelengkap di layar ini: bila gagal dimuat,
      // riwayat tetap tampil — hanya pengisian dari kalender yang nonaktif.
      final options = await _tryFetchOptions();

      emit(state.copyWith(
        status: MoodHistoryStatus.ready,
        monthly: monthly,
        stats: stats,
        month: monthly.month,
        options: options ?? state.options,
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

  /// Menyimpan check-in untuk [date] — tanggal yang diketuk pada kalender.
  ///
  /// Nilainya persis yang diisi mahasiswa pada form; tidak ada nilai bawaan
  /// yang dikarang di sini, karena angka karangan ikut dihitung indikator
  /// peringatan dini yang dilihat dosen.
  ///
  /// Server melakukan upsert per tanggal, jadi mengisi tanggal yang sudah ada
  /// berarti memperbaikinya. Batas mundur tanggal tetap divalidasi server;
  /// [MoodHistoryState.canCheckInOn] hanya menjaga agar form tidak dibuka untuk
  /// tanggal yang pasti ditolak.
  Future<bool> saveCheckin({
    required int moodScore,
    required int stressLevel,
    required double sleepHours,
    required DateTime date,
    String academicTrigger = '',
  }) async {
    emit(state.copyWith(isSaving: true, clearError: true, clearSuccess: true));

    try {
      await _repository.saveDailyMetric(
        moodScore: moodScore,
        stressLevel: stressLevel,
        sleepHours: sleepHours,
        academicTrigger: academicTrigger,
        metricDate: _formatDate(date),
      );

      // Kalender dan statistik dimuat ulang bersama: satu check-in mengubah
      // keduanya, dan menampilkan yang satu tanpa yang lain membuat layar
      // seperti melaporkan dua kenyataan berbeda.
      final monthly = await _repository.fetchMonthly(month: state.month);
      final stats = await _repository.fetchStats(periodDays: state.periodDays);

      emit(state.copyWith(
        status: MoodHistoryStatus.ready,
        monthly: monthly,
        stats: stats,
        month: monthly.month,
        isSaving: false,
        successMessage: 'Check-in tersimpan.',
      ));
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.message));
      return false;
    }
  }

  void clearMessages() => emit(state.copyWith(clearError: true, clearSuccess: true));

  Future<CheckinOptions?> _tryFetchOptions() async {
    try {
      return await _repository.fetchOptions();
    } on ApiException {
      return null;
    }
  }

  static String _formatDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _formatMonth(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
}
