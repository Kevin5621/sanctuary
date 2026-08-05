import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../../../core/widgets/vector_illustrations.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/daily_metric_repository.dart';
import '../../domain/entities/daily_metric.dart';
import '../cubit/beranda_cubit.dart';
import 'dass21_screening_page.dart';
import 'latihan_napas_page.dart';
import 'mahasiswa_shell_page.dart';

class BerandaTab extends StatelessWidget {
  const BerandaTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BerandaCubit(context.read<DailyMetricRepository>())..load(),
      child: const _BerandaView(),
    );
  }
}

class _BerandaView extends StatefulWidget {
  const _BerandaView();

  @override
  State<_BerandaView> createState() => _BerandaViewState();
}

class _BerandaViewState extends State<_BerandaView> {
  static const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  MoodType? _selectedHeaderMood;

  final List<Map<String, dynamic>> _moodPills = const [
    {'mood': MoodType.happiness, 'label': 'Happy', 'emoji': '😄'},
    {'mood': MoodType.sadness, 'label': 'Sad', 'emoji': '😔'},
    {'mood': MoodType.fear, 'label': 'Fear', 'emoji': '😟'},
    {'mood': MoodType.anger, 'label': 'Anger', 'emoji': '😠'},
    {'mood': MoodType.disgust, 'label': 'Disgust', 'emoji': '😐'},
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    final firstName = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName.trim().split(RegExp(r'\s+')).first
        : 'Sahabat';

    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<BerandaCubit, BerandaState>(
          builder: (context, state) {
            final today = state.summary.today;

            return RefreshIndicator(
              color: AppColors.midnight,
              backgroundColor: Colors.white,
              onRefresh: () => context.read<BerandaCubit>().refresh(),
              child: Column(
                children: [
                  // 1. Dark Navy Top Header (Sesuai Referensi Gambar 1)
                  _buildHeader(context, firstName, today),

                  const SizedBox(height: 12),

                  // 2. Top-Rounded Content Sheet (Latar Krem Soft)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.creamBg,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Indicator Bar
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

                            // Kategori Fitur Utama (Circle Icon Buttons)
                            const Text(
                              'Kategori Fitur',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: AppColors.midnight,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildCategoriesRow(context),

                            const SizedBox(height: AppSpacing.lg),

                            // Status Loading / Failure / Content
                            if (state.status == BerandaStatus.loading || state.status == BerandaStatus.initial)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 48),
                                child: Center(
                                  child: CircularProgressIndicator(color: AppColors.midnight),
                                ),
                              )
                            else if (state.status == BerandaStatus.failure)
                              _buildErrorCard(context, state.errorMessage)
                            else ...[
                              // Ringkasan Hari Ini
                              _buildTodayCard(today),
                              const SizedBox(height: AppSpacing.lg),

                              // Kalender Mood Mingguan
                              const Text(
                                'Kalender Mood Mingguan',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.midnight,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _buildWeeklyCalendar(state.summary),
                            ],

                            const SizedBox(height: AppSpacing.lg),

                            // Rekomendasi Coping & Skrining
                            const Text(
                              'Rekomendasi Coping & Wellness',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: AppColors.midnight,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Banner Skrining DASS-21
                            _buildDass21Banner(context),

                            const SizedBox(height: AppSpacing.md),

                            // Grid Side-by-Side (Latihan Napas & Jurnal Refleksi)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCopingCard(
                                    title: 'Latihan Napas',
                                    subtitle: '4-7-8 Relaksasi 5 menit',
                                    icon: Icons.air_rounded,
                                    color: AppColors.moodFearBg,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const LatihanNapasPage()),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _buildCopingCard(
                                    title: 'Jurnal Refleksi',
                                    subtitle: 'Catat rasa syukurmu',
                                    icon: Icons.edit_note_rounded,
                                    color: AppColors.moodHappinessBg,
                                    onTap: () => MahasiswaShellPage.switchTab(context, 2),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 100),
                          ],
                        ),
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

  // --- Dark Navy Top Header (Sesuai Referensi Gambar 1) ---
  Widget _buildHeader(BuildContext context, String firstName, DailyMetric? today) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      child: Column(
        children: [
          // Top Navigation Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // User Profile Avatar & Name
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    firstName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              // Action Buttons (Mood Analytics & Calendar)
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      MahasiswaShellPage.switchTab(context, 1);
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.donut_large_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      MahasiswaShellPage.switchTab(context, 1);
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Central Meditation Icon & Greeting Title
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wb_twilight_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            '${_greeting()}!',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 26,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bagaimana harimu sejauh ini?',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 16),

          // Mood Check-in Selector Pills (Gambar 1 style)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _moodPills.map((item) {
                final mood = item['mood'] as MoodType;
                final label = item['label'] as String;
                final emoji = item['emoji'] as String;
                final isSelected = _selectedHeaderMood == mood;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedHeaderMood = mood;
                    });
                    // Simpan ke Backend secara real-time!
                    context.read<BerandaCubit>().logQuickMood(mood);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Mood $label $emoji berhasil disimpan ke server! ✨'),
                        duration: const Duration(seconds: 2),
                        action: SnackBarAction(
                          label: 'Detail',
                          textColor: AppColors.sunnyYellow,
                          onPressed: () {
                            MahasiswaShellPage.switchTab(context, 1);
                          },
                        ),
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? AppColors.midnight : Colors.white,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // --- Circle Categories Buttons (Gambar 1 style) ---
  Widget _buildCategoriesRow(BuildContext context) {
    final categories = [
      {
        'label': 'Relaksasi',
        'sub': 'Napas 4-7-8',
        'icon': Icons.air_rounded,
        'bg': AppColors.moodFearBg,
        'onTap': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LatihanNapasPage())),
      },
      {
        'label': 'Refleksi',
        'sub': 'Jurnal',
        'icon': Icons.edit_note_rounded,
        'bg': AppColors.moodHappinessBg,
        'onTap': () => MahasiswaShellPage.switchTab(context, 2),
      },
      {
        'label': 'Skrining',
        'sub': 'DASS-21',
        'icon': Icons.assignment_turned_in_rounded,
        'bg': AppColors.lavenderBg,
        'onTap': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Dass21ScreeningPage())),
      },
      {
        'label': 'Konsul AI',
        'sub': 'Terapis',
        'icon': Icons.psychology_rounded,
        'bg': AppColors.moodSadnessBg,
        'onTap': () => MahasiswaShellPage.switchTab(context, 3),
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: categories.map((cat) {
        return GestureDetector(
          onTap: cat['onTap'] as VoidCallback,
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: cat['bg'] as Color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.midnight, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.cartoonShadow,
                      offset: Offset(0, 4),
                      blurRadius: 6,
                    )
                  ],
                ),
                child: Icon(cat['icon'] as IconData, color: AppColors.midnight, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                cat['label'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.midnight,
                ),
              ),
              Text(
                cat['sub'] as String,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.warmTextSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- Banner DASS-21 ---
  Widget _buildDass21Banner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const Dass21ScreeningPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.lavenderBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.midnight, width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cartoonShadow,
              offset: Offset(0, 4),
              blurRadius: 8,
            )
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
                    'Ukur tingkat Depresi, Cemas & Stresmu secara akurat.',
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

  // --- Ringkasan Hari Ini ---
  Widget _buildTodayCard(DailyMetric? today) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cartoonShadow,
            offset: Offset(0, 4),
            blurRadius: 10,
          )
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
                text: today != null ? 'Tercatat Hari Ini' : 'Belum Check-in',
                color: today != null ? AppColors.moodDisgustBg : AppColors.creamAlt,
                borderColor: today != null ? AppColors.ewsNormal : AppColors.ewsInsufficient,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (today == null)
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
                  child: const Icon(Icons.bedtime_outlined, color: AppColors.warmTextMuted),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kamu belum check-in hari ini',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.midnight,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Isi mood, stres & tidurmu di menu Pelacak Mood.',
                        style: TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                CartoonMoodBlob(mood: _moodTypeFor(today), size: 54),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _todayHeadline(today),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.midnight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stres: ${today.stressLevel}/5 · Tidur: ${_formatHours(today.sleepHours)} jam',
                        style: const TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // --- Kalender Mood Mingguan ---
  Widget _buildWeeklyCalendar(WeeklyMoodSummary summary) {
    final weekStart = summary.weekStart;
    final now = DateTime.now();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dayLabels[index],
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: isToday ? AppColors.midnight : AppColors.warmTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  metric != null
                      ? CartoonMoodBlob(mood: _moodTypeFor(metric), size: 32)
                      : const _EmptyDayBlob(size: 32),
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

  Widget _buildErrorCard(BuildContext context, String? message) {
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
                'Gagal memuat ringkasan mood',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.midnight),
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

  Widget _buildCopingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.midnight, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cartoonShadow,
              offset: Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
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
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.warmTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Tampilan ---

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 19) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  String _todayHeadline(DailyMetric today) {
    final trigger = _prettifyTrigger(today.academicTrigger);
    final label = today.emotionLabelText.isNotEmpty ? today.emotionLabelText : 'Mood ${today.moodScore}/5';
    return trigger.isEmpty ? label : '$label ($trigger)';
  }

  String _prettifyTrigger(String raw) {
    if (raw.isEmpty) return '';
    return raw
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0]}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _formatHours(double hours) =>
      hours == hours.roundToDouble() ? hours.toStringAsFixed(0) : hours.toStringAsFixed(1);

  MoodType _moodTypeFor(DailyMetric metric) {
    switch (metric.emotionLabel) {
      case 'ANXIOUS':
        return MoodType.fear;
      case 'SAD':
        return MoodType.sadness;
      case 'ANGRY':
        return MoodType.anger;
      case 'TIRED':
      case 'NEUTRAL':
        return MoodType.disgust;
      case 'CALM':
      case 'JOY':
        return MoodType.happiness;
    }
    if (metric.moodScore >= 4) return MoodType.happiness;
    if (metric.moodScore == 3) return MoodType.disgust;
    if (metric.moodScore == 2) return MoodType.fear;
    return MoodType.sadness;
  }
}

class _EmptyDayBlob extends StatelessWidget {
  const _EmptyDayBlob({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.creamAlt,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Icon(Icons.horizontal_rule_rounded, size: size * 0.5, color: AppColors.warmTextMuted),
    );
  }
}
