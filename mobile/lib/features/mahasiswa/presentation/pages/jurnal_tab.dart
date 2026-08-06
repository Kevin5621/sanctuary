import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/clay_container.dart';
import '../../../../core/widgets/vector_illustrations.dart';
import '../../data/repositories/journal_repository.dart';
import '../../domain/entities/journal.dart';
import '../cubit/jurnal_cubit.dart';
import '../cubit/sebaran_emosi_cubit.dart';
import 'bantuan_darurat_page.dart';
import 'latihan_napas_page.dart';
import 'mahasiswa_shell_page.dart';

/// Tab Jurnal (M-JUR-02, M-JUR-04, M-JUR-05, M-JUR-06).
///
/// Perubahan penting dibanding versi sebelumnya:
///   - Tombol "Analisis Emosi" benar-benar memanggil backend, bukan menunda
///     900 ms lalu menampilkan hasil yang ditulis di kode.
///   - Daftar kata kunci krisis di sisi klien DIHAPUS. Penanda krisis kini
///     hanya datang dari server, yang memakai leksikon tunggal yang sama
///     dengan Terapis AI. Dua daftar di dua tempat pasti menyimpang.
///   - Pemilih tanggal dibatasi 7 hari ke belakang (D-8), sama dengan batas
///     yang ditegakkan server.
class JurnalTab extends StatelessWidget {
  const JurnalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JurnalCubit>(
      create: (context) => JurnalCubit(context.read<JournalRepository>()),
      child: const _JurnalView(),
    );
  }
}

class _JurnalView extends StatefulWidget {
  const _JurnalView();

  @override
  State<_JurnalView> createState() => _JurnalViewState();
}

class _JurnalViewState extends State<_JurnalView> {
  final TextEditingController _noteController = TextEditingController();
  DateTime _journalDate = DateTime.now();

  /// Batas backdate (D-8). Nilainya sama dengan STUDENT_MAX_BACKDATE_DAYS di
  /// server; klien hanya mencegah mahasiswa memilih tanggal yang pasti
  /// ditolak — keputusan sesungguhnya tetap milik backend.
  static const _maxBackdateDays = 7;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _journalDate,
      firstDate: now.subtract(const Duration(days: _maxBackdateDays)),
      lastDate: now,
      helpText: 'Maksimal $_maxBackdateDays hari ke belakang',
    );
    if (picked != null) setState(() => _journalDate = picked);
  }

  void _submit() {
    context.read<JurnalCubit>().saveAndAnalyze(
          content: _noteController.text,
          journalDate: _journalDate,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JurnalCubit, JurnalState>(
      listenWhen: (previous, current) =>
          previous.analysis != current.analysis && current.analysis != null,
      listener: (context, state) {
        // Sebaran Emosi di tab Mood ikut disegarkan supaya grafiknya tidak
        // tertinggal satu analisis dari kenyataan.
        context.read<SebaranEmosiCubit>().refresh();
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.creamBg,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    journalDate: _journalDate,
                    onPickDate: _pickDate,
                    isDateError: state.isDateError,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // M-JUR-05 — kartu krisis, hanya bila SERVER menandainya.
                  if (state.showCrisisCard && state.analysis != null)
                    CrisisAlertCardWidget(
                      message: state.analysis!.crisisMessage.isNotEmpty
                          ? state.analysis!.crisisMessage
                          : 'Sistem mendeteksi tanda krisis. Kamu tidak sendirian.',
                      onCallHotline: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BantuanDaruratPage(),
                        ),
                      ),
                      onDismiss: context.read<JurnalCubit>().dismissCrisisCard,
                    ),

                  _ComposerCard(
                    controller: _noteController,
                    isAnalyzing: state.isAnalyzing,
                    onSubmit: _submit,
                  ),

                  if (state.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ErrorCard(
                      message: state.errorMessage!,
                      onDismiss: context.read<JurnalCubit>().clearError,
                    ),
                  ],

                  if (state.analysis != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _AnalysisResultCard(analysis: state.analysis!),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.journalDate,
    required this.onPickDate,
    required this.isDateError,
  });

  final DateTime journalDate;
  final VoidCallback onPickDate;
  final bool isDateError;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jurnal Refleksi',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: AppColors.midnight,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${journalDate.day}/${journalDate.month}/${journalDate.year}',
              style: TextStyle(
                color: isDateError ? AppColors.ewsIntervention : AppColors.warmTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: onPickDate,
          icon: const Icon(Icons.calendar_today_rounded, size: 15),
          label: const Text('Pilih Tanggal'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.midnight,
            side: const BorderSide(color: AppColors.midnight, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
          ),
        ),
      ],
    );
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({
    required this.controller,
    required this.isAnalyzing,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isAnalyzing;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ClayContainer(
      color: AppColors.cardBg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Refleksi Hari Ini',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.midnight,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Tuliskan pikiran atau perasaanmu secara bebas. Catatanmu bersifat '
            'privat — hanya kamu yang bisa membacanya.',
            style: TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            maxLines: 6,
            minLines: 4,
            enabled: !isAnalyzing,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.midnight,
              height: 1.45,
            ),
            decoration: InputDecoration(
              hintText: 'Apa yang kamu rasakan atau alami hari ini?…',
              hintStyle: const TextStyle(
                color: AppColors.warmTextMuted,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.creamBg,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(
                  color: AppColors.cartoonBorder,
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(
                  color: AppColors.cartoonBorder,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(
                  color: AppColors.midnight,
                  width: 1.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClayButton(
            label: isAnalyzing ? 'Menganalisis emosi…' : 'Analisis & Simpan Jurnal',
            icon: Icons.auto_awesome_rounded,
            isLoading: isAnalyzing,
            color: AppColors.midnight,
            foregroundColor: Colors.white,
            onPressed: isAnalyzing ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

/// M-JUR-02 + M-JUR-04 — hasil analisis sungguhan dari server.
class _AnalysisResultCard extends StatelessWidget {
  const _AnalysisResultCard({required this.analysis});

  final JournalAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.emotion(analysis.emotionLabel);

    return ClayContainer(
      color: AppColors.cardBg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cartoonBorder),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: AppColors.midnight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hasil Analisis Emosi',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.midnight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Emosi dominan: ${analysis.emotionLabelText} '
                      '(${analysis.confidencePercent}% keyakinan)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.warmTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (analysis.copingSuggestions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Saran yang bisa kamu coba',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.midnight,
              ),
            ),
            const SizedBox(height: 6),
            ...analysis.copingSuggestions.map(
              (suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16,
                        color: AppColors.sageDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppColors.warmTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.air_rounded,
                  label: 'Latihan Napas',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LatihanNapasPage()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickAction(
                  icon: Icons.psychology_rounded,
                  label: 'Terapis AI',
                  onTap: () => MahasiswaShellPage.switchTab(context, 3),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),
          // Transparansi: sebut versi model yang sebenarnya dipakai, bukan
          // nama model yang belum terpasang.
          Text(
            'Model: ${analysis.modelVersion}',
            style: const TextStyle(fontSize: 10.5, color: AppColors.warmTextMuted),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClayContainer(
      color: AppColors.creamAlt,
      onTap: onTap,
      depth: 8,
      spread: 4,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.midnight, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppColors.midnight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return ClayContainer(
      color: AppColors.moodAngerBg,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 20, color: AppColors.midnight),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12.5, color: AppColors.midnight),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.midnight,
          ),
        ],
      ),
    );
  }
}
