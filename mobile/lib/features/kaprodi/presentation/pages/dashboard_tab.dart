import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/privacy_states.dart';
import '../../data/repositories/program_repository.dart';
import '../../domain/entities/program_dashboard.dart';
import '../cubit/kaprodi_cubit.dart';

/// Dashboard Kaprodi (K-DAS-01..07).
///
/// Dua aturan yang membentuk seluruh layar ini:
///   · D-9 — "perlu intervensi" adalah PERSENTASE, tidak pernah jumlah orang.
///   · I-4 — bila prodi di bawah ambang k-anonymity, tidak ada satu angka pun
///     yang ditampilkan, termasuk jumlah pesertanya sendiri.
class KaprodiDashboardTab extends StatelessWidget {
  const KaprodiDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DashboardCubit(context.read<ProgramRepository>())..load(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.midnight,
              backgroundColor: Colors.white,
              onRefresh: () => context.read<DashboardCubit>().refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const SectionHeader(
                    title: 'Dashboard Prodi',
                    subtitle: 'Kondisi prodi dalam angka, tanpa identitas siapa pun',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _PeriodSelector(
                    selected: state.periodDays,
                    enabled: !state.status.isLoading,
                    onSelect: (days) =>
                        context.read<DashboardCubit>().selectPeriod(days),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (state.status.isLoading)
                    const LoadingState(label: 'Menghitung agregat prodi…')
                  else if (state.status.isFailure)
                    ErrorStateCard(
                      message: state.errorMessage ??
                          'Periksa koneksi internet Anda lalu coba lagi.',
                      onRetry: () => context.read<DashboardCubit>().load(),
                    )
                  else if (state.isInsufficient)
                    InsufficientDataCard(
                      minimumGroupSize: state.dashboard.minimumGroupSize,
                      context: 'program studi Anda',
                    )
                  else
                    _DashboardContent(dashboard: state.dashboard),

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
          for (final days in DashboardCubit.allowedPeriods)
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

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.dashboard});

  final ProgramDashboard dashboard;

  /// Warna latar per metrik. Dipetakan dari `key` yang stabil, bukan dari
  /// urutan array — supaya menambah metrik baru di backend tidak menggeser
  /// warna metrik lain.
  static const _metricStyle = {
    'avg_mood': (AppColors.moodHappinessBg, Icons.sentiment_satisfied_alt_rounded),
    'need_intervention': (AppColors.moodAngerBg, Icons.priority_high_rounded),
    'active_7_days': (AppColors.moodDisgustBg, Icons.calendar_month_rounded),
    'avg_stress': (AppColors.moodFearBg, Icons.bolt_rounded),
    'avg_sleep': (AppColors.moodSadnessBg, Icons.bedtime_outlined),
    'screened': (AppColors.lavenderBg, Icons.assignment_turned_in_rounded),
  };

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
                  'Dihitung dari ${dashboard.groupSize} mahasiswa yang '
                  'mengaktifkan izin "Ikut Statistik Prodi". '
                  'Tidak ada nama maupun data per mahasiswa di layar ini.',
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

        // ---- 6 kartu metrik (K-DAS-01..06) ----
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dashboard.metrics.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.18,
          ),
          itemBuilder: (context, index) {
            final metric = dashboard.metrics[index];
            final style = _metricStyle[metric.key] ??
                (AppColors.creamAlt, Icons.insights_rounded);
            return _MetricTile(
              metric: metric,
              color: style.$1,
              icon: style.$2,
            );
          },
        ),

        const SizedBox(height: AppSpacing.lg),

        // ---- K-DAS-07 — sebaran tingkat perhatian ----
        const Text(
          'Sebaran Tingkat Perhatian',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.midnight,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Proporsi, bukan jumlah orang — sama alasannya dengan metrik intervensi',
          style: TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (dashboard.hasEwsDistribution)
          _EwsDistributionCard(shares: dashboard.ewsDistribution)
        else
          InsufficientDataCard(
            minimumGroupSize: dashboard.minimumGroupSize,
            context: 'sebaran tingkat perhatian',
          ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.metric,
    required this.color,
    required this.icon,
  });

  final MetricCard metric;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cartoonShadow,
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: AppColors.midnight),
              const Spacer(),
              // D-9 ditegaskan di UI: kartu persentase diberi penanda satuan
              // supaya tidak ada yang membacanya sebagai jumlah mahasiswa.
              if (metric.isPercentage)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: const Text(
                    'persentase',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warmTextSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    // Nilai null dirender "—", bukan 0 (I-4).
                    metric.displayValue,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      height: 1.1,
                      color: AppColors.midnight,
                    ),
                  ),
                ),
              ),
              if (metric.hasValue && metric.displayUnit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  metric.displayUnit,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warmTextSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            metric.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: AppColors.midnight,
            ),
          ),
          if (metric.hint.isNotEmpty)
            Text(
              metric.hint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
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
  const _EwsDistributionCard({required this.shares});

  final List<EwsShare> shares;

  @override
  Widget build(BuildContext context) {
    return StateCard(
      child: Column(
        children: [
          for (final share in shares)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 122,
                    child: EwsLevelBadge(
                      level: share.level,
                      label: share.levelLabel,
                      dense: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      child: LinearProgressIndicator(
                        value: (share.percentage / 100).clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: AppColors.creamAlt,
                        valueColor: AlwaysStoppedAnimation(
                          AppColors.ewsLevel(share.level),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 38,
                    child: Text(
                      '${share.percentage.round()}%',
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
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: AppColors.warmTextMuted),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Persentase dihitung dari mahasiswa yang datanya cukup untuk '
                  'dievaluasi, bukan dari seluruh peserta statistik.',
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.3,
                    color: AppColors.warmTextMuted,
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
