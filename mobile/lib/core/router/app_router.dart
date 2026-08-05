import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/privacy/presentation/pages/privacy_settings_page.dart';
import '../../features/shell/presentation/widgets/adaptive_shell.dart';
import '../theme/app_theme.dart';
import '../widgets/clay_container.dart';
import '../widgets/responsive.dart';
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

      // ---------------- MAHASISWA: 4 tab + slot Terapis AI ----------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AdaptiveShell(
          navigationShell: navigationShell,
          destinations: const [
            ShellDestination(
              label: 'Beranda',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
            ),
            ShellDestination(
              label: 'Mood',
              icon: Icons.mood_outlined,
              selectedIcon: Icons.mood_rounded,
            ),
            ShellDestination(
              label: 'Jurnal',
              icon: Icons.menu_book_outlined,
              selectedIcon: Icons.menu_book_rounded,
            ),
            ShellDestination(
              label: 'Profil',
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
            ),
          ],
          // Slot Terapis AI dibuka sebagai layar penuh di atas shell,
          // bukan sebagai tab kelima.
          floatingAction: FloatingActionButton(
            onPressed: () => context.push('/student/ai-chat'),
            tooltip: 'Terapis AI',
            child: const Icon(Icons.forum_outlined),
          ),
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student/home',
              builder: (_, __) => const PlaceholderPage(
                title: 'Beranda',
                description:
                    'Sapaan, ringkasan hari ini, kalender mood mingguan, dan pintasan DASS-21.',
                icon: Icons.spa_outlined,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student/mood',
              builder: (_, __) => const PlaceholderPage(
                title: 'Mood',
                description:
                    'Check-in harian (mood, stres, tidur, pemicu akademik), grafik ritme, dan sebaran emosi.',
                icon: Icons.insights_outlined,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student/journal',
              builder: (_, __) => const PlaceholderPage(
                title: 'Jurnal',
                description:
                    'Catatan bebas tersimpan di server, analisis emosi, saran coping, dan deteksi krisis.',
                icon: Icons.edit_note_outlined,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student/profile',
              builder: (_, __) => const _StudentProfilePage(),
              routes: [
                GoRoute(
                  path: 'privacy',
                  builder: (_, __) => const PrivacySettingsPage(),
                ),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/student/ai-chat',
        builder: (_, __) => const PlaceholderPage(
          title: 'Terapis AI',
          description:
              'Antarmuka chat (mock). Integrasi model bahasa belum diaktifkan pada tahap ini.',
          icon: Icons.forum_outlined,
        ),
      ),

      // ---------------- DOSEN PEMBIMBING: 3 tab ----------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AdaptiveShell(
          navigationShell: navigationShell,
          destinations: const [
            ShellDestination(
              label: 'Bimbingan',
              icon: Icons.groups_outlined,
              selectedIcon: Icons.groups_rounded,
            ),
            ShellDestination(
              label: 'Kondisi',
              icon: Icons.analytics_outlined,
              selectedIcon: Icons.analytics_rounded,
            ),
            ShellDestination(
              label: 'Profil',
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
            ),
          ],
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/lecturer/advisees',
              builder: (_, __) => const PlaceholderPage(
                title: 'Bimbingan',
                description:
                    'Daftar mahasiswa bimbingan terurut Early Warning System dan status minta dihubungi.',
                icon: Icons.groups_outlined,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/lecturer/condition',
              builder: (_, __) => const PlaceholderPage(
                title: 'Kondisi',
                description:
                    'Gambaran agregat kelompok bimbingan (30/90/120 hari) dengan ambang k-anonymity.',
                icon: Icons.analytics_outlined,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/lecturer/profile',
              builder: (_, __) => const _RoleProfilePage(),
            ),
          ]),
        ],
      ),

      // ---------------- KAPRODI: 4 tab ----------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AdaptiveShell(
          navigationShell: navigationShell,
          destinations: const [
            ShellDestination(
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard_rounded,
            ),
            ShellDestination(
              label: 'Pembimbing',
              icon: Icons.school_outlined,
              selectedIcon: Icons.school_rounded,
            ),
            ShellDestination(
              label: 'Laporan',
              icon: Icons.description_outlined,
              selectedIcon: Icons.description_rounded,
            ),
            ShellDestination(
              label: 'Profil',
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
            ),
          ],
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/kaprodi/dashboard',
              builder: (_, __) => const PlaceholderPage(
                title: 'Dashboard Prodi',
                description:
                    '6 metrik agregat prodi dan sebaran EWS. Angka hanya tampil bila kelompok >= 5 mahasiswa.',
                icon: Icons.dashboard_outlined,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/kaprodi/advisors',
              builder: (_, __) => const PlaceholderPage(
                title: 'Pembimbing',
                description: 'Daftar dosen pembimbing beserta beban bimbingannya.',
                icon: Icons.school_outlined,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/kaprodi/reports',
              builder: (_, __) => const PlaceholderPage(
                title: 'Laporan',
                description: 'Evaluasi per angkatan, tetap tunduk pada ambang k-anonymity.',
                icon: Icons.description_outlined,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/kaprodi/profile',
              builder: (_, __) => const _RoleProfilePage(),
            ),
          ]),
        ],
      ),

      // ---------------- ADMIN: 2 tab ----------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AdaptiveShell(
          navigationShell: navigationShell,
          destinations: const [
            ShellDestination(
              label: 'Bantuan',
              icon: Icons.support_agent_outlined,
              selectedIcon: Icons.support_agent_rounded,
            ),
            ShellDestination(
              label: 'Profil',
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
            ),
          ],
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/support',
              builder: (_, __) => const PlaceholderPage(
                title: 'Layanan Bantuan',
                description:
                    'CRUD layanan nomor darurat/krisis: nama, telepon, keterangan, 24 jam, aktif, urutan.',
                icon: Icons.support_agent_outlined,
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/profile',
              builder: (_, __) => const _RoleProfilePage(),
            ),
          ]),
        ],
      ),
    ],
    errorBuilder: (context, state) => PlaceholderPage(
      title: 'Halaman tidak ditemukan',
      description: 'Rute ${state.uri} tidak dikenali.',
      icon: Icons.explore_off_outlined,
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

/// Profil mahasiswa — pintu masuk menu Privasi & Berbagi Data.
class _StudentProfilePage extends StatelessWidget {
  const _StudentProfilePage();

  @override
  Widget build(BuildContext context) {
    return _ProfileScaffold(
      title: 'Profil',
      menuItems: [
        _ProfileMenuItem(
          icon: Icons.privacy_tip_outlined,
          label: 'Privasi & Berbagi Data',
          description: 'Atur seberapa banyak pembimbing dapat melihat.',
          onTap: () => context.push('/student/profile/privacy'),
        ),
        const _ProfileMenuItem(
          icon: Icons.fact_check_outlined,
          label: 'Skrining DASS-21',
          description: 'Isi kuesioner dan lihat riwayat hasilmu.',
        ),
        const _ProfileMenuItem(
          icon: Icons.history_rounded,
          label: 'Riwayat Analisis',
          description: 'Hasil analisis emosi dari jurnalmu.',
        ),
        const _ProfileMenuItem(
          icon: Icons.school_outlined,
          label: 'Edukasi Model',
          description: 'Bagaimana analisis emosi bekerja dan batasannya.',
        ),
        const _ProfileMenuItem(
          icon: Icons.emergency_outlined,
          label: 'Layanan Bantuan Darurat',
          description: 'Nomor pendamping profesional yang bisa dihubungi.',
        ),
        const _ProfileMenuItem(
          icon: Icons.self_improvement_outlined,
          label: 'Latihan Napas & Grounding',
          description: 'Panduan singkat untuk menenangkan diri.',
        ),
        const _ProfileMenuItem(
          icon: Icons.settings_outlined,
          label: 'Pengingat & Mode Gelap',
          description: 'Atur notifikasi check-in dan tampilan aplikasi.',
        ),
      ],
    );
  }
}

/// Profil untuk Dosen / Kaprodi / Admin — identitas dan batas akses.
class _RoleProfilePage extends StatelessWidget {
  const _RoleProfilePage();

  @override
  Widget build(BuildContext context) {
    return const _ProfileScaffold(title: 'Profil', menuItems: []);
  }
}

class _ProfileMenuItem {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.description,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback? onTap;
}

class _ProfileScaffold extends StatelessWidget {
  const _ProfileScaffold({required this.title, required this.menuItems});

  final String title;
  final List<_ProfileMenuItem> menuItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthCubit>().state;
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ContentContainer(
        child: ListView(
          children: [
            ClayCard(
              child: Row(
                children: [
                  ClayContainer(
                    width: 56,
                    height: 56,
                    color: theme.colorScheme.primaryContainer,
                    child: Center(
                      child: Text(
                        user?.initials ?? '?',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? '—',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          '${auth.role.label} · ${user?.email ?? ''}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            for (final item in menuItems) ...[
              ClayCard(
                onTap: item.onTap,
                child: Row(
                  children: [
                    Icon(item.icon, color: theme.colorScheme.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label, style: theme.textTheme.titleMedium),
                          Text(item.description, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            const SizedBox(height: AppSpacing.md),
            ClayButton(
              label: 'Keluar',
              icon: Icons.logout_rounded,
              color: theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.onSurface,
              onPressed: () => context.read<AuthCubit>().logout(),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
