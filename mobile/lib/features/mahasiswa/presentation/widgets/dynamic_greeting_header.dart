import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/beranda_cubit.dart';

/// Fase waktu dalam sehari
enum TimeOfDayPhase { pagi, siang, sore, malam }

/// Header Greeting Dinamis bergaya **Modern Minimalism**.
/// Mengedepankan ruang bernapas (whitespace), tipografi bersih, dan latar atmosferik
/// yang tenang tanpa elemen visual yang menumpuk.
class DynamicGreetingHeader extends StatefulWidget {
  const DynamicGreetingHeader({
    super.key,
    required this.firstName,
    required this.state,
  });

  final String firstName;
  final BerandaState state;

  static TimeOfDayPhase get currentPhase {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return TimeOfDayPhase.pagi;
    if (hour >= 11 && hour < 15) return TimeOfDayPhase.siang;
    if (hour >= 15 && hour < 19) return TimeOfDayPhase.sore;
    return TimeOfDayPhase.malam;
  }

  static Color getScaffoldColor(TimeOfDayPhase phase) {
    return _TimePhaseConfig.forPhase(phase).frontHillsColor;
  }

  @override
  State<DynamicGreetingHeader> createState() => _DynamicGreetingHeaderState();
}

class _DynamicGreetingHeaderState extends State<DynamicGreetingHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = DynamicGreetingHeader.currentPhase;
    final config = _TimePhaseConfig.forPhase(phase);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      width: double.infinity,
      child: Stack(
        children: [
          // Latar Belakang Gradient Atmosferik & Lukisan Bukit Minimalis
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ModernMinimalistBackgroundPainter(
                    progress: _animController.value,
                    phase: phase,
                    config: config,
                  ),
                );
              },
            ),
          ),

          // Konten Header Minimalis & Airy
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              12,
              AppSpacing.md,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris Atas: Profil & Streak Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white38, width: 1.2),
                          ),
                          child: Center(
                            child: Text(
                              widget.firstName.isNotEmpty
                                  ? widget.firstName[0].toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.firstName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: 0.2,
                              ),
                            ),
                            Text(
                              config.atmosphereTag,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (widget.state.summary.currentStreak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusPill),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: AppColors.sunnyYellow,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.state.summary.currentStreak} hari',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),

                // Greeting & Subtitle Bersih & Spacious
                Center(
                  child: Column(
                    children: [
                      Text(
                        '${config.greeting}!',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                          color: Colors.white,
                          letterSpacing: -0.4,
                          shadows: [
                            Shadow(
                              color: Colors.black12,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.state.hasCheckedInToday
                            ? config.subtitleCheckedIn
                            : config.subtitleDefault,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Konfigurasi Atmosfer Waktu Modern Minimalism
// ------------------------------------------------------------------

class _TimePhaseConfig {
  const _TimePhaseConfig({
    required this.greeting,
    required this.atmosphereTag,
    required this.subtitleDefault,
    required this.subtitleCheckedIn,
    required this.backgroundGradient,
    required this.backHillsColor,
    required this.frontHillsColor,
  });

  final String greeting;
  final String atmosphereTag;
  final String subtitleDefault;
  final String subtitleCheckedIn;
  final LinearGradient backgroundGradient;
  final Color backHillsColor;
  final Color frontHillsColor;

  factory _TimePhaseConfig.forPhase(TimeOfDayPhase phase) {
    switch (phase) {
      case TimeOfDayPhase.pagi:
        return const _TimePhaseConfig(
          greeting: 'Selamat Pagi',
          atmosphereTag: 'Pagi Cerah',
          subtitleDefault: 'Semangat menyambut hari baru yang penuh harapan.',
          subtitleCheckedIn: 'Terima kasih sudah check-in pagi ini.',
          backgroundGradient: LinearGradient(
            colors: [
              Color(0xFF4A6572), // Soft Blue Steel
              Color(0xFF8E24AA), // Elegant Soft Violet
              Color(0xFFE57373), // Soft Rose Sunset
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          backHillsColor: Color(0x66AB47BC),
          frontHillsColor: Color(0xFF8E24AA),
        );
      case TimeOfDayPhase.siang:
        return const _TimePhaseConfig(
          greeting: 'Selamat Siang',
          atmosphereTag: 'Siang Cerah',
          subtitleDefault: 'Tetap semangat dan jaga energi positifmu ya!',
          subtitleCheckedIn: 'Terima kasih sudah check-in siang ini.',
          backgroundGradient: LinearGradient(
            colors: [
              Color(0xFF0288D1), // Deep Azure Sky
              Color(0xFF29B6F6), // Bright Sky
              Color(0xFF80DEEA), // Soft Cyan
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          backHillsColor: Color(0x664DD0E1),
          frontHillsColor: Color(0xFF0288D1),
        );
      case TimeOfDayPhase.sore:
        return const _TimePhaseConfig(
          greeting: 'Selamat Sore',
          atmosphereTag: 'Senja Calm',
          subtitleDefault: 'Waktunya bersantai sejenak setelah beraktivitas.',
          subtitleCheckedIn: 'Terima kasih sudah check-in sore ini.',
          backgroundGradient: LinearGradient(
            colors: [
              Color(0xFF3B1F50), // Deep Purple
              Color(0xFF6A1B9A), // Royal Violet
              Color(0xFFFF7043), // Soft Warm Coral
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          backHillsColor: Color(0x668E24AA),
          frontHillsColor: Color(0xFF3B1F50),
        );
      case TimeOfDayPhase.malam:
        return const _TimePhaseConfig(
          greeting: 'Selamat Malam',
          atmosphereTag: 'Malam Berbintang',
          subtitleDefault: 'Istirahatlah yang cukup dan tenangkan pikiranmu.',
          subtitleCheckedIn: 'Terima kasih sudah check-in malam ini.',
          backgroundGradient: LinearGradient(
            colors: [
              Color(0xFF0B0F19), // Deep Midnight
              Color(0xFF161936), // Calm Indigo
              Color(0xFF282C54), // Twilight Slate
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          backHillsColor: Color(0x553730A3),
          frontHillsColor: Color(0xFF0B0F19),
        );
    }
  }
}

// ------------------------------------------------------------------
// Modern Minimalist Background Painter
// ------------------------------------------------------------------

class _ModernMinimalistBackgroundPainter extends CustomPainter {
  _ModernMinimalistBackgroundPainter({
    required this.progress,
    required this.phase,
    required this.config,
  });

  final double progress;
  final TimeOfDayPhase phase;
  final _TimePhaseConfig config;

  static const List<_StarSpec> _stars = [
    _StarSpec(0.12, 0.15, 2.0, 0.0, 0.85),
    _StarSpec(0.25, 0.28, 1.6, 1.2, 0.7),
    _StarSpec(0.38, 0.12, 2.4, 2.4, 0.9),
    _StarSpec(0.55, 0.22, 1.8, 0.6, 0.75),
    _StarSpec(0.72, 0.18, 2.2, 3.1, 0.85),
    _StarSpec(0.88, 0.25, 1.5, 1.8, 0.7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Langit Gradient
    final skyPaint = Paint()
      ..shader = config.backgroundGradient.createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // 2. Bintang Berkelap-Kelip (Khusus Malam - Sangat Halus)
    if (phase == TimeOfDayPhase.malam) {
      final starPaint = Paint()..style = PaintingStyle.fill;
      for (final star in _stars) {
        final center = Offset(star.x * size.width, star.y * size.height);
        final cycle = math.sin((progress * math.pi * 2) + star.phaseOffset);
        final opacity = ((cycle + 1) / 2) * (star.maxOpacity - 0.2) + 0.2;

        starPaint.color = Colors.white.withValues(alpha: opacity);
        canvas.drawCircle(center, star.size, starPaint);
      }
    }

    // 3. Ambient Glow Aura Matahari/Bulan (Di Pojok Kanan Atas, Tidak Menumpuk Teks)
    final pulse = math.sin(progress * math.pi * 2);
    final glowCenter = Offset(size.width * 0.82, size.height * 0.25);
    const glowRadius = 60.0;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.25 + (pulse * 0.05)),
          Colors.white.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: glowCenter, radius: glowRadius),
      );
    canvas.drawCircle(glowCenter, glowRadius, glowPaint);

    // 4. Lapisan Bukit Belakang (Soft Minimalist Curve)
    final backHillPath = Path()
      ..moveTo(0, size.height * 0.72)
      ..cubicTo(
        size.width * 0.4,
        size.height * 0.65,
        size.width * 0.7,
        size.height * 0.78,
        size.width,
        size.height * 0.70,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final backHillPaint = Paint()..color = config.backHillsColor;
    canvas.drawPath(backHillPath, backHillPaint);

    // 5. Lapisan Bukit Depan (Seamless Transition ke Content Sheet)
    final frontHillPath = Path()
      ..moveTo(0, size.height * 0.82)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.90,
        size.width * 0.65,
        size.height * 0.78,
        size.width,
        size.height * 0.85,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final frontHillPaint = Paint()..color = config.frontHillsColor;
    canvas.drawPath(frontHillPath, frontHillPaint);
  }

  @override
  bool shouldRepaint(covariant _ModernMinimalistBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.phase != phase;
  }
}

class _StarSpec {
  const _StarSpec(this.x, this.y, this.size, this.phaseOffset, this.maxOpacity);

  final double x;
  final double y;
  final double size;
  final double phaseOffset;
  final double maxOpacity;
}
