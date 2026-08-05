import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';

class DosenBimbinganTab extends StatelessWidget {
  const DosenBimbinganTab({super.key});

  final List<Map<String, dynamic>> _students = const [
    {
      'name': 'Budi Santoso',
      'nim': '22010145',
      'ews': 'RISK',
      'ewsLabel': 'Perlu Perhatian (Risk)',
      'color': AppColors.ewsRisk,
      'bgColor': AppColors.moodAngerBg,
      'requestContact': true,
      'lastCheckin': 'Hari ini',
    },
    {
      'name': 'Charlie Pratama',
      'nim': '22010198',
      'ews': 'WATCH',
      'ewsLabel': 'Pantau (Watch)',
      'color': AppColors.ewsWatch,
      'bgColor': AppColors.moodFearBg,
      'requestContact': false,
      'lastCheckin': 'Kemarin',
    },
    {
      'name': 'Siti Rahma',
      'nim': '22010210',
      'ews': 'NORMAL',
      'ewsLabel': 'Normal',
      'color': AppColors.ewsNormal,
      'bgColor': AppColors.moodDisgustBg,
      'requestContact': false,
      'lastCheckin': '3 hari lalu',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daftar Bimbingan',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: AppColors.midnight),
                      ),
                      Text(
                        'Peran: Dosen Pembimbing Akademik',
                        style: TextStyle(fontSize: 13, color: AppColors.warmTextSecondary),
                      ),
                    ],
                  ),
                  WavyBadge(text: '3 Mahasiswa', color: AppColors.lavenderBg),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              for (final st in _students) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.cartoonBorder, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: AppColors.cartoonShadow, blurRadius: 8, offset: Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: st['bgColor'] as Color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.midnight, width: 1.5),
                                ),
                                child: const Center(
                                  child: Text('👨‍🎓', style: TextStyle(fontSize: 20)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    st['name'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.midnight),
                                  ),
                                  Text(
                                    'NIM: ${st['nim']} · Check-in: ${st['lastCheckin']}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          WavyBadge(
                            text: st['ewsLabel'] as String,
                            color: (st['color'] as Color).withValues(alpha: 0.2),
                            borderColor: st['color'] as Color,
                            textColor: AppColors.midnight,
                          ),
                          const SizedBox(width: 8),
                          if (st['requestContact'] as bool)
                            const WavyBadge(
                              text: '🚨 Minta Dihubungi',
                              color: AppColors.moodAngerBg,
                              borderColor: AppColors.ewsIntervention,
                              textColor: AppColors.ewsIntervention,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Mengirim undangan bimbingan ke ${st['name']}')),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                        label: const Text('Hubungi Mahasiswa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.midnight,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
