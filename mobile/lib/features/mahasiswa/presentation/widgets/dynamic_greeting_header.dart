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
    return _TimePhaseConfig.forPhase(phase).scaffoldColor;
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
          // Latar Belakang Gradient Atmosferik Clean & Simple
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CleanAtmosphericBackgroundPainter(
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
              24,
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
                const SizedBox(height: 24),

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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// Konfigurasi Atmosfer Waktu Clean & Simple
// ------------------------------------------------------------------

class _TimePhaseConfig {
  const _TimePhaseConfig({
    required this.greeting,
    required this.atmosphereTag,
    required this.subtitleDefault,
    required this.subtitleCheckedIn,
    required this.backgroundGradient,
    required this.glowAccentColor,
    required this.scaffoldColor,
  });

  final String greeting;
  final String atmosphereTag;
  final String subtitleDefault;
  final String subtitleCheckedIn;
  final LinearGradient backgroundGradient;
  final Color glowAccentColor;
  final Color scaffoldColor;

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
              Color(0xFF1E293B), // Deep Slate
              Color(0xFF0F172A), // Midnight Navy Slate
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          glowAccentColor: Color(0xFFF59E0B), // Warm Amber Glow
          scaffoldColor: Color(0xFF1E293B),
        );
      case TimeOfDayPhase.siang:
        return const _TimePhaseConfig(
          greeting: 'Selamat Siang',
          atmosphereTag: 'Siang Cerah',
          subtitleDefault: 'Tetap semangat dan jaga energi positifmu ya!',
          subtitleCheckedIn: 'Terima kasih sudah check-in siang ini.',
          backgroundGradient: LinearGradient(
            colors: [
              Color(0xFF0288D1), // Sky Azure Blue
              Color(0xFF0F172A), // Midnight Navy Transition
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          glowAccentColor: Color(0xFF38BDF8), // Cyan Sky Glow
          scaffoldColor: Color(0xFF0288D1),
        );
      case TimeOfDayPhase.sore:
        return const _TimePhaseConfig(
          greeting: 'Selamat Sore',
          atmosphereTag: 'Senja Calm',
          subtitleDefault: 'Waktunya bersantai sejenak setelah beraktivitas.',
          subtitleCheckedIn: 'Terima kasih sudah check-in sore ini.',
          backgroundGradient: LinearGradient(
            colors: [
              Color(0xFF2E1065), // Deep Sunset Dusk Violet
              Color(0xFF0F172A), // Midnight Navy Transition
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          glowAccentColor: Color(0xFFFB7185), // Warm Rose Sunset Glow
          scaffoldColor: Color(0xFF2E1065),
        );
      case TimeOfDayPhase.malam:
        return const _TimePhaseConfig(
          greeting: 'Selamat Malam',
          atmosphereTag: 'Malam Berbintang',
          subtitleDefault: 'Istirahatlah yang cukup dan tenangkan pikiranmu.',
          subtitleCheckedIn: 'Terima kasih sudah check-in malam ini.',
          backgroundGradient: LinearGradient(
            colors: [
              Color(0xFF090D16), // Deep Midnight
              Color(0xFF0F172A), // Dark Slate
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          glowAccentColor: Color(0xFF818CF8), // Soft Moonlight Indigo Glow
          scaffoldColor: Color(0xFF090D16),
        );
    }
  }
}

// ------------------------------------------------------------------
// Clean Atmospheric Background Painter
// ------------------------------------------------------------------

class _CleanAtmosphericBackgroundPainter extends CustomPainter {
  _CleanAtmosphericBackgroundPainter({
    required this.progress,
    required this.phase,
    required this.config,
  });

  final double progress;
  final TimeOfDayPhase phase;
  final _TimePhaseConfig config;

  static const List<_StarSpec> _stars = [
    _StarSpec(0.12, 0.20, 1.8, 0.0, 0.7),
    _StarSpec(0.28, 0.35, 1.4, 1.2, 0.6),
    _StarSpec(0.45, 0.18, 2.0, 2.4, 0.8),
    _StarSpec(0.65, 0.30, 1.5, 0.6, 0.65),
    _StarSpec(0.82, 0.22, 1.8, 3.1, 0.75),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Clean 2-Stop Linear Gradient Sky
    final skyPaint = Paint()
      ..shader = config.backgroundGradient.createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // 2. Bintang Berkelap-Kelip (Khusus Malam)
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

    // 3. Ultra-soft Ambient Glow Aura (Top Right)
    final pulse = math.sin(progress * math.pi * 2);
    final glowCenter = Offset(size.width * 0.85, size.height * 0.22);
    const glowRadius = 90.0;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          config.glowAccentColor.withValues(alpha: 0.22 + (pulse * 0.04)),
          config.glowAccentColor.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: glowCenter, radius: glowRadius),
      );
    canvas.drawCircle(glowCenter, glowRadius, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _CleanAtmosphericBackgroundPainter oldDelegate) {
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
