import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';

class BantuanDaruratPage extends StatelessWidget {
  const BantuanDaruratPage({super.key});

  final List<Map<String, String>> _contacts = const [
    {
      'title': 'Hotline Kesehatan Mental RI (119 Ext 8)',
      'number': '119-8',
      'desc': 'Layanan pencegahan krisis & konsultasi gratis Kemenkes RI 24 jam.',
      'status': 'Aktif 24 Jam',
    },
    {
      'title': 'Layanan Konseling Kemahasiswaan Kampus',
      'number': '0812-3456-7890',
      'desc': 'Unit layanan bimbingan konseling akademik & kesehatan jiwa mahasiswa.',
      'status': 'Senin - Jumat (08:00 - 16:00)',
    },
    {
      'title': 'Yayasan Pulih (Konseling Psikologi)',
      'number': '021-78842580',
      'desc': 'Layanan pemulihan trauma dan konseling kesehatan mental.',
      'status': 'Aktif',
    },
    {
      'title': 'Into The Light Indonesia',
      'number': 'pendampingan@intothelightid.org',
      'desc': 'Pendampingan pencegahan bunuh diri dan edukasi kesehatan jiwa.',
      'status': 'Aktif',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        title: const Text('Layanan Bantuan Darurat'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.moodAngerBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.ewsIntervention, width: 1.5),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_rounded, color: AppColors.ewsIntervention, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Jika kamu atau orang yang kamu kenal membutuhkan bantuan segera, hubungi kontak darurat di bawah ini.',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.midnight, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final contact in _contacts) ...[
            Container(
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
                      Expanded(
                        child: Text(
                          contact['title']!,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.midnight),
                        ),
                      ),
                      WavyBadge(text: contact['status']!, color: AppColors.moodDisgustBg),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    contact['desc']!,
                    style: const TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Menghubungi ${contact['number']}...')),
                      );
                    },
                    icon: const Icon(Icons.phone, size: 18),
                    label: Text('Panggil ${contact['number']}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.midnight,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
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
    );
  }
}
