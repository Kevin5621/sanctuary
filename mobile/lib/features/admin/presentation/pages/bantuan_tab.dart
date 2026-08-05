import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';

class AdminBantuanTab extends StatefulWidget {
  const AdminBantuanTab({super.key});

  @override
  State<AdminBantuanTab> createState() => _AdminBantuanTabState();
}

class _AdminBantuanTabState extends State<AdminBantuanTab> {
  final List<Map<String, dynamic>> _services = [
    {
      'id': '1',
      'title': 'Hotline Kesehatan Mental Kemenkes RI',
      'phone': '119 Ext 8',
      'desc': 'Layanan pencegahan krisis gratis 24 jam.',
      'is24h': true,
      'isActive': true,
      'order': 1,
    },
    {
      'id': '2',
      'title': 'Unit Konseling Kampus',
      'phone': '0812-3456-7890',
      'desc': 'Layanan bimbingan konseling akademik.',
      'is24h': false,
      'isActive': true,
      'order': 2,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kelola Layanan Bantuan',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: AppColors.midnight),
                    ),
                    Text(
                      'Peran: Admin Sistem',
                      style: TextStyle(fontSize: 13, color: AppColors.warmTextSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tambah Layanan Bantuan Baru')),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.midnight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusPill)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            for (final s in _services) ...[
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
                            s['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.midnight),
                          ),
                        ),
                        Switch(
                          value: s['isActive'] as bool,
                          activeThumbColor: AppColors.midnight,
                          onChanged: (val) {
                            setState(() {
                              s['isActive'] = val;
                            });
                          },
                        ),
                      ],
                    ),
                    Text('Telepon: ${s['phone']}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.warmTextSecondary, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(s['desc'] as String, style: const TextStyle(fontSize: 12, color: AppColors.warmTextSecondary)),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        WavyBadge(text: s['is24h'] as bool ? '24 Jam' : 'Jam Kerja', color: AppColors.moodFearBg),
                        const SizedBox(width: 8),
                        WavyBadge(text: 'Urutan: ${s['order']}', color: AppColors.creamAlt),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
