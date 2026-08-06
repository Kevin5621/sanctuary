import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../data/repositories/dass_repository.dart';
import '../../domain/entities/dass21.dart';
import '../cubit/dass_cubit.dart';
import 'bantuan_darurat_page.dart';

/// Halaman Skrining DASS-21.
///
/// Soal, ambang keparahan, dan disclaimer seluruhnya berasal dari server.
/// Layar ini hanya mengumpulkan jawaban dan menampilkan hasil — tidak ada
/// satu pun perhitungan klinis di sisi klien.
class Dass21ScreeningPage extends StatelessWidget {
  const Dass21ScreeningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DassCubit(context.read<DassRepository>())..load(),
      child: const _Dass21View(),
    );
  }
}

class _Dass21View extends StatelessWidget {
  const _Dass21View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        title: const Text('Skrining DASS-21'),
        elevation: 0,
        actions: [
          BlocBuilder<DassCubit, DassState>(
            builder: (context, state) {
              if (state.history.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Riwayat skrining',
                onPressed: () => context.read<DassCubit>().showHistory(),
                icon: const Icon(Icons.history_rounded),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<DassCubit, DassState>(
        listenWhen: (previous, current) => previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          if (state.errorMessage == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.midnight));
          }
          if (state.status == DassStatus.failure) {
            return _ErrorView(message: state.errorMessage);
          }

          return switch (state.view) {
            DassView.questionnaire => _QuestionnaireView(state: state),
            DassView.result => _ResultView(state: state),
            DassView.history => _HistoryView(state: state),
          };
        },
      ),
    );
  }
}

// ------------------------------------------------------------------
// Pengisian
// ------------------------------------------------------------------

class _QuestionnaireView extends StatelessWidget {
  const _QuestionnaireView({required this.state});

  final DassState state;

  @override
  Widget build(BuildContext context) {
    final questionnaire = state.questionnaire;

    return Column(
      children: [
        _ProgressBanner(state: state),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _InstructionCard(
                instruction: questionnaire.instruction,
                disclaimer: questionnaire.disclaimer,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final question in questionnaire.questions)
                _QuestionCard(
                  question: question,
                  options: questionnaire.options,
                  selected: state.answers[question.number],
                ),
            ],
          ),
        ),
        _SubmitBar(state: state),
      ],
    );
  }
}

class _ProgressBanner extends StatelessWidget {
  const _ProgressBanner({required this.state});

  final DassState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.answeredCount} dari ${state.totalQuestions} soal',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              WavyBadge(
                text: '${(state.progress * 100).toInt()}%',
                color: AppColors.lavenderBg,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 10,
              backgroundColor: AppColors.creamAlt,
              color: AppColors.moodDisgust,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({required this.instruction, required this.disclaimer});

  final String instruction;
  final String disclaimer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.lavenderBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            instruction,
            style: const TextStyle(fontSize: 13, color: AppColors.midnight, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.midnight),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  disclaimer,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.midnight.withValues(alpha: 0.75),
                    height: 1.35,
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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.options,
    required this.selected,
  });

  final DassQuestion question;
  final List<DassAnswerOption> options;
  final int? selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${question.number}. ${question.text}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.midnight,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final option in options)
            InkWell(
              onTap: () => context.read<DassCubit>().answer(question.number, option.value),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: selected == option.value ? AppColors.moodDisgustBg : AppColors.creamBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: selected == option.value
                        ? AppColors.moodDisgust
                        : AppColors.cartoonBorder,
                    width: selected == option.value ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected == option.value
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      color: selected == option.value
                          ? AppColors.midnight
                          : AppColors.warmTextSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      option.label,
                      style: TextStyle(
                        fontWeight: selected == option.value ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.midnight,
                        fontSize: 13,
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

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.state});

  final DassState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: AppColors.cartoonShadow, blurRadius: 10, offset: Offset(0, -4)),
        ],
      ),
      child: ElevatedButton(
        // Pengiriman baru terbuka setelah semua soal terjawab: skor DASS-21
        // hanya bermakna bila seluruh item terisi.
        onPressed: (!state.isComplete || state.isSubmitting)
            ? null
            : () => context.read<DassCubit>().submit(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.midnight,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
        child: state.isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                state.isComplete
                    ? 'Lihat hasil skrining'
                    : 'Lengkapi semua soal (${state.answeredCount}/${state.totalQuestions})',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// Hasil
// ------------------------------------------------------------------

class _ResultView extends StatelessWidget {
  const _ResultView({required this.state});

  final DassState state;

  @override
  Widget build(BuildContext context) {
    final result = state.result;
    if (result == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.midnight, width: 1.8),
            boxShadow: const [
              BoxShadow(color: AppColors.cartoonShadow, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              CartoonMoodBlob(
                mood: result.hasSevere ? MoodType.sadness : MoodType.happiness,
                size: 80,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Hasil Skrining DASS-21',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: AppColors.midnight,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final subscale in result.subscales) ...[
                _SubscaleTile(subscale: subscale),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Kategori berat memunculkan jalur bantuan lebih dulu daripada saran
        // mandiri — pada titik ini yang dibutuhkan adalah manusia.
        if (result.hasSevere) const _SevereHelpCard(),

        if (result.copingSuggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _SuggestionsCard(suggestions: result.copingSuggestions),
        ],

        const SizedBox(height: AppSpacing.md),
        _DisclaimerCard(text: result.disclaimer),

        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: () => context.read<DassCubit>().showHistory(),
          icon: const Icon(Icons.history_rounded, size: 18),
          label: const Text(
            'Lihat riwayat & tren',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.midnight,
            side: const BorderSide(color: AppColors.midnight, width: 1.5),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _SubscaleTile extends StatelessWidget {
  const _SubscaleTile({required this.subscale});

  final DassSubscaleResult subscale;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(subscale.severity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subscale.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.midnight,
                ),
              ),
              WavyBadge(text: subscale.severityLabel, color: color, textColor: Colors.white),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: subscale.fraction,
              minHeight: 6,
              backgroundColor: Colors.white,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Skor ${subscale.score} dari ${subscale.maxScore}',
            style: const TextStyle(fontSize: 11, color: AppColors.warmTextSecondary),
          ),
        ],
      ),
    );
  }

  static Color _severityColor(String severity) => switch (severity) {
        'EXTREMELY_SEVERE' => AppColors.ewsIntervention,
        'SEVERE' => AppColors.ewsRisk,
        'MODERATE' => AppColors.ewsWatch,
        'MILD' => AppColors.moodDisgust,
        _ => AppColors.ewsNormal,
      };
}

class _SevereHelpCard extends StatelessWidget {
  const _SevereHelpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.moodAngerBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.ewsIntervention, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite_rounded, color: AppColors.ewsIntervention),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kamu tidak harus menghadapi ini sendirian',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.midnight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Hasilmu berada pada tingkat yang sebaiknya dibicarakan dengan pendamping '
            'profesional. Menghubungi mereka bukan tanda menyerah.',
            style: TextStyle(fontSize: 12, color: AppColors.warmTextSecondary, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BantuanDaruratPage()),
            ),
            icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
            label: const Text(
              'Lihat layanan bantuan',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ewsIntervention,
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

class _SuggestionsCard extends StatelessWidget {
  const _SuggestionsCard({required this.suggestions});

  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Langkah yang bisa kamu ambil',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.midnight,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final suggestion in suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.spa_outlined, size: 16, color: AppColors.moodDisgust),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.midnight,
                        height: 1.4,
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

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.creamAlt,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warmTextSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.warmTextSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Riwayat & tren
// ------------------------------------------------------------------

class _HistoryView extends StatelessWidget {
  const _HistoryView({required this.state});

  final DassState state;

  @override
  Widget build(BuildContext context) {
    final history = state.history;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: history.isWorsening ? AppColors.moodAngerBg : AppColors.moodDisgustBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
          ),
          child: Row(
            children: [
              Icon(
                history.isWorsening ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: AppColors.midnight,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.changeLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.midnight,
                      ),
                    ),
                    Text(
                      '${history.count} pengisian tersimpan',
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
        ),
        const SizedBox(height: AppSpacing.md),
        if (history.trend.length >= 2) _TrendChart(trend: history.trend),
        const SizedBox(height: AppSpacing.md),
        for (final result in history.results) _HistoryTile(result: result),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton.icon(
          onPressed: () => context.read<DassCubit>().startNewScreening(),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Isi skrining baru', style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.midnight,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.trend});

  final List<DassTrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tren Skor Total',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.midnight,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Skor yang menurun berarti keluhan berkurang.',
            style: TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0,
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                  ),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < trend.length; i++)
                        FlSpot(i.toDouble(), trend[i].totalScore.toDouble()),
                    ],
                    isCurved: true,
                    color: AppColors.lavenderDark,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.lavenderBg.withValues(alpha: 0.6),
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.result});

  final DassResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                result.takenDate,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.midnight,
                ),
              ),
              Text(
                'Total ${result.totalScore}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.warmTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final subscale in result.subscales)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.creamAlt,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    '${subscale.label}: ${subscale.severityLabel}',
                    style: const TextStyle(
                      fontSize: 11,
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
            Text(
              message ?? 'Gagal memuat kuesioner.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.warmTextSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => context.read<DassCubit>().load(),
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
