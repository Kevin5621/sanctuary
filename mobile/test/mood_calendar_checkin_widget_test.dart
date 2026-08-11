import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary/core/widgets/cartoon_mood_blob.dart';
import 'package:sanctuary/features/mahasiswa/domain/entities/daily_metric.dart';
import 'package:sanctuary/features/mahasiswa/presentation/cubit/beranda_cubit.dart';
import 'package:sanctuary/features/mahasiswa/presentation/cubit/mood_history_cubit.dart';
import 'package:sanctuary/features/mahasiswa/presentation/cubit/sebaran_emosi_cubit.dart';
import 'package:sanctuary/features/mahasiswa/presentation/pages/mood_tab.dart';

import 'support/fake_repositories.dart';

/// Kalender tab Mood bukan hanya bacaan: tanggal yang belum terisi harus bisa
/// diketuk untuk membuka check-in tanggal itu. [mood_history_cubit_test.dart]
/// menjaga aturannya; file ini menjaga bahwa ketukannya benar-benar sampai.

MonthlyMood currentMonth({List<DailyMetric> days = const []}) {
  final now = DateTime.now();
  return MonthlyMood(
    month: '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}',
    monthLabel: 'Bulan ini',
    firstDate: DateTime(now.year, now.month),
    daysInMonth: DateTime(now.year, now.month + 1, 0).day,
    days: days,
    checkinCount: days.length,
    avgMood: 0,
    hasNextMonth: false,
  );
}

Widget wrap(FakeDailyMetricRepository metrics) {
  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MoodHistoryCubit(metrics)..load()),
        BlocProvider(
          create: (_) => BerandaCubit(
            metrics: metrics,
            contactRequests: FakeContactRequestRepository(),
          ),
        ),
        BlocProvider(create: (_) => SebaranEmosiCubit(FakeJournalRepository())..load()),
      ],
      child: const MoodTab(),
    ),
  );
}

/// Layar uji dibuat tinggi agar seluruh kalender masuk tanpa perlu digulir —
/// yang diuji di sini ketukannya, bukan pengguliran.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('mengetuk tanggal kosong membuka check-in untuk tanggal itu', (tester) async {
    useTallScreen(tester);
    final metrics = FakeDailyMetricRepository(monthly: currentMonth());
    final today = DateTime.now();

    await tester.pumpWidget(wrap(metrics));
    await tester.pumpAndSettle();

    final cell = find.byTooltip('${today.day}: ketuk untuk check-in');
    expect(cell, findsOneWidget);

    await tester.tap(cell);
    await tester.pumpAndSettle();

    expect(find.text('Simpan check-in'), findsOneWidget);

    // Perasaan hanya ditanya sekali, lewat skala mood. Tidak ada lagi pemilih
    // emosi terpisah yang menanyakan hal yang sama dengan cara lain.
    expect(find.text('Emosi yang paling terasa'), findsNothing);
    expect(find.text('Bagaimana perasaanmu?'), findsOneWidget);

    await tester.tap(find.text('Simpan check-in'));
    await tester.pumpAndSettle();

    expect(
      metrics.lastSaved?['metric_date'],
      '${today.year.toString().padLeft(4, '0')}-'
      '${today.month.toString().padLeft(2, '0')}-'
      '${today.day.toString().padLeft(2, '0')}',
    );
    expect(find.text('Simpan check-in'), findsNothing, reason: 'sheet tertutup setelah tersimpan');
    expect(find.text('Check-in tersimpan.'), findsOneWidget);
  });

  // Batas mundur milik server. Tanggal di luar batas tidak boleh membuka form
  // yang isiannya sudah pasti ditolak setelah mahasiswa mengisinya — tapi
  // ketukannya tetap dijawab, bukan didiamkan.
  testWidgets('tanggal di masa depan menjelaskan sebabnya, bukan membuka form', (tester) async {
    useTallScreen(tester);
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    if (now.day == daysInMonth) return; // tidak ada tanggal depan di bulan ini

    final metrics = FakeDailyMetricRepository(monthly: currentMonth());

    await tester.pumpWidget(wrap(metrics));
    await tester.pumpAndSettle();

    final future = find.byTooltip('${now.day + 1}: belum check-in');
    expect(future, findsOneWidget, reason: 'sel masa depan tidak menawarkan ketukan');

    await tester.tap(future);
    await tester.pumpAndSettle();

    expect(find.text('Simpan check-in'), findsNothing);
    expect(find.text('Hari itu belum tiba.'), findsOneWidget);
    expect(metrics.lastSaved, isNull);
  });

  // Wajah pada kalender mengikuti "bagaimana perasaanmu" (skala 1..5) — satu-
  // satunya pertanyaan tentang perasaan yang tersisa pada check-in.
  testWidgets('wajah pada sel kalender mengikuti skor mood', (tester) async {
    useTallScreen(tester);
    final today = DateTime.now();

    final metrics = FakeDailyMetricRepository(
      monthly: currentMonth(days: [
        DailyMetric(
          date: today,
          moodScore: 1,
          moodLabel: 'Sangat buruk',
          stressLevel: 4,
          sleepHours: 5,
        ),
      ]),
    );

    await tester.pumpWidget(wrap(metrics));
    await tester.pumpAndSettle();

    final cell = find.byTooltip('${today.day}: Sangat buruk · ketuk untuk mengubah');
    expect(cell, findsOneWidget);

    final blob = tester.widget<CartoonMoodBlob>(
      find.descendant(of: cell, matching: find.byType(CartoonMoodBlob)),
    );
    expect(blob.mood, MoodType.sadness, reason: 'mood 1 digambar sebagai wajah paling murung');
  });
}
