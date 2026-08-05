import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class LatihanNapasPage extends StatefulWidget {
  const LatihanNapasPage({super.key});

  @override
  State<LatihanNapasPage> createState() => _LatihanNapasPageState();
}

class _LatihanNapasPageState extends State<LatihanNapasPage> {
  bool _isRunning = false;
  String _phase = 'Tekan Mulai'; // Tarik Napas (4s), Tahan (7s), Hembuskan (8s)
  int _secondsLeft = 4;
  Timer? _timer;
  int _cycleCount = 0;

  void _startExercise() {
    setState(() {
      _isRunning = true;
      _cycleCount = 0;
    });
    _runPhase('Tarik Napas (Hidung)', 4, () {
      _runPhase('Tahan Napas', 7, () {
        _runPhase('Hembuskan Perlahan (Mulut)', 8, () {
          setState(() {
            _cycleCount++;
          });
          if (_isRunning) {
            _startExercise();
          }
        });
      });
    });
  }

  void _runPhase(String title, int duration, VoidCallback onComplete) {
    if (!_isRunning) return;
    setState(() {
      _phase = title;
      _secondsLeft = duration;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isRunning) {
        timer.cancel();
        return;
      }
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
        onComplete();
      }
    });
  }

  void _stopExercise() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _phase = 'Selesai / Tekan Mulai';
      _secondsLeft = 4;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        title: const Text('Latihan Napas 4-7-8'),
        elevation: 0,
      ),
      body: LayoutBuilder(
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
                      border: Border.all(color: AppColors.midnight, width: 1.5),
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
                        const Text(
                          'Teknik Relaksasi Napas 4-7-8',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.midnight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Siklus Selesai: $_cycleCount',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.warmTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Animated Breathing Circle
                        AnimatedContainer(
                          duration: Duration(seconds: _secondsLeft),
                          width: _isRunning && _phase.startsWith('Tarik') ? 180 : 130,
                          height: _isRunning && _phase.startsWith('Tarik') ? 180 : 130,
                          decoration: BoxDecoration(
                            color: _phase.startsWith('Tarik')
                                ? AppColors.moodFearBg
                                : (_phase.startsWith('Tahan')
                                    ? AppColors.moodDisgustBg
                                    : AppColors.moodSadnessBg),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.midnight, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.cartoonShadow,
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$_secondsLeft',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 38,
                                    color: AppColors.midnight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Detik',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warmTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          _phase,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.midnight,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton(
                          onPressed: _isRunning ? _stopExercise : _startExercise,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isRunning ? AppColors.ewsIntervention : AppColors.midnight,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                          ),
                          child: Text(
                            _isRunning ? 'Hentikan Latihan' : 'Mulai Latihan Napas',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Card Petunjuk Grounding 5-4-3-2-1 (Diperbaiki Kontras & Visibilitas Teks)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.creamAlt,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.midnight, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cartoonShadow,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Petunjuk Grounding 5-4-3-2-1:',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.midnight,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• 5 Hal yang bisa kamu LIHAT di sekitarmu.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.midnight,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        Text(
                          '• 4 Hal yang bisa kamu SENTUH.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.midnight,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        Text(
                          '• 3 Hal yang bisa kamu DENGAR.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.midnight,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        Text(
                          '• 2 Hal yang bisa kamu CIUM aromanya.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.midnight,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        Text(
                          '• 1 Hal positif tentang dirimu.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.midnight,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
