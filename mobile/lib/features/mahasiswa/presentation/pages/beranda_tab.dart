import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../../../core/widgets/vector_illustrations.dart';

class BerandaTab extends StatelessWidget {
  const BerandaTab({super.key});

  @override
  Widget build(BuildContext context) {
    final days = [
      {'day': 'Sen', 'date': '3', 'mood': MoodType.happiness, 'selected': false},
      {'day': 'Sel', 'date': '4', 'mood': MoodType.disgust, 'selected': false},
      {'day': 'Rab', 'date': '5', 'mood': MoodType.fear, 'selected': true},
      {'day': 'Kam', 'date': '6', 'mood': MoodType.sadness, 'selected': false},
      {'day': 'Jum', 'date': '7', 'mood': MoodType.anger, 'selected': false},
      {'day': 'Sab', 'date': '8', 'mood': MoodType.happiness, 'selected': false},
      {'day': 'Min', 'date': '9', 'mood': MoodType.happiness, 'selected': false},
    ];

    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Sapaan Bernama
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Selamat Pagi, Charlie! ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              color: AppColors.midnight,
                            ),
                          ),
                          const Text('👋', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Bagaimana perasaanmu hari ini?',
                        style: TextStyle(
                          color: AppColors.warmTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.moodHappinessBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.midnight, width: 1.5),
                    ),
                    child: const Center(
                      child: Text('😊', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // 2. Ringkasan Kondisi Hari Ini (Today's Condition Summary Card)
              Container(
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
                          text: 'EWS: Normal',
                          color: AppColors.moodDisgustBg,
                          borderColor: AppColors.moodDisgust,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Row(
                      children: [
                        CartoonMoodBlob(mood: MoodType.fear, size: 54),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cemas Ringan (Tugas Akhir)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.midnight,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Stres: 2/5 · Tidur: 7.5 jam',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.warmTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 3. Kalender Mood Mingguan (Weekly Mood Calendar)
              const Text(
                'Kalender Mood Mingguan',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.midnight,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 105,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final item = days[index];
                    final isSelected = item['selected'] as bool;
                    final mood = item['mood'] as MoodType;

                    return Container(
                      width: 58,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.moodFearBg : Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: isSelected ? AppColors.midnight : AppColors.cartoonBorder,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['day'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: isSelected ? AppColors.midnight : AppColors.warmTextSecondary,
                            ),
                          ),
                          CartoonMoodBlob(mood: mood, size: 36),
                          Text(
                            item['date'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppColors.midnight,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 4. Pintasan menuju Skrining DASS-21 (Shortcut to DASS-21 Screening)
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const _Dass21Wrapper()),
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
                              'Ukur tingkat Depresi, Cemas & Stresmu sekarang.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.warmTextSecondary,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              ),

              const SizedBox(height: AppSpacing.lg),

              // 5. Tips Coping & Inspirasi Hari Ini
              const Text(
                'Rekomendasi Coping Hari Ini',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.midnight,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildCopingCard(
                      title: 'Latihan Napas 4-7-8',
                      subtitle: '5 menit relaksasi',
                      icon: Icons.air_rounded,
                      color: AppColors.moodFearBg,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildCopingCard(
                      title: 'Jurnal Refleksi',
                      subtitle: 'Tulis hal yang disyukuri',
                      icon: Icons.edit_note_rounded,
                      color: AppColors.moodHappinessBg,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCopingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.midnight, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
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
    );
  }
}

class _Dass21Wrapper extends StatelessWidget {
  const _Dass21Wrapper();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: SizedBox.expand(
          child: Column(
            children: [
              Expanded(child: PlaceholderScreen(title: 'DASS-21 Screening')),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Page $title')),
    );
  }
}
