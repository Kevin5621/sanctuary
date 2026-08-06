import 'package:flutter/material.dart';
import '../../../../core/widgets/floating_cartoon_navbar.dart';
import 'admin_profil_tab.dart';
import 'bantuan_tab.dart';
import 'kelola_akun_tab.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  late int _currentIndex = widget.initialIndex;

  final List<Widget> _tabs = const [
    AdminBantuanTab(),
    KelolaAkunTab(),
    AdminProfilTab(),
  ];

  final List<FloatingCartoonNavbarItem> _navItems = const [
    FloatingCartoonNavbarItem(
      icon: Icons.support_agent_outlined,
      selectedIcon: Icons.support_agent_rounded,
      label: 'Bantuan',
    ),
    FloatingCartoonNavbarItem(
      icon: Icons.manage_accounts_outlined,
      selectedIcon: Icons.manage_accounts_rounded,
      label: 'Akun',
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
