# Environment config

File di sini dipakai lewat `--dart-define-from-file` — cara resmi Flutter
menyuntikkan konfigurasi per-lingkungan saat build (bukan file `.env` yang
dibaca saat runtime). Lihat penjelasan lengkap di
[`lib/core/config/app_config.dart`](../lib/core/config/app_config.dart).

| File | Kapan dipakai | `API_BASE_URL` wajib? |
|---|---|---|
| `env.dev.json` | development (opsional — `flutter run` tanpa flag sudah setara) | Tidak — otomatis terdeteksi per platform |
| `env.staging.json` | build/rilis ke lingkungan staging/QA | **Ya** |
| `env.prod.json` | build/rilis ke production | **Ya** |

```bash
flutter run                                                  # development, auto-detect
flutter run --dart-define-from-file=config/env.staging.json  # staging
flutter build apk --release --dart-define-from-file=config/env.prod.json
flutter build ipa --release --dart-define-from-file=config/env.prod.json
```

Bila `API_BASE_URL` tidak diisi pada build staging/production, aplikasi
sengaja **crash saat start** dengan pesan jelas — lebih baik ketahuan
langsung daripada build production diam-diam menembak `localhost`.

> **URL staging/production di file ini masih placeholder** (`sanctuary.ac.id`
> belum tentu domain nyata). Ganti dengan URL infrastruktur sesungguhnya
> sebelum dipakai CI/CD.
