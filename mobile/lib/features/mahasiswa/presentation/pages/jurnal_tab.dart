import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../../../core/widgets/vector_illustrations.dart';
import '../../data/repositories/journal_repository.dart';
import '../../domain/entities/journal.dart';
import '../cubit/jurnal_cubit.dart';
import '../widgets/mood_visuals.dart';
import 'bantuan_darurat_page.dart';
import 'latihan_napas_page.dart';

class JurnalTab extends StatelessWidget {
  const JurnalTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => JurnalCubit(context.read<JournalRepository>())..load(),
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
  final _contentController = TextEditingController();
  final _titleController = TextEditingController();
  DateTime _journalDate = DateTime.now();

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        child: BlocConsumer<JurnalCubit, JurnalState>(
          listenWhen: (previous, current) =>
              previous.successMessage != current.successMessage ||
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            final message = state.successMessage ?? state.errorMessage;
            if (message == null) return;

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
            context.read<JurnalCubit>().clearMessages();
          },
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.midnight,
              backgroundColor: Colors.white,
              onRefresh: () => context.read<JurnalCubit>().refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: AppSpacing.md),

                  // Kartu krisis tampil paling atas: bila sistem mendeteksi
                  // tanda krisis, jalur bantuan tidak boleh perlu di-scroll.
                  if (state.showCrisisCard)
                    CrisisAlertCardWidget(
                      message: state.analysis!.crisisMessage,
                      onCallHotline: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const BantuanDaruratPage()),
                      ),
                      onDismiss: () => context.read<JurnalCubit>().dismissAnalysis(),
                    ),

                  _buildComposer(context, state),
                  const SizedBox(height: AppSpacing.lg),

                  if (state.analysis != null && !state.showCrisisCard) ...[
                    _AnalysisCard(analysis: state.analysis!),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  const Text(
                    'Catatan Sebelumnya',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.midnight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  if (state.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator(color: AppColors.midnight)),
                    )
                  else if (state.status == JurnalStatus.failure)
                    _ListErrorCard(message: state.errorMessage)
                  else if (state.isEmpty)
                    const _EmptyJournalCard()
                  else ...[
                    for (final entry in state.entries)
                      _JournalCard(entry: entry, isAnalyzing: state.analyzingId == entry.id),
                    if (state.hasNextPage)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: OutlinedButton(
                          onPressed: state.isLoadingMore
                              ? null
                              : () => context.read<JurnalCubit>().loadMore(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.midnight,
                            side: const BorderSide(color: AppColors.midnight, width: 1.5),
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                            ),
                          ),
                          child: Text(
                            state.isLoadingMore ? 'Memuat…' : 'Muat lebih banyak',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jurnal Refleksi',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: AppColors.midnight,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Hanya kamu yang bisa membaca catatan ini.',
                style: TextStyle(color: AppColors.warmTextSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: _journalDate,
              firstDate: now.subtract(const Duration(days: 7)),
              lastDate: now,
            );
            if (picked != null) setState(() => _journalDate = picked);
          },
          icon: const Icon(Icons.calendar_today_rounded, size: 15),
          label: Text(_isToday(_journalDate) ? 'Hari ini' : _formatShortDate(_journalDate)),
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

  Widget _buildComposer(BuildContext context, JurnalState state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.midnight, width: 1.5),
        boxShadow: const [
          BoxShadow(color: AppColors.cartoonShadow, offset: Offset(0, 4), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tulis Catatan',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.midnight,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Tuliskan pikiran atau perasaanmu secara bebas.',
            style: TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _titleController,
            decoration: _inputDecoration('Judul (opsional)'),
            style: const TextStyle(fontSize: 14, color: AppColors.midnight),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _contentController,
            maxLines: 6,
            minLines: 4,
            style: const TextStyle(fontSize: 14, color: AppColors.midnight, height: 1.45),
            decoration: _inputDecoration('Apa yang kamu rasakan atau alami hari ini?'),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: state.isSubmitting ? null : () => _submit(context, analyze: true),
            icon: state.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            label: Text(
              state.isSubmitting ? 'Menyimpan…' : 'Simpan & Analisis Emosi',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.midnight,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Menulis tanpa dianalisis harus tetap mungkin: analisis adalah
          // pilihan pemiliknya, bukan syarat untuk boleh bercerita.
          TextButton(
            onPressed: state.isSubmitting ? null : () => _submit(context, analyze: false),
            child: const Text(
              'Simpan saja, tanpa analisis',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.warmTextSecondary),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.warmTextMuted, fontSize: 13),
        filled: true,
        fillColor: AppColors.creamBg,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.cartoonBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.cartoonBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.midnight, width: 1.8),
        ),
      );

  Future<void> _submit(BuildContext context, {required bool analyze}) async {
    final saved = await context.read<JurnalCubit>().submit(
          content: _contentController.text,
          title: _titleController.text,
          date: _journalDate,
          analyzeNow: analyze,
        );

    if (saved) {
      _contentController.clear();
      _titleController.clear();
      setState(() => _journalDate = DateTime.now());
    }
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static String _formatShortDate(DateTime date) => '${date.day}/${date.month}';
}

// ------------------------------------------------------------------
// Hasil analisis
// ------------------------------------------------------------------

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.analysis});

  final JournalAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final mood = MoodVisuals.forEmotion(analysis.emotionLabel);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: mood.bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.midnight, width: 1.5),
        boxShadow: const [
          BoxShadow(color: AppColors.cartoonShadow, offset: Offset(0, 4), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CartoonMoodBlob(mood: mood, size: 44),
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
                      '${analysis.emotionLabelText} · keyakinan ${analysis.confidencePercent}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.midnight.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.read<JurnalCubit>().dismissAnalysis(),
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.midnight),
              ),
            ],
          ),
          if (analysis.copingSuggestions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Yang bisa kamu coba:',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.midnight,
              ),
            ),
            const SizedBox(height: 6),
            for (final suggestion in analysis.copingSuggestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: AppColors.midnight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.midnight,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const LatihanNapasPage()),
            ),
            icon: const Icon(Icons.air_rounded, size: 16),
            label: const Text('Latihan Napas', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.midnight,
              side: const BorderSide(color: AppColors.midnight, width: 1.2),
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Transparansi model ditempatkan di tempat hasilnya dibaca, bukan
          // hanya di layar edukasi yang jarang dibuka.
          Text(
            'Analisis otomatis (${analysis.modelVersion}) bisa keliru — kamu yang paling tahu perasaanmu.',
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: AppColors.midnight.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Daftar catatan
// ------------------------------------------------------------------

class _JournalCard extends StatelessWidget {
  const _JournalCard({required this.entry, required this.isAnalyzing});

  final JournalListItem entry;
  final bool isAnalyzing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: entry.isCrisisFlagged ? AppColors.ewsIntervention : AppColors.cartoonBorder,
          width: entry.isCrisisFlagged ? 1.6 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (entry.isAnalyzed)
                CartoonMoodBlob(mood: MoodVisuals.forEmotion(entry.emotionLabel), size: 32)
              else
                const EmptyDayCell(size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title.isEmpty ? _formatDate(entry.journalDate) : entry.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.midnight,
                      ),
                    ),
                    Text(
                      entry.isAnalyzed
                          ? '${_formatDate(entry.journalDate)} · ${entry.emotionLabelText}'
                          : '${_formatDate(entry.journalDate)} · belum dianalisis',
                      style: const TextStyle(fontSize: 11, color: AppColors.warmTextSecondary),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.warmTextSecondary),
                onSelected: (value) {
                  if (value == 'analyze') {
                    context.read<JurnalCubit>().analyzeExisting(entry.id);
                  } else if (value == 'delete') {
                    _confirmDelete(context);
                  }
                },
                itemBuilder: (context) => [
                  if (!entry.isAnalyzed)
                    const PopupMenuItem(value: 'analyze', child: Text('Analisis emosi')),
                  const PopupMenuItem(value: 'delete', child: Text('Hapus catatan')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entry.preview,
            style: const TextStyle(fontSize: 13, color: AppColors.midnight, height: 1.4),
          ),
          if (entry.isCrisisFlagged) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.favorite_rounded, size: 14, color: AppColors.ewsIntervention),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Catatan ini menyentuh hal berat. Bantuan tersedia kapan saja.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ewsIntervention.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (isAnalyzing)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<JurnalCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus catatan ini?'),
        content: const Text('Catatan yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.ewsIntervention)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) await cubit.delete(entry.id);
  }

  static String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _EmptyJournalCard extends StatelessWidget {
  const _EmptyJournalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: const Column(
        children: [
          Icon(Icons.menu_book_rounded, size: 36, color: AppColors.warmTextMuted),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Belum ada catatan',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.midnight,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tidak perlu rapi atau panjang. Satu kalimat pun sudah cukup.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.warmTextSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ListErrorCard extends StatelessWidget {
  const _ListErrorCard({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            message ?? 'Gagal memuat catatan.',
            style: const TextStyle(fontSize: 13, color: AppColors.midnight),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => context.read<JurnalCubit>().load(),
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
    );
  }
}
