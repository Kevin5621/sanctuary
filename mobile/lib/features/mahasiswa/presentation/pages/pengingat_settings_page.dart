import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class PengingatSettingsPage extends StatefulWidget {
  const PengingatSettingsPage({super.key});

  @override
  State<PengingatSettingsPage> createState() => _PengingatSettingsPageState();
}

class _PengingatSettingsPageState extends State<PengingatSettingsPage> {
  bool _enableDailyReminder = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        title: const Text('Pengingat & Tampilan'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.cartoonBorder, width: 1.2),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _enableDailyReminder,
                  onChanged: (val) {
                    setState(() {
                      _enableDailyReminder = val;
                    });
                  },
                  activeThumbColor: AppColors.midnight,
                  title: const Text(
                    'Pengingat Check-In Harian',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.midnight),
                  ),
                  subtitle: const Text(
                    'Dapatkan notifikasi ramah setiap hari untuk mencatat mood dan refleksi.',
                    style: TextStyle(fontSize: 12, color: AppColors.warmTextSecondary),
                  ),
                ),
                if (_enableDailyReminder) ...[
                  const Divider(),
                  ListTile(
                    title: const Text('Waktu Notifikasi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.lavenderBg,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        _reminderTime.format(context),
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.midnight),
                      ),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _reminderTime,
                      );
                      if (time != null) {
                        setState(() {
                          _reminderTime = time;
                        });
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
