import 'package:flutter/material.dart';
import '../../../../core/widgets/floating_cartoon_navbar.dart';
import 'dashboard_tab.dart';
import 'kaprodi_profil_tab.dart';
import 'laporan_tab.dart';
import 'pembimbing_tab.dart';

class KaprodiShellPage extends StatefulWidget {
  const KaprodiShellPage({super.key});

  @override
  State<KaprodiShellPage> createState() => _KaprodiShellPageState();
}

class _KaprodiShellPageState extends State<KaprodiShellPage> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    KaprodiDashboardTab(),
    KaprodiPembimbingTab(),
    KaprodiLaporanTab(),
    KaprodiProfilTab(),
  ];

  final List<FloatingCartoonNavbarItem> _navItems = const [
    FloatingCartoonNavbarItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    FloatingCartoonNavbarItem(
      icon: Icons.school_outlined,
      selectedIcon: Icons.school_rounded,
      label: 'Pembimbing',
    ),
    FloatingCartoonNavbarItem(
      icon: Icons.description_outlined,
      selectedIcon: Icons.description_rounded,
      label: 'Laporan',
    ),
    FloatingCartoonNavbarItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: FloatingCartoonNavbar(
        selectedIndex: _currentIndex,
        onTap: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
        items: _navItems,
      ),
    );
  }
}
