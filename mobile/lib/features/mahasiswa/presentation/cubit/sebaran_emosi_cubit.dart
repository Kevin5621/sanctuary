import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/repositories/journal_repository.dart';
import '../../domain/entities/journal.dart';

part 'sebaran_emosi_state.dart';

/// Cubit "Sebaran Emosi" di tab Mood (M-MOOD-04).
///
/// Sumbernya HANYA analisis jurnal (D-3). Cubit ini sengaja tidak menyentuh
/// repository check-in mood: mencampur keduanya akan membuat satu hari buruk
/// terhitung dua kali, persis yang dilarang keputusan D-3.
class SebaranEmosiCubit extends Cubit<SebaranEmosiState> {
  SebaranEmosiCubit(this._repository) : super(const SebaranEmosiState());

  final JournalRepository _repository;

  Future<void> load({int rangeDays = 30}) async {
    emit(state.copyWith(
      status: SebaranEmosiStatus.loading,
      rangeDays: rangeDays,
      clearError: true,
    ));

    try {
      final distribution =
          await _repository.fetchEmotionDistribution(rangeDays: rangeDays);
      emit(state.copyWith(
        status: SebaranEmosiStatus.ready,
        distribution: distribution,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(
        status: SebaranEmosiStatus.failure,
        errorMessage: error.message,
      ));
    }
  }

  Future<void> changeRange(int rangeDays) => load(rangeDays: rangeDays);

  Future<void> refresh() => load(rangeDays: state.rangeDays);
}
