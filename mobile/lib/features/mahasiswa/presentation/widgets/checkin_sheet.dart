import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../domain/entities/daily_metric.dart';
import 'mood_visuals.dart';

/// Penyimpan check-in. Sheet ini tidak tahu cubit mana yang memegang datanya —
/// Beranda menyimpan lewat BerandaCubit, tab Mood lewat MoodHistoryCubit, dan
/// keduanya memakai form yang sama persis. Mengembalikan true bila tersimpan.
typedef CheckinSubmit = Future<bool> Function({
  required int moodScore,
  required int stressLevel,
  required double sleepHours,
  required String academicTrigger,
  required DateTime date,
});

/// Form check-in harian.
///
/// Dulu form ini menempati seluruh tab Mood, lalu dipindah ke Beranda sebagai
/// bottom sheet karena check-in adalah tindakan harian yang harus berada di
/// layar pertama. Kini tab Mood memanggilnya kembali dari kalender: mengetuk
/// tanggal yang belum terisi membuka form yang sama untuk tanggal itu.
///
/// Seluruh pilihan (skala, emosi, pemicu, batas mundur tanggal) berasal dari
/// [CheckinOptions] yang dikirim server. Tidak ada daftar yang ditulis di sini.
class CheckinSheet extends StatefulWidget {
  const CheckinSheet({
    super.key,
    required this.options,
    required this.onSubmit,
    this.existing,
    this.initialMood,
    this.initialDate,
  });

  final CheckinOptions options;

  final CheckinSubmit onSubmit;

  /// Check-in yang sudah ada pada tanggal itu — form terbuka dalam mode ubah.
  final DailyMetric? existing;

  /// Mood yang sudah dipilih dari pintasan di header.
  final int? initialMood;

  /// Tanggal awal form. Dipakai saat sheet dibuka dari sel kalender; tanpa ini
  /// form terbuka untuk hari ini.
  final DateTime? initialDate;

  /// Membuka sheet dan mengembalikan true bila tersimpan.
  static Future<bool> show(
    BuildContext context, {
    required CheckinOptions options,
    required CheckinSubmit onSubmit,
    DailyMetric? existing,
    int? initialMood,
    DateTime? initialDate,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CheckinSheet(
        options: options,
        onSubmit: onSubmit,
        existing: existing,
        initialMood: initialMood,
        initialDate: initialDate,
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
  late String _trigger;
  late DateTime _date;
  late final TextEditingController _triggerController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;
    _moodScore = widget.initialMood ?? existing?.moodScore ?? 3;
    _stressLevel = existing?.stressLevel ?? 3;
    _sleepHours = existing?.sleepHours ?? 7.0;
    _trigger = existing?.academicTrigger ?? '';
    _triggerController = TextEditingController(text: _trigger);
    _date = widget.initialDate ?? existing?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _triggerController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.existing != null;

  bool get _isToday {
    final now = DateTime.now();
    return _date.year == now.year && _date.month == now.month && _date.day == now.day;
  }

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
    final String title;
    final String subtitle;

    if (_isEditing) {
      title = 'Ubah check-in';
      subtitle = _isToday
          ? 'Kamu sudah mengisi hari ini. Perubahan akan menimpa isian sebelumnya.'
          : 'Tanggal ini sudah terisi. Perubahan akan menimpa isian sebelumnya.';
    } else if (_isToday) {
      title = 'Check-in hari ini';
      subtitle = 'Isi apa adanya. Tidak ada jawaban yang salah.';
    } else {
      title = 'Check-in ${_formatDate(_date)}';
      subtitle = 'Isi sesuai yang kamu ingat tentang hari itu, apa adanya.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: AppColors.midnight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.warmTextSecondary, height: 1.35),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final now = DateTime.now();
    final earliest = widget.options.earliestDate(now);

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
                  _isToday ? 'Hari ini' : _formatDate(_date),
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
        onPressed: _isSaving ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.midnight,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
        child: _isSaving
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
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);

    final saved = await widget.onSubmit(
      moodScore: _moodScore,
      stressLevel: _stressLevel,
      sleepHours: _sleepHours,
      academicTrigger: _triggerController.text.trim(),
      date: _date,
    );

    if (!mounted) return;
    // Sheet tetap terbuka bila gagal: isian mahasiswa tidak boleh hilang hanya
    // karena jaringan putus. Pesan galatnya ditampilkan layar pemanggil.
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSaving = false);
    }
  }

  static String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
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
