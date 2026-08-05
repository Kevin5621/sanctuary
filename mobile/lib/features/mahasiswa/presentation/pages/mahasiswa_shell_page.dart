import 'package:flutter/material.dart';
import '../../../../core/widgets/floating_cartoon_navbar.dart';
import 'beranda_tab.dart';
import 'jurnal_tab.dart';
import 'mood_tab.dart';
import 'profil_tab.dart';
import 'terapis_ai_tab.dart';

class MahasiswaShellPage extends StatefulWidget {
  const MahasiswaShellPage({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MahasiswaShellPage> createState() => _MahasiswaShellPageState();
}

class _MahasiswaShellPageState extends State<MahasiswaShellPage> {
  late int _currentIndex;

  final List<Widget> _tabs = const [
    BerandaTab(),
    MoodTab(),
    JurnalTab(),
    TerapisAiTab(),
    ProfilTab(),
  ];

  final List<FloatingCartoonNavbarItem> _navItems = const [
    FloatingCartoonNavbarItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Beranda',
    ),
    FloatingCartoonNavbarItem(
      icon: Icons.mood_outlined,
      selectedIcon: Icons.mood_rounded,
      label: 'Mood',
    ),
    FloatingCartoonNavbarItem(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
      label: 'Jurnal',
    ),
    FloatingCartoonNavbarItem(
      icon: Icons.forum_outlined,
      selectedIcon: Icons.forum_rounded,
      label: 'Terapis AI',
    ),
    FloatingCartoonNavbarItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows body content to scroll smoothly behind floating navbar
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: FloatingCartoonNavbar(
        selectedIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _navItems,
      ),
    );
  }
}
