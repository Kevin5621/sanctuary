import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary/core/network/dio_client.dart';
import 'package:sanctuary/core/network/token_storage.dart';
import 'package:sanctuary/features/privacy/data/repositories/privacy_repository.dart';
import 'package:sanctuary/features/privacy/domain/entities/privacy_setting.dart';
import 'package:sanctuary/features/privacy/presentation/cubit/privacy_cubit.dart';

/// Repository palsu: tidak menyentuh jaringan, mengembalikan nilai yang
/// dikendalikan pengujian.
class _FakePrivacyRepository extends PrivacyRepository {
  _FakePrivacyRepository(this._setting)
      : super(DioClient(
          tokenStorage: TokenStorage(),
          onSessionExpired: _noop,
        ));

  PrivacySetting _setting;
  PrivacySetting? lastSaved;

  static Future<void> _noop() async {}

  @override
  Future<PrivacySetting> fetch() async => _setting;

  @override
  Future<List<PrivacyOption>> fetchOptions() async => const [
        PrivacyOption(level: ShareLevel.closed, label: 'Tertutup', description: ''),
        PrivacyOption(level: ShareLevel.summary, label: 'Ringkasan', description: ''),
        PrivacyOption(
            level: ShareLevel.summaryTrend, label: 'Ringkasan + Tren', description: ''),
      ];

  @override
  Future<PrivacySetting> update(PrivacySetting setting) async {
    lastSaved = setting;
    _setting = setting;
    return setting;
  }
}

void main() {
  const openSetting = PrivacySetting(
    shareLevel: ShareLevel.summaryTrend,
    allowEarlyWarning: true,
    allowProgramStatistic: true,
  );

  test('memuat pengaturan tersimpan beserta daftar pilihan', () async {
    final cubit = PrivacyCubit(_FakePrivacyRepository(openSetting));

    await cubit.load();

    expect(cubit.state.status, PrivacyStatus.ready);
    expect(cubit.state.saved.shareLevel, ShareLevel.summaryTrend);
    expect(cubit.state.options, hasLength(3));
    expect(cubit.state.hasChanges, isFalse);
  });

  test('memilih Tertutup otomatis mematikan peringatan dini', () async {
    final cubit = PrivacyCubit(_FakePrivacyRepository(openSetting));
    await cubit.load();

    cubit.selectShareLevel(ShareLevel.closed);

    expect(cubit.state.draft.allowEarlyWarning, isFalse);
    expect(cubit.state.hasChanges, isTrue);
  });

  test('peringatan dini tidak dapat diaktifkan saat tingkat Tertutup', () async {
    final cubit = PrivacyCubit(_FakePrivacyRepository(openSetting));
    await cubit.load();

    cubit.selectShareLevel(ShareLevel.closed);
    cubit.toggleEarlyWarning(true);

    expect(cubit.state.draft.allowEarlyWarning, isFalse);
  });

  test('perubahan hanya terkirim saat disimpan', () async {
    final repository = _FakePrivacyRepository(openSetting);
    final cubit = PrivacyCubit(repository);
    await cubit.load();

    cubit.toggleProgramStatistic(false);
    expect(repository.lastSaved, isNull, reason: 'draft belum boleh dikirim');

    await cubit.save();

    expect(repository.lastSaved?.allowProgramStatistic, isFalse);
    expect(cubit.state.hasChanges, isFalse);
    expect(cubit.state.successMessage, isNotNull);
  });

  test('membatalkan perubahan mengembalikan nilai tersimpan', () async {
    final cubit = PrivacyCubit(_FakePrivacyRepository(openSetting));
    await cubit.load();

    cubit.selectShareLevel(ShareLevel.closed);
    cubit.discardChanges();

    expect(cubit.state.draft, cubit.state.saved);
    expect(cubit.state.hasChanges, isFalse);
  });
}
