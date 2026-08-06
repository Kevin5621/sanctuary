import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/admin/presentation/pages/admin_shell_page.dart';
import '../../features/dosen/presentation/pages/dosen_shell_page.dart';
import '../../features/kaprodi/presentation/pages/kaprodi_shell_page.dart';
import '../../features/mahasiswa/presentation/pages/mahasiswa_shell_page.dart';
import '../../features/privacy/presentation/pages/privacy_settings_page.dart';
import 'router_refresh.dart';

/// Prefix rute per peran — dipakai gerbang navigasi untuk memastikan
/// pengguna tidak dapat membuka shell milik peran lain (walau dengan deep link).
const _rolePathPrefix = {
  UserRole.student: '/student',
  UserRole.lecturer: '/lecturer',
  UserRole.headOfProgram: '/kaprodi',
  UserRole.admin: '/admin',
};

/// Router aplikasi dengan gerbang berbasis peran.
///
/// Aturan redirect:
///  1. Sesi belum diketahui  -> layar splash (memulihkan token).
///  2. Belum masuk           -> /login.
///  3. Sudah masuk           -> shell sesuai peran; deep link ke shell peran
///     lain otomatis dialihkan kembali ke beranda perannya.
///
/// Catatan keamanan: gerbang ini murni untuk pengalaman pengguna. Otorisasi
/// sesungguhnya tetap ditegakkan backend (RBAC + privacy middleware).
GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final auth = authCubit.state;
      final location = state.matchedLocation;

      if (auth.status == AuthStatus.unknown) {
        return location == '/' ? null : '/';
      }

      if (auth.status == AuthStatus.unauthenticated) {
        return location == '/login' ? null : '/login';
      }

      final home = auth.role.homeRoute;
      final prefix = _rolePathPrefix[auth.role];

      if (prefix == null) return '/login';
      if (location == '/' || location == '/login') return home;
      if (!location.startsWith(prefix)) return home;

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const _SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),

      // ---------------- MAHASISWA: 5 tab (Beranda, Mood, Jurnal, Terapis AI, Profil) ----------------
      GoRoute(
        path: '/student/home',
        builder: (_, __) => const MahasiswaShellPage(initialIndex: 0),
      ),
      GoRoute(
        path: '/student/mood',
        builder: (_, __) => const MahasiswaShellPage(initialIndex: 1),
      ),
      GoRoute(
        path: '/student/journal',
        builder: (_, __) => const MahasiswaShellPage(initialIndex: 2),
      ),
      GoRoute(
        path: '/student/ai-chat',
        builder: (_, __) => const MahasiswaShellPage(initialIndex: 3),
      ),
      GoRoute(
        path: '/student/profile',
        builder: (_, __) => const MahasiswaShellPage(initialIndex: 4),
        routes: [
          GoRoute(
            path: 'privacy',
            builder: (_, __) => const PrivacySettingsPage(),
          ),
        ],
      ),

      // ---------------- DOSEN PEMBIMBING: 3 tab ----------------
      GoRoute(
        path: '/lecturer/advisees',
        builder: (_, __) => const DosenShellPage(),
      ),
      GoRoute(
        path: '/lecturer/condition',
        builder: (_, __) => const DosenShellPage(),
      ),
      GoRoute(
        path: '/lecturer/profile',
        builder: (_, __) => const DosenShellPage(),
      ),

      // ---------------- KAPRODI: 4 tab ----------------
      GoRoute(
        path: '/kaprodi/dashboard',
        builder: (_, __) => const KaprodiShellPage(),
      ),
      GoRoute(
        path: '/kaprodi/advisors',
        builder: (_, __) => const KaprodiShellPage(),
      ),
      GoRoute(
        path: '/kaprodi/reports',
        builder: (_, __) => const KaprodiShellPage(),
      ),
      GoRoute(
        path: '/kaprodi/profile',
        builder: (_, __) => const KaprodiShellPage(),
      ),

      // ---------------- ADMIN: 2 tab ----------------
      GoRoute(
        path: '/admin/support',
        builder: (_, __) => const AdminShellPage(),
      ),
      GoRoute(
        path: '/admin/profile',
        builder: (_, __) => const AdminShellPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Halaman tidak ditemukan')),
      body: Center(child: Text('Rute ${state.uri} tidak dikenali.')),
    ),
  );
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
