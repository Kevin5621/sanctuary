import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';

/// Halaman Skrining DASS-21 (Depression Anxiety Stress Scale 21)
class Dass21ScreeningPage extends StatefulWidget {
  const Dass21ScreeningPage({super.key});

  @override
  State<Dass21ScreeningPage> createState() => _Dass21ScreeningPageState();
}

class _Dass21ScreeningPageState extends State<Dass21ScreeningPage> {
  final Map<int, int> _answers = {};
  bool _isSubmitted = false;

  final List<String> _questions = const [
    "1. Saya merasa sulit untuk menenangkan diri.",
    "2. Saya merasa mulut saya kering.",
    "3. Saya sama sekali tidak merasakan perasaan positif.",
    "4. Saya mengalami kesulitan bernapas (misal: napas cepat).",
    "5. Saya merasa sulit untuk berinisiatif melakukan sesuatu.",
    "6. Saya cenderung bereaksi berlebihan terhadap situasi.",
    "7. Saya merasakan gemetar (misal: pada tangan).",
    "8. Saya merasa menggunakan banyak energi untuk gelisah.",
    "9. Saya khawatir tentang situasi yang membuat saya panik.",
    "10. Saya merasa tidak ada hal yang dapat diharapkan.",
    "11. Saya merasa diri saya mudah gelisah.",
    "12. Saya merasa sulit untuk rileks.",
    "13. Saya merasa sedih dan tertekan.",
    "14. Saya tidak sabar dengan penundaan.",
    "15. Saya merasa hampir panik.",
    "16. Saya tidak dapat antusias terhadap apa pun.",
    "17. Saya merasa diri saya tidak berharga.",
    "18. Saya merasa agak tersinggung.",
    "19. Saya menyadari detak jantung saya tanpa aktivitas fisik.",
    "20. Saya merasa takut tanpa alasan yang jelas.",
    "21. Saya merasa hidup ini tidak berarti.",
  ];

  final List<String> _options = const [
    "Tidak Pernah (0)",
    "Kadang-kadang (1)",
    "Sering (2)",
    "Hampir Selalu (3)",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        title: const Text('Skrining DASS-21'),
        elevation: 0,
      ),
      body: _isSubmitted ? _buildResultView() : _buildQuestionnaireView(),
    );
  }

  Widget _buildQuestionnaireView() {
    final progress = _answers.length / _questions.length;

    return Column(
      children: [
        // Progress Bar Banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kemajuan: ${_answers.length} dari ${_questions.length} Soal',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  WavyBadge(text: '${(progress * 100).toInt()}% Selesai', color: AppColors.lavenderBg),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: AppColors.creamAlt,
                  color: AppColors.moodDisgust,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final selectedValue = _answers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _questions[index],
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.midnight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Column(
                      children: List.generate(4, (optIndex) {
                        final isSelected = selectedValue == optIndex;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _answers[index] = optIndex;
                            });
                          },
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.moodDisgustBg : AppColors.creamBg,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(
                                color: isSelected ? AppColors.moodDisgust : AppColors.cartoonBorder,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                  color: isSelected ? AppColors.midnight : AppColors.warmTextSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _options[optIndex],
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: AppColors.midnight,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Submit Button
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: AppColors.cartoonShadow, blurRadius: 10, offset: Offset(0, -4))
            ],
          ),
          child: ElevatedButton(
            onPressed: _answers.length == _questions.length
                ? () {
                    setState(() {
                      _isSubmitted = true;
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.midnight,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
            child: Text(
              _answers.length == _questions.length
                  ? 'Hitung Hasil Skrining'
                  : 'Lengkapi Semua Soal (${_answers.length}/${_questions.length})',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (AppSpacing.md * 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.midnight, width: 1.8),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cartoonShadow,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const CartoonMoodBlob(mood: MoodType.happiness, size: 90),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Hasil Skrining DASS-21 Anda',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.midnight),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Skrining ini digunakan untuk deteksi awal kondisi emosional.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.warmTextSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildScoreTile('Depresi', 'Ringan', '10 / 42', AppColors.moodHappinessBg, AppColors.moodHappiness),
                      const SizedBox(height: AppSpacing.sm),
                      _buildScoreTile('Kecemasan (Anxiety)', 'Sedang', '14 / 42', AppColors.moodAngerBg, AppColors.moodAnger),
                      const SizedBox(height: AppSpacing.sm),
                      _buildScoreTile('Stres', 'Normal', '8 / 42', AppColors.moodDisgustBg, AppColors.moodDisgust),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.lavenderBg,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.midnight, width: 1.2),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, color: AppColors.midnight),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Saran Coping: Cobalah latihan napas 4-7-8 atau ngobrol dengan Terapis AI jika merasa cemas.',
                                style: TextStyle(color: AppColors.midnight, fontSize: 13, height: 1.4, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isSubmitted = false;
                            _answers.clear();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.midnight,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                        ),
                        child: const Text('Isi Ulang Skrining', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreTile(String title, String level, String score, Color bgColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.midnight)),
              Text('Skor: $score', style: const TextStyle(color: AppColors.warmTextSecondary, fontSize: 12)),
            ],
          ),
          WavyBadge(text: level, color: accentColor, textColor: Colors.white),
        ],
      ),
    );
  }
}
