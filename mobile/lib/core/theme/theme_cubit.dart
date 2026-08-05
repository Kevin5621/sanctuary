import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penyimpanan preferensi tampilan.
///
/// Memakai [FlutterSecureStorage] yang sudah dipakai [TokenStorage] alih-alih
/// menambah dependensi baru hanya untuk satu boolean. Isinya bukan rahasia,
/// tetapi menumpang penyimpanan yang sudah tersedia di semua platform target
/// lebih murah daripada memperkenalkan paket kedua.
class ThemePreferenceStorage {
  ThemePreferenceStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions:
                  IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  final FlutterSecureStorage _storage;

  static const _key = 'sanctuary.theme_mode';

  Future<ThemeMode> read() async {
    final value = await _storage.read(key: _key);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.system,
    };
  }

  Future<void> write(ThemeMode mode) => _storage.write(
        key: _key,
        value: switch (mode) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
        },
      );
}

/// Cubit tema aplikasi (L-PRO-04 / M-PRO-08).
///
/// Pilihan pengguna disimpan dan dipulihkan saat aplikasi dibuka kembali —
/// `ThemeMode.system` hanya menjadi nilai awal sebelum pengguna memilih,
/// bukan satu-satunya perilaku yang mungkin.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._storage) : super(ThemeMode.system);

  final ThemePreferenceStorage _storage;

  /// Dipanggil sekali saat startup, sebelum MaterialApp dibangun.
  Future<void> restore() async {
    emit(await _storage.read());
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == state) return;
    emit(mode);
    await _storage.write(mode);
  }

  /// Toggle dua arah untuk switch sederhana pada layar Profil.
  ///
  /// Saat masih mengikuti sistem, nilai [isCurrentlyDark] menentukan arah
  /// pertama supaya sakelarnya bergerak sesuai yang dilihat pengguna, bukan
  /// melompat ke tema yang sama dengan tampilan saat itu.
  Future<void> toggleDark({required bool isCurrentlyDark}) {
    final target = switch (state) {
      ThemeMode.system => isCurrentlyDark ? ThemeMode.light : ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
    };
    return setMode(target);
  }
}
