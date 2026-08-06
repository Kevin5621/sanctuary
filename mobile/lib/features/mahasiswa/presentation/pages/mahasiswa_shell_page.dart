import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/floating_cartoon_navbar.dart';
import '../../data/repositories/journal_repository.dart';
import '../cubit/sebaran_emosi_cubit.dart';
import 'beranda_tab.dart';
import 'jurnal_tab.dart';
import 'mood_tab.dart';
import 'profil_tab.dart';
import 'terapis_ai_tab.dart';

class MahasiswaShellPage extends StatefulWidget {
  const MahasiswaShellPage({super.key, this.initialIndex = 0});

  final int initialIndex;

  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MahasiswaShellPageState>();
    if (state != null) {
      state.setTab(index);
    }
  }

  @override
  State<MahasiswaShellPage> createState() => _MahasiswaShellPageState();
}

class _MahasiswaShellPageState extends State<MahasiswaShellPage> {
  late int _currentIndex;

  void setTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

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
    // SebaranEmosiCubit hidup di level shell, bukan di dalam tab Mood.
    // Alasannya: tab Jurnal perlu menyegarkannya setelah sebuah analisis
    // selesai, sehingga grafik di tab Mood tidak tertinggal satu analisis dari
    // kenyataan. Satu instance dipakai bersama kedua tab.
    return BlocProvider<SebaranEmosiCubit>(
      create: (context) =>
          SebaranEmosiCubit(context.read<JournalRepository>())..load(),
      child: Scaffold(
        extendBody: true, // Floating navbar over scrollable background
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: FloatingCartoonNavbar(
          selectedIndex: _currentIndex,
          onTap: (index) {
            setTab(index);
          },
          items: _navItems,
        ),
      ),
    );
  }
}

