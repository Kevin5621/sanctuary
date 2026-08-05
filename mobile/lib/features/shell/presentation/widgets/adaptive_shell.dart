import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/clay_container.dart';
import '../../../../core/widgets/responsive.dart';

class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Kerangka navigasi bersama seluruh peran.
///
/// Responsif: bottom navigation pada mobile portrait, NavigationRail pada
/// tablet/desktop landscape. Jumlah tab ditentukan pemanggil sesuai peran
/// (Mahasiswa 4, Dosen 3, Kaprodi 4, Admin 2).
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({
    super.key,
    required this.navigationShell,
    required this.destinations,
    this.floatingAction,
  });

  final StatefulNavigationShell navigationShell;
  final List<ShellDestination> destinations;
  final Widget? floatingAction;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // Menekan tab yang sama akan kembali ke akar cabang tersebut.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final useRail = Responsive.useSideNavigation(context);

    if (useRail) {
      return Scaffold(
        floatingActionButton: floatingAction,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _goBranch,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: floatingAction,
      body: navigationShell,
      bottomNavigationBar: ClayContainer(
        type: ClayType.flat,
        borderRadius: 0,
        depth: 6,
        spread: 10,
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goBranch,
          destinations: [
            for (final destination in destinations)
              NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label,
              ),
          ],
        ),
      ),
    );
  }
}

/// Halaman sementara untuk tab yang belum diimplementasikan.
/// Menyatakan cakupan dengan jujur alih-alih menampilkan layar kosong.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.construction_rounded,
    this.actions,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: ContentContainer(
        child: Center(
          child: ClayCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40, color: theme.colorScheme.primary),
                const SizedBox(height: AppSpacing.md),
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
