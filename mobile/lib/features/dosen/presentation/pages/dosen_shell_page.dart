import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Bimbingan',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Kondisi',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
