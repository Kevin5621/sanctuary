import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Komponen state bersama untuk layar Dosen, Kaprodi, dan Admin.
///
/// Alasan komponen ini dikumpulkan di satu tempat: tiga state di bawah adalah
/// tempat aplikasi paling mudah berbohong, dan kebohongannya tidak terlihat
/// seperti bug.
///
///   1. `is_sufficient:false` (k-anonymity) — bila satu layar diam-diam
///      menampilkan "0" alih-alih "Data belum cukup", ambang k-anonymity
///      kehilangan artinya di layar itu.
///   2. `share_level = CLOSED` — menampilkannya sebagai "Normal" adalah
///      kegagalan produk, bukan sekadar salah label (L-BIM-05).
///   3. Daftar nomor darurat kosong — menampilkan nomor tebakan lebih berbahaya
///      daripada mengaku belum ada (A-BAN-03).
///
/// Dengan satu implementasi bersama, ketiga aturan itu benar di semua layar
/// sekaligus atau salah di semua layar sekaligus — dan yang kedua akan segera
/// ketahuan.

// ------------------------------------------------------------------
// Kerangka kartu bergaya kartun (border tegas + bayangan keras),
// mengikuti bahasa visual yang sudah dipakai layar Mahasiswa.
// ------------------------------------------------------------------

class StateCard extends StatelessWidget {
  const StateCard({
    super.key,
    required this.child,
    this.color = AppColors.cardBg,
    this.borderColor = AppColors.cartoonBorder,
    this.borderWidth = 1.5,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
  });

  final Widget child;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cartoonShadow,
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Kerangka isi state: ikon bulat, judul, penjelasan, aksi opsional.
class _StateBody extends StatelessWidget {
  const _StateBody({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.description,
    this.footnote,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String description;
  final String? footnote;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
                border: Border.all(color: iconColor, width: 1.5),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.midnight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.warmTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (footnote != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            footnote!,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.35,
              fontStyle: FontStyle.italic,
              color: AppColors.warmTextMuted,
            ),
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: AppSpacing.md),
          action!,
        ],
      ],
    );
  }
}

// ------------------------------------------------------------------
// 1. k-anonymity — "Data belum cukup"
// ------------------------------------------------------------------

/// State untuk response agregat dengan `is_sufficient: false` (I-4).
///
/// PENTING: widget ini sengaja TIDAK menerima parameter ukuran kelompok.
/// Backend memang tidak mengirimkannya saat di bawah ambang, dan menyediakan
/// slot untuk angka itu hanya akan mengundang seseorang mengisinya nanti.
/// Yang boleh disebut hanyalah AMBANG-nya (`minimumGroupSize`), karena itu
/// aturan sistem — bukan cerminan siapa pun.
class InsufficientDataCard extends StatelessWidget {
  const InsufficientDataCard({
    super.key,
    this.minimumGroupSize,
    this.context,
    this.margin,
  });

  /// Ambang k-anonymity dari server (`minimum_group_size`).
  final int? minimumGroupSize;

  /// Konteks kelompok, mis. "kelompok bimbingan Anda" atau "angkatan 2023".
  final String? context;

  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext buildContext) {
    final scope = context ?? 'kelompok ini';
    final threshold = minimumGroupSize;

    return StateCard(
      margin: margin,
      color: AppColors.creamAlt,
      child: _StateBody(
        icon: Icons.shield_outlined,
        iconColor: AppColors.lavenderDark,
        iconBackground: AppColors.lavenderBg,
        title: 'Data belum cukup',
        description: threshold == null
            ? 'Angka untuk $scope belum dapat ditampilkan karena jumlah '
                'anggotanya di bawah ambang privasi.'
            : 'Angka untuk $scope baru ditampilkan bila anggotanya minimal '
                '$threshold mahasiswa.',
        footnote: 'Pada kelompok kecil, rata-rata praktis menunjuk orang '
            'tertentu. Jumlah anggotanya sendiri juga tidak ditampilkan.',
      ),
    );
  }
}

// ------------------------------------------------------------------
// 2. share_level = CLOSED — "mahasiswa memilih tidak berbagi"
// ------------------------------------------------------------------

/// State untuk mahasiswa yang memilih tingkat berbagi Tertutup (L-BIM-05).
///
/// Tidak boleh disamarkan menjadi "Normal", "-", atau kartu kosong. Dosen harus
/// tahu bahwa yang ia lihat adalah PILIHAN mahasiswa, bukan ketiadaan masalah.
class ClosedShareCard extends StatelessWidget {
  const ClosedShareCard({
    super.key,
    this.studentName,
    this.notice,
    this.margin,
    this.compact = false,
  });

  final String? studentName;

  /// `privacy_notice` dari server. Dipakai bila ada supaya kalimatnya sama
  /// persis dengan yang ditegakkan backend.
  final String? notice;

  final EdgeInsetsGeometry? margin;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final subject = studentName == null ? 'Mahasiswa' : studentName!;
    final message = notice?.isNotEmpty == true
        ? notice!
        : '$subject memilih untuk tidak membagikan data kondisinya.';

    if (compact) {
      return Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 15, color: AppColors.warmTextSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: AppColors.warmTextSecondary,
              ),
            ),
          ),
        ],
      );
    }

    return StateCard(
      margin: margin,
      color: AppColors.creamAlt,
      child: _StateBody(
        icon: Icons.lock_outline_rounded,
        iconColor: AppColors.warmTextSecondary,
        iconBackground: AppColors.cardBg,
        title: 'Mahasiswa memilih tidak berbagi',
        description: message,
        footnote: 'Ini pilihan yang sah dan bukan tanda ada masalah. '
            'Anda tetap dapat menyapanya lewat jalur biasa.',
      ),
    );
  }
}

/// Catatan saat mahasiswa berbagi indikator tetapi menolak peringatan dini.
/// Beda sebab dengan [ClosedShareCard], jadi dibedakan agar dosen tidak salah
/// menyimpulkan bahwa mahasiswanya menutup segalanya.
class EarlyWarningOffCard extends StatelessWidget {
  const EarlyWarningOffCard({super.key, this.notice, this.margin});

  final String? notice;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return StateCard(
      margin: margin,
      color: AppColors.creamAlt,
      child: _StateBody(
        icon: Icons.notifications_off_outlined,
        iconColor: AppColors.warmTextSecondary,
        iconBackground: AppColors.cardBg,
        title: 'Peringatan dini dinonaktifkan',
        description: notice?.isNotEmpty == true
            ? notice!
            : 'Mahasiswa menonaktifkan peringatan dini ke pembimbing, '
                'sehingga status perhatiannya tidak dihitung untuk Anda.',
        footnote: 'Indikator kondisi lain tetap tampil sesuai izin yang dipilih.',
      ),
    );
  }
}

// ------------------------------------------------------------------
// 3. State umum: kosong, gagal, memuat
// ------------------------------------------------------------------

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.inbox_outlined,
    this.footnote,
    this.action,
    this.margin,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? footnote;
  final Widget? action;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.creamAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.warmTextMuted, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.midnight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.warmTextSecondary,
              ),
            ),
            if (footnote != null) ...[
              const SizedBox(height: 6),
              Text(
                footnote!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.warmTextMuted,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorStateCard extends StatelessWidget {
  const ErrorStateCard({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Gagal memuat data',
    this.margin,
  });

  final String message;
  final VoidCallback? onRetry;
  final String title;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return StateCard(
      margin: margin,
      borderColor: AppColors.ewsRisk,
      child: _StateBody(
        icon: Icons.wifi_off_rounded,
        iconColor: AppColors.ewsRisk,
        iconBackground: AppColors.moodAngerBg,
        title: title,
        description: message,
        action: onRetry == null
            ? null
            : OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.midnight,
                  side: const BorderSide(color: AppColors.midnight, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              ),
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label, this.padding = 48});

  final String? label;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.midnight),
            if (label != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                label!,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.warmTextSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// Badge status
// ------------------------------------------------------------------

/// Badge tingkat perhatian EWS.
///
/// `level` null ATAU `INSUFFICIENT_DATA` TIDAK PERNAH dirender sebagai "Normal"
/// — keduanya punya tampilan sendiri. Menyebut seseorang "Normal" padahal
/// datanya kosong adalah kegagalan produk (lihat PRD §6.4).
class EwsLevelBadge extends StatelessWidget {
  const EwsLevelBadge({
    super.key,
    required this.level,
    this.label,
    this.dense = false,
  });

  final String? level;
  final String? label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.ewsLevel(level);
    final text = label?.isNotEmpty == true ? label! : _fallbackLabel(level);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(level), size: dense ? 12 : 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.midnight,
                fontWeight: FontWeight.w700,
                fontSize: dense ? 11 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fallbackLabel(String? level) => switch (level) {
        'NORMAL' => 'Normal',
        'WATCH' => 'Waspada',
        'RISK' => 'Risiko',
        'INTERVENTION' => 'Perlu Intervensi',
        'INSUFFICIENT_DATA' => 'Data belum cukup',
        _ => 'Tidak dibagikan',
      };

  static IconData _iconFor(String? level) => switch (level) {
        'NORMAL' => Icons.check_circle_outline_rounded,
        'WATCH' => Icons.visibility_outlined,
        'RISK' => Icons.error_outline_rounded,
        'INTERVENTION' => Icons.priority_high_rounded,
        'INSUFFICIENT_DATA' => Icons.hourglass_empty_rounded,
        _ => Icons.lock_outline_rounded,
      };
}

/// Badge "belum diverifikasi" untuk nomor layanan bertanda `[VERIFIKASI]`
/// (A-BAN-04).
///
/// Sengaja mencolok: ini blocker rilis. Nomor krisis yang salah lebih berbahaya
/// daripada tidak ada nomor sama sekali, jadi statusnya harus mengganggu
/// sampai seseorang benar-benar menelepon dan memastikannya.
class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key, this.dense = false});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.moodAngerBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.ewsIntervention, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.gpp_maybe_outlined,
              size: dense ? 12 : 14, color: AppColors.ewsIntervention),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              'Belum diverifikasi',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.ewsIntervention,
                fontWeight: FontWeight.w700,
                fontSize: dense ? 11 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu ringkas berisi daftar batas akses peran (`access_limits` dari server).
/// Dipakai tab Profil Dosen, Kaprodi, dan Admin.
class AccessLimitsCard extends StatelessWidget {
  const AccessLimitsCard({
    super.key,
    required this.limits,
    this.title = 'Yang tidak dapat Anda lihat',
    this.margin,
  });

  final List<String> limits;
  final String title;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return StateCard(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined,
                  size: 20, color: AppColors.midnight),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.midnight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final limit in limits)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.block_rounded,
                        size: 14, color: AppColors.ewsRisk),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      limit,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.warmTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Judul layar konsisten untuk seluruh tab peran non-mahasiswa.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: AppColors.midnight,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.warmTextSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}
