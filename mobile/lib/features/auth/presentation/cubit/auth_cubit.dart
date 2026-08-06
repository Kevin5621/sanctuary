import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_state.dart';

/// Sumber kebenaran status sesi.
///
/// GoRouter menyimak cubit ini untuk mengarahkan pengguna ke shell yang sesuai
/// dengan perannya, sehingga tidak ada navigasi manual setelah login.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  /// Dipanggil sekali saat aplikasi start: memulihkan sesi dari secure storage.
  Future<void> restoreSession() async {
    if (!await _repository.hasSession()) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, clearUser: true));
      return;
    }

    try {
      final user = await _repository.currentUser();
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } on ApiException {
      // Token tidak lagi valid — perlakukan sebagai belum masuk.
      emit(state.copyWith(status: AuthStatus.unauthenticated, clearUser: true));
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      final user = await _repository.login(
        email: email.trim(),
        password: password,
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isSubmitting: false,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: error.message,
        fieldErrors: {
          for (final field in error.fieldErrors) field.field: field.message,
        },
      ));
    }
  }

  /// Pendaftaran mahasiswa. Sukses berarti sesi langsung aktif, sehingga
  /// gerbang router memindahkan pengguna ke beranda mahasiswa tanpa navigasi
  /// manual — persis seperti setelah login.
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String studentNumber,
    required int cohortYear,
    required String studyProgramId,
    String? phone,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      final user = await _repository.register(
        fullName: fullName.trim(),
        email: email.trim(),
        password: password,
        passwordConfirmation: passwordConfirmation,
        studentNumber: studentNumber.trim(),
        cohortYear: cohortYear,
        studyProgramId: studyProgramId,
        phone: phone?.trim(),
      );
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isSubmitting: false,
      ));
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: error.message,
        fieldErrors: {
          for (final field in error.fieldErrors) field.field: field.message,
        },
      ));
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  /// Dipanggil DioClient ketika refresh token gagal.
  void onSessionExpired() {
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void clearError() => emit(state.copyWith(clearError: true));
}
