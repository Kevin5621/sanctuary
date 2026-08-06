import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary/core/network/api_exception.dart';
import 'package:sanctuary/features/auth/domain/entities/app_user.dart';
import 'package:sanctuary/features/auth/domain/entities/study_program.dart';
import 'package:sanctuary/features/auth/domain/repositories/auth_repository.dart';
import 'package:sanctuary/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sanctuary/features/auth/presentation/cubit/study_program_cubit.dart';

/// Repository palsu untuk alur pendaftaran. [AuthRepository] adalah kontrak
/// abstrak, jadi fake ini cukup mengimplementasikannya langsung.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.registerError,
    this.programsError,
    this.programs = const [
      StudyProgram(id: 'prodi-1', code: 'TI', name: 'Teknik Informatika'),
    ],
  });

  ApiException? registerError;
  ApiException? programsError;
  List<StudyProgram> programs;

  Map<String, dynamic>? lastRegisterArgs;

  @override
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String studentNumber,
    required int cohortYear,
    required String studyProgramId,
    String? phone,
  }) async {
    if (registerError != null) throw registerError!;

    lastRegisterArgs = {
      'full_name': fullName,
      'email': email,
      'student_number': studentNumber,
      'cohort_year': cohortYear,
      'study_program_id': studyProgramId,
      'phone': phone,
    };

    return AppUser(
      id: 'user-1',
      fullName: fullName,
      email: email,
      role: UserRole.student,
      studentNumber: studentNumber,
      cohortYear: cohortYear,
    );
  }

  @override
  Future<List<StudyProgram>> studyPrograms() async {
    if (programsError != null) throw programsError!;
    return programs;
  }

  @override
  Future<AppUser> login({required String email, required String password}) async =>
      throw UnimplementedError();

  @override
  Future<AppUser> currentUser() async => throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<bool> hasSession() async => false;
}

Future<bool> _register(AuthCubit cubit) => cubit.register(
      fullName: '  Alya Prameswari ',
      email: '  alya@sanctuary.ac.id ',
      password: 'rahasia123',
      passwordConfirmation: 'rahasia123',
      studentNumber: ' 220001 ',
      cohortYear: 2022,
      studyProgramId: 'prodi-1',
      phone: '081200000001',
    );

void main() {
  group('AuthCubit.register', () {
    test('pendaftaran berhasil langsung membuat sesi mahasiswa', () async {
      final repository = _FakeAuthRepository();
      final cubit = AuthCubit(repository);

      final ok = await _register(cubit);

      expect(ok, isTrue);
      expect(cubit.state.status, AuthStatus.authenticated);
      // Peran hasil pendaftaran selalu mahasiswa; gerbang router memakainya
      // untuk memindahkan pengguna ke beranda tanpa navigasi manual.
      expect(cubit.state.role, UserRole.student);
      expect(cubit.state.isSubmitting, isFalse);
    });

    test('spasi di sekitar isian dirapikan sebelum dikirim', () async {
      final repository = _FakeAuthRepository();
      final cubit = AuthCubit(repository);

      await _register(cubit);

      expect(repository.lastRegisterArgs?['full_name'], 'Alya Prameswari');
      expect(repository.lastRegisterArgs?['email'], 'alya@sanctuary.ac.id');
      expect(repository.lastRegisterArgs?['student_number'], '220001');
    });

    test('gagal mendaftar tidak meninggalkan sesi setengah jadi', () async {
      final repository = _FakeAuthRepository(
        registerError: const ApiException(
          code: 'EMAIL_ALREADY_REGISTERED',
          message: 'Email ini sudah terdaftar',
          statusCode: 409,
          fieldErrors: [
            FieldError(
                field: 'email', code: 'CONFLICT', message: 'Sudah dipakai'),
          ],
        ),
      );
      final cubit = AuthCubit(repository);

      final ok = await _register(cubit);

      expect(ok, isFalse);
      expect(cubit.state.status, AuthStatus.unknown);
      expect(cubit.state.user, isNull);
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.fieldErrors['email'], 'Sudah dipakai');
    });
  });

  group('StudyProgramCubit', () {
    test('memuat daftar program studi', () async {
      final cubit = StudyProgramCubit(_FakeAuthRepository());

      await cubit.load();

      expect(cubit.state.status, StudyProgramStatus.ready);
      expect(cubit.state.programs.single.label, 'Teknik Informatika · TI');
      expect(cubit.state.isEmpty, isFalse);
    });

    // Dua sebab yang berbeda perlu kalimat yang berbeda: menyuruh "coba lagi"
    // atas daftar yang memang kosong tidak akan pernah menolong.
    test('daftar kosong dibedakan dari gagal memuat', () async {
      final empty = StudyProgramCubit(_FakeAuthRepository(programs: const []));
      await empty.load();

      expect(empty.state.isEmpty, isTrue);
      expect(empty.state.status, StudyProgramStatus.ready);

      final failing = StudyProgramCubit(
        _FakeAuthRepository(
          programsError: const ApiException(
            code: ApiErrorCode.networkError,
            message: 'Tidak dapat terhubung ke server.',
          ),
        ),
      );
      await failing.load();

      expect(failing.state.status, StudyProgramStatus.failure);
      expect(failing.state.isEmpty, isFalse);
      expect(failing.state.errorMessage, isNotNull);
    });
  });
}
