import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/repositories/contact_request_repository.dart';
import '../../domain/entities/advisor.dart';

part 'my_advisors_state.dart';

/// Kartu "Pembimbingmu" pada tab Profil mahasiswa.
///
/// Sengaja diambil dari server setiap kali layar dibuka, bukan dari payload
/// sesi: alokasi pembimbing berubah di sisi prodi, dan daftar yang basi akan
/// membuat mahasiswa salah menilai siapa yang bisa melihat datanya.
class MyAdvisorsCubit extends Cubit<MyAdvisorsState> {
  MyAdvisorsCubit(this._repository) : super(const MyAdvisorsState());

  final ContactRequestRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: MyAdvisorsStatus.loading, clearError: true));
    try {
      final advisors = await _repository.fetchAdvisors();
      emit(state.copyWith(
        status: MyAdvisorsStatus.ready,
        advisors: advisors,
        clearError: true,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(
        status: MyAdvisorsStatus.failure,
        errorMessage: error.message,
      ));
    }
  }
}
