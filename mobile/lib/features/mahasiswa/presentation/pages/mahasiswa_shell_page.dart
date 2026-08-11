import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/floating_cartoon_navbar.dart';
import '../../data/repositories/contact_request_repository.dart';
import '../../data/repositories/daily_metric_repository.dart';
import '../../data/repositories/journal_repository.dart';
import '../cubit/beranda_cubit.dart';
import '../cubit/mood_history_cubit.dart';
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
    // Beberapa cubit hidup di level shell, bukan di dalam satu tab, karena
    // tab lain perlu menyegarkannya:
    //
    // - SebaranEmosiCubit: tab Jurnal menyegarkannya setelah sebuah analisis
    //   selesai, sehingga grafik di tab Mood tidak tertinggal satu analisis
    //   dari kenyataan.
    // - BerandaCubit & MoodHistoryCubit: check-in kini bisa diisi dari dua
    //   layar — tombol di Beranda dan kalender di tab Mood. IndexedStack
    //   menjaga keduanya tetap hidup, jadi tanpa instance bersama yang satu
    //   tidak pernah tahu yang lain baru saja menyimpan. Kalender Mood yang
    //   basi berbahaya: hari yang sudah terisi terlihat kosong, dan mengetuknya
    //   akan menimpa isian tadi dengan nilai bawaan form.
    return MultiBlocProvider(
      providers: [
        BlocProvider<SebaranEmosiCubit>(
          create: (context) => SebaranEmosiCubit(context.read<JournalRepository>())..load(),
        ),
        BlocProvider<BerandaCubit>(
          create: (context) => BerandaCubit(
            metrics: context.read<DailyMetricRepository>(),
            contactRequests: context.read<ContactRequestRepository>(),
          )..load(),
        ),
        BlocProvider<MoodHistoryCubit>(
          create: (context) => MoodHistoryCubit(context.read<DailyMetricRepository>())..load(),
        ),
      ],
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

