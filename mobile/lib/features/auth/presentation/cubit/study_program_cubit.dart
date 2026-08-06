import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/study_program.dart';
import '../../domain/repositories/auth_repository.dart';

part 'study_program_state.dart';

/// Memuat daftar program studi untuk dropdown pendaftaran.
///
/// Dipisah dari [AuthCubit] karena umurnya berbeda: daftar ini hanya relevan
/// selama formulir pendaftaran terbuka, sedangkan AuthCubit hidup sepanjang
/// aplikasi berjalan sebagai sumber kebenaran sesi.
class StudyProgramCubit extends Cubit<StudyProgramState> {
  StudyProgramCubit(this._repository) : super(const StudyProgramState());

  final AuthRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: StudyProgramStatus.loading, clearError: true));

    try {
      final programs = await _repository.studyPrograms();
      emit(state.copyWith(
        status: StudyProgramStatus.ready,
        programs: programs,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(
        status: StudyProgramStatus.failure,
        errorMessage: error.message,
      ));
    }
  }
}
