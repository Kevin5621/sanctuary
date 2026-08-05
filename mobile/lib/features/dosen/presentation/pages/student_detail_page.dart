import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../../../core/widgets/privacy_states.dart';
import '../../data/repositories/mentor_repository.dart';
import '../../domain/entities/advisee.dart';
import '../cubit/student_detail_cubit.dart';

/// Halaman detail mahasiswa (L-BIM-04).
///
/// Isi halaman ditentukan `share_level` yang dipilih mahasiswa:
///   · Tertutup        → tidak ada indikator sama sekali, dinyatakan terus terang
///   · Ringkasan       → indikator kondisi, tanpa grafik tren
///   · Ringkasan+Tren  → indikator + grafik tren mingguan
///
/// Penyaringannya dilakukan SERVER; halaman ini hanya merender apa yang datang.
/// Tidak ada cabang di sini yang bisa "membuka" data yang tidak dikirim.
class StudentDetailPage extends StatelessWidget {
  const StudentDetailPage({
    super.key,
    required this.studentId,
    this.fallbackName,
  });

  final String studentId;

  /// Nama dari daftar, dipakai sebagai judul selama data detail dimuat.
  final String? fallbackName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          StudentDetailCubit(context.read<MentorRepository>(), studentId)..load(),
      child: _StudentDetailView(fallbackName: fallbackName),
    );
  }
}

class _StudentDetailView extends StatelessWidget {
  const _StudentDetailView({this.fallbackName});

  final String? fallbackName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        backgroundColor: AppColors.creamBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.midnight,
        title: BlocBuilder<StudentDetailCubit, StudentDetailState>(
          builder: (context, state) => Text(
            state.indicator?.fullName ?? fallbackName ?? 'Detail Mahasiswa',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.midnight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<StudentDetailCubit, StudentDetailState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const LoadingState(label: 'Memuat indikator…');
            }

            if (state.status == StudentDetailStatus.failure) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ErrorStateCard(
                  title: state.isForbidden
                      ? 'Tidak dapat diakses'
                      : 'Gagal memuat indikator',
                  message: state.errorMessage ??
                      'Periksa koneksi internet Anda lalu coba lagi.',
                  // Penolakan otorisasi tidak akan berubah dengan mencoba ulang,
                  // jadi tombol Coba Lagi sengaja tidak ditawarkan.
                  onRetry: state.isForbidden
                      ? null
                      : () => context.read<StudentDetailCubit>().load(),
                ),
              );
            }

            final indicator = state.indicator;
            if (indicator == null) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: EmptyStateCard(
                  title: 'Data tidak tersedia',
                  description: 'Tidak ada indikator yang dapat ditampilkan.',
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _IdentityCard(indicator: indicator),
                const SizedBox(height: AppSpacing.md),

                // ---- L-BIM-05: Tertutup dinyatakan jujur ----
                if (indicator.shareLevel.isClosed) ...[
                  ClosedShareCard(
                    studentName: indicator.fullName,
                    notice: indicator.privacyNotice,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _NoIndicatorExplanation(),
                ] else ...[
                  // ---- Status EWS ----
                  if (indicator.ews != null) ...[
                    _EwsCard(ews: indicator.ews!),
                    const SizedBox(height: AppSpacing.md),
                  ] else ...[
                    EarlyWarningOffCard(notice: indicator.privacyNotice),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // ---- Indikator kondisi (SUMMARY & SUMMARY_TREND) ----
                  if (indicator.summary != null) ...[
                    _SummaryCard(summary: indicator.summary!),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // ---- Grafik tren (hanya SUMMARY_TREND) ----
                  if (indicator.hasTrend)
                    _TrendCard(points: indicator.trend)
                  else
                    _TrendUnavailableCard(shareLevel: indicator.shareLevel),
                ],

                const SizedBox(height: AppSpacing.md),
                const _ContactGuidanceCard(),
                const SizedBox(height: AppSpacing.xl),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.indicator});

  final StudentIndicator indicator;

  @override
  Widget build(BuildContext context) {
    return StateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.lavenderBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.midnight, width: 1.8),
                ),
                child: Center(
                  child: Text(
                    indicator.fullName.trim().isEmpty
                        ? '?'
                        : indicator.fullName.trim()[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppColors.midnight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      indicator.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: AppColors.midnight,
                      ),
                    ),
                    if (indicator.studentNumber != null)
                      Text(
                        'NIM ${indicator.studentNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.warmTextSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              WavyBadge(
                text: 'Berbagi: ${indicator.shareLevelLabel}',
                color: AppColors.lavenderBg,
                borderColor: AppColors.lavenderDark,
                textColor: AppColors.lavenderDark,
              ),
              if (indicator.hasOpenContactRequest)
                const WavyBadge(
                  text: '✋ Minta dihubungi',
                  color: AppColors.moodAngerBg,
                  borderColor: AppColors.ewsIntervention,
                  textColor: AppColors.ewsIntervention,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EwsCard extends StatelessWidget {
  const _EwsCard({required this.ews});

  final EwsSummary ews;

  @override
  Widget build(BuildContext context) {
    // "Data belum cukup" bukan "Normal": bila titik datanya kurang, engine
    // memang tidak menyimpulkan apa pun dan kartu ini harus mengatakannya.
    if (!ews.isSufficient) {
      return StateCard(
        color: AppColors.creamAlt,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                EwsLevelBadge(level: ews.level, label: ews.levelLabel),
                const Spacer(),
                Text(
                  '${ews.dataPoints} check-in / ${ews.windowDays} hari',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.warmTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Titik data harian mahasiswa ini belum cukup untuk menyimpulkan '
              'tingkat perhatian. Ini bukan berarti kondisinya normal — '
              'melainkan belum dapat dinilai.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.warmTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final color = AppColors.ewsLevel(ews.level);

    return StateCard(
      borderColor: color,
      borderWidth: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Tingkat Perhatian',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.midnight,
                ),
              ),
              const Spacer(),
              EwsLevelBadge(level: ews.level, label: ews.levelLabel),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Skor ${ews.score} · dihitung dari ${ews.dataPoints} check-in '
            'dalam ${ews.windowDays} hari terakhir',
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.warmTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final indicator in ews.indicators)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    indicator.triggered
                        ? Icons.error_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 17,
                    color: indicator.triggered
                        ? AppColors.ewsRisk
                        : AppColors.ewsNormal,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          indicator.label,
                          style: TextStyle(
                            fontWeight: indicator.triggered
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                            color: AppColors.midnight,
                          ),
                        ),
                        // `detail` berisi angka hasil hitungan (mis. "2 malam
                        // dengan tidur < 5 jam") — bukan kutipan tulisan
                        // mahasiswa. Aman ditampilkan.
                        Text(
                          indicator.detail,
                          style: const TextStyle(
                            fontSize: 11.5,
                            height: 1.35,
                            color: AppColors.warmTextSecondary,
                          ),
                        ),
                      ],
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final ConditionSummary summary;

  @override
  Widget build(BuildContext context) {
    return StateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Indikator ${summary.windowDays} Hari Terakhir',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.midnight,
            ),
          ),
          Text(
            'Dihitung dari ${summary.checkinCount} check-in',
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.warmTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Rata-rata mood',
                  value: summary.avgMood.toStringAsFixed(1),
                  unit: '/ 5',
                  color: AppColors.moodHappinessBg,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricTile(
                  label: 'Rata-rata stres',
                  value: summary.avgStress.toStringAsFixed(1),
                  unit: '/ 5',
                  color: AppColors.moodAngerBg,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricTile(
                  label: 'Rata-rata tidur',
                  value: summary.avgSleepHours.toStringAsFixed(1),
                  unit: 'jam',
                  color: AppColors.moodSadnessBg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppColors.midnight,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.warmTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: AppColors.warmTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.points});

  final List<WeeklyTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    return StateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tren Mingguan',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.midnight,
            ),
          ),
          const Text(
            'Ditampilkan karena mahasiswa memilih tingkat berbagi Ringkasan + Tren',
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.warmTextSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 1,
                maxY: 5,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.cartoonBorder,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 26,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.warmTextSecondary,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _weekLabel(points[index].weekStart),
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: AppColors.warmTextSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  _line(points.map((p) => p.avgMood).toList(),
                      AppColors.moodHappiness),
                  _line(points.map((p) => p.avgStress).toList(),
                      AppColors.moodAnger),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: [
              _LegendDot(color: AppColors.moodHappiness, label: 'Mood'),
              SizedBox(width: AppSpacing.md),
              _LegendDot(color: AppColors.moodAnger, label: 'Stres'),
            ],
          ),
        ],
      ),
    );
  }

  static LineChartBarData _line(List<double> values, Color color) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
      ],
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 3.5,
          color: Colors.white,
          strokeWidth: 2,
          strokeColor: color,
        ),
      ),
    );
  }

  static String _weekLabel(String isoDate) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return '';
    return '${parsed.day}/${parsed.month}';
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.warmTextSecondary,
          ),
        ),
      ],
    );
  }
}

/// Menjelaskan mengapa grafik tren tidak ada — pilihan mahasiswa, bukan bug.
class _TrendUnavailableCard extends StatelessWidget {
  const _TrendUnavailableCard({required this.shareLevel});

  final ShareLevel shareLevel;

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      icon: Icons.show_chart_rounded,
      title: 'Grafik tren tidak dibagikan',
      description: shareLevel == ShareLevel.summary
          ? 'Mahasiswa memilih tingkat berbagi Ringkasan, sehingga grafik tren '
              'mingguan tidak dikirim kepada Anda.'
          : 'Belum ada titik tren yang dapat ditampilkan untuk periode ini.',
      footnote: 'Tingkat berbagi sepenuhnya ditentukan mahasiswa dan dapat '
          'diubah kapan saja dari perangkatnya.',
    );
  }
}

class _NoIndicatorExplanation extends StatelessWidget {
  const _NoIndicatorExplanation();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateCard(
      icon: Icons.visibility_off_outlined,
      title: 'Tidak ada indikator untuk ditampilkan',
      description:
          'Karena mahasiswa memilih tingkat berbagi Tertutup, tidak ada '
          'rata-rata mood, stres, tidur, maupun status perhatian yang dikirim '
          'kepada Anda.',
      footnote: 'Anda tetap dapat menyapanya seperti biasa — hanya saja tanpa '
          'informasi kondisi dari aplikasi ini.',
    );
  }
}

/// Menegaskan bahwa aplikasi bukan kanal pesan (PRD §3.3).
///
/// Kartu ini menggantikan tombol "Hubungi Mahasiswa" pada versi dummy
/// sebelumnya, yang menjanjikan kemampuan mengirim pesan — sesuatu yang memang
/// tidak ada dan tidak boleh ada di aplikasi ini.
class _ContactGuidanceCard extends StatelessWidget {
  const _ContactGuidanceCard();

  @override
  Widget build(BuildContext context) {
    return const StateCard(
      color: AppColors.moodFearBg,
      borderColor: AppColors.moodFear,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.forum_outlined, size: 20, color: AppColors.midnight),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menyapa dilakukan di luar aplikasi',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.midnight,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Sanctuary sengaja tidak menyediakan kanal pesan dosen–mahasiswa. '
                  'Gunakan jalur yang biasa Anda pakai, dan mulailah dari '
                  'menanyakan kabar — bukan dari angka di layar ini.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.warmTextSecondary,
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
