import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary/features/mahasiswa/presentation/cubit/jurnal_cubit.dart';

import 'support/fake_repositories.dart';

void main() {
  test('memuat daftar catatan', () async {
    final repository = FakeJournalRepository(
      entries: [FakeJournalRepository.item('j1'), FakeJournalRepository.item('j2')],
    );
    final cubit = JurnalCubit(repository);

    await cubit.load();

    expect(cubit.state.status, JurnalStatus.ready);
    expect(cubit.state.entries, hasLength(2));
    expect(cubit.state.isEmpty, isFalse);
  });

  test('daftar kosong ditandai isEmpty', () async {
    final cubit = JurnalCubit(FakeJournalRepository());

    await cubit.load();

    expect(cubit.state.isEmpty, isTrue);
  });

  test('gagal memuat menghasilkan status failure', () async {
    final cubit = JurnalCubit(FakeJournalRepository(failList: true));

    await cubit.load();

    expect(cubit.state.status, JurnalStatus.failure);
    expect(cubit.state.errorMessage, isNotNull);
  });

  test('catatan kosong ditolak tanpa memanggil API', () async {
    final repository = FakeJournalRepository();
    final cubit = JurnalCubit(repository);
    await cubit.load();

    final saved = await cubit.submit(content: '   ');

    expect(saved, isFalse);
    expect(repository.lastContent, isNull);
    expect(cubit.state.errorMessage, isNotNull);
  });

  test('menyimpan dengan analisis mengembalikan hasil analisis', () async {
    final repository = FakeJournalRepository();
    final cubit = JurnalCubit(repository);
    await cubit.load();

    final saved = await cubit.submit(
      content: '  Aku cemas menghadapi ujian.  ',
      date: DateTime(2026, 8, 4),
    );

    expect(saved, isTrue);
    expect(repository.lastContent, 'Aku cemas menghadapi ujian.',
        reason: 'spasi berlebih dipangkas sebelum dikirim');
    expect(repository.lastJournalDate, '2026-08-04');
    expect(repository.lastAnalyzeNow, isTrue);
    expect(cubit.state.analysis?.emotionLabelText, 'Cemas');
    expect(cubit.state.successMessage, isNotNull);
  });

  // Analisis adalah pilihan pemiliknya, bukan syarat untuk boleh bercerita.
  test('menyimpan tanpa analisis tidak menghasilkan kartu analisis', () async {
    final repository = FakeJournalRepository();
    final cubit = JurnalCubit(repository);
    await cubit.load();

    await cubit.submit(content: 'Hanya ingin menulis.', analyzeNow: false);

    expect(repository.lastAnalyzeNow, isFalse);
    expect(cubit.state.analysis, isNull);
  });

  test('penandaan krisis memunculkan kartu bantuan', () async {
    final repository = FakeJournalRepository()
      ..nextAnalysis = FakeJournalRepository.analysis(crisis: true);
    final cubit = JurnalCubit(repository);
    await cubit.load();

    await cubit.submit(content: 'Rasanya berat sekali.');

    expect(cubit.state.showCrisisCard, isTrue);
    expect(cubit.state.analysis?.crisisMessage, isNotEmpty,
        reason: 'penandaan krisis tanpa pesan bantuan tidak berguna');
  });

  test('menutup kartu analisis tidak menghapus catatannya', () async {
    final repository = FakeJournalRepository(entries: [FakeJournalRepository.item('j1')]);
    final cubit = JurnalCubit(repository);
    await cubit.load();
    await cubit.submit(content: 'Aku cemas.');

    cubit.dismissAnalysis();

    expect(cubit.state.analysis, isNull);
    expect(cubit.state.entries, isNotEmpty);
  });

  test('menganalisis catatan lama memperbarui daftar', () async {
    final repository = FakeJournalRepository(
      entries: [FakeJournalRepository.item('j1', analyzed: false)],
    );
    final cubit = JurnalCubit(repository);
    await cubit.load();

    await cubit.analyzeExisting('j1');

    expect(repository.analyzedId, 'j1');
    expect(cubit.state.analysis, isNotNull);
    expect(cubit.state.analyzingId, isNull, reason: 'penanda proses harus dibersihkan');
  });

  test('menghapus catatan mengeluarkannya dari daftar', () async {
    final repository = FakeJournalRepository(
      entries: [FakeJournalRepository.item('j1'), FakeJournalRepository.item('j2')],
    );
    final cubit = JurnalCubit(repository);
    await cubit.load();

    await cubit.delete('j1');

    expect(repository.deletedId, 'j1');
    expect(cubit.state.entries.map((entry) => entry.id), ['j2']);
    expect(cubit.state.successMessage, isNotNull);
  });

  test('muat lebih banyak menambahkan halaman berikutnya', () async {
    final repository = FakeJournalRepository(
      entries: [FakeJournalRepository.item('j1')],
      hasNextPage: true,
    );
    final cubit = JurnalCubit(repository);
    await cubit.load();

    repository.entries = [FakeJournalRepository.item('j2')];
    repository.hasNextPage = false;
    await cubit.loadMore();

    expect(cubit.state.entries.map((entry) => entry.id), ['j1', 'j2']);
    expect(cubit.state.hasNextPage, isFalse);
  });

  test('muat lebih banyak diabaikan bila tidak ada halaman berikutnya', () async {
    final repository = FakeJournalRepository(entries: [FakeJournalRepository.item('j1')]);
    final cubit = JurnalCubit(repository);
    await cubit.load();

    await cubit.loadMore();

    expect(cubit.state.entries, hasLength(1));
  });
}
