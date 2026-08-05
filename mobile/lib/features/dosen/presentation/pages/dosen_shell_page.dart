import 'package:flutter/material.dart';
import '../../../../core/widgets/floating_cartoon_navbar.dart';
import 'bimbingan_tab.dart';
import 'dosen_profil_tab.dart';
import 'kondisi_tab.dart';

class DosenShellPage extends StatefulWidget {
  const DosenShellPage({super.key});

  @override
  State<DosenShellPage> createState() => _DosenShellPageState();
}

class _DosenShellPageState extends State<DosenShellPage> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    DosenBimbinganTab(),
    DosenKondisiTab(),
    DosenProfilTab(),
  ];

  final List<FloatingCartoonNavbarItem> _navItems = const [
    FloatingCartoonNavbarItem(
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
      label: 'Bimbingan',
    ),
    FloatingCartoonNavbarItem(
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics_rounded,
      label: 'Kondisi',
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
