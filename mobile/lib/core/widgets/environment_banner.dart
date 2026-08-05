import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// Pita label pojok yang menandai build non-production (mis. "DEV",
/// "STAGING"). Mencegah kekeliruan umum di lapangan — tester melaporkan bug
/// yang sebenarnya sudah diperbaiki di lingkungan lain, atau sebaliknya
/// mengira sedang menguji versi rilis padahal masih staging.
///
/// Tidak pernah tampil pada build production.
class EnvironmentBanner extends StatelessWidget {
  const EnvironmentBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppConfig.isProduction) return child;

    final color = switch (AppConfig.environment) {
      AppEnvironment.staging => Colors.orange,
      AppEnvironment.development => Colors.blueGrey,
      AppEnvironment.production => Colors.transparent, // tidak pernah dipakai
    };

    return Banner(
      location: BannerLocation.topEnd,
      message: AppConfig.environmentLabel,
      color: color,
      child: child,
    );
  }
}
