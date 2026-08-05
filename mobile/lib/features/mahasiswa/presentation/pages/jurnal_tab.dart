import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../../../core/widgets/vector_illustrations.dart';

class JurnalTab extends StatefulWidget {
  const JurnalTab({super.key});

  @override
  State<JurnalTab> createState() => _JurnalTabState();
}

class _JurnalTabState extends State<JurnalTab> {
  final TextEditingController _noteController = TextEditingController(
    text: 'Hari ini bimbingan bab 4 terasa agak berat. Dosen minta banyak revisi metrik evaluasi. Rasanya agak cemas dan capek banget, pengen menyerah...',
  );
  DateTime _journalDate = DateTime.now();
  bool _isAnalyzing = false;
  bool _showAnalysisResult = true;
  bool _isCrisisDetected = true; // Auto crisis detection demo state
  bool _showCrisisCard = true;

  final List<String> _crisisKeywords = const ['menyerah', 'bunuh diri', 'tidak sanggup', 'putus asa', 'mati'];

  void _checkCrisisKeywords(String text) {
    final lower = text.toLowerCase();
    final hasCrisis = _crisisKeywords.any((kw) => lower.contains(kw));
    setState(() {
      _isCrisisDetected = hasCrisis;
      if (hasCrisis) _showCrisisCard = true;
    });
  }

  void _runIndoBertAnalysis() {
    setState(() {
      _isAnalyzing = true;
      _showAnalysisResult = false;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _showAnalysisResult = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

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
              // Header & Backdate Picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jurnal Refleksi',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: AppColors.midnight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tanggal: ${_journalDate.day}/${_journalDate.month}/${_journalDate.year}',
                        style: const TextStyle(
                          color: AppColors.warmTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _journalDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _journalDate = date;
                        });
                      }
                    },
                    icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                    label: const Text('Tanggal Mundur'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.midnight,
                      side: const BorderSide(color: AppColors.midnight, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Kartu Bantuan Krisis Otomatis (Auto Crisis Detection Card)
              if (_isCrisisDetected && _showCrisisCard)
                CrisisAlertCardWidget(
                  message: 'Sistem mendeteksi kata kunci tekanan emosional ("menyerah/putus asa"). Layanan konseling 24/7 selalu siap mendampingimu.',
                  onCallHotline: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Menghubungi Hotline 119 Ext 8...')),
                    );
                  },
                  onDismiss: () {
                    setState(() {
                      _showCrisisCard = false;
                    });
                  },
                ),

              // 1. Text Area Catatan Bebas
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
                    const Text(
                      'Tulis Catatan Jurnal Bebas',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.midnight),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _noteController,
                      maxLines: 5,
                      onChanged: _checkCrisisKeywords,
                      decoration: const InputDecoration(
                        hintText: 'Tuliskan pikiran, perasaan, atau peristiwa hari ini...',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Tombol Analisis Emosi (IndoBERT)
                    ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _runIndoBertAnalysis,
                      icon: _isAnalyzing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                      label: Text(
                        _isAnalyzing ? 'Menganalisis dengan IndoBERT...' : 'Analisis Emosi (IndoBERT)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.midnight,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 2. Hasil Analisis Emosi & Coping Recommendation
              if (_showAnalysisResult) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.moodFearBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.midnight, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              CartoonMoodBlob(mood: MoodType.fear, size: 42),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hasil Analisis IndoBERT',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.midnight),
                                  ),
                                  Text(
                                    'Emosi Utama: Kecemasan (Fear) - 86%',
                                    style: TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          WavyBadge(text: 'Kecemasan', color: Colors.white),
                        ],
                      ),
                      const Divider(height: 24),
                      const Text(
                        'Saran Latihan Coping Terdeteksi:',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.midnight),
                      ),
                      const SizedBox(height: 8),
                      _buildCopingRecommendationTile(
                        icon: Icons.air_rounded,
                        title: '1. Latihan Napas 4-7-8 (5 Menit)',
                        desc: 'Menurunkan frekuensi detak jantung dan meredakan rasa cemas akibat deadline.',
                      ),
                      const SizedBox(height: 8),
                      _buildCopingRecommendationTile(
                        icon: Icons.self_improvement_rounded,
                        title: '2. Grounding 5-4-3-2-1',
                        desc: 'Fokuskan pikiran pada 5 objek fisik di sekitarmu untuk mengurai kelelahan emosional.',
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

  Widget _buildCopingRecommendationTile({required IconData icon, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.cartoonBorder, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.midnight, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.midnight)),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.warmTextSecondary, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
