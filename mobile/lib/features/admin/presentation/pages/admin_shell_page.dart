import 'package:flutter/material.dart';
import '../../../../core/widgets/floating_cartoon_navbar.dart';
import 'admin_profil_tab.dart';
import 'bantuan_tab.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    AdminBantuanTab(),
    AdminProfilTab(),
  ];

  final List<FloatingCartoonNavbarItem> _navItems = const [
    FloatingCartoonNavbarItem(
      icon: Icons.support_agent_outlined,
      selectedIcon: Icons.support_agent_rounded,
      label: 'Bantuan',
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
