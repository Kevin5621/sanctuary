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
      emotionDistribution: const [
        EmotionShare(
          emotion: 'CALM',
          label: 'Tenang',
          count: 6,
          percentage: 60,
          isNegative: false,
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
}
