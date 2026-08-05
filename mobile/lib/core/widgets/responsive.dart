import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum ScreenSize { mobile, tablet, desktop }

/// Helper responsif tunggal — dipakai seluruh layar agar aturan breakpoint
/// tidak tersebar (mobile portrait vs tablet/desktop landscape).
class Responsive {
  const Responsive._();

  static ScreenSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppSpacing.desktopBreakpoint) return ScreenSize.desktop;
    if (width >= AppSpacing.tabletBreakpoint) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }

  static bool isMobile(BuildContext context) =>
      of(context) == ScreenSize.mobile;

  /// Layar lebar memakai NavigationRail, bukan bottom navigation.
  static bool useSideNavigation(BuildContext context) => !isMobile(context);

  /// Jumlah kolom grid yang wajar per ukuran layar.
  static int gridColumns(BuildContext context) => switch (of(context)) {
        ScreenSize.mobile => 1,
        ScreenSize.tablet => 2,
        ScreenSize.desktop => 3,
      };

  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) =>
      switch (of(context)) {
        ScreenSize.mobile => mobile,
        ScreenSize.tablet => tablet ?? mobile,
        ScreenSize.desktop => desktop ?? tablet ?? mobile,
      };
}

/// Membatasi lebar konten dan memusatkannya pada layar lebar,
/// sehingga baris teks tetap nyaman dibaca di tablet/desktop.
class ContentContainer extends StatelessWidget {
  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.maxContentWidth,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
