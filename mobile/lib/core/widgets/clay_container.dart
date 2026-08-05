import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Arah "cahaya" pada permukaan clay.
enum ClayType {
  /// Menonjol keluar (kartu, tombol).
  convex,

  /// Masuk ke dalam (bidang input, area terpilih).
  concave,

  /// Datar dengan bayangan halus.
  flat,
}

/// Blok pembangun Claymorphism.
///
/// Efek clay dibentuk dua bayangan berlawanan arah: sorotan terang di kiri-atas
/// dan bayangan gelap di kanan-bawah. Nilainya menyesuaikan brightness tema
/// sehingga permukaan tetap terbaca pada mode gelap.
class ClayContainer extends StatelessWidget {
  const ClayContainer({
    super.key,
    this.child,
    this.color,
    this.borderRadius = AppSpacing.radiusMd,
    this.depth = 12,
    this.spread = 6,
    this.type = ClayType.convex,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.border,
  });

  final Widget? child;
  final Color? color;
  final double borderRadius;

  /// Jarak bayangan — makin besar makin "tebal" permukaannya.
  final double depth;

  /// Blur bayangan.
  final double spread;

  final ClayType type;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = color ??
        (isDark ? AppColors.darkSurfaceAlt : AppColors.creamAlt);

    final highlight =
        isDark ? AppColors.clayHighlightDarkMode : AppColors.clayShadowLight;
    final shadow =
        isDark ? AppColors.clayShadowDarkMode : AppColors.clayShadowDarkLight;

    final offset = depth / 2;

    final shadows = switch (type) {
      ClayType.convex => [
          BoxShadow(
            color: shadow,
            offset: Offset(offset, offset),
            blurRadius: spread * 2,
          ),
          BoxShadow(
            color: highlight,
            offset: Offset(-offset, -offset),
            blurRadius: spread * 2,
          ),
        ],
      // Concave dibalik arahnya untuk memberi kesan cekung.
      ClayType.concave => [
          BoxShadow(
            color: shadow,
            offset: Offset(-offset / 2, -offset / 2),
            blurRadius: spread,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: highlight,
            offset: Offset(offset / 2, offset / 2),
            blurRadius: spread,
            spreadRadius: -1,
          ),
        ],
      ClayType.flat => [
          BoxShadow(
            color: shadow,
            offset: const Offset(0, 2),
            blurRadius: spread,
          ),
        ],
    };

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows,
        border: border,
        gradient: type == ClayType.convex
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(highlight.withValues(alpha: 0.35), baseColor),
                  baseColor,
                ],
              )
            : null,
      ),
      child: child,
    );

    if (onTap == null) {
      return margin == null ? content : Padding(padding: margin!, child: content);
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      ),
    );
  }
}

/// Kartu clay siap pakai dengan judul, subjudul, dan aksi opsional.
class ClayCard extends StatelessWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.color,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClayContainer(
      color: color,
      onTap: onTap,
      padding: padding,
      margin: margin,
      borderRadius: AppSpacing.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || leading != null || trailing != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(title!, style: theme.textTheme.titleMedium),
                        if (subtitle != null)
                          Text(subtitle!, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Tombol utama bergaya clay dengan state loading.
class ClayButton extends StatelessWidget {
  const ClayButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
    this.color,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expanded;
  final Color? color;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDisabled = onPressed == null || isLoading;

    final background = color ?? scheme.primary;
    final foreground = foregroundColor ?? scheme.onPrimary;

    return Opacity(
      opacity: isDisabled ? 0.6 : 1,
      child: ClayContainer(
        onTap: isDisabled ? null : onPressed,
        color: background,
        depth: 10,
        spread: 5,
        borderRadius: AppSpacing.radiusSm,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        width: expanded ? double.infinity : null,
        child: Row(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(foreground),
                ),
              )
            else if (icon != null)
              Icon(icon, size: 20, color: foreground),
            if (isLoading || icon != null) const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
