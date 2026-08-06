import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/jurnal_cubit.dart';

/// Form pembuat catatan jurnal refleksi dalam bentuk bottom sheet.
///
/// Memisahkan UI tulis catatan dari layar utama agar tampilan jurnal bersih
/// dan fokus pada riwayat serta ringkasan analisis.
class JurnalComposerSheet extends StatefulWidget {
  const JurnalComposerSheet({
    super.key,
    this.initialDate,
  });

  final DateTime? initialDate;

  /// Membuka modal bottom sheet untuk menulis catatan baru.
  /// Mengembalikan `true` bila catatan berhasil disimpan.
  static Future<bool> show(
    BuildContext context, {
    DateTime? initialDate,
  }) async {
    final cubit = context.read<JurnalCubit>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: JurnalComposerSheet(initialDate: initialDate),
      ),
    );
    return saved ?? false;
  }

  @override
  State<JurnalComposerSheet> createState() => _JurnalComposerSheetState();
}

class _JurnalComposerSheetState extends State<JurnalComposerSheet> {
  late DateTime _journalDate;
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _journalDate = widget.initialDate ?? DateTime.now();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.creamBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusLg),
              ),
              border: Border.all(color: AppColors.midnight, width: 1.5),
            ),
            child: Column(
              children: [
                _buildHandle(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: AppSpacing.md),
                      _buildDatePicker(context),
                      const SizedBox(height: AppSpacing.md),
                      _buildInputsSection(),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
                _buildSubmitBar(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandle() => Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.warmTextMuted.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tulis Catatan Refleksi',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColors.midnight,
                letterSpacing: -0.3,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.close_rounded, color: AppColors.midnight),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'Tuliskan pikiran atau perasaanmu secara bebas. Catatan ini bersifat privat.',
          style: TextStyle(fontSize: 13, color: AppColors.warmTextSecondary, height: 1.35),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final now = DateTime.now();
    final isToday = _isToday(_journalDate);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.midnight),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tanggal Catatan',
                  style: TextStyle(fontSize: 11, color: AppColors.warmTextSecondary),
                ),
                Text(
                  isToday ? 'Hari ini (${_formatDate(_journalDate)})' : _formatDate(_journalDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.midnight,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _journalDate,
                firstDate: now.subtract(const Duration(days: 7)),
                lastDate: now,
              );
              if (picked != null) {
                setState(() => _journalDate = picked);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.midnight,
              side: const BorderSide(color: AppColors.midnight, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text(
              'Ubah',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputsSection() {
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
          const Text(
            'Judul',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.midnight,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            decoration: _inputDecoration('Judul catatan (opsional)'),
            style: const TextStyle(fontSize: 14, color: AppColors.midnight),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Isi Catatan',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.midnight,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _contentController,
            maxLines: 7,
            minLines: 4,
            style: const TextStyle(fontSize: 14, color: AppColors.midnight, height: 1.45),
            decoration: _inputDecoration('Apa yang kamu rasakan atau alami hari ini?'),
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

  Widget _buildSubmitBar(BuildContext context) {
    return BlocBuilder<JurnalCubit, JurnalState>(
      buildWhen: (previous, current) => previous.isSubmitting != current.isSubmitting,
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md + MediaQuery.of(context).padding.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusMd)),
            boxShadow: [
              BoxShadow(color: AppColors.cartoonShadow, blurRadius: 10, offset: Offset(0, -4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 4),
              TextButton(
                onPressed: state.isSubmitting ? null : () => _submit(context, analyze: false),
                child: const Text(
                  'Simpan saja, tanpa analisis',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.warmTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit(BuildContext context, {required bool analyze}) async {
    final saved = await context.read<JurnalCubit>().submit(
          content: _contentController.text,
          title: _titleController.text,
          date: _journalDate,
          analyzeNow: analyze,
        );

    if (saved && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
