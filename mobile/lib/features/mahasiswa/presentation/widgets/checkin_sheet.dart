import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../domain/entities/daily_metric.dart';
import '../cubit/beranda_cubit.dart';
import 'mood_visuals.dart';

/// Form check-in harian.
///
/// Dulu form ini menempati seluruh tab Mood. Ia dipindah ke Beranda sebagai
/// bottom sheet karena check-in adalah tindakan harian yang harus berada di
/// layar pertama — sementara tab Mood kini murni tempat melihat riwayat.
///
/// Seluruh pilihan (skala, emosi, pemicu, batas mundur tanggal) berasal dari
/// [CheckinOptions] yang dikirim server. Tidak ada daftar yang ditulis di sini.
class CheckinSheet extends StatefulWidget {
  const CheckinSheet({
    super.key,
    required this.options,
    this.existing,
    this.initialMood,
  });

  final CheckinOptions options;

  /// Check-in hari ini yang sudah ada — form terbuka dalam mode ubah.
  final DailyMetric? existing;

  /// Mood yang sudah dipilih dari pintasan di header.
  final int? initialMood;

  /// Membuka sheet dan mengembalikan true bila tersimpan.
  static Future<bool> show(
    BuildContext context, {
    required CheckinOptions options,
    DailyMetric? existing,
    int? initialMood,
  }) async {
    final cubit = context.read<BerandaCubit>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: CheckinSheet(
          options: options,
          existing: existing,
          initialMood: initialMood,
        ),
      ),
    );
    return saved ?? false;
  }

  @override
  State<CheckinSheet> createState() => _CheckinSheetState();
}

class _CheckinSheetState extends State<CheckinSheet> {
  late int _moodScore;
  late int _stressLevel;
  late double _sleepHours;
  late String _emotion;
  late String _trigger;
  late DateTime _date;
  late final TextEditingController _triggerController;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;
    _moodScore = widget.initialMood ?? existing?.moodScore ?? 3;
    _stressLevel = existing?.stressLevel ?? 3;
    _sleepHours = existing?.sleepHours ?? 7.0;
    _emotion = existing?.emotionLabel ?? '';
    _trigger = existing?.academicTrigger ?? '';
    _triggerController = TextEditingController(text: _trigger);
    _date = existing?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _triggerController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.existing != null;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.creamBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
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
                      _buildMoodSection(),
                      const SizedBox(height: AppSpacing.md),
                      _buildStressSection(),
                      const SizedBox(height: AppSpacing.md),
                      _buildSleepSection(),
                      const SizedBox(height: AppSpacing.md),
                      _buildEmotionSection(),
                      const SizedBox(height: AppSpacing.md),
                      _buildTriggerSection(),
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
          color: AppColors.warmTextMuted.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEditing ? 'Ubah check-in' : 'Check-in hari ini',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.midnight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _isEditing
              ? 'Kamu sudah mengisi hari ini. Perubahan akan menimpa isian sebelumnya.'
              : 'Isi apa adanya. Tidak ada jawaban yang salah.',
          style: const TextStyle(fontSize: 13, color: AppColors.warmTextSecondary, height: 1.35),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final now = DateTime.now();
    final earliest = widget.options.earliestDate(now);
    final isToday = _date.year == now.year && _date.month == now.month && _date.day == now.day;

    return _Card(
      child: Row(
        children: [
          const Icon(Icons.event_rounded, size: 20, color: AppColors.midnight),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Hari ini' : '${_date.day}/${_date.month}/${_date.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.midnight,
                  ),
                ),
                Text(
                  'Bisa diisi mundur maksimal ${widget.options.maxBackdateDays} hari',
                  style: const TextStyle(fontSize: 11, color: AppColors.warmTextSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: earliest,
                lastDate: now,
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: const Text('Ubah', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Bagaimana perasaanmu?', trailing: widget.options.moodLabel(_moodScore)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final option in widget.options.moodScale)
                CartoonMoodBlob(
                  mood: MoodVisuals.forScore(option.value),
                  size: 52,
                  isSelected: _moodScore == option.value,
                  onTap: () => setState(() => _moodScore = option.value),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStressSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Tingkat stres', trailing: widget.options.stressLabel(_stressLevel)),
          Slider(
            value: _stressLevel.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: AppColors.midnight,
            inactiveColor: AppColors.creamAlt,
            onChanged: (value) => setState(() => _stressLevel = value.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Jam tidur semalam', trailing: '${_sleepHours.toStringAsFixed(1)} jam'),
          Slider(
            value: _sleepHours,
            min: 0,
            max: 12,
            divisions: 24,
            activeColor: AppColors.midnight,
            inactiveColor: AppColors.creamAlt,
            onChanged: (value) => setState(() => _sleepHours = value),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Emosi yang paling terasa', trailing: 'opsional'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in widget.options.emotions)
                _ChoiceChip(
                  label: option.label,
                  isSelected: _emotion == option.value,
                  onTap: () => setState(
                    () => _emotion = _emotion == option.value ? '' : option.value,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Apa pemicunya?', trailing: 'opsional'),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _triggerController,
            onChanged: (val) => _trigger = val.trim(),
            decoration: InputDecoration(
              hintText: 'Misal: Bimbingan skripsi, deadline tugas...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.warmTextMuted),
              filled: true,
              fillColor: AppColors.creamBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: const BorderSide(color: AppColors.cartoonBorder, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: const BorderSide(color: AppColors.cartoonBorder, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                borderSide: const BorderSide(color: AppColors.midnight, width: 1.5),
              ),
            ),
            style: const TextStyle(fontSize: 13, color: AppColors.midnight),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitBar(BuildContext context) {
    return BlocBuilder<BerandaCubit, BerandaState>(
      buildWhen: (previous, current) => previous.isSaving != current.isSaving,
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
            boxShadow: [
              BoxShadow(color: AppColors.cartoonShadow, blurRadius: 10, offset: Offset(0, -4)),
            ],
          ),
          child: ElevatedButton(
            onPressed: state.isSaving ? null : () => _submit(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.midnight,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
            child: state.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    _isEditing ? 'Perbarui check-in' : 'Simpan check-in',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _submit(BuildContext context) async {
    final saved = await context.read<BerandaCubit>().saveCheckin(
          moodScore: _moodScore,
          stressLevel: _stressLevel,
          sleepHours: _sleepHours,
          emotionLabel: _emotion,
          academicTrigger: _triggerController.text.trim(),
          date: _date,
        );

    if (saved && context.mounted) Navigator.of(context).pop(true);
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.midnight,
            ),
          ),
        ),
        if (trailing != null && trailing!.isNotEmpty)
          Text(
            trailing!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.warmTextSecondary,
            ),
          ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.midnight : AppColors.creamBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: isSelected ? AppColors.midnight : AppColors.cartoonBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.midnight,
          ),
        ),
      ),
    );
  }
}
