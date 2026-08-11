import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary/features/mahasiswa/domain/entities/daily_metric.dart';
import 'package:sanctuary/features/mahasiswa/presentation/cubit/mood_history_cubit.dart';

import 'support/fake_repositories.dart';

MonthlyMood monthOf(String month, {int checkinCount = 5, bool hasNextMonth = true}) => MonthlyMood(
      month: month,
      monthLabel: 'Agustus 2026',
      firstDate: DateTime(2026, 8),
      daysInMonth: 31,
      days: [
        for (var day = 1; day <= checkinCount; day++)
          DailyMetric(
            date: DateTime(2026, 8, day),
            moodScore: 4,
            stressLevel: 2,
            sleepHours: 7,
          ),
      ],
      checkinCount: checkinCount,
      avgMood: 4,
      hasNextMonth: hasNextMonth,
    );

MoodStats statsWith({required bool sufficient, int checkinCount = 10}) => MoodStats(
      periodDays: 30,
      points: [
        for (var day = 1; day <= checkinCount; day++)
          MoodTrendPoint(
            date: DateTime(2026, 8, day),
            moodScore: 4,
            stressLevel: 2,
            sleepHours: 7,
          ),
      ],
      topTriggers: const [TriggerShare(trigger: 'TUGAS', label: 'Tugas kuliah', count: 4)],
      checkinCount: checkinCount,
      avgMood: sufficient ? 4 : 0,
      avgStress: sufficient ? 2 : 0,
      avgSleepHours: sufficient ? 7 : 0,
      currentStreak: sufficient ? 5 : 0,
      longestStreak: sufficient ? 8 : 0,
      isSufficient: sufficient,
      message: sufficient ? '' : 'Data belum cukup untuk menampilkan pola.',
    );

void main() {
  test('memuat kalender bulan berjalan dan statistik 30 hari', () async {
    final repository = FakeDailyMetricRepository(
      monthly: monthOf('2026-08'),
      stats: statsWith(sufficient: true),
    );
    final cubit = MoodHistoryCubit(repository);

    await cubit.load();

    expect(cubit.state.status, MoodHistoryStatus.ready);
    expect(cubit.state.month, '2026-08');
    expect(cubit.state.periodDays, 30);
    expect(cubit.state.stats.isSufficient, isTrue);
    expect(repository.lastRequestedPeriod, 30);
  });

  test('tanpa check-in sama sekali ditandai isEmpty', () async {
    final cubit = MoodHistoryCubit(
      FakeDailyMetricRepository(
        monthly: monthOf('2026-08', checkinCount: 0),
        stats: statsWith(sufficient: false, checkinCount: 0),
      ),
    );

    await cubit.load();

    expect(cubit.state.isEmpty, isTrue);
  });

  // Server yang memutuskan apakah datanya cukup. Klien hanya mengikuti,
  // supaya ambangnya tidak berbeda antara aplikasi dan mesin EWS.
  test('state tidak cukup dibawa apa adanya dari server', () async {
    final cubit = MoodHistoryCubit(
      FakeDailyMetricRepository(
        monthly: monthOf('2026-08', checkinCount: 2),
        stats: statsWith(sufficient: false, checkinCount: 2),
      ),
    );

    await cubit.load();

    expect(cubit.state.stats.isSufficient, isFalse);
    expect(cubit.state.stats.message, isNotEmpty);
    expect(cubit.state.stats.avgMood, 0, reason: 'rata-rata tidak dikirim saat belum cukup');
  });

  test('mundur satu bulan meminta bulan sebelumnya', () async {
    final repository = FakeDailyMetricRepository(monthly: monthOf('2026-08'));
    final cubit = MoodHistoryCubit(repository);
    await cubit.load();

    repository.monthly = monthOf('2026-07');
    await cubit.changeMonth(-1);

    expect(repository.lastRequestedMonth, '2026-07');
    expect(cubit.state.isMonthLoading, isFalse);
  });

  test('maju ke bulan depan ditolak saat hasNextMonth false', () async {
    final repository = FakeDailyMetricRepository(
      monthly: monthOf('2026-08', hasNextMonth: false),
    );
    final cubit = MoodHistoryCubit(repository);
    await cubit.load();

    repository.lastRequestedMonth = null;
    await cubit.changeMonth(1);

    expect(repository.lastRequestedMonth, isNull, reason: 'bulan depan pasti kosong');
  });

  test('mengubah periode memuat ulang statistik saja', () async {
    final repository = FakeDailyMetricRepository(
      monthly: monthOf('2026-08'),
      stats: statsWith(sufficient: true),
    );
    final cubit = MoodHistoryCubit(repository);
    await cubit.load();

    repository.lastRequestedMonth = null;
    await cubit.changePeriod(90);

    expect(cubit.state.periodDays, 90);
    expect(repository.lastRequestedPeriod, 90);
    expect(repository.lastRequestedMonth, isNull, reason: 'kalender tidak perlu dimuat ulang');
  });

  test('memilih periode yang sedang aktif tidak memanggil ulang API', () async {
    final repository = FakeDailyMetricRepository(monthly: monthOf('2026-08'));
    final cubit = MoodHistoryCubit(repository);
    await cubit.load();

    repository.lastRequestedPeriod = null;
    await cubit.changePeriod(30);

    expect(repository.lastRequestedPeriod, isNull);
  });

  // ------------------------------------------------------------------
  // Check-in dari kalender
  // ------------------------------------------------------------------

  test('check-in dari sel kalender dikirim untuk tanggal yang diketuk', () async {
    final repository = FakeDailyMetricRepository(
      monthly: monthOf('2026-08'),
      stats: statsWith(sufficient: true),
    );
    final cubit = MoodHistoryCubit(repository);
    await cubit.load();

    final tapped = DateTime.now().subtract(const Duration(days: 3));
    repository.lastRequestedMonth = null;
    repository.lastRequestedPeriod = null;

    final saved = await cubit.saveCheckin(
      moodScore: 2,
      stressLevel: 4,
      sleepHours: 5.5,
      academicTrigger: 'Deadline tugas',
      date: tapped,
    );

    expect(saved, isTrue);
    expect(cubit.state.isSaving, isFalse);
    expect(cubit.state.successMessage, isNotNull);

    // Nilai dikirim persis seperti yang diisi mahasiswa — tidak ada nilai
    // bawaan yang dikarang klien, karena angkanya ikut dihitung EWS.
    expect(repository.lastSaved, {
      'mood_score': 2,
      'stress_level': 4,
      'sleep_hours': 5.5,
      'academic_trigger': 'Deadline tugas',
      'metric_date': '${tapped.year.toString().padLeft(4, '0')}-'
          '${tapped.month.toString().padLeft(2, '0')}-'
          '${tapped.day.toString().padLeft(2, '0')}',
    });

    // Satu check-in mengubah kalender sekaligus statistik; keduanya dimuat ulang.
    expect(repository.lastRequestedMonth, '2026-08');
    expect(repository.lastRequestedPeriod, 30);
  });

  test('tanggal di masa depan dan di luar batas mundur tidak bisa diisi', () async {
    final cubit = MoodHistoryCubit(
      FakeDailyMetricRepository(monthly: monthOf('2026-08')),
    );
    await cubit.load();

    final today = DateTime.now();
    expect(cubit.state.canCheckInOn(today), isTrue);
    expect(cubit.state.canCheckInOn(today.subtract(const Duration(days: 30))), isTrue);
    expect(cubit.state.canCheckInOn(today.add(const Duration(days: 1))), isFalse);
    expect(
      cubit.state.canCheckInOn(today.subtract(const Duration(days: 31))),
      isFalse,
      reason: 'batas mundur 30 hari datang dari server, bukan ditebak klien',
    );
  });

  // Batasnya milik server. Selama pilihan belum termuat klien tidak boleh
  // menebak skala maupun batas tanggalnya sendiri.
  test('tanpa pilihan dari server tidak ada tanggal yang bisa diisi', () async {
    final cubit = MoodHistoryCubit(
      FakeDailyMetricRepository(monthly: monthOf('2026-08'), failOptions: true),
    );
    await cubit.load();

    expect(cubit.state.status, MoodHistoryStatus.ready, reason: 'riwayat tetap tampil');
    expect(cubit.state.canCheckInOn(DateTime.now()), isFalse);
  });

  test('check-in yang gagal tidak menghapus riwayat yang sudah tampil', () async {
    final repository = FakeDailyMetricRepository(
      monthly: monthOf('2026-08'),
      stats: statsWith(sufficient: true),
    );
    final cubit = MoodHistoryCubit(repository);
    await cubit.load();

    repository.failSave = true;
    final saved = await cubit.saveCheckin(
      moodScore: 3,
      stressLevel: 3,
      sleepHours: 7,
      date: DateTime.now(),
    );

    expect(saved, isFalse);
    expect(cubit.state.isSaving, isFalse);
    expect(cubit.state.errorMessage, isNotNull);
    expect(cubit.state.status, MoodHistoryStatus.ready);
    expect(cubit.state.monthly.checkinCount, 5);
  });
}
