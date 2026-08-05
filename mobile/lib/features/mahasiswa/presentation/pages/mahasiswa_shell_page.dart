import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.cartoonShadow,
              offset: Offset(0, -4),
              blurRadius: 10,
            )
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.mood_outlined),
              selectedIcon: Icon(Icons.mood_rounded),
              label: 'Mood',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Jurnal',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum_rounded),
              label: 'Terapis AI',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
