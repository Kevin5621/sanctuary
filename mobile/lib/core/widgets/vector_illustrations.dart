import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Ilustrasi Vektor Cartoon untuk Banner Skrining DASS-21
class Dass21BannerIllustration extends StatelessWidget {
  const Dass21BannerIllustration({super.key, this.height = 100});
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: height * 1.2,
      child: CustomPaint(
        painter: _Dass21Painter(),
      ),
    );
  }
}

class _Dass21Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = AppColors.midnight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Background Blob Pink Soft
    final blobPaint = Paint()..color = AppColors.moodHappinessBg;
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.1)
      ..quadraticBezierTo(size.width * 0.9, 0, size.width * 0.85, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.7, size.height * 1.0, size.width * 0.1, size.height * 0.85)
      ..quadraticBezierTo(0, size.height * 0.5, size.width * 0.2, size.height * 0.1);
    canvas.drawPath(path, blobPaint);
    canvas.drawPath(path, strokePaint);

    // Checklist Board
    final boardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.25, size.height * 0.2, size.width * 0.5, size.height * 0.65),
      const Radius.circular(10),
    );
    canvas.drawRRect(boardRect, Paint()..color = Colors.white);
    canvas.drawRRect(boardRect, strokePaint);

    // Clip top
    final clipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.38, size.height * 0.14, size.width * 0.24, size.height * 0.12),
      const Radius.circular(4),
    );
    canvas.drawRRect(clipRect, Paint()..color = AppColors.midnight);

    // Lines & Checkmarks
    final checkPaint = Paint()
      ..color = AppColors.moodDisgust
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final lineY1 = size.height * 0.4;
    final lineY2 = size.height * 0.6;

    // Check 1
    final check1 = Path()
      ..moveTo(size.width * 0.32, lineY1)
      ..lineTo(size.width * 0.38, lineY1 + 5)
      ..lineTo(size.width * 0.46, lineY1 - 5);
    canvas.drawPath(check1, checkPaint);
    canvas.drawLine(Offset(size.width * 0.52, lineY1), Offset(size.width * 0.68, lineY1), strokePaint);

    // Check 2
    final check2 = Path()
      ..moveTo(size.width * 0.32, lineY2)
      ..lineTo(size.width * 0.38, lineY2 + 5)
      ..lineTo(size.width * 0.46, lineY2 - 5);
    canvas.drawPath(check2, checkPaint);
    canvas.drawLine(Offset(size.width * 0.52, lineY2), Offset(size.width * 0.68, lineY2), strokePaint);

    // Sparkle star
    final starPaint = Paint()..color = AppColors.sunnyYellow;
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.25), 8, starPaint);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.25), 8, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Avatar Vektor Cartoon Terapis AI (Google Gemini 2.5 Flash)
class AiTherapistAvatarIllustration extends StatelessWidget {
  const AiTherapistAvatarIllustration({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.lavenderBg,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.midnight, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cartoonShadow,
            offset: Offset(0, 3),
            blurRadius: 6,
          )
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.7, size * 0.7),
          painter: _GeminiRobotPainter(),
        ),
      ),
    );
  }
}

class _GeminiRobotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = AppColors.midnight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);

    // Robot head blob
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size.width * 0.85, height: size.height * 0.75),
      const Radius.circular(16),
    );
    canvas.drawRRect(headRect, Paint()..color = Colors.white);
    canvas.drawRRect(headRect, strokePaint);

    // Antenna spark
    canvas.drawLine(Offset(center.dx, center.dy - size.height * 0.375), Offset(center.dx, center.dy - size.height * 0.5), strokePaint);
    canvas.drawCircle(Offset(center.dx, center.dy - size.height * 0.52), 4, Paint()..color = AppColors.moodHappiness);
    canvas.drawCircle(Offset(center.dx, center.dy - size.height * 0.52), 4, strokePaint);

    // Eyes (Cute AI Star sparkle eyes)
    final eyePaint = Paint()..color = AppColors.midnight;
    canvas.drawCircle(Offset(center.dx - size.width * 0.2, center.dy - size.height * 0.05), 3.5, eyePaint);
    canvas.drawCircle(Offset(center.dx + size.width * 0.2, center.dy - size.height * 0.05), 3.5, eyePaint);

    // Smile
    final smilePath = Path()
      ..moveTo(center.dx - size.width * 0.15, center.dy + size.height * 0.15)
      ..quadraticBezierTo(center.dx, center.dy + size.height * 0.3, center.dx + size.width * 0.15, center.dy + size.height * 0.15);
    canvas.drawPath(smilePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Kartu Bantuan Krisis Otomatis (Pop Up Banner saat Tanda Krisis Terdeteksi)
class CrisisAlertCardWidget extends StatelessWidget {
  const CrisisAlertCardWidget({
    super.key,
    required this.onCallHotline,
    required this.onDismiss,
    this.message = 'Sistem mendeteksi tanda krisis atau tekanan emosional tinggi. Kamu tidak sendirian.',
  });

  final VoidCallback onCallHotline;
  final VoidCallback onDismiss;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.moodAngerBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.ewsIntervention, width: 2),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.ewsIntervention,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Kartu Bantuan Krisis (24/7)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.midnight,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 20, color: AppColors.midnight),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.midnight,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCallHotline,
                  icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
                  label: const Text('Hubungi Hotline 119 Ext 8'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ewsIntervention,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
