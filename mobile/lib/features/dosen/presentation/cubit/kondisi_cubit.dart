import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/repositories/mentor_repository.dart';
import '../../domain/entities/group_condition.dart';

part 'kondisi_state.dart';

/// Cubit tab Kondisi (L-KON-01..04).
class KondisiCubit extends Cubit<KondisiState> {
  KondisiCubit(this._repository) : super(const KondisiState());

  final MentorRepository _repository;

  /// Periode yang diizinkan backend. Nilai di luar daftar ini ditolak server
  /// dengan INVALID_QUERY_PARAM, jadi pemilih di UI dibatasi ke tiga ini saja.
  static const allowedPeriods = [30, 90, 120];

  Future<void> load() async {
    emit(state.copyWith(status: KondisiStatus.loading, clearError: true));
    await _fetch(state.periodDays);
  }

  Future<void> refresh() => _fetch(state.periodDays);

  /// Mengganti periode 30 / 90 / 120 hari.
  Future<void> selectPeriod(int periodDays) async {
    if (periodDays == state.periodDays) return;
    if (!allowedPeriods.contains(periodDays)) return;

    emit(state.copyWith(
      periodDays: periodDays,
      status: KondisiStatus.loading,
      clearError: true,
    ));
    await _fetch(periodDays);
  }

  Future<void> _fetch(int periodDays) async {
    try {
      final condition = await _repository.fetchGroupCondition(
        periodDays: periodDays,
      );
      emit(state.copyWith(
        status: KondisiStatus.ready,
        condition: condition,
        clearError: true,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(
        status: KondisiStatus.failure,
        errorMessage: error.message,
      ));
    }
  }
}
