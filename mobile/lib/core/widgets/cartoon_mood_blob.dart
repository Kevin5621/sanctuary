import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum MoodType {
  disgust('Disgust', 'Jijik', AppColors.moodDisgust, AppColors.moodDisgustBg),
  fear('Fear', 'Cemas', AppColors.moodFear, AppColors.moodFearBg),
  sadness('Sadness', 'Sedih', AppColors.moodSadness, AppColors.moodSadnessBg),
  anger('Anger', 'Marah', AppColors.moodAnger, AppColors.moodAngerBg),
  happiness('Happiness', 'Bahagia', AppColors.moodHappiness, AppColors.moodHappinessBg);

  const MoodType(this.labelEn, this.labelId, this.color, this.bgColor);
  final String labelEn;
  final String labelId;
  final Color color;
  final Color bgColor;
}

/// Widget Blob Cartoon dengan Ekspresi Wajah Doodle Minimalis
class CartoonMoodBlob extends StatelessWidget {
  const CartoonMoodBlob({
    super.key,
    required this.mood,
    this.size = 80,
    this.isSelected = false,
    this.showBadge = false,
    this.badgeText,
    this.onTap,
  });

  final MoodType mood;
  final double size;
  final bool isSelected;
  final bool showBadge;
  final String? badgeText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        transform: Matrix4.identity()..scale(isSelected ? 1.08 : 1.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showBadge)
              WavyBadge(
                text: badgeText ?? mood.labelEn,
                color: Colors.white,
                borderColor: AppColors.midnight,
              ),
            if (showBadge) const SizedBox(height: 4),
            CustomPaint(
              size: Size(size, size),
              painter: _MoodBlobPainter(
                mood: mood,
                isSelected: isSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodBlobPainter extends CustomPainter {
  _MoodBlobPainter({required this.mood, required this.isSelected});

  final MoodType mood;
  final bool isSelected;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final fillPaint = Paint()
      ..color = mood.color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = AppColors.midnight
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 1. Gambar Bentuk Blob Organik Kustom per Mood
    final path = Path();
    switch (mood) {
      case MoodType.disgust:
        // Soft rounded squarish blob with irregular wavy corners
        path.moveTo(center.dx - radius * 0.8, center.dy - radius * 0.6);
        path.quadraticBezierTo(center.dx, center.dy - radius * 0.95, center.dx + radius * 0.7, center.dy - radius * 0.7);
        path.quadraticBezierTo(center.dx + radius * 0.95, center.dy + radius * 0.1, center.dx + radius * 0.7, center.dy + radius * 0.8);
        path.quadraticBezierTo(center.dx - radius * 0.2, center.dy + radius * 0.95, center.dx - radius * 0.85, center.dy + radius * 0.6);
        path.quadraticBezierTo(center.dx - radius * 0.95, center.dy - radius * 0.1, center.dx - radius * 0.8, center.dy - radius * 0.6);
        break;

      case MoodType.fear:
        // Cloud / multi-lobe wavy star blob
        for (int i = 0; i < 8; i++) {
          final angle = (i * math.pi / 4);
          final r = (i % 2 == 0) ? radius * 0.95 : radius * 0.75;
          final x = center.dx + r * math.cos(angle);
          final y = center.dy + r * math.sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            final prevAngle = ((i - 1) * math.pi / 4);
            final cpAngle = (prevAngle + angle) / 2;
            final cpR = radius * 1.05;
            final cpx = center.dx + cpR * math.cos(cpAngle);
            final cpy = center.dy + cpR * math.sin(cpAngle);
            path.quadraticBezierTo(cpx, cpy, x, y);
          }
        }
        path.close();
        break;

      case MoodType.sadness:
        // Soft organic droplet tear shape
        path.moveTo(center.dx, center.dy - radius * 0.9);
        path.cubicTo(center.dx + radius * 0.95, center.dy - radius * 0.3, center.dx + radius * 0.9, center.dy + radius * 0.8, center.dx, center.dy + radius * 0.85);
        path.cubicTo(center.dx - radius * 0.9, center.dy + radius * 0.8, center.dx - radius * 0.95, center.dy - radius * 0.3, center.dx, center.dy - radius * 0.9);
        break;

      case MoodType.anger:
        // Star-like sharp rounded spiky blob
        for (int i = 0; i < 6; i++) {
          final angle = (i * math.pi / 3) - math.pi / 6;
          final r = (i % 2 == 0) ? radius * 0.95 : radius * 0.65;
          final x = center.dx + r * math.cos(angle);
          final y = center.dy + r * math.sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        break;

      case MoodType.happiness:
        // Scalloped flower heart organic blob
        for (int i = 0; i < 10; i++) {
          final angle = (i * math.pi / 5);
          final r = (i % 2 == 0) ? radius * 0.95 : radius * 0.8;
          final x = center.dx + r * math.cos(angle);
          final y = center.dy + r * math.sin(angle);
          if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
        }
        path.close();
        break;
    }

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    // 2. Gambar Ekspresi Wajah Doodle Minimalis (Mata & Mulut)
    _drawDoodleFace(canvas, center, radius);
  }

  void _drawDoodleFace(Canvas canvas, Offset center, double radius) {
    final facePaint = Paint()
      ..color = AppColors.midnight
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, radius * 0.05)
      ..strokeCap = StrokeCap.round;

    final fillEyePaint = Paint()
      ..color = AppColors.midnight
      ..style = PaintingStyle.fill;

    switch (mood) {
      case MoodType.disgust:
        // Mata setengah tertutup lesu / mengantuk (flat line horizontally)
        final eyeY = center.dy - radius * 0.15;
        canvas.drawLine(Offset(center.dx - radius * 0.4, eyeY), Offset(center.dx - radius * 0.15, eyeY), facePaint);
        canvas.drawLine(Offset(center.dx + radius * 0.15, eyeY), Offset(center.dx + radius * 0.4, eyeY), facePaint);
        // Mulut wavy lurus kesal
        final mouthPath = Path()
          ..moveTo(center.dx - radius * 0.3, center.dy + radius * 0.3)
          ..quadraticBezierTo(center.dx, center.dy + radius * 0.15, center.dx + radius * 0.3, center.dy + radius * 0.3);
        canvas.drawPath(mouthPath, facePaint);
        break;

      case MoodType.fear:
        // Mata terpejam gelisah (wavy zig-zag > <)
        final eyeY = center.dy - radius * 0.15;
        // Left eye >
        final leftEye = Path()
          ..moveTo(center.dx - radius * 0.4, eyeY - radius * 0.15)
          ..lineTo(center.dx - radius * 0.25, eyeY)
          ..lineTo(center.dx - radius * 0.4, eyeY + radius * 0.15);
        canvas.drawPath(leftEye, facePaint);
        // Right eye <
        final rightEye = Path()
          ..moveTo(center.dx + radius * 0.4, eyeY - radius * 0.15)
          ..lineTo(center.dx + radius * 0.25, eyeY)
          ..lineTo(center.dx + radius * 0.4, eyeY + radius * 0.15);
        canvas.drawPath(rightEye, facePaint);
        // Mulut zig-zag cemas (W-shape)
        final mouth = Path()
          ..moveTo(center.dx - radius * 0.3, center.dy + radius * 0.25)
          ..lineTo(center.dx - radius * 0.15, center.dy + radius * 0.35)
          ..lineTo(center.dx, center.dy + radius * 0.25)
          ..lineTo(center.dx + radius * 0.15, center.dy + radius * 0.35)
          ..lineTo(center.dx + radius * 0.3, center.dy + radius * 0.25);
        canvas.drawPath(mouth, facePaint);
        break;

      case MoodType.sadness:
        // Mata titik bulat dengan alis melengkung sedih
        final eyeY = center.dy - radius * 0.1;
        canvas.drawCircle(Offset(center.dx - radius * 0.3, eyeY), radius * 0.08, fillEyePaint);
        canvas.drawCircle(Offset(center.dx + radius * 0.3, eyeY), radius * 0.08, fillEyePaint);
        // Mulut melengkung ke bawah 🙁
        final mouth = Path()
          ..moveTo(center.dx - radius * 0.3, center.dy + radius * 0.4)
          ..quadraticBezierTo(center.dx, center.dy + radius * 0.2, center.dx + radius * 0.3, center.dy + radius * 0.4);
        canvas.drawPath(mouth, facePaint);
        break;

      case MoodType.anger:
        // Alis tajam V \ / dan mata marah
        final eyeY = center.dy - radius * 0.1;
        // Left eyebrow \
        canvas.drawLine(Offset(center.dx - radius * 0.45, eyeY - radius * 0.25), Offset(center.dx - radius * 0.15, eyeY - radius * 0.05), facePaint);
        // Right eyebrow /
        canvas.drawLine(Offset(center.dx + radius * 0.45, eyeY - radius * 0.25), Offset(center.dx + radius * 0.15, eyeY - radius * 0.05), facePaint);
        // Eyes
        canvas.drawCircle(Offset(center.dx - radius * 0.28, eyeY + radius * 0.05), radius * 0.08, fillEyePaint);
        canvas.drawCircle(Offset(center.dx + radius * 0.28, eyeY + radius * 0.05), radius * 0.08, fillEyePaint);
        // Mulut terbalik grump
        final mouth = Path()
          ..moveTo(center.dx - radius * 0.3, center.dy + radius * 0.35)
          ..quadraticBezierTo(center.dx, center.dy + radius * 0.2, center.dx + radius * 0.3, center.dy + radius * 0.35);
        canvas.drawPath(mouth, facePaint);
        break;

      case MoodType.happiness:
        // Mata tersenyum lengkung ^^ & pipi pink
        final eyeY = center.dy - radius * 0.1;
        final leftEye = Path()
          ..moveTo(center.dx - radius * 0.4, eyeY)
          ..quadraticBezierTo(center.dx - radius * 0.28, eyeY - radius * 0.2, center.dx - radius * 0.15, eyeY);
        canvas.drawPath(leftEye, facePaint);
        final rightEye = Path()
          ..moveTo(center.dx + radius * 0.15, eyeY)
          ..quadraticBezierTo(center.dx + radius * 0.28, eyeY - radius * 0.2, center.dx + radius * 0.4, eyeY);
        canvas.drawPath(rightEye, facePaint);
        // Mulut tersenyum lebar 🙂
        final mouth = Path()
          ..moveTo(center.dx - radius * 0.3, center.dy + radius * 0.2)
          ..quadraticBezierTo(center.dx, center.dy + radius * 0.5, center.dx + radius * 0.3, center.dy + radius * 0.2);
        canvas.drawPath(mouth, facePaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _MoodBlobPainter oldDelegate) {
    return oldDelegate.mood != mood || oldDelegate.isSelected != isSelected;
  }
}

/// Label Cartoon dengan Border Tipis Bergelombang (Wavy Scalloped Badge)
class WavyBadge extends StatelessWidget {
  const WavyBadge({
    super.key,
    required this.text,
    this.color = Colors.white,
    this.textColor = AppColors.midnight,
    this.borderColor = AppColors.midnight,
  });

  final String text;
  final Color color;
  final Color textColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cartoonShadow,
            offset: Offset(0, 2),
            blurRadius: 4,
          )
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
