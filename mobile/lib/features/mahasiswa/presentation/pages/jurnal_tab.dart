import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../../../core/widgets/vector_illustrations.dart';
import 'latihan_napas_page.dart';
import 'mahasiswa_shell_page.dart';

class JurnalTab extends StatefulWidget {
  const JurnalTab({super.key});

  @override
  State<JurnalTab> createState() => _JurnalTabState();
}

class _JurnalTabState extends State<JurnalTab> {
  final TextEditingController _noteController = TextEditingController(
    text:
        'Hari ini bimbingan bab 4 terasa agak berat. Dosen minta banyak revisi metrik evaluasi. Rasanya agak cemas dan capek banget, pengen menyerah...',
  );
  DateTime _journalDate = DateTime.now();
  bool _isAnalyzing = false;
  bool _showAnalysisResult = true;
  bool _isCrisisDetected = true;
  bool _showCrisisCard = true;

  final List<String> _crisisKeywords = const [
    'menyerah',
    'bunuh diri',
    'tidak sanggup',
    'putus asa',
    'mati'
  ];

  void _checkCrisisKeywords(String text) {
    final lower = text.toLowerCase();
    final hasCrisis = _crisisKeywords.any((kw) => lower.contains(kw));
    setState(() {
      _isCrisisDetected = hasCrisis;
      if (hasCrisis) _showCrisisCard = true;
    });
  }

  void _runIndoBertAnalysis() {
    if (_noteController.text.trim().isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _showAnalysisResult = false;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
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
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Bar (Judul & Pemilih Tanggal)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jurnal Refleksi',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: AppColors.midnight,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_journalDate.day}/${_journalDate.month}/${_journalDate.year}',
                        style: const TextStyle(
                          color: AppColors.warmTextSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
                    icon: const Icon(Icons.calendar_today_rounded, size: 15),
                    label: const Text('Pilih Tanggal'),
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

              const SizedBox(height: AppSpacing.md),

              // 2. Alert Krisis Otomatis (Jika Terdeteksi Tekanan Berat)
              if (_isCrisisDetected && _showCrisisCard)
                CrisisAlertCardWidget(
                  message:
                      'Sistem mendeteksi tekanan emosional berat. Layanan konseling 24/7 selalu siap membantumu.',
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

              // 3. Card Menulis Jurnal (Ruang Refleksi Minimalis & Bersih)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.midnight, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.cartoonShadow,
                      offset: Offset(0, 4),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Refleksi Hari Ini',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.midnight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tuliskan pikiran atau perasaanmu secara bebas. Catatanmu bersifat privat.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warmTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _noteController,
                      maxLines: 6,
                      minLines: 4,
                      onChanged: _checkCrisisKeywords,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.midnight,
                        height: 1.45,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Apa yang kamu rasakan atau alami hari ini?...',
                        hintStyle: const TextStyle(color: AppColors.warmTextMuted, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.creamBg,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: const BorderSide(color: AppColors.cartoonBorder, width: 1.2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: const BorderSide(color: AppColors.cartoonBorder, width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          borderSide: const BorderSide(color: AppColors.midnight, width: 1.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Tombol Simpan & Analisis
                    ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _runIndoBertAnalysis,
                      icon: _isAnalyzing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                      label: Text(
                        _isAnalyzing ? 'Menganalisis Emosi...' : 'Analisis & Simpan Jurnal',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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

              // 4. Hasil Analisis IndoBERT (Tampilan Simplified & Tidak Crowded)
              if (_showAnalysisResult) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.moodFearBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.midnight, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.cartoonShadow,
                        offset: Offset(0, 4),
                        blurRadius: 8,
                      ),
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
                              const CartoonMoodBlob(mood: MoodType.fear, size: 44),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Hasil Analisis IndoBERT',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppColors.midnight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Emosi Dominan: Kecemasan (86%)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.midnight.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const WavyBadge(text: 'Cemas', color: Colors.white),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: AppColors.midnight.withValues(alpha: 0.2), width: 1),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, color: AppColors.midnight, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Catatanmu menunjukkan tekanan cemas. Cobalah rekomendasi relaksasi di bawah ini.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.midnight,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Rekomendasi Coping Cepat:',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.midnight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const LatihanNapasPage()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  border: Border.all(color: AppColors.midnight, width: 1.2),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.air_rounded, color: AppColors.midnight, size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Latihan Napas 4-7-8',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: AppColors.midnight,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                MahasiswaShellPage.switchTab(context, 3);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  border: Border.all(color: AppColors.midnight, width: 1.2),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.psychology_rounded, color: AppColors.midnight, size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Curhat Terapis AI',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: AppColors.midnight,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Floating Navbar spacing
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

