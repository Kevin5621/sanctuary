import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/repositories/mentor_repository.dart';
import '../../domain/entities/advisee.dart';

part 'dosen_profil_state.dart';

/// Cubit tab Profil dosen (L-PRO-02..03).
class DosenProfilCubit extends Cubit<DosenProfilState> {
  DosenProfilCubit(this._repository) : super(const DosenProfilState());

  final MentorRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: DosenProfilStatus.loading, clearError: true));

    try {
      final profile = await _repository.fetchProfile();
      emit(state.copyWith(
        status: DosenProfilStatus.ready,
        profile: profile,
        clearError: true,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(
        status: DosenProfilStatus.failure,
        errorMessage: error.message,
      ));
    }
  }
}
