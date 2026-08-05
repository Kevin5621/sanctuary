import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cartoon_mood_blob.dart';
import '../../data/repositories/daily_metric_repository.dart';


class MoodTab extends StatefulWidget {
  const MoodTab({super.key});

  @override
  State<MoodTab> createState() => _MoodTabState();
}

class _MoodTabState extends State<MoodTab> {
  MoodType _selectedMood = MoodType.happiness;
  double _stressLevel = 2.0; // 1 to 5
  double _sleepHours = 7.5; // 0 to 12
  DateTime _selectedDate = DateTime.now();
  final Set<String> _selectedTriggers = {'Tugas Akhir', 'Dosen Pembimbing'};

  final List<String> _triggersList = const [
    'Tugas Akhir',
    'Ujian / UTS / UAS',
    'Presentasi',
    'Dosen Pembimbing',
    'Jadwal Kuliah',
    'Keuangan',
    'Relasi Pertemanan',
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
              // Header & Pemilih Tanggal Backfill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pelacak Mood',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: AppColors.midnight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tanggal: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(
                          color: AppColors.warmTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: const Text('Isi Terlewat'),
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

              // 1. Section Check-In Harian
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
                      '1. Tingkat Mood',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.midnight),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: MoodType.values.map((m) {
                          final isSel = _selectedMood == m;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: CartoonMoodBlob(
                              mood: m,
                              size: 58,
                              isSelected: isSel,
                              showBadge: true,
                              onTap: () {
                                setState(() {
                                  _selectedMood = m;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const Divider(height: 28),

                    // Tingkat Stres (1-5)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '2. Tingkat Stres',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.midnight),
                        ),
                        WavyBadge(
                          text: '${_stressLevel.toInt()}/5 (${_stressLevel <= 2 ? "Rendah" : "Tinggi"})',
                          color: _stressLevel <= 2 ? AppColors.moodDisgustBg : AppColors.moodAngerBg,
                        ),
                      ],
                    ),
                    Slider(
                      value: _stressLevel,
                      min: 1.0,
                      max: 5.0,
                      divisions: 4,
                      activeColor: AppColors.midnight,
                      inactiveColor: AppColors.creamAlt,
                      onChanged: (val) {
                        setState(() {
                          _stressLevel = val;
                        });
                      },
                    ),

                    const Divider(height: 28),

                    // Jam Tidur
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '3. Durasi Tidur',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.midnight),
                        ),
                        WavyBadge(
                          text: '${_sleepHours.toStringAsFixed(1)} Jam',
                          color: AppColors.moodFearBg,
                        ),
                      ],
                    ),
                    Slider(
                      value: _sleepHours,
                      min: 0.0,
                      max: 12.0,
                      divisions: 24,
                      activeColor: AppColors.midnight,
                      inactiveColor: AppColors.creamAlt,
                      onChanged: (val) {
                        setState(() {
                          _sleepHours = val;
                        });
                      },
                    ),

                    const Divider(height: 28),

                    // Faktor Pemicu Akademik
                    const Text(
                      '4. Faktor Pemicu Akademik',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.midnight),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _triggersList.map((trigger) {
                        final isSel = _selectedTriggers.contains(trigger);
                        return FilterChip(
                          selected: isSel,
                          label: Text(trigger),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.midnight,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          selectedColor: AppColors.midnight,
                          backgroundColor: AppColors.creamBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                            side: const BorderSide(color: AppColors.cartoonBorder, width: 1),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTriggers.add(trigger);
                              } else {
                                _selectedTriggers.remove(trigger);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    ElevatedButton(
                      onPressed: () async {
                        final (score, label) = switch (_selectedMood) {
                          MoodType.happiness => (5, 'JOY'),
                          MoodType.disgust => (3, 'NEUTRAL'),
                          MoodType.fear => (2, 'ANXIOUS'),
                          MoodType.anger => (2, 'ANGRY'),
                          MoodType.sadness => (1, 'SAD'),
                        };

                        final trigger = _selectedTriggers.isNotEmpty ? _selectedTriggers.first : '';
                        final dateStr =
                            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

                        try {
                          await context.read<DailyMetricRepository>().saveDailyMetric(
                                moodScore: score,
                                stressLevel: _stressLevel.toInt(),
                                sleepHours: _sleepHours,
                                emotionLabel: label,
                                academicTrigger: trigger,
                                metricDate: dateStr,
                              );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Check-in mood berhasil disimpan ke server! ✨')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal menyimpan check-in: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.midnight,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                      child: const Text('Simpan Check-In Hari Ini', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 2. Grafik Ritme Mood (Mood Rhythm Curve Chart)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.cartoonBorder, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grafik Ritme Mood Mingguan',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.midnight),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tren mood 7 hari terakhir',
                      style: TextStyle(color: AppColors.warmTextSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 180,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  const titles = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                                  if (val.toInt() >= 0 && val.toInt() < titles.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(titles[val.toInt()], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 4),
                                FlSpot(1, 2),
                                FlSpot(2, 3),
                                FlSpot(3, 1),
                                FlSpot(4, 5),
                                FlSpot(5, 4),
                                FlSpot(6, 5),
                              ],
                              isCurved: true,
                              color: AppColors.midnight,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.moodHappinessBg.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 3. Sebaran Emosi (Emotion Distribution Breakdown)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.cartoonBorder, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sebaran Emosi',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.midnight),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildEmotionProgress('Bahagia (Happiness)', 0.45, AppColors.moodHappiness),
                    const SizedBox(height: 8),
                    _buildEmotionProgress('Cemas (Fear)', 0.25, AppColors.moodFear),
                    const SizedBox(height: 8),
                    _buildEmotionProgress('Jijik/Apatis (Disgust)', 0.15, AppColors.moodDisgust),
                    const SizedBox(height: 8),
                    _buildEmotionProgress('Sedih (Sadness)', 0.10, AppColors.moodSadness),
                    const SizedBox(height: 8),
                    _buildEmotionProgress('Marah (Anger)', 0.05, AppColors.moodAnger),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionProgress(String label, double pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.midnight)),
            Text('${(pct * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.midnight)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppColors.creamAlt,
            color: color,
          ),
        ),
      ],
    );
  }
}
