import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart' show PaginationMeta;
import '../../data/repositories/mentor_repository.dart';
import '../../domain/entities/advisee.dart';

part 'bimbingan_state.dart';

/// Cubit tab Bimbingan (L-BIM-01..03).
///
/// Memuat dua daftar sekaligus karena keduanya tampil pada layar yang sama:
/// daftar bimbingan dan daftar "minta dihubungi".
class BimbinganCubit extends Cubit<BimbinganState> {
  BimbinganCubit(this._repository) : super(const BimbinganState());

  final MentorRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: BimbinganStatus.loading, clearError: true));
    await _fetch();
  }

  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    try {
      // Kedua permintaan berjalan paralel: daftar bimbingan dan daftar
      // permintaan dihubungi tidak saling bergantung.
      final results = await Future.wait([
        _repository.fetchAdvisees(),
        _repository.fetchContactRequests(),
      ]);

      final advisees = results[0] as ({List<Advisee> items, PaginationMeta? meta});
      final requests = results[1] as List<ContactRequest>;

      emit(state.copyWith(
        status: BimbinganStatus.ready,
        // Urutan dipertahankan apa adanya dari server (L-BIM-01):
        // minta-dihubungi → prioritas EWS → nama.
        advisees: advisees.items,
        totalAdvisees: advisees.meta?.total ?? advisees.items.length,
        contactRequests: requests,
        clearError: true,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(
        status: BimbinganStatus.failure,
        errorMessage: error.message,
      ));
    }
  }
}
