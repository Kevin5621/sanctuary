import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary/core/network/api_exception.dart';
import 'package:sanctuary/features/admin/data/repositories/user_admin_repository.dart';
import 'package:sanctuary/features/admin/domain/entities/managed_user.dart';
import 'package:sanctuary/features/admin/presentation/cubit/kelola_akun_cubit.dart';
import 'package:sanctuary/features/auth/domain/entities/study_program.dart';

import 'support/fake_repositories.dart';

/// Repository palsu: repository asli berupa kelas konkret, jadi fake ini
/// meng-override method-nya sambil mewarisi konstruktor — pola yang sama
/// dipakai pengujian cubit lain.
class _FakeUserAdminRepository extends UserAdminRepository {
  _FakeUserAdminRepository({
    List<ManagedUser>? users,
    this.failList = false,
    this.saveError,
  })  : users = users ?? const [],
        super(dummyClient());

  List<ManagedUser> users;
  bool failList;
  ApiException? saveError;

  String? lastRoleFilter;
  StaffAccountDraft? lastDraft;
  String? lastUpdatedId;
  int optionsFetchCount = 0;

  @override
  Future<List<ManagedUser>> fetchAll({
    String? role,
    bool? isActive,
    String? search,
    int page = 1,
  }) async {
    if (failList) throw networkError;
    lastRoleFilter = role;
    if (role == null) return users;
    return users.where((user) => user.role == role).toList();
  }

  @override
  Future<StaffFormOptions> fetchFormOptions() async {
    optionsFetchCount++;
    return const StaffFormOptions(
      roles: [
        RoleOption(value: 'LECTURER', label: 'Dosen Pembimbing'),
        RoleOption(value: 'HEAD_OF_PROGRAM', label: 'Kaprodi'),
      ],
      studyPrograms: [
        StudyProgram(id: 'prodi-1', code: 'TI', name: 'Teknik Informatika'),
      ],
    );
  }

  @override
  Future<ManagedUser> create(StaffAccountDraft draft) async {
    if (saveError != null) throw saveError!;
    lastDraft = draft;
    return _userFrom(draft, id: 'baru');
  }

  @override
  Future<ManagedUser> update(String id, StaffAccountDraft draft) async {
    if (saveError != null) throw saveError!;
    lastUpdatedId = id;
    lastDraft = draft;

    final updated = _userFrom(draft, id: id);
    users = [
      for (final user in users) user.id == id ? updated : user,
    ];
    return updated;
  }

  static ManagedUser _userFrom(StaffAccountDraft draft, {required String id}) =>
      ManagedUser(
        id: id,
        fullName: draft.fullName,
        email: draft.email,
        role: draft.role,
        roleLabel: draft.role == 'LECTURER' ? 'Dosen Pembimbing' : 'Kaprodi',
        studyProgramId: draft.studyProgramId,
        lecturerNumber: draft.lecturerNumber,
        phone: draft.phone,
        isActive: draft.isActive,
      );
}

ManagedUser _lecturer({
  String id = 'dosen-1',
  String role = 'LECTURER',
  bool isActive = true,
  String? lastLoginAt,
}) =>
    ManagedUser(
      id: id,
      fullName: 'Dr. Sinta Pembimbing',
      email: '$id@sanctuary.ac.id',
      role: role,
      roleLabel: role == 'LECTURER' ? 'Dosen Pembimbing' : 'Kaprodi',
      studyProgramId: 'prodi-1',
      studyProgram: 'Teknik Informatika',
      lecturerNumber: '0011224402',
      isActive: isActive,
      lastLoginAt: lastLoginAt,
    );

void main() {
  test('memuat daftar akun beserta opsi formulir', () async {
    final repository = _FakeUserAdminRepository(users: [_lecturer()]);
    final cubit = KelolaAkunCubit(repository);

    await cubit.load(withOptions: true);

    expect(cubit.state.status, AkunStatus.ready);
    expect(cubit.state.users, hasLength(1));
    expect(cubit.state.activeCount, 1);
    // Formulir tidak boleh dapat dibuka sebelum daftar peran & prodi ada:
    // menebak nilainya di klien berarti mengirim akun ke prodi yang belum
    // tentu terdaftar.
    expect(cubit.state.canOpenForm, isTrue);
  });

  test('opsi formulir hanya diambil sekali walau daftar dimuat ulang', () async {
    final repository = _FakeUserAdminRepository(users: [_lecturer()]);
    final cubit = KelolaAkunCubit(repository);

    await cubit.load(withOptions: true);
    await cubit.refresh();
    await cubit.refresh();

    expect(repository.optionsFetchCount, 1);
  });

  test('kegagalan jaringan tidak mengosongkan daftar secara diam-diam', () async {
    final repository = _FakeUserAdminRepository(failList: true);
    final cubit = KelolaAkunCubit(repository);

    await cubit.load();

    expect(cubit.state.status, AkunStatus.failure);
    expect(cubit.state.errorMessage, isNotNull);
    // isEmpty hanya benar setelah server menjawab dengan daftar kosong —
    // layar tidak boleh berkata "belum ada akun" saat sebenarnya gagal memuat.
    expect(cubit.state.isEmpty, isFalse);
  });

  test('menyaring per peran meneruskan filter ke server', () async {
    final repository = _FakeUserAdminRepository(users: [
      _lecturer(),
      _lecturer(id: 'kaprodi-1', role: 'HEAD_OF_PROGRAM'),
    ]);
    final cubit = KelolaAkunCubit(repository);
    await cubit.load(withOptions: true);

    await cubit.filterByRole('HEAD_OF_PROGRAM');

    expect(repository.lastRoleFilter, 'HEAD_OF_PROGRAM');
    expect(cubit.state.roleFilter, 'HEAD_OF_PROGRAM');
    expect(cubit.state.users.single.role, 'HEAD_OF_PROGRAM');
  });

  test('memilih "Semua" mengembalikan daftar tanpa filter', () async {
    final repository = _FakeUserAdminRepository(users: [_lecturer()]);
    final cubit = KelolaAkunCubit(repository);
    await cubit.load(withOptions: true);
    await cubit.filterByRole('LECTURER');

    await cubit.filterByRole(null);

    expect(cubit.state.roleFilter, isNull);
    expect(repository.lastRoleFilter, isNull);
  });

  test('membuat akun baru mengirim email & kata sandi', () async {
    final repository = _FakeUserAdminRepository();
    final cubit = KelolaAkunCubit(repository);
    await cubit.load(withOptions: true);

    final saved = await cubit.save(const StaffAccountDraft(
      fullName: 'Dr. Sinta Pembimbing',
      role: 'LECTURER',
      studyProgramId: 'prodi-1',
      email: 'sinta@sanctuary.ac.id',
      password: 'rahasia123',
    ));

    expect(saved, isTrue);
    expect(repository.lastDraft?.toCreateBody()['email'], 'sinta@sanctuary.ac.id');
    expect(repository.lastDraft?.toCreateBody()['password'], 'rahasia123');
    expect(cubit.state.successMessage, contains('dibuat'));
  });

  test('mengubah akun tanpa mengisi kata sandi tidak mengirim password',
      () async {
    final repository = _FakeUserAdminRepository(users: [_lecturer()]);
    final cubit = KelolaAkunCubit(repository);
    await cubit.load(withOptions: true);

    await cubit.save(
      const StaffAccountDraft(
        fullName: 'Dr. Sinta P.',
        role: 'LECTURER',
        studyProgramId: 'prodi-1',
      ),
      id: 'dosen-1',
    );

    // Kata sandi yang ikut terkirim akan mengakhiri sesi pemilik akun di
    // server. Menyimpan perubahan nama tidak boleh punya efek samping itu.
    expect(repository.lastUpdatedId, 'dosen-1');
    expect(repository.lastDraft?.toUpdateBody().containsKey('password'), isFalse);
  });

  test('menonaktifkan akun mempertahankan atribut lain apa adanya', () async {
    final repository = _FakeUserAdminRepository(users: [_lecturer()]);
    final cubit = KelolaAkunCubit(repository);
    await cubit.load(withOptions: true);

    await cubit.toggleActive(cubit.state.users.single);

    final body = repository.lastDraft!.toUpdateBody();
    expect(body['is_active'], isFalse);
    expect(body['lecturer_number'], '0011224402');
    expect(body['study_program_id'], 'prodi-1');
    expect(cubit.state.users.single.isActive, isFalse);
  });

  test('gagal menyimpan memetakan field_errors dari server', () async {
    final repository = _FakeUserAdminRepository(
      saveError: const ApiException(
        code: 'EMAIL_ALREADY_REGISTERED',
        message: 'Email ini sudah terdaftar',
        statusCode: 409,
        fieldErrors: [
          FieldError(field: 'email', code: 'CONFLICT', message: 'Sudah dipakai'),
        ],
      ),
    );
    final cubit = KelolaAkunCubit(repository);
    await cubit.load(withOptions: true);

    final saved = await cubit.save(const StaffAccountDraft(
      fullName: 'Dr. Sinta Pembimbing',
      role: 'LECTURER',
      studyProgramId: 'prodi-1',
      email: 'sinta@sanctuary.ac.id',
      password: 'rahasia123',
    ));

    expect(saved, isFalse);
    expect(cubit.state.isSaving, isFalse);
    expect(cubit.state.fieldErrors['email'], 'Sudah dipakai');
  });

  test('akun yang belum pernah masuk ditandai', () {
    expect(_lecturer().hasNeverSignedIn, isTrue);
    expect(
      _lecturer(lastLoginAt: '2026-08-06T10:00:00Z').hasNeverSignedIn,
      isFalse,
    );
  });
}
