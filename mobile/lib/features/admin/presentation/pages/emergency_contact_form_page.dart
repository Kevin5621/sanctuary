import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/privacy_states.dart';
import '../../../support/domain/entities/emergency_contact.dart';
import '../../../support/presentation/cubit/emergency_contact_cubit.dart';

/// Form tambah/ubah layanan bantuan darurat (A-BAN-01).
///
/// Dibuka dari [AdminBantuanTab] dengan cubit yang sama (lewat
/// [BlocProvider.value]), sehingga daftar di belakangnya ikut segar setelah
/// simpan tanpa perlu memuat ulang manual.
class EmergencyContactFormPage extends StatefulWidget {
  const EmergencyContactFormPage({
    super.key,
    this.existing,
    required this.serviceTypes,
  });

  /// Null berarti membuat entri baru.
  final EmergencyContact? existing;

  final List<ServiceTypeOption> serviceTypes;

  @override
  State<EmergencyContactFormPage> createState() =>
      _EmergencyContactFormPageState();
}

class _EmergencyContactFormPageState extends State<EmergencyContactFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _sortOrderController;

  late String _serviceType;
  late bool _is24Hours;
  late bool _isActive;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _nameController = TextEditingController(text: existing?.name ?? '');
    _phoneController = TextEditingController(text: existing?.phone ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _sortOrderController =
        TextEditingController(text: '${existing?.sortOrder ?? 0}');

    // Nilai awal harus ada di daftar pilihan, kalau tidak DropdownButtonFormField
    // akan melempar. Jatuh ke opsi pertama bila jenis lama sudah tidak dikenal.
    final available = widget.serviceTypes.map((t) => t.value).toSet();
    final initial = existing?.serviceType ?? 'OTHER';
    _serviceType = available.contains(initial)
        ? initial
        : (widget.serviceTypes.isNotEmpty
            ? widget.serviceTypes.first.value
            : 'OTHER');

    _is24Hours = existing?.is24Hours ?? false;
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final contact = EmergencyContact(
      id: widget.existing?.id ?? '',
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      description: _descriptionController.text.trim(),
      serviceType: _serviceType,
      serviceTypeLabel: '',
      is24Hours: _is24Hours,
      isActive: _isActive,
      sortOrder: int.tryParse(_sortOrderController.text.trim()) ?? 0,
    );

    final saved = await context.read<EmergencyContactCubit>().save(contact);
    if (saved && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Pratinjau penanda verifikasi mengikuti apa yang diketik, memakai aturan
    // yang sama dengan server: keberadaan "[VERIFIKASI]" pada keterangan.
    final willNeedVerification =
        _descriptionController.text.toUpperCase().contains('[VERIFIKASI]');

    return Scaffold(
      backgroundColor: AppColors.creamBg,
      appBar: AppBar(
        backgroundColor: AppColors.creamBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.midnight,
        title: Text(
          _isEditing ? 'Ubah Layanan' : 'Tambah Layanan',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.midnight,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const _CriticalNoticeCard(),
              const SizedBox(height: AppSpacing.md),

              const _FieldLabel('Nama layanan'),
              TextFormField(
                controller: _nameController,
                decoration: _decoration('mis. Unit Konseling Mahasiswa'),
                textInputAction: TextInputAction.next,
                maxLength: 128,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 3) return 'Minimal 3 karakter';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              const _FieldLabel('Nomor telepon'),
              TextFormField(
                controller: _phoneController,
                decoration: _decoration('mis. 119 atau (021) 5550-0100'),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                maxLength: 32,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 3) return 'Nomor telepon wajib diisi';
                  if (!RegExp(r'\d').hasMatch(text)) {
                    return 'Harus memuat angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              const _FieldLabel('Jenis layanan'),
              DropdownButtonFormField<String>(
                initialValue: _serviceType,
                decoration: _decoration('Pilih jenis'),
                items: [
                  for (final option in widget.serviceTypes)
                    DropdownMenuItem(
                      value: option.value,
                      child: Text(option.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _serviceType = value);
                },
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Wajib dipilih' : null,
              ),
              const SizedBox(height: AppSpacing.sm),

              const _FieldLabel('Keterangan'),
              TextFormField(
                controller: _descriptionController,
                decoration: _decoration(
                  'Jam layanan, cara menghubungi, atau catatan lain',
                ),
                maxLines: 3,
                maxLength: 500,
                onChanged: (_) => setState(() {}),
              ),

              // A-BAN-04 — pratinjau langsung status verifikasi.
              if (willNeedVerification) ...[
                const SizedBox(height: 4),
                const Row(
                  children: [
                    VerificationBadge(dense: true),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Penanda [VERIFIKASI] terdeteksi, nomor ini akan ditandai belum diverifikasi.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: AppColors.warmTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              const _FieldLabel('Urutan tampil'),
              TextFormField(
                controller: _sortOrderController,
                decoration: _decoration('0 = paling atas'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null) return 'Harus berupa angka';
                  if (parsed < 0 || parsed > 999) return 'Antara 0 dan 999';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              StateCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _is24Hours,
                      activeTrackColor: AppColors.midnight,
                      title: const Text(
                        'Layanan 24 jam',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.midnight,
                        ),
                      ),
                      subtitle: const Text(
                        'Tandai bila dapat dihubungi kapan saja',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.warmTextSecondary,
                        ),
                      ),
                      onChanged: (value) => setState(() => _is24Hours = value),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isActive,
                      activeTrackColor: AppColors.midnight,
                      title: const Text(
                        'Aktif',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.midnight,
                        ),
                      ),
                      subtitle: const Text(
                        'Saat nonaktif, layanan ini tidak terlihat sama sekali '
                        'oleh mahasiswa, dosen, maupun kaprodi',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.3,
                          color: AppColors.warmTextSecondary,
                        ),
                      ),
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              BlocBuilder<EmergencyContactCubit, EmergencyContactState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      if (state.errorMessage != null) ...[
                        ErrorStateCard(
                          title: 'Gagal menyimpan',
                          message: state.errorMessage!,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      ElevatedButton.icon(
                        onPressed: state.isSaving ? null : _submit,
                        icon: state.isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(_isEditing ? 'Simpan Perubahan' : 'Tambahkan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.midnight,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusPill),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 13,
          color: AppColors.warmTextMuted,
        ),
        filled: true,
        fillColor: AppColors.cardBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.cartoonBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.cartoonBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.midnight, width: 1.8),
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppColors.midnight,
        ),
      ),
    );
  }
}

/// Pengingat bahwa data di layar ini bukan konfigurasi biasa.
class _CriticalNoticeCard extends StatelessWidget {
  const _CriticalNoticeCard();

  @override
  Widget build(BuildContext context) {
    return const StateCard(
      color: AppColors.moodAngerBg,
      borderColor: AppColors.ewsIntervention,
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 20, color: AppColors.ewsIntervention),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Nomor ini akan dihubungi orang yang sedang tidak baik-baik saja. '
              'Pastikan Anda benar-benar meneleponnya sebelum diaktifkan, '
              'nomor krisis yang salah lebih berbahaya daripada tidak ada nomor.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.midnight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
