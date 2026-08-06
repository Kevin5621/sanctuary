import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/clay_container.dart';
import '../../../../core/widgets/vector_illustrations.dart';
import '../../data/repositories/ai_chat_repository.dart';
import '../../domain/entities/ai_chat.dart';
import '../cubit/terapis_ai_cubit.dart';
import 'bantuan_darurat_page.dart';
import 'latihan_napas_page.dart';

/// Tab Terapis AI (M-AI).
///
/// Struktur layar mengikuti keputusan D-5: consent diperiksa lebih dulu, dan
/// tidak ada jalur menuju kotak pesan sebelum mahasiswa memutuskan. Bila ia
/// menolak, tab TETAP ADA namun isinya latihan mandiri — menolak berbagi data
/// ke pihak ketiga tidak boleh berarti kehilangan akses ke fitur menenangkan.
class TerapisAiTab extends StatelessWidget {
  const TerapisAiTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TerapisAiCubit>(
      create: (context) =>
          TerapisAiCubit(context.read<AiChatRepository>())..load(),
      child: const _TerapisAiView(),
    );
  }
}

class _TerapisAiView extends StatelessWidget {
  const _TerapisAiView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TerapisAiCubit, TerapisAiState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.creamBg,
          appBar: _buildAppBar(context, state),
          body: switch (state.view) {
            TerapisAiView.loading =>
              const Center(child: CircularProgressIndicator()),
            TerapisAiView.consent => _ConsentScreen(state: state),
            TerapisAiView.selfHelp => const _SelfHelpScreen(),
            TerapisAiView.serviceUnavailable => const _ServiceUnavailableScreen(),
            TerapisAiView.failure => _FailureScreen(state: state),
            TerapisAiView.chat => _ChatScreen(state: state),
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, TerapisAiState state) {
    // Penghitung giliran memakai batas dari SERVER, bukan angka yang
    // ditulis di klien — pemangkasan 100 giliran terjadi di backend (M-AI-03).
    final subtitle = switch (state.view) {
      TerapisAiView.chat =>
        'Gemini 2.5 Flash · ${state.history.turnCount}/${state.history.turnLimit} giliran',
      TerapisAiView.selfHelp => 'Mode latihan mandiri',
      _ => 'Pendamping refleksi',
    };

    return AppBar(
      elevation: 0,
      title: Row(
        children: [
          const AiTherapistAvatarIllustration(size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Terapis AI',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.warmTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// M-AI-01 — Layar consent
// ---------------------------------------------------------------------------

class _ConsentScreen extends StatelessWidget {
  const _ConsentScreen({required this.state});

  final TerapisAiState state;

  @override
  Widget build(BuildContext context) {
    final notice = state.consent.notice;
    final cubit = context.read<TerapisAiCubit>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.consent.needsRenewal)
              const ClayContainer(
                color: AppColors.moodAngerBg,
                padding: EdgeInsets.all(AppSpacing.md),
                margin: EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.update_rounded, color: AppColors.midnight),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Pemberitahuan privasi telah diperbarui. Silakan baca '
                        'kembali sebelum melanjutkan.',
                        style: TextStyle(fontSize: 13, color: AppColors.midnight),
                      ),
                    ),
                  ],
                ),
              ),

            ClayContainer(
              color: AppColors.cardBg,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.lavenderBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.privacy_tip_rounded,
                          color: AppColors.midnight,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          notice.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.midnight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    notice.summary,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.midnight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...notice.points.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Icon(
                              Icons.check_circle_outline_rounded,
                              size: 17,
                              color: AppColors.sageDark,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              point,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: AppColors.warmTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            ClayButton(
              label: notice.acceptLabel,
              icon: Icons.verified_user_rounded,
              isLoading: state.isSubmittingConsent,
              onPressed: state.isSubmittingConsent
                  ? null
                  : () => cubit.decideConsent(accepted: true),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClayButton(
              label: notice.declineLabel,
              color: AppColors.creamAlt,
              foregroundColor: AppColors.midnight,
              onPressed: state.isSubmittingConsent
                  ? null
                  : () => cubit.decideConsent(accepted: false),
            ),

            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                'Versi pemberitahuan: ${notice.noticeVersion}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.warmTextMuted,
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fallback saat consent ditolak — latihan mandiri (M-PRO-05)
// ---------------------------------------------------------------------------

class _SelfHelpScreen extends StatelessWidget {
  const _SelfHelpScreen();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TerapisAiCubit>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ClayContainer(
              color: AppColors.sageLight,
              padding: EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_moon_rounded, color: AppColors.sageDark),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Kamu memilih untuk tidak mengirim percakapan ke layanan '
                      'pihak ketiga. Pilihan itu dihormati — tidak ada teks yang '
                      'dikirim keluar. Latihan di bawah ini berjalan sepenuhnya '
                      'di aplikasi.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.midnight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            const Text(
              'Latihan Mandiri',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.midnight,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            _SelfHelpCard(
              icon: Icons.air_rounded,
              title: 'Latihan Napas 4-7-8',
              subtitle: 'Menurunkan ketegangan dalam beberapa menit.',
              color: AppColors.moodFearBg,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LatihanNapasPage()),
              ),
            ),
            _SelfHelpCard(
              icon: Icons.spa_rounded,
              title: 'Grounding 5-4-3-2-1',
              subtitle: 'Mengembalikan fokus ke sekitarmu saat pikiran ramai.',
              color: AppColors.lavenderBg,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LatihanNapasPage()),
              ),
            ),
            _SelfHelpCard(
              icon: Icons.emergency_rounded,
              title: 'Layanan Bantuan Darurat',
              subtitle: 'Terhubung dengan pendamping profesional 24/7.',
              color: AppColors.moodAngerBg,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BantuanDaruratPage()),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            ClayContainer(
              color: AppColors.creamAlt,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Berubah pikiran?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.midnight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kamu bisa membaca ulang pemberitahuan privasinya dan '
                    'memutuskan kembali kapan saja.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.warmTextSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClayButton(
                    label: 'Baca ulang pemberitahuan',
                    icon: Icons.menu_book_rounded,
                    expanded: false,
                    color: AppColors.cardBg,
                    foregroundColor: AppColors.midnight,
                    onPressed: cubit.reopenConsent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _SelfHelpCard extends StatelessWidget {
  const _SelfHelpCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClayContainer(
      color: color,
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: AppColors.midnight, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.midnight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.warmTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.midnight),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Layanan belum dikonfigurasi di server
// ---------------------------------------------------------------------------

class _ServiceUnavailableScreen extends StatelessWidget {
  const _ServiceUnavailableScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ClayContainer(
              color: AppColors.creamAlt,
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Icon(Icons.cloud_off_rounded,
                      size: 42, color: AppColors.warmTextSecondary),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Terapis AI belum aktif',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.midnight,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Layanan percakapan belum tersedia di server ini. '
                    'Latihan napas dan grounding tetap bisa kamu pakai.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.warmTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClayButton(
              label: 'Buka Latihan Napas',
              icon: Icons.air_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LatihanNapasPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailureScreen extends StatelessWidget {
  const _FailureScreen({required this.state});

  final TerapisAiState state;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 42, color: AppColors.warmTextSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              state.errorMessage ?? 'Gagal memuat percakapan.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.warmTextSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClayButton(
              label: 'Coba lagi',
              icon: Icons.refresh_rounded,
              expanded: false,
              onPressed: context.read<TerapisAiCubit>().refresh,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// M-AI-02 — Percakapan
// ---------------------------------------------------------------------------

class _ChatScreen extends StatefulWidget {
  const _ChatScreen({required this.state});

  final TerapisAiState state;

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.history.messages.length !=
        widget.state.history.messages.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    context.read<TerapisAiCubit>().sendMessage(text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cubit = context.read<TerapisAiCubit>();
    final messages = state.history.messages;

    return Column(
      children: [
        // M-AI-04 — kartu bantuan krisis, komponen yang sama dengan jurnal.
        if (state.showCrisisCard)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: CrisisAlertCardWidget(
              message: state.crisisMessage.isNotEmpty
                  ? state.crisisMessage
                  : 'Sistem mendeteksi tanda krisis. Kamu tidak sendirian.',
              onCallHotline: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BantuanDaruratPage()),
              ),
              onDismiss: cubit.dismissCrisisCard,
            ),
          ),

        if (state.history.isTruncated)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              'Menampilkan ${state.history.turnLimit} giliran terakhir. '
              'Percakapan yang lebih lama tidak ditampilkan.',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.warmTextMuted,
              ),
            ),
          ),

        Expanded(
          child: messages.isEmpty
              ? const _EmptyChatState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: messages.length + (state.isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= messages.length) return const _TypingBubble();
                    return _MessageBubble(message: messages[index]);
                  },
                ),
        ),

        if (state.errorMessage != null)
          _ErrorBar(
            message: state.errorMessage!,
            canRetry: state.hasRetryableMessage,
            onRetry: cubit.retryLastMessage,
            onDismiss: cubit.clearError,
          ),

        _Composer(
          controller: _controller,
          isSending: state.isSending,
          onSend: _send,
        ),
      ],
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AiTherapistAvatarIllustration(size: 72),
            SizedBox(height: AppSpacing.md),
            Text(
              'Mulai percakapan',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.midnight,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Ceritakan apa yang sedang kamu rasakan. Terapis AI bukan '
              'psikolog dan tidak memberi diagnosis.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.warmTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isFromStudent;

    // Dua shade dari palet yang sudah dipakai tab lain: lavender untuk
    // mahasiswa, krem untuk AI. Tidak ada warna baru yang diperkenalkan.
    final bubbleColor = isUser ? AppColors.lavenderBg : AppColors.cardBg;

    return Opacity(
      opacity: message.isPending ? 0.6 : 1,
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              ClayContainer(
                color: bubbleColor,
                depth: 8,
                spread: 4,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: const TextStyle(
                        color: AppColors.midnight,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    if (message.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          _formatTime(message.createdAt!),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.warmTextMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Balasan fallback ditandai jujur: mahasiswa berhak tahu bahwa
              // yang ia baca adalah pesan sistem, bukan jawaban model.
              if (message.isFallback)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 12, color: AppColors.warmTextMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Pesan otomatis — model sedang tidak merespons',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                          color: AppColors.warmTextMuted.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: ClayContainer(
        color: AppColors.cardBg,
        depth: 8,
        spread: 4,
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Terapis AI sedang menulis…',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.warmTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBar extends StatelessWidget {
  const _ErrorBar({
    required this.message,
    required this.canRetry,
    required this.onRetry,
    required this.onDismiss,
  });

  final String message;
  final bool canRetry;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.moodAngerBg,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: AppColors.midnight),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.midnight),
            ),
          ),
          if (canRetry)
            TextButton(
              onPressed: onRetry,
              child: const Text('Kirim ulang'),
            ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.midnight,
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: 84),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: AppColors.cartoonShadow,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isSending,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Tulis pesan ke Terapis AI…',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            onPressed: isSending ? null : onSend,
            icon: isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.midnight,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
