import 'package:flutter/material.dart';
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded),
            label: 'Pembimbing',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description_rounded),
            label: 'Laporan',
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
