import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class KaprodiPembimbingTab extends StatelessWidget {
  const KaprodiPembimbingTab({super.key});

  final List<Map<String, dynamic>> _advisors = const [
    {'name': 'Dr. Ir. Hendra Wijaya, M.T.', 'students': 25, 'riskCount': 2},
    {'name': 'Prof. Dr. Maya Putri, S.Kom., M.T.', 'students': 22, 'riskCount': 1},
    {'name': 'Dr. Ahmad Fauzi, M.Sc.', 'students': 28, 'riskCount': 4},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const Text(
              'Daftar Dosen Pembimbing',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: AppColors.midnight),
            ),
            const SizedBox(height: 2),
            const Text('Beban bimbingan & sebaran EWS per dosen', style: TextStyle(fontSize: 13, color: AppColors.warmTextSecondary)),
            const SizedBox(height: AppSpacing.lg),

            for (final adv in _advisors) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(adv['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.midnight)),
                        const SizedBox(height: 2),
                        Text('Total Bimbingan: ${adv['students']} Mhs', style: const TextStyle(fontSize: 12, color: AppColors.warmTextSecondary)),
                      ],
                    ),
                    Text(
                      '${adv['riskCount']} Risk',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ewsIntervention, fontSize: 13),
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
