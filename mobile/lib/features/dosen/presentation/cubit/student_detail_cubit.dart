import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/repositories/mentor_repository.dart';
import '../../domain/entities/advisee.dart';

part 'student_detail_state.dart';

/// Cubit halaman detail mahasiswa (L-BIM-04).
class StudentDetailCubit extends Cubit<StudentDetailState> {
  StudentDetailCubit(this._repository, this.studentId)
      : super(const StudentDetailState());

  final MentorRepository _repository;
  final String studentId;

  Future<void> load() async {
    emit(state.copyWith(status: StudentDetailStatus.loading, clearError: true));

    try {
      final indicator = await _repository.fetchStudentIndicator(studentId);
      emit(state.copyWith(
        status: StudentDetailStatus.ready,
        indicator: indicator,
        clearError: true,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(
        status: StudentDetailStatus.failure,
        errorMessage: error.message,
        // ADVISOR_ASSIGNMENT_REQUIRED ditandai terpisah: itu bukan gangguan
        // jaringan melainkan penolakan otorisasi, dan pesannya ke dosen harus
        // berbeda supaya tidak terus mencoba memuat ulang.
        isForbidden: error.code == ApiErrorCode.advisorAssignmentRequired ||
            error.code == ApiErrorCode.roleInsufficient,
      ));
    }
  }
}
