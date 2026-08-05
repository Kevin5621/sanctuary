import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';

class RiwayatAnalisisPage extends StatelessWidget {
  const RiwayatAnalisisPage({super.key});

  final List<Map<String, dynamic>> _history = const [
    {
      'date': '5 Agu 2026',
      'time': '20:15',
      'mood': MoodType.fear,
      'emotion': 'Kecemasan Sedang (Anxiety)',
      'confidence': '88%',
      'summary': 'Tercatat ada tekanan deadline Tugas Akhir dan revisi bab 4.',
      'coping': 'Teknik Napas 4-7-8 & Istirahat 15 menit',
    },
    {
      'date': '3 Agu 2026',
      'time': '14:30',
      'mood': MoodType.happiness,
      'emotion': 'Perasaan Positif & Lega',
      'confidence': '94%',
      'summary': 'Diskusi bimbingan dosen berjalan lancar.',
      'coping': 'Pertahankan pola komunikasi positif',
    },
    {
      'date': '1 Agu 2026',
      'time': '21:00',
      'mood': MoodType.sadness,
      'emotion': 'Kelelahan Emosional (Burnout)',
      'confidence': '82%',
      'summary': 'Kurang tidur akibat pengerjaan tugas berturut-turut.',
      'coping': 'Tidur teratur min. 7 jam & jalan santai',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        title: const Text('Riwayat Analisis Emosi'),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          final MoodType mood = item['mood'] as MoodType;
          final String date = item['date'] as String;
          final String time = item['time'] as String;
          final String emotion = item['emotion'] as String;
          final String confidence = item['confidence'] as String;
          final String summary = item['summary'] as String;
          final String coping = item['coping'] as String;

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CartoonMoodBlob(mood: mood, size: 36),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              date,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.midnight),
                            ),
                            Text(
                              time,
                              style: const TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    WavyBadge(text: confidence, color: AppColors.lavenderBg),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: mood.bgColor,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.analytics_outlined, size: 18, color: AppColors.midnight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          emotion,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.midnight),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  summary,
                  style: const TextStyle(fontSize: 13, color: AppColors.midnight, height: 1.4),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.spa_outlined, size: 16, color: AppColors.moodDisgust),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Saran Coping: $coping',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warmTextSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
