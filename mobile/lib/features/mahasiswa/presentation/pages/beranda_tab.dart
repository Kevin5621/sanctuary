import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../../../core/widgets/vector_illustrations.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/daily_metric.dart';
import '../cubit/beranda_cubit.dart';
import '../cubit/mood_history_cubit.dart';
import '../widgets/checkin_sheet.dart';
import '../widgets/dynamic_greeting_header.dart';
import '../widgets/mood_visuals.dart';
import 'bantuan_darurat_page.dart';
import 'dass21_screening_page.dart';
import 'latihan_napas_page.dart';
import 'mahasiswa_shell_page.dart';

/// BerandaCubit-nya disediakan MahasiswaShellPage, bukan di sini: tab Mood
/// ikut menyimpan check-in, dan Beranda harus melihat hasilnya.
class BerandaTab extends StatelessWidget {
  const BerandaTab({super.key});

  @override
  Widget build(BuildContext context) => const _BerandaView();
}

class _BerandaView extends StatelessWidget {
  const _BerandaView();

  static const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    final firstName = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName.trim().split(RegExp(r'\s+')).first
        : 'Sahabat';

    final phase = DynamicGreetingHeader.currentPhase;
    final scaffoldBgColor = DynamicGreetingHeader.getScaffoldColor(phase);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<BerandaCubit, BerandaState>(
          listenWhen: (previous, current) =>
              previous.successMessage != current.successMessage ||
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            final message = state.successMessage ?? state.errorMessage;
            if (message == null) return;

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
            context.read<BerandaCubit>().clearMessages();
          },
          builder: (context, state) {
            return RefreshIndicator(
              color: scaffoldBgColor,
              backgroundColor: Colors.white,
              onRefresh: () => context.read<BerandaCubit>().refresh(),
              child: Column(
                children: [
                  DynamicGreetingHeader(firstName: firstName, state: state),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        color: AppColors.creamBg,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 12,
                        ),
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppColors.warmTextMuted.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          if (state.isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 64),
                              child: Center(
                                child: CircularProgressIndicator(color: AppColors.midnight),
                              ),
                            )
                          else if (state.status == BerandaStatus.failure)
                            _ErrorCard(message: state.errorMessage)
                          else ...[
                            _TodayCard(state: state),
                            const SizedBox(height: AppSpacing.lg),
                            if (!state.isFirstTime) ...[
                              const _SectionHeading('Kalender Mood Mingguan'),
                              const SizedBox(height: AppSpacing.sm),
                              _WeeklyCalendar(
                                summary: state.summary,
                                dayLabels: _dayLabels,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],
                            const _SectionHeading('Kategori Fitur'),
                            const SizedBox(height: AppSpacing.md),
                            const _CategoriesRow(),
                            const SizedBox(height: AppSpacing.lg),
                            const _Dass21Banner(),
                            const SizedBox(height: AppSpacing.md),
                            _ContactRequestCard(state: state),
                            const SizedBox(height: AppSpacing.md),
                            const _CopingRow(),
                          ],
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
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
// Kartu ringkasan hari ini + tombol check-in
// ------------------------------------------------------------------

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.state});

  final BerandaState state;

  @override
  Widget build(BuildContext context) {
    final today = state.summary.today;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(color: AppColors.cartoonShadow, offset: Offset(0, 4), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ringkasan Hari Ini',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.midnight,
                ),
              ),
              WavyBadge(
                text: today != null ? 'Sudah check-in' : 'Belum check-in',
                color: today != null ? AppColors.moodDisgustBg : AppColors.creamAlt,
                borderColor: today != null ? AppColors.ewsNormal : AppColors.ewsInsufficient,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (today == null)
            _EmptyToday(state: state)
          else
            _FilledToday(today: today, state: state),
        ],
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday({required this.state});

  final BerandaState state;

  @override
  Widget build(BuildContext context) {
    final isFirstTime = state.isFirstTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.creamAlt,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
              ),
              child: const Icon(Icons.wb_sunny_outlined, color: AppColors.warmTextMuted),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isFirstTime ? 'Mulai dari hari ini' : 'Kamu belum check-in hari ini',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.midnight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isFirstTime
                        ? 'Satu check-in singkat sudah cukup untuk memulai. Polamu akan mulai terbaca setelah beberapa hari.'
                        : 'Butuh kurang dari satu menit.',
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
        const SizedBox(height: AppSpacing.md),
        _CheckinButton(state: state, label: 'Isi check-in sekarang'),
      ],
    );
  }
}

class _FilledToday extends StatelessWidget {
  const _FilledToday({required this.today, required this.state});

  final DailyMetric today;
  final BerandaState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CartoonMoodBlob(mood: MoodVisuals.forScore(today.moodScore), size: 54),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _headline(today),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.midnight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Stres: ${today.stressLabel} · Tidur: ${_formatHours(today.sleepHours)} jam',
                    style: const TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
                  ),
                  if (today.academicTriggerText.isNotEmpty)
                    Text(
                      'Pemicu: ${today.academicTriggerText}',
                      style: const TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _CheckinButton(state: state, label: 'Ubah check-in hari ini', isOutlined: true),
      ],
    );
  }

  static String _headline(DailyMetric today) =>
      today.moodLabel.isNotEmpty ? today.moodLabel : 'Mood ${today.moodScore}/5';

  static String _formatHours(double hours) =>
      hours == hours.roundToDouble() ? hours.toStringAsFixed(0) : hours.toStringAsFixed(1);
}

class _CheckinButton extends StatelessWidget {
  const _CheckinButton({
    required this.state,
    required this.label,
    this.isOutlined = false,
  });

  final BerandaState state;
  final String label;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    // Form baru dibuka setelah pilihan dari server tersedia, supaya tidak ada
    // layar yang menampilkan daftar emosi atau batas tanggal versi klien.
    final cubit = context.read<BerandaCubit>();
    final moodHistory = context.read<MoodHistoryCubit>();

    final onPressed = state.canCheckIn
        ? () async {
            final saved = await CheckinSheet.show(
              context,
              options: state.options,
              existing: state.summary.today,
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

            // Kalender di tab Mood memegang bulan yang sama. Dibiarkan basi, ia
            // menampilkan hari ini sebagai kosong — dan mengetuknya akan
            // menimpa check-in ini dengan nilai bawaan form.
            if (saved) await moodHistory.refresh();
          }
        : null;

    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.midnight,
          side: const BorderSide(color: AppColors.midnight, width: 1.5),
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.midnight,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// Kalender mingguan
// ------------------------------------------------------------------

class _WeeklyCalendar extends StatelessWidget {
  const _WeeklyCalendar({required this.summary, required this.dayLabels});

  final WeeklyMoodSummary summary;
  final List<String> dayLabels;

  @override
  Widget build(BuildContext context) {
    final weekStart = summary.weekStart;
    final now = DateTime.now();

    return Row(
      children: List.generate(7, (index) {
        final date = weekStart?.add(Duration(days: index));
        final metric = date == null ? null : summary.forDate(date);
        final isToday = date != null &&
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 6 ? 0 : 6),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isToday ? AppColors.moodFearBg : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isToday ? AppColors.midnight : AppColors.cartoonBorder,
                  width: isToday ? 2.0 : 1.0,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    dayLabels[index],
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: isToday ? AppColors.midnight : AppColors.warmTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  metric != null
                      ? CartoonMoodBlob(mood: MoodVisuals.forScore(metric.moodScore), size: 32)
                      : const EmptyDayCell(size: 32),
                  const SizedBox(height: 6),
                  Text(
                    date == null ? '-' : '${date.day}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: AppColors.midnight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ------------------------------------------------------------------
// Minta dihubungi
// ------------------------------------------------------------------

class _ContactRequestCard extends StatelessWidget {
  const _ContactRequestCard({required this.state});

  final BerandaState state;

  @override
  Widget build(BuildContext context) {
    final contact = state.contact;
    if (!contact.hasAdvisor) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: contact.hasOpenRequest ? AppColors.moodDisgustBg : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.waving_hand_rounded, color: AppColors.midnight, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  contact.hasOpenRequest
                      ? 'Permintaan terkirim ke ${contact.advisorSummary}'
                      : 'Ingin disapa ${contact.advisorSummary}?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.midnight,
                  ),
                ),
              ),
            ],
          ),

          // Saat pembimbingnya lebih dari satu, namanya tetap disebut satu per
          // satu. "2 pembimbingmu" saja menyisakan pertanyaan siapa — dan
          // pertanyaan itu justru yang membuat orang ragu menekan tombolnya.
          if (contact.hasMultipleAdvisors) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final advisor in contact.advisors)
                  _AdvisorChip(name: advisor.fullName),
              ],
            ),
          ],

          const SizedBox(height: 6),
          Text(
            // Penjelasan datang dari server: janji privasi hanya boleh punya
            // satu rumusan, dan rumusannya sama dengan yang ditegakkan API.
            contact.explanation,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.warmTextSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (contact.hasOpenRequest)
            OutlinedButton(
              onPressed: state.isSaving
                  ? null
                  : () => context.read<BerandaCubit>().cancelContactRequest(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.midnight,
                side: const BorderSide(color: AppColors.midnight, width: 1.5),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
              child: const Text('Batalkan permintaan',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )
          else
            ElevatedButton(
              onPressed: state.isSaving || !contact.canRequest
                  ? null
                  : () => context.read<BerandaCubit>().requestContact(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.midnight,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
              child: const Text('Minta dihubungi', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

/// Chip nama pembimbing — dipakai saat mahasiswa punya lebih dari satu.
class _AdvisorChip extends StatelessWidget {
  const _AdvisorChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_rounded, size: 13, color: AppColors.midnight),
          const SizedBox(width: 5),
          Text(
            name,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.midnight,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Pintasan lain
// ------------------------------------------------------------------

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 17,
        color: AppColors.midnight,
      ),
    );
  }
}

class _CategoriesRow extends StatelessWidget {
  const _CategoriesRow();

  @override
  Widget build(BuildContext context) {
    final categories = <_Category>[
      _Category(
        label: 'Riwayat',
        sub: 'Mood',
        icon: Icons.insights_rounded,
        background: AppColors.moodFearBg,
        onTap: () => MahasiswaShellPage.switchTab(context, 1),
      ),
      _Category(
        label: 'Refleksi',
        sub: 'Jurnal',
        icon: Icons.edit_note_rounded,
        background: AppColors.moodHappinessBg,
        onTap: () => MahasiswaShellPage.switchTab(context, 2),
      ),
      _Category(
        label: 'Skrining',
        sub: 'DASS-21',
        icon: Icons.assignment_turned_in_rounded,
        background: AppColors.lavenderBg,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const Dass21ScreeningPage()),
        ),
      ),
      _Category(
        label: 'Bantuan',
        sub: 'Darurat',
        icon: Icons.emergency_rounded,
        background: AppColors.moodAngerBg,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const BantuanDaruratPage()),
        ),
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (final category in categories)
          GestureDetector(
            onTap: category.onTap,
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: category.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.midnight, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cartoonShadow,
                        offset: Offset(0, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(category.icon, color: AppColors.midnight, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  category.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.midnight,
                  ),
                ),
                Text(
                  category.sub,
                  style: const TextStyle(fontSize: 11, color: AppColors.warmTextSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Category {
  const _Category({
    required this.label,
    required this.sub,
    required this.icon,
    required this.background,
    required this.onTap,
  });

  final String label;
  final String sub;
  final IconData icon;
  final Color background;
  final VoidCallback onTap;
}

class _Dass21Banner extends StatelessWidget {
  const _Dass21Banner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const Dass21ScreeningPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.lavenderBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.midnight, width: 1.8),
          boxShadow: const [
            BoxShadow(color: AppColors.cartoonShadow, offset: Offset(0, 4), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            const Dass21BannerIllustration(height: 70),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Skrining DASS-21',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.midnight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Skrining awal untuk depresi, kecemasan, dan stres. Bukan diagnosis.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.warmTextSecondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.midnight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mulai Skrining',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CopingRow extends StatelessWidget {
  const _CopingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CopingCard(
            title: 'Latihan Napas',
            subtitle: 'Relaksasi 4-7-8',
            icon: Icons.air_rounded,
            color: AppColors.moodFearBg,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const LatihanNapasPage()),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _CopingCard(
            title: 'Jurnal Refleksi',
            subtitle: 'Tulis yang kamu rasakan',
            icon: Icons.edit_note_rounded,
            color: AppColors.moodHappinessBg,
            onTap: () => MahasiswaShellPage.switchTab(context, 2),
          ),
        ),
      ],
    );
  }
}

class _CopingCard extends StatelessWidget {
  const _CopingCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.midnight, width: 1.5),
          boxShadow: const [
            BoxShadow(color: AppColors.cartoonShadow, offset: Offset(0, 4), blurRadius: 6),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.midnight, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.midnight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.warmTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: AppColors.ewsRisk),
              SizedBox(width: 8),
              Text(
                'Gagal memuat Beranda',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.midnight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message ?? 'Periksa koneksi internetmu lalu coba lagi.',
            style: const TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => context.read<BerandaCubit>().load(),
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
