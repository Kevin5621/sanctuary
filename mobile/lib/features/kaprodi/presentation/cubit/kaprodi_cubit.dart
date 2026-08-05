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
    emit(state.copyWith(status: LoadStatus.loading, clearError: true));
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final advisors = await _repository.fetchAdvisors();
      emit(state.copyWith(
        status: LoadStatus.ready,
        advisors: advisors,
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
