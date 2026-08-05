import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/vector_illustrations.dart';

class TerapisAiTab extends StatefulWidget {
  const TerapisAiTab({super.key});

  @override
  State<TerapisAiTab> createState() => _TerapisAiTabState();
}

class _TerapisAiTabState extends State<TerapisAiTab> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'Halo Charlie! Saya Terapis AI (Google Gemini 2.5 Flash). Ada yang sedang mengganggu pikiranmu atau ingin didiskusikan hari ini?',
      'time': '10:00',
    },
    {
      'isUser': true,
      'text': 'Saya merasa cemas dengan revisi skripsi yang menumpuk. Takut tidak lulus tepat waktu.',
      'time': '10:01',
    },
    {
      'isUser': false,
      'text': 'Perasaan cemas menjelang kelulusan sangat wajar dialami mahasiswa. Mari kita urai beban tersebut menjadi langkah-langkah kecil. Bagaimana jika kita atur target 30 menit per hari?',
      'time': '10:02',
    },
  ];

  int _turnCount = 3; // Up to 100 turns
  bool _showCrisisCard = false;

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMsg = text.trim();
    _msgController.clear();

    setState(() {
      _messages.add({
        'isUser': true,
        'text': userMsg,
        'time': '10:05',
      });
      _turnCount++;
      if (userMsg.toLowerCase().contains('bunuh diri') ||
          userMsg.toLowerCase().contains('putus asa') ||
          userMsg.toLowerCase().contains('menyerah')) {
        _showCrisisCard = true;
      }
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': 'Terima kasih sudah berbagi denganku. Ingatlah bahwa progres kecil tetaplah sebuah progres. Jangan ragu beristirahat sejenak jika merasa kewalahan.',
            'time': '10:06',
          });
          _turnCount++;
        });
      }
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        title: Row(
          children: [
            const AiTherapistAvatarIllustration(size: 38),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Terapis AI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text('Gemini 2.5 Flash · $_turnCount/100 Giliran', style: const TextStyle(fontSize: 11, color: AppColors.warmTextSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Riwayat percakapan tersimpan aman.')),
              );
            },
            icon: const Icon(Icons.history_rounded, color: AppColors.midnight),
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_showCrisisCard)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: CrisisAlertCardWidget(
                message: 'Kartu Bantuan Krisis Otomatis: Kami mendeteksi topik krisis berat. Hubungi Hotline 119 Ext 8 untuk pendampingan konselor.',
                onCallHotline: () {},
                onDismiss: () {
                  setState(() {
                    _showCrisisCard = false;
                  });
                },
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] as bool;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.midnight : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(AppSpacing.radiusMd),
                        topRight: const Radius.circular(AppSpacing.radiusMd),
                        bottomLeft: Radius.circular(isUser ? AppSpacing.radiusMd : 4),
                        bottomRight: Radius.circular(isUser ? 4 : AppSpacing.radiusMd),
                      ),
                      border: Border.all(
                        color: isUser ? AppColors.midnight : AppColors.cartoonBorder,
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cartoonShadow,
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text'] as String,
                          style: TextStyle(
                            color: isUser ? Colors.white : AppColors.midnight,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            msg['time'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: isUser ? Colors.white70 : AppColors.warmTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                _buildPromptChip('Saya merasa cemas tentang skripsi'),
                _buildPromptChip('Bagaimana cara tidur lebih nyenyak?'),
                _buildPromptChip('Trik mengatasi burnout kuliah'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.only(bottom: 84),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: AppColors.cartoonShadow, blurRadius: 10, offset: Offset(0, -4))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    onSubmitted: _sendMessage,
                    decoration: const InputDecoration(
                      hintText: 'Tulis pesan ke Terapis AI...',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filled(
                  onPressed: () => _sendMessage(_msgController.text),
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.midnight,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.midnight),
        backgroundColor: AppColors.lavenderBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          side: const BorderSide(color: AppColors.cartoonBorder, width: 1),
        ),
        onPressed: () => _sendMessage(label),
      ),
    );
  }
}
