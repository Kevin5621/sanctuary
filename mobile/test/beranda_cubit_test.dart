import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary/features/mahasiswa/domain/entities/daily_metric.dart';
import 'package:sanctuary/features/mahasiswa/presentation/cubit/beranda_cubit.dart';

import 'support/fake_repositories.dart';

BerandaCubit buildCubit({
  FakeDailyMetricRepository? metrics,
  FakeContactRequestRepository? contacts,
}) {
  return BerandaCubit(
    metrics: metrics ?? FakeDailyMetricRepository(),
    contactRequests: contacts ?? FakeContactRequestRepository(),
  );
}

WeeklyMoodSummary summaryWithToday() => WeeklyMoodSummary(
      weekStart: DateTime(2026, 8, 3),
      weekEnd: DateTime(2026, 8, 9),
      today: DailyMetric(
        date: DateTime.now(),
        moodScore: 4,
        moodLabel: 'Baik',
        stressLevel: 2,
        stressLabel: 'Santai',
        sleepHours: 7.5,
      ),
      days: [
        DailyMetric(date: DateTime.now(), moodScore: 4, stressLevel: 2, sleepHours: 7.5),
      ],
      checkinCount: 1,
      currentStreak: 3,
    );

void main() {
  test('memuat ringkasan, pilihan check-in, dan status minta dihubungi', () async {
    final cubit = buildCubit(
      metrics: FakeDailyMetricRepository(summary: summaryWithToday()),
    );

    await cubit.load();

    expect(cubit.state.status, BerandaStatus.ready);
    expect(cubit.state.hasCheckedInToday, isTrue);
    expect(cubit.state.summary.currentStreak, 3);
    expect(cubit.state.canCheckIn, isTrue, reason: 'pilihan check-in harus termuat');
    expect(cubit.state.contact.advisorName, isNotEmpty);
  });

  test('pengguna baru ditandai isFirstTime, bukan sekadar kalender kosong', () async {
    final cubit = buildCubit();

    await cubit.load();

    expect(cubit.state.isFirstTime, isTrue);
    expect(cubit.state.hasCheckedInToday, isFalse);
  });

  // Kegagalan memuat data pelengkap tidak boleh menjatuhkan seluruh Beranda —
  // ringkasan mood tetap yang paling penting untuk tampil.
  test('gagal memuat pilihan check-in tidak membuat Beranda gagal', () async {
    final metrics = FakeDailyMetricRepository(failOptions: true);
    final cubit = buildCubit(metrics: metrics);

    await cubit.load();

    expect(cubit.state.status, BerandaStatus.ready);
    expect(cubit.state.canCheckIn, isFalse, reason: 'form tidak boleh dibuka tanpa pilihan server');
  });

  test('gagal memuat ringkasan menghasilkan status failure', () async {
    final cubit = buildCubit(metrics: FakeDailyMetricRepository(failWeekly: true));

    await cubit.load();

    expect(cubit.state.status, BerandaStatus.failure);
    expect(cubit.state.errorMessage, isNotNull);
  });

  // Ini inti pemindahan check-in ke Beranda: seluruh nilai harus datang dari
  // yang benar-benar diisi mahasiswa. Stres dan jam tidur yang dikarang klien
  // akan ikut dihitung indikator peringatan dini.
  test('check-in mengirim persis nilai yang diisi, tanpa nilai karangan', () async {
    final metrics = FakeDailyMetricRepository();
    final cubit = buildCubit(metrics: metrics);
    await cubit.load();

    final saved = await cubit.saveCheckin(
      moodScore: 2,
      stressLevel: 5,
      sleepHours: 4.5,
      emotionLabel: 'ANXIOUS',
      academicTrigger: 'SKRIPSI',
      date: DateTime(2026, 8, 4),
    );

    expect(saved, isTrue);
    expect(metrics.lastSaved, {
      'mood_score': 2,
      'stress_level': 5,
      'sleep_hours': 4.5,
      'emotion_label': 'ANXIOUS',
      'academic_trigger': 'SKRIPSI',
      'metric_date': '2026-08-04',
    });
  });

  test('check-in memuat ulang ringkasan dan memberi pesan sukses', () async {
    final metrics = FakeDailyMetricRepository();
    final cubit = buildCubit(metrics: metrics);
    await cubit.load();

    metrics.summary = summaryWithToday();
    await cubit.saveCheckin(moodScore: 4, stressLevel: 2, sleepHours: 7.5);

    expect(cubit.state.hasCheckedInToday, isTrue);
    expect(cubit.state.successMessage, isNotNull);
    expect(cubit.state.isSaving, isFalse);
  });

  test('minta dihubungi mengubah status menjadi terbuka', () async {
    final contacts = FakeContactRequestRepository();
    final cubit = buildCubit(contacts: contacts);
    await cubit.load();

    final requested = await cubit.requestContact(note: 'Ingin bicara soal skripsi.');

    expect(requested, isTrue);
    expect(contacts.lastNote, 'Ingin bicara soal skripsi.');
    expect(cubit.state.contact.hasOpenRequest, isTrue);
    expect(cubit.state.contact.canRequest, isFalse);
  });

  test('membatalkan permintaan mengembalikan tombol ke keadaan semula', () async {
    final contacts = FakeContactRequestRepository(
      state: FakeContactRequestRepository.withAdvisor(hasOpenRequest: true),
    );
    final cubit = buildCubit(contacts: contacts);
    await cubit.load();

    await cubit.cancelContactRequest();

    expect(contacts.cancelled, isTrue);
    expect(cubit.state.contact.hasOpenRequest, isFalse);
    expect(cubit.state.contact.canRequest, isTrue);
  });

  test('formatApiDate memakai format YYYY-MM-DD', () {
    expect(formatApiDate(DateTime(2026, 1, 9)), '2026-01-09');
  });
}
