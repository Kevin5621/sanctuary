import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/repositories/program_repository.dart';
import '../../domain/entities/program_dashboard.dart';

part 'kaprodi_state.dart';

/// Cubit dashboard prodi (K-DAS-01..07).
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository) : super(const DashboardState());

  final ProgramRepository _repository;

  static const allowedPeriods = [30, 90, 120];

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading, clearError: true));
    await _fetch(state.periodDays);
  }

  Future<void> refresh() => _fetch(state.periodDays);

  Future<void> selectPeriod(int periodDays) async {
    if (periodDays == state.periodDays) return;
    if (!allowedPeriods.contains(periodDays)) return;

    emit(state.copyWith(
      periodDays: periodDays,
      status: LoadStatus.loading,
      clearError: true,
    ));
    await _fetch(periodDays);
  }

  Future<void> _fetch(int periodDays) async {
    try {
      final dashboard = await _repository.fetchDashboard(periodDays: periodDays);
      emit(state.copyWith(
        status: LoadStatus.ready,
        dashboard: dashboard,
        clearError: true,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(
        status: LoadStatus.failure,
        errorMessage: error.message,
      ));
    }
  }
}

/// Cubit tab Pembimbing (K-PEM-01).
class PembimbingCubit extends Cubit<PembimbingState> {
  PembimbingCubit(this._repository) : super(const PembimbingState());

  final ProgramRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(
      status: LoadStatus.loading,
      clearError: true,
      clearSuccess: true,
    ));
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final results = await Future.wait([
        _repository.fetchAdvisors(),
        _repository.fetchStudents(),
      ]);
      final advisors = results[0] as List<AdvisorLoad>;
      final students = results[1] as List<ProgramStudent>;

      emit(state.copyWith(
        status: LoadStatus.ready,
        advisors: advisors,
        students: students,
        clearError: true,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(
        status: LoadStatus.failure,
        errorMessage: error.message,
      ));
    }
  }

  /// Setel daftar bimbingan satu dosen (layar per-dosen).
  Future<bool> setAdvisees({
    required String advisorId,
    required List<String> studentIds,
  }) {
    return _save(
      () => _repository.setAdvisees(advisorId: advisorId, studentIds: studentIds),
      'Alokasi mahasiswa bimbingan berhasil disimpan.',
    );
  }

  /// Setel daftar pembimbing satu mahasiswa (layar per-mahasiswa) — inilah
  /// jalur yang dipakai saat mahasiswa dibimbing lebih dari satu dosen.
  Future<bool> setStudentAdvisors({
    required String studentId,
    required List<String> advisorIds,
  }) {
    return _save(
      () => _repository.setStudentAdvisors(
        studentId: studentId,
        advisorIds: advisorIds,
      ),
      'Pembimbing mahasiswa berhasil diperbarui.',
    );
  }

  /// Lepas satu pasangan dosen–mahasiswa tanpa menyentuh pembimbing lainnya.
  Future<bool> removeAdvisor({
    required ProgramStudent student,
    required String advisorId,
  }) {
    final remaining =
        student.advisorIds.where((id) => id != advisorId).toList();
    return setStudentAdvisors(
      studentId: student.id,
      advisorIds: remaining,
    );
  }

  Future<bool> _save(Future<void> Function() action, String successMessage) async {
    emit(state.copyWith(isSaving: true, clearError: true, clearSuccess: true));
    try {
      await action();
      await refresh();
      emit(state.copyWith(isSaving: false, successMessage: successMessage));
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isSaving: false, errorMessage: error.message));
      return false;
    }
  }

  void clearMessages() {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }
}

/// Cubit tab Laporan (K-LAP-01).
class LaporanCubit extends Cubit<LaporanState> {
  LaporanCubit(this._repository) : super(const LaporanState());

  final ProgramRepository _repository;

  static const allowedPeriods = [30, 90, 120];

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading, clearError: true));
    await _fetch(state.periodDays);
  }

  Future<void> refresh() => _fetch(state.periodDays);

  Future<void> selectPeriod(int periodDays) async {
    if (periodDays == state.periodDays) return;
    if (!allowedPeriods.contains(periodDays)) return;

    emit(state.copyWith(
      periodDays: periodDays,
      status: LoadStatus.loading,
      clearError: true,
    ));
    await _fetch(periodDays);
  }

  Future<void> _fetch(int periodDays) async {
    try {
      final reports = await _repository.fetchCohortReports(
        periodDays: periodDays,
      );
      emit(state.copyWith(
        status: LoadStatus.ready,
        reports: reports,
        clearError: true,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(
        status: LoadStatus.failure,
        errorMessage: error.message,
      ));
    }
  }
}

/// Cubit tab Profil kaprodi (K-PRO-01).
class KaprodiProfilCubit extends Cubit<KaprodiProfilState> {
  KaprodiProfilCubit(this._repository) : super(const KaprodiProfilState());

  final ProgramRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading, clearError: true));

    try {
      final profile = await _repository.fetchProfile();
      emit(state.copyWith(
        status: LoadStatus.ready,
        profile: profile,
        clearError: true,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(
        status: LoadStatus.failure,
        errorMessage: error.message,
      ));
    }
  }
}
