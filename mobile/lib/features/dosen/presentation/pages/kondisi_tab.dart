import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/privacy_states.dart';
import '../../data/repositories/mentor_repository.dart';
import '../../domain/entities/group_condition.dart';
import '../cubit/kondisi_cubit.dart';

/// Tab Kondisi — agregat kelompok bimbingan (L-KON-01..04).
///
/// Seluruh angka di layar ini tunduk k-anonymity. Bila kelompok di bawah
/// ambang, server tidak mengirim satu angka pun dan layar menampilkan
/// "Data belum cukup" — termasuk tidak menyebut berapa orang anggotanya.
class DosenKondisiTab extends StatelessWidget {
  const DosenKondisiTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KondisiCubit(context.read<MentorRepository>())..load(),
      child: const _KondisiView(),
    );
  }
}

class _KondisiView extends StatelessWidget {
  const _KondisiView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<KondisiCubit, KondisiState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.midnight,
              backgroundColor: Colors.white,
              onRefresh: () => context.read<KondisiCubit>().refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const SectionHeader(
                    title: 'Kondisi Kelompok',
                    subtitle: 'Gambaran agregat seluruh mahasiswa bimbingan',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // L-KON-04 — pemilih periode 30 / 90 / 120 hari.
                  _PeriodSelector(
                    selected: state.periodDays,
                    enabled: !state.isLoading,
                    onSelect: (days) =>
                        context.read<KondisiCubit>().selectPeriod(days),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (state.isLoading)
                    const LoadingState(label: 'Menghitung agregat…')
                  else if (state.status == KondisiStatus.failure)
                    ErrorStateCard(
                      message: state.errorMessage ??
                          'Periksa koneksi internet Anda lalu coba lagi.',
                      onRetry: () => context.read<KondisiCubit>().load(),
                    )
                  else if (state.isInsufficient)
                    // I-4 — TANPA angka apa pun, termasuk ukuran kelompok.
                    InsufficientDataCard(
                      minimumGroupSize: state.condition.minimumGroupSize,
                      context: 'kelompok bimbingan Anda',
                    )
                  else
                    _SufficientContent(condition: state.condition),

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

// ------------------------------------------------------------------
// L-KON-04 — pemilih periode
// ------------------------------------------------------------------

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.onSelect,
    this.enabled = true,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.creamAlt,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Row(
        children: [
          for (final days in KondisiCubit.allowedPeriods)
            Expanded(
              child: GestureDetector(
                onTap: enabled ? () => onSelect(days) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        days == selected ? AppColors.midnight : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    '$days hari',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: days == selected
                          ? Colors.white
                          : AppColors.warmTextSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Isi saat k-anonymity terpenuhi
// ------------------------------------------------------------------

class _SufficientContent extends StatelessWidget {
  const _SufficientContent({required this.condition});

  final GroupCondition condition;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StateCard(
          color: AppColors.lavenderBg,
          borderColor: AppColors.lavenderDark,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined,
                  color: AppColors.lavenderDark, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Agregat ${condition.groupSize} mahasiswa yang membagikan '
                  'indikator. Tidak ada nama maupun tulisan yang ditampilkan.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: AppColors.midnight,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ---- Rata-rata kelompok ----
        Row(
          children: [
            Expanded(
              child: _AggregateTile(
                label: 'Rata-rata mood',
                value: condition.avgMood,
                unit: '/ 5',
                color: AppColors.moodHappinessBg,
                icon: Icons.sentiment_satisfied_alt_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _AggregateTile(
                label: 'Rata-rata stres',
                value: condition.avgStress,
                unit: '/ 5',
                color: AppColors.moodAngerBg,
                icon: Icons.bolt_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _AggregateTile(
                label: 'Rata-rata tidur',
                value: condition.avgSleepHours,
                unit: 'jam',
                color: AppColors.moodSadnessBg,
                icon: Icons.bedtime_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // ---- L-KON-02 — sebaran tingkat perhatian ----
        const Text(
          'Sebaran Tingkat Perhatian',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.midnight,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (condition.hasEwsDistribution)
          _EwsDistributionCard(condition: condition)
        else
          // Sebaran ini hanya dihitung dari mahasiswa yang MENGIZINKAN
          // peringatan dini — kelompok yang bisa lebih kecil dari kelompok
          // berbagi indikator, sehingga bisa gagal ambang sendiri.
          InsufficientDataCard(
            minimumGroupSize: condition.minimumGroupSize,
            context: 'mahasiswa yang mengizinkan peringatan dini',
          ),

        const SizedBox(height: AppSpacing.lg),

        // ---- L-KON-03 — sebaran emosi (LABEL saja) ----
        const Text(
          'Sebaran Emosi',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.midnight,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Hanya label hasil analisis — teks jurnalnya tidak pernah dikirim',
          style: TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (condition.hasEmotionDistribution)
          _EmotionDistributionCard(shares: condition.emotionDistribution)
        else
          const EmptyStateCard(
            icon: Icons.donut_large_outlined,
            title: 'Belum ada hasil analisis emosi',
            description:
                'Belum ada catatan emosi pada periode ini untuk kelompok Anda.',
          ),
      ],
    );
  }
}

class _AggregateTile extends StatelessWidget {
  const _AggregateTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  final String label;

  /// Null berarti server tidak mengeluarkan angkanya. Ditampilkan sebagai "—",
  /// TIDAK PERNAH sebagai 0 — nol adalah pernyataan, kosong bukan.
  final double? value;

  final String unit;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cartoonShadow,
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.midnight),
          const SizedBox(height: 6),
          Text(
            value == null ? '—' : value!.toStringAsFixed(1),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 21,
              color: AppColors.midnight,
            ),
          ),
          Text(
            value == null ? 'tidak tersedia' : unit,
            style: const TextStyle(
              fontSize: 10,
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

class _EwsDistributionCard extends StatelessWidget {
  const _EwsDistributionCard({required this.condition});

  final GroupCondition condition;

  @override
  Widget build(BuildContext context) {
    final total = condition.ewsTotal;

    return StateCard(
      child: Column(
        children: [
          for (final entry in condition.orderedEwsDistribution)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 122,
                    child: EwsLevelBadge(level: entry.key, dense: true),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : entry.value / total,
                        minHeight: 10,
                        backgroundColor: AppColors.creamAlt,
                        valueColor: AlwaysStoppedAnimation(
                          AppColors.ewsLevel(entry.key),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 26,
                    child: Text(
                      '${entry.value}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.midnight,
                      ),
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

/// Sebaran emosi kelompok.
///
/// Menampilkan LABEL emosi dan proporsinya. Tidak ada jalur di sini yang
/// menyentuh teks jurnal — API-nya memang hanya mengirim label + jumlah
/// (L-KON-03).
class _EmotionDistributionCard extends StatelessWidget {
  const _EmotionDistributionCard({required this.shares});

  final List<EmotionShare> shares;

  static const _emotionColor = {
    'JOY': AppColors.moodHappiness,
    'CALM': AppColors.moodDisgust,
    'NEUTRAL': AppColors.warmTextMuted,
    'SAD': AppColors.moodSadness,
    'ANXIOUS': AppColors.moodFear,
    'ANGRY': AppColors.moodAnger,
    'TIRED': AppColors.lavender,
  };

  @override
  Widget build(BuildContext context) {
    final negativeShare = shares
        .where((s) => s.isNegative)
        .fold<double>(0, (sum, s) => sum + s.percentage);

    return StateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Batang proporsi tunggal — lebih mudah dibaca sekilas daripada
          // pie chart, dan tidak menyiratkan presisi yang tidak dimiliki data.
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: SizedBox(
              height: 16,
              child: Row(
                children: [
                  for (final share in shares)
                    Expanded(
                      flex: (share.percentage * 100).round().clamp(1, 1000000),
                      child: Container(
                        color: _emotionColor[share.emotionLabel] ??
                            AppColors.lavender,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: 10,
            children: [
              for (final share in shares)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: _emotionColor[share.emotionLabel] ??
                            AppColors.lavender,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${share.displayLabel} ${share.percentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.midnight,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (negativeShare > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.creamAlt,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                '${negativeShare.toStringAsFixed(0)}% catatan bernada negatif '
                '(sedih, cemas, marah, lelah). Angka ini gambaran kelompok — '
                'bukan penilaian atas siapa pun.',
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  color: AppColors.warmTextSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
