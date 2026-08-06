import 'package:flutter/material.dart';

/// Pita label pojok yang menandai build non-production.
/// (Banner dev dihapus sesuai permintaan)
class EnvironmentBanner extends StatelessWidget {
  const EnvironmentBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
