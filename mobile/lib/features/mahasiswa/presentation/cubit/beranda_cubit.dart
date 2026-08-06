import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/repositories/contact_request_repository.dart';
import '../../data/repositories/daily_metric_repository.dart';
import '../../domain/entities/contact_request.dart';
import '../../domain/entities/daily_metric.dart';

part 'beranda_state.dart';

/// Cubit layar Beranda mahasiswa.
///
/// Beranda adalah satu-satunya tempat check-in harian diisi (tab Mood murni
/// riwayat). Alasannya: check-in adalah tindakan harian yang harus ada di layar
/// pertama, sementara riwayat adalah tempat merenung yang dibuka sesekali.
class BerandaCubit extends Cubit<BerandaState> {
  BerandaCubit({
    required DailyMetricRepository metrics,
    required ContactRequestRepository contactRequests,
  })  : _metrics = metrics,
        _contactRequests = contactRequests,
        super(const BerandaState());

  final DailyMetricRepository _metrics;
  final ContactRequestRepository _contactRequests;

  Future<void> load() async {
    emit(state.copyWith(status: BerandaStatus.loading, clearError: true));

    try {
      final summary = await _metrics.fetchWeeklySummary();

      // Pilihan check-in dan status "minta dihubungi" bersifat pelengkap:
      // kegagalannya tidak boleh membuat Beranda gagal tampil seluruhnya.
      final options = await _tryFetchOptions();
      final contact = await _tryFetchContactState();

      emit(state.copyWith(
        status: BerandaStatus.ready,
        summary: summary,
        options: options ?? state.options,
        contact: contact ?? state.contact,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(status: BerandaStatus.failure, errorMessage: error.message));
    }
  }

  Future<void> refresh() => load();

  /// Menyimpan check-in harian.
  ///
  /// Seluruh nilai berasal dari yang benar-benar diisi mahasiswa. Tidak ada
  /// jalur "simpan cepat" yang mengarang tingkat stres atau jam tidur — angka
  /// karangan itu ikut dihitung indikator peringatan dini, dan dosen akan
  /// menerima sinyal yang tidak pernah dimaksudkan siapa pun.
  Future<bool> saveCheckin({
    required int moodScore,
    required int stressLevel,
    required double sleepHours,
    String emotionLabel = '',
    String academicTrigger = '',
    DateTime? date,
  }) async {
    emit(state.copyWith(isSaving: true, clearError: true, clearSuccess: true));

    try {
      await _metrics.saveDailyMetric(
        moodScore: moodScore,
        stressLevel: stressLevel,
        sleepHours: sleepHours,
        emotionLabel: emotionLabel,
        academicTrigger: academicTrigger,
        metricDate: date == null ? null : formatApiDate(date),
      );

      final summary = await _metrics.fetchWeeklySummary();
      emit(state.copyWith(
        status: BerandaStatus.ready,
        summary: summary,
        isSaving: false,
        successMessage: 'Check-in tersimpan.',
      ));
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.message));
      return false;
    }
  }

  Future<bool> requestContact({String note = ''}) async {
    emit(state.copyWith(isSaving: true, clearError: true, clearSuccess: true));

    try {
      await _contactRequests.create(note: note);
      final contact = await _contactRequests.fetchState();
      emit(state.copyWith(
        contact: contact,
        isSaving: false,
        successMessage: 'Pembimbingmu akan melihat permintaan ini.',
      ));
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.message));
      return false;
    }
  }

  Future<void> cancelContactRequest() async {
    emit(state.copyWith(isSaving: true, clearError: true, clearSuccess: true));

    try {
      await _contactRequests.cancel();
      final contact = await _contactRequests.fetchState();
      emit(state.copyWith(
        contact: contact,
        isSaving: false,
        successMessage: 'Permintaan dibatalkan.',
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.message));
    }
  }

  void clearMessages() => emit(state.copyWith(clearError: true, clearSuccess: true));

  Future<CheckinOptions?> _tryFetchOptions() async {
    try {
      return await _metrics.fetchOptions();
    } on ApiException {
      return null;
    }
  }

  Future<ContactRequestState?> _tryFetchContactState() async {
    try {
      return await _contactRequests.fetchState();
    } on ApiException {
      return null;
    }
  }
}

/// Format YYYY-MM-DD sesuai yang diharapkan API.
String formatApiDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
