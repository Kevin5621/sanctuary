import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../domain/entities/daily_metric.dart';
import '../cubit/beranda_cubit.dart';
import '../cubit/mood_history_cubit.dart';
import '../widgets/checkin_sheet.dart';
import '../widgets/mood_visuals.dart';
import '../widgets/sebaran_emosi_card.dart';

/// Tab Mood — riwayat, dan tempat menutup celahnya.
///
/// Layar ini terutama untuk melihat pola: kalender bulanan, ritme mood, sebaran
/// emosi, dan pemicu tersering. Tanggal yang belum terisi bisa diketuk langsung
/// dari kalender untuk membuka form check-in tanggal itu — form yang sama
/// dengan yang dipakai Beranda, dengan batas mundur tanggal dari server.
///
/// MoodHistoryCubit-nya disediakan MahasiswaShellPage, bukan dibuat di sini:
/// Beranda ikut menyimpan check-in, dan kalender di layar ini harus melihat
/// hasilnya.
///
/// Sebaran Emosi (M-MOOD-04) di bagian bawah tab membaca hasil analisis JURNAL (D-3),
/// bukan daily-metrics, dan menggunakan SebaranEmosiCubit yang hidup di level shell.
class MoodTab extends StatelessWidget {
  const MoodTab({super.key});

  @override
  Widget build(BuildContext context) => const _MoodHistoryView();
}

class _MoodHistoryView extends StatelessWidget {
  const _MoodHistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        child: BlocConsumer<MoodHistoryCubit, MoodHistoryState>(
          listenWhen: (previous, current) =>
              previous.successMessage != current.successMessage ||
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            // Kegagalan memuat sudah punya layarnya sendiri; menumpuknya dengan
            // snackbar hanya membuat pesan yang sama muncul dua kali.
            if (state.status == MoodHistoryStatus.failure) return;

            final message = state.successMessage ?? state.errorMessage;
            if (message == null) return;

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
            context.read<MoodHistoryCubit>().clearMessages();
          },
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.midnight));
            }
            if (state.status == MoodHistoryStatus.failure) {
              return _ErrorView(message: state.errorMessage);
            }

            return RefreshIndicator(
              color: AppColors.midnight,
              backgroundColor: Colors.white,
              onRefresh: () => context.read<MoodHistoryCubit>().refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const _Header(),
                  const SizedBox(height: AppSpacing.lg),
                  if (state.isEmpty) ...[
                    _EmptyHistory(state: state),
                    const SizedBox(height: AppSpacing.lg),
                    _MonthlyCalendarCard(state: state),
                    const SizedBox(height: AppSpacing.lg),
                    const SebaranEmosiCard(),
                  ] else ...[
                    _MonthlyCalendarCard(state: state),
                    const SizedBox(height: AppSpacing.lg),
                    _PeriodSelector(state: state),
                    const SizedBox(height: AppSpacing.md),
                    if (!state.stats.isSufficient) ...[
                      _InsufficientCard(message: state.stats.message),
                      const SizedBox(height: AppSpacing.md),
                      const SebaranEmosiCard(),
                    ] else ...[
                      _SummaryRow(stats: state.stats),
                      const SizedBox(height: AppSpacing.md),
                      _MoodRhythmCard(stats: state.stats),
                      if (state.stats.topTriggers.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        _TriggerCard(stats: state.stats),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      const SebaranEmosiCard(),
                    ],
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Mood',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: AppColors.midnight,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Pola yang terbentuk dari check-in harianmu.',
          style: TextStyle(color: AppColors.warmTextSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

/// Belum ada satu pun check-in. Kalender tetap ditampilkan di bawah kartu ini
/// karena sekarang ia bisa diketuk — jalan memulai ada di layar ini juga,
/// bukan hanya di Beranda.
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.state});

  final MoodHistoryState state;

  @override
  Widget build(BuildContext context) {
    final canCheckIn = state.canCheckInOn(DateTime.now());

    return _Card(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.creamAlt,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.insights_rounded, size: 34, color: AppColors.warmTextMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Belum ada riwayat',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.midnight,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Riwayat terbentuk dari check-in harian. Mulai dari hari ini, atau '
            'ketuk tanggal mana pun di kalender di bawah.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.warmTextSecondary, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: canCheckIn ? () => _openCheckin(context, date: DateTime.now()) : null,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Check-in hari ini',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.midnight,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Kalender bulanan
// ------------------------------------------------------------------

/// Membuka form check-in untuk [date]. Bila tanggal itu sudah terisi, form
/// terbuka dalam mode ubah — server melakukan upsert per tanggal, jadi mengisi
/// ulang berarti memperbaiki, bukan menambah baris kedua.
///
/// Tanggal di luar batas ditolak di sini dengan alasan yang jelas, bukan
/// dibiarkan sampai server menolaknya setelah mahasiswa mengisi seluruh form.
Future<void> _openCheckin(
  BuildContext context, {
  required DateTime date,
  DailyMetric? existing,
}) async {
  final cubit = context.read<MoodHistoryCubit>();
  final beranda = context.read<BerandaCubit>();
  final state = cubit.state;

  if (!state.canCheckInOn(date)) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(_blockedReason(state, date))));
    return;
  }

  final saved = await CheckinSheet.show(
    context,
    options: state.options,
    existing: existing,
    initialDate: date,
    onSubmit: ({
      required moodScore,
      required stressLevel,
      required sleepHours,
      required academicTrigger,
      required date,
    }) =>
        cubit.saveCheckin(
      moodScore: moodScore,
      stressLevel: stressLevel,
      sleepHours: sleepHours,
      academicTrigger: academicTrigger,
      date: date,
    ),
  );

  // Beranda memegang ringkasan mingguan dan status "sudah check-in hari ini".
  // Tanpa penyegaran ini ia tetap mengaku belum terisi sampai aplikasi dibuka
  // ulang, padahal mahasiswa baru saja mengisinya di layar ini.
  if (saved) await beranda.refresh();
}

String _blockedReason(MoodHistoryState state, DateTime date) {
  if (!state.options.isLoaded) {
    return 'Pilihan check-in belum termuat. Tarik layar ke bawah untuk memuat ulang.';
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (DateTime(date.year, date.month, date.day).isAfter(today)) {
    return 'Hari itu belum tiba.';
  }

  return 'Check-in hanya bisa diisi mundur maksimal '
      '${state.options.maxBackdateDays} hari.';
}

class _MonthlyCalendarCard extends StatelessWidget {
  const _MonthlyCalendarCard({required this.state});

  final MoodHistoryState state;

  static const _weekdayLabels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

  @override
  Widget build(BuildContext context) {
    final monthly = state.monthly;
    final firstDate = monthly.firstDate;
    if (firstDate == null) return const SizedBox.shrink();

    // Kolom pertama kalender adalah Senin (weekday 1 di Dart).
    final leadingBlanks = firstDate.weekday - 1;
    final cellCount = leadingBlanks + monthly.daysInMonth;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: state.isMonthLoading
                    ? null
                    : () => context.read<MoodHistoryCubit>().changeMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.midnight),
              ),
              Expanded(
                child: Text(
                  monthly.monthLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.midnight,
                  ),
                ),
              ),
              IconButton(
                onPressed: (!monthly.hasNextMonth || state.isMonthLoading)
                    ? null
                    : () => context.read<MoodHistoryCubit>().changeMonth(1),
                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.midnight),
              ),
            ],
          ),
          Text(
            '${monthly.checkinCount} hari terisi'
            '${monthly.checkinCount > 0 ? ' · rata-rata mood ${monthly.avgMood.toStringAsFixed(1)}/5' : ''}',
            style: const TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
          ),
          if (state.options.isLoaded) ...[
            const SizedBox(height: 2),
            Text(
              'Ketuk tanggal untuk mengisi atau mengubah check-in '
              '(maksimal ${state.options.maxBackdateDays} hari ke belakang).',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.warmTextMuted,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final label in _weekdayLabels)
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warmTextSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (state.isMonthLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator(color: AppColors.midnight)),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: cellCount,
              itemBuilder: (context, index) {
                if (index < leadingBlanks) return const SizedBox.shrink();

                final day = index - leadingBlanks + 1;
                final date = DateTime(firstDate.year, firstDate.month, day);
                return _DayCell(
                  date: date,
                  metric: monthly.forDay(day),
                  isCheckinAllowed: state.canCheckInOn(date),
                );
              },
            ),
          const SizedBox(height: AppSpacing.sm),
          const _MoodLegend(),
        ],
      ),
    );
  }
}

/// Satu sel kalender.
///
/// Sel yang masih boleh diisi bisa diketuk: yang kosong membuka check-in baru,
/// yang terisi membuka mode ubah. Sel di luar batas mundur tetap ditampilkan
/// apa adanya — riwayat lama tidak boleh terlihat seperti masih bisa diubah.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isCheckinAllowed,
    this.metric,
  });

  final DateTime date;
  final bool isCheckinAllowed;
  final DailyMetric? metric;

  @override
  Widget build(BuildContext context) {
    final filled = metric != null;
    final day = date.day;
    final radius = BorderRadius.circular(AppSpacing.radiusSm / 2);

    final String tooltip;
    if (filled) {
      tooltip = '$day: ${metric!.moodLabel}'
          '${isCheckinAllowed ? ' · ketuk untuk mengubah' : ''}';
    } else {
      tooltip = isCheckinAllowed ? '$day: ketuk untuk check-in' : '$day: belum check-in';
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? MoodVisuals.backgroundForScore(metric!.moodScore) : AppColors.creamAlt,
        borderRadius: radius,
        child: InkWell(
          // Sel di luar batas tetap bisa diketuk — bukan untuk membuka form,
          // melainkan untuk menjawab "kenapa tidak bisa?". Sel mati yang diam
          // saja membuat pengguna mengetuk berulang tanpa pernah tahu sebabnya.
          onTap: () => _openCheckin(context, date: date, existing: metric),
          borderRadius: radius,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: filled
                    ? MoodVisuals.colorForScore(metric!.moodScore)
                    : (isCheckinAllowed ? AppColors.midnight : AppColors.cartoonBorder),
                width: filled ? 1.5 : 1,
              ),
            ),
            child: filled
                ? ClipRRect(
                    borderRadius: radius,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: CartoonMoodBlob(
                              mood: MoodVisuals.forScore(metric!.moodScore),
                              size: 32,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 1,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '$day',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.midnight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCheckinAllowed ? FontWeight.w700 : FontWeight.w400,
                          color: isCheckinAllowed
                              ? AppColors.midnight
                              : AppColors.warmTextMuted,
                        ),
                      ),
                      if (isCheckinAllowed)
                        const Icon(Icons.add_rounded, size: 12, color: AppColors.midnight),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _MoodLegend extends StatelessWidget {
  const _MoodLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (var score = 1; score <= 5; score++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: MoodVisuals.colorForScore(score),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$score',
                style: const TextStyle(fontSize: 11, color: AppColors.warmTextSecondary),
              ),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.creamAlt,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cartoonBorder),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'belum diisi',
              style: TextStyle(fontSize: 11, color: AppColors.warmTextSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------
// Statistik periode
// ------------------------------------------------------------------

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.state});

  final MoodHistoryState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Periode',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.midnight,
          ),
        ),
        const Spacer(),
        for (final period in MoodHistoryCubit.availablePeriods)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: GestureDetector(
              onTap: state.isStatsLoading
                  ? null
                  : () => context.read<MoodHistoryCubit>().changePeriod(period),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: state.periodDays == period ? AppColors.midnight : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  border: Border.all(
                    color: state.periodDays == period
                        ? AppColors.midnight
                        : AppColors.cartoonBorder,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  '$period hari',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: state.periodDays == period ? Colors.white : AppColors.midnight,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Server menilai data belum cukup untuk membentuk pola.
class _InsufficientCard extends StatelessWidget {
  const _InsufficientCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          const Icon(Icons.hourglass_bottom_rounded, color: AppColors.ewsInsufficient),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data belum cukup',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.midnight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.isEmpty
                      ? 'Lanjutkan check-in beberapa hari lagi agar polanya terbaca.'
                      : message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.warmTextSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.stats});

  final MoodStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Rata-rata mood',
            value: stats.avgMood.toStringAsFixed(1),
            unit: '/5',
            color: AppColors.moodHappinessBg,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            label: 'Rata-rata tidur',
            value: stats.avgSleepHours.toStringAsFixed(1),
            unit: ' jam',
            color: AppColors.moodFearBg,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            label: 'Rangkaian',
            value: '${stats.currentStreak}',
            unit: ' hari',
            color: AppColors.moodDisgustBg,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColors.midnight,
              ),
              children: [
                TextSpan(
                  text: unit,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.warmTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.warmTextSecondary),
          ),
        ],
      ),
    );
  }
}

class _MoodRhythmCard extends StatelessWidget {
  const _MoodRhythmCard({required this.stats});

  final MoodStats stats;

  @override
  Widget build(BuildContext context) {
    final points = stats.points;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ritme Mood',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.midnight,
            ),
          ),
          Text(
            '${stats.checkinCount} check-in dalam ${stats.periodDays} hari terakhir',
            style: const TextStyle(color: AppColors.warmTextSecondary, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 1,
                maxY: 5,
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 24, interval: 1),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (points.length / 4).clamp(1, 60).toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        final date = points[index].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < points.length; i++)
                        FlSpot(i.toDouble(), points[i].moodScore.toDouble()),
                    ],
                    isCurved: true,
                    color: AppColors.midnight,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: points.length <= 31),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.moodHappinessBg.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TriggerCard extends StatelessWidget {
  const _TriggerCard({required this.stats});

  final MoodStats stats;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pemicu Tersering',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.midnight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final trigger in stats.topTriggers)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.lavenderBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(color: AppColors.cartoonBorder),
                  ),
                  child: Text(
                    '${trigger.label} · ${trigger.count}x',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.midnight,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.5),
      ),
      child: child,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.ewsRisk),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Gagal memuat riwayat',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.midnight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message ?? 'Periksa koneksi internetmu lalu coba lagi.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.warmTextSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => context.read<MoodHistoryCubit>().load(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.midnight,
                side: const BorderSide(color: AppColors.midnight, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
              child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
