# Sanctuary

Aplikasi kesehatan mental mahasiswa. **Full Online** — seluruh data (mood, jurnal, chat) disimpan dan diakses langsung lewat REST API, tanpa database lokal maupun sinkronisasi offline di aplikasi.

```
Sanctuary/
├─ api-standart/     Standar API yang diikuti backend (sumber kebenaran)
├─ backend/          Go 1.23 + Gin, monolith vertical slice, PostgreSQL
└─ mobile/           Flutter, Clean Architecture feature-first, Cubit/BLoC
```

Status build saat ini: `go build ./...` ✔ · `go vet ./...` ✔ · 8 test EWS ✔ · `flutter analyze` bersih ✔ · 5 test Cubit privasi ✔

---

## 1. Menjalankan

### Backend

```bash
cd backend
cp .env.example .env          # sesuaikan DB_DSN & JWT_SECRET (min. 32 karakter)
createdb sanctuary            # PostgreSQL 14+

# Skema: pilih salah satu
psql -d sanctuary -f migrations/20260805090000_initial_schema.sql   # produksi-grade (Atlas)
# atau set DB_AUTO_MIGRATE=true untuk development

go run ./cmd/seed             # data demo (idempotent)
go run ./cmd/api              # http://localhost:8080
```

### Mobile

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1   # emulator Android
```

### Akun demo

Password seluruh akun: `Sanctuary123!` (ubah lewat `SEED_DEFAULT_PASSWORD`).

| Email | Peran | Catatan |
|---|---|---|
| `admin@sanctuary.ac.id` | Admin (2 tab) | CRUD layanan darurat |
| `kaprodi@sanctuary.ac.id` | Kaprodi (4 tab) | 6 mahasiswa ikut statistik → dashboard tampil |
| `dosen1@sanctuary.ac.id` | Dosen (3 tab) | **5 bimbingan** → tab Kondisi tampil |
| `dosen2@sanctuary.ac.id` | Dosen (3 tab) | **3 bimbingan** → tab Kondisi "Data belum cukup" |
| `mahasiswa1..8@sanctuary.ac.id` | Mahasiswa (4 tab + AI) | profil kondisi bervariasi (lihat tabel di §5) |

---

## 2. Arsitektur backend

Mengikuti [`api-standart/api-folder-structure.md`](api-standart/api-folder-structure.md): monolith Go dengan vertical slice per domain.

```
backend/
├─ cmd/{api,seed}/                    entry point
├─ internal/core/
│  ├─ apptime/                        SATU-SATUNYA sumber waktu (larangan time.Now())
│  ├─ constants/                      role, share level, level & indikator EWS
│  ├─ infrastructure/{config,database,redis,router}/
│  ├─ middleware/                     auth, rbac, privacy, security, rate limit
│  └─ utils/                          response envelope, error codes, pagination, jwt, k-anonymity
├─ internal/auth/                     login, rotasi refresh token, audit
├─ internal/student/                  privasi, jurnal (privat), metrik harian, DASS-21
├─ internal/mentor/                   daftar bimbingan + ENGINE EWS
├─ internal/program/                  agregat prodi (k-anonymity)
├─ internal/support/                  layanan bantuan darurat
├─ migrations/                        Atlas SQL, timestamped
└─ apps/api/seeders/                  satu-satunya tempat data demo dibuat
```

Setiap domain berlapis `data/{models,repositories}` → `domain/{dto,mapper,usecase}` → `presentation/{handler,router}`.

Kepatuhan standar:

| Standar | Implementasi |
|---|---|
| Amplop response `{success, data, meta}` | [`utils/response.go`](backend/internal/core/utils/response.go) |
| Error code UPPER_SNAKE + `ErrorCodeMap` | [`utils/errors.go`](backend/internal/core/utils/errors.go) |
| `page`/`per_page`, maks 20, `NormalizePagination` | [`utils/pagination.go`](backend/internal/core/utils/pagination.go) |
| ORDER BY whitelist (`clause.OrderByColumn`) | `utils.SafeOrderBy` |
| Rotasi refresh token + `SELECT … FOR UPDATE` | [`auth_usecase.go`](backend/internal/auth/domain/usecase/auth_usecase.go) |
| CSRF double-submit, security headers, CORS | [`security_middleware.go`](backend/internal/core/middleware/security_middleware.go) |
| Rate limit Redis fixed-window, fail-closed | [`rate_limit_middleware.go`](backend/internal/core/middleware/rate_limit_middleware.go) |
| Context ber-timeout untuk semua query | `utils.DBContext` |
| Panic recovery, body limit, graceful shutdown | `middleware.Recovery`, `cmd/api/main.go` |
| Tanpa hardcode nilai bisnis | seluruh ambang ada di `config.Config` |

### Catatan penyimpangan yang disengaja

`api-security-standards.md` §1.1 mewajibkan token hanya lewat cookie HttpOnly. Aplikasi Flutter native tidak memiliki cookie jar browser, sehingga:

- **Klien web** → token tetap dikirim via cookie `HttpOnly; Secure; SameSite=Strict` + wajib `X-CSRF-Token`.
- **Klien native** (`X-Client-Type: mobile`) → token dikembalikan di body dan disimpan pada Keychain/EncryptedSharedPreferences; CSRF dilewati karena Bearer bukan ambient credential.

Keduanya ditangani satu handler ([`auth_handler.go`](backend/internal/auth/presentation/handler/auth_handler.go)) dan satu middleware ([`auth_middleware.go`](backend/internal/core/middleware/auth_middleware.go)).

---

## 3. Aturan privasi (ditegakkan server-side)

### Konten privat mutlak

Teks **Jurnal Bebas** dan **Chat AI** hanya bisa diakses mahasiswa pemiliknya. Pertahanannya berlapis:

1. **Rute** — hanya ada di bawah `/students/me/…`; tidak ada endpoint yang menerima id mahasiswa dari klien.
2. **Middleware** — `PrivateContentGuard()` menolak role selain `STUDENT` dengan `PRIVATE_CONTENT_FORBIDDEN`.
3. **Repository** — `JournalRepository` tidak memiliki satu pun method yang bisa membaca lintas pengguna; setiap query wajib menerima `userID` dari klaim JWT.
4. **Skema** — kolom teks berada di tabel terpisah dari metrik agregabel, sehingga query analitik secara struktural tidak menyentuhnya.

### Matriks akses

| Data | Mahasiswa (pemilik) | Dosen Pembimbing | Kaprodi | Admin |
|---|---|---|---|---|
| Teks jurnal & chat AI | ✅ penuh | ❌ tidak ada jalur API | ❌ | ❌ |
| Indikator kondisi individu | ✅ | ⚠️ sesuai `share_level` | ❌ | ❌ |
| Tren mingguan | ✅ | ⚠️ hanya `SUMMARY_TREND` | ❌ | ❌ |
| Status EWS | ✅ | ⚠️ butuh `allow_early_warning` | ❌ (hanya sebaran agregat) | ❌ |
| Agregat kelompok | — | ⚠️ k-anonymity ≥ 5 | ⚠️ k-anonymity ≥ 5 | ❌ |
| Layanan darurat | 📖 baca | 📖 baca | 📖 baca | ✏️ CRUD |

### Tiga tingkat berbagi + dua izin terpisah

| `share_level` | Yang dosen terima |
|---|---|
| `CLOSED` (Tertutup) | `null` — tidak ada indikator sama sekali |
| `SUMMARY` (Ringkasan) | indikator kondisi, tanpa tren |
| `SUMMARY_TREND` (Ringkasan + Tren) | indikator + grafik tren mingguan |

- `allow_early_warning` — status EWS dikirim ke pembimbing (otomatis mati saat `CLOSED`).
- `allow_program_statistic` — data ikut dihitung dalam agregat prodi.

Default untuk mahasiswa yang belum pernah mengatur: **paling tertutup** (`CLOSED`, kedua izin `false`) — lihat `DefaultPrivacySetting`.

### K-anonymity

`utils.NewAggregateGuard(groupSize)` adalah gerbang tunggal seluruh angka agregat. Bila anggota < `K_ANONYMITY_MIN_GROUP` (default 5, config menolak nilai < 5), response tetap `200` dengan `is_sufficient: false` dan pesan "Data belum cukup" — tanpa satu angka pun, termasuk ukuran kelompoknya sendiri (angka kecil sudah bersifat re-identifying).

Setiap pembukaan indikator mahasiswa oleh dosen dan setiap akses agregat tercatat di `audit_logs` (tanpa memuat konten privat).

---

## 4. Early Warning System

Implementasi: [`internal/mentor/domain/usecase/ews_usecase.go`](backend/internal/mentor/domain/usecase/ews_usecase.go) — kalkulasi murni (`Calculate`) terpisah dari I/O sehingga bisa diuji unit.

| Indikator | Aturan | Config |
|---|---|---|
| `LOW_MOOD_STREAK` | mood ≤ 2 **lebih dari** 5 hari berturut-turut (hari tanpa check-in memutus rangkaian) | `EWS_LOW_MOOD_*` |
| `NEGATIVE_EMOTION_RATIO` | emosi negatif > 60%, minimal 4 data beremosi | `EWS_NEGATIVE_EMOTION_*` |
| `DASS_WORSENING` | total skor naik, atau muncul kategori Severe yang sebelumnya tidak ada | — |
| `LOW_SLEEP_NIGHTS` | tidur < 5 jam pada ≥ 2 malam | `EWS_LOW_SLEEP_*` |

Skor = jumlah indikator terpicu → level:

| Skor | Level | Label |
|---|---|---|
| 0 | `NORMAL` | Normal |
| 1 | `WATCH` | Waspada |
| 2 | `RISK` | Risiko |
| ≥ 3 **atau** DASS Severe/Extremely Severe | `INTERVENTION` | Perlu Intervensi |

Data harian < `EWS_MIN_DATA_POINTS` (default 4) → `INSUFFICIENT_DATA` / "Data belum cukup", tidak pernah level menyesatkan.

Hasil disimpan di `early_warning_logs` (kolom `indicators` jsonb, tanpa teks jurnal) agar daftar bimbingan dapat diurutkan tanpa hitung ulang; log yang dievaluasi hari ini dianggap masih berlaku.

Urutan daftar bimbingan: permintaan "minta dihubungi" → prioritas level EWS → nama.

---

## 5. Data demo & skenario uji

| Mahasiswa | Pembimbing | `share_level` | EWS harapan | Menguji |
|---|---|---|---|---|
| 1 Alya | Dosen 1 | Ringkasan + Tren | Perlu Intervensi | 4 indikator + DASS severe |
| 2 Bagas | Dosen 1 | Ringkasan + Tren | Risiko | 2 indikator |
| 3 Citra | Dosen 1 | Ringkasan | Waspada | 1 indikator, tanpa tren |
| 4 Dimas | Dosen 1 | Ringkasan + Tren | Normal | izin peringatan dini **mati** |
| 5 Erika | Dosen 1 | Ringkasan | Normal | kelompok Dosen 1 pas 5 → agregat keluar |
| 6 Fajar | Dosen 2 | **Tertutup** | — | dosen menerima indikator kosong |
| 7 Gita | Dosen 2 | Ringkasan + Tren | Waspada | status "minta dihubungi" |
| 8 Hendra | Dosen 2 | Ringkasan | Data belum cukup | hanya 2 check-in |

Angkatan 2022 (5 mahasiswa, semua ikut statistik) → laporan angkatan tampil. Angkatan 2023 (1 ikut statistik) → "Data belum cukup".

---

## 6. Endpoint

Base: `/api/v1` · Semua response memakai amplop standar.

| Method | Path | Akses |
|---|---|---|
| POST | `/auth/login`, `/auth/refresh` | publik (rate-limited per IP + per email) |
| POST/GET | `/auth/logout`, `/auth/me` | terautentikasi |
| GET/PUT | `/students/me/privacy-settings` | Mahasiswa |
| GET | `/students/me/privacy-settings/options` | Mahasiswa |
| GET/POST | `/students/me/journals` | Mahasiswa (PrivateContentGuard) |
| GET/DELETE | `/students/me/journals/:id` | Mahasiswa (pemilik) |
| POST | `/students/me/journals/:id/analyze` | Mahasiswa (pemilik) |
| GET | `/mentors/me/students` | Dosen |
| GET | `/mentors/me/students/:id` | Dosen (wajib pembimbingnya) |
| GET | `/mentors/me/condition?period_days=30\|90\|120` | Dosen (k-anonymity) |
| GET | `/programs/me/dashboard`, `/advisors`, `/reports/cohorts` | Kaprodi (k-anonymity) |
| GET | `/support/emergency-contacts` | semua peran (nonaktif hanya terlihat Admin) |
| POST/PUT/DELETE | `/support/emergency-contacts[/:id]` | Admin |

---

## 7. Arsitektur mobile

```
mobile/lib/
├─ core/
│  ├─ config/          AppConfig (dart-define, tanpa URL hardcode)
│  ├─ theme/           AppColors (sage/lavender/cream/warm grey/calming blue), AppTheme, AppSpacing
│  ├─ widgets/         ClayContainer · ClayCard · ClayButton · Responsive · ContentContainer
│  ├─ network/         DioClient (amplop + auto-refresh 401), ApiException, TokenStorage
│  └─ router/          GoRouter + gerbang peran
└─ features/<fitur>/
   ├─ data/{models,datasources,repositories}
   ├─ domain/{entities,repositories}
   └─ presentation/{cubit,pages}
```

- **Claymorphism** — `ClayContainer` membentuk permukaan dari dua bayangan berlawanan (sorotan kiri-atas, bayangan kanan-bawah) yang nilainya menyesuaikan light/dark. `ClayType.concave` dipakai untuk state terpilih.
- **Responsif** — `Responsive` memusatkan aturan breakpoint: bottom navigation pada mobile portrait, `NavigationRail` pada tablet/desktop; login memakai satu kolom vs dua panel.
- **Gerbang peran** — `createRouter` mengalihkan berdasarkan `AuthStatus` dan prefix rute per peran (`/student`, `/lecturer`, `/kaprodi`, `/admin`), jumlah tab mengikuti `UserRole.tabCount` (4/3/4/2). Gerbang ini murni UX; otorisasi sebenarnya tetap di backend.
- **Sesi** — hanya token yang tersimpan di perangkat (secure storage OS). Tidak ada jurnal/mood yang di-cache lokal.

---

## 8. Yang belum dikerjakan

Cakupan tahap ini adalah fondasi arsitektur + tiga fitur kunci yang diminta. Yang masih placeholder:

- Layar Beranda, Mood, Jurnal, dan tab Dosen/Kaprodi/Admin di Flutter — rute, shell navigasi, dan endpoint backendnya sudah siap; UI-nya masih `PlaceholderPage`.
- Endpoint check-in mood harian, DASS-21, dan chat AI belum diekspos (model, repository, dan skema tabelnya sudah ada).
- Analisis emosi memakai leksikon mock (`mock-lexicon-v1`); antarmuka `EmotionAnalyzer` sengaja kecil agar penggantian ke model NLP tidak menyentuh usecase.
- Nomor layanan darurat bertanda `[VERIFIKASI]` adalah placeholder kampus dan **wajib** diverifikasi Admin sebelum rilis.
- Kode error khusus Sanctuary (`PRIVATE_CONTENT_FORBIDDEN`, `INSUFFICIENT_GROUP_SIZE`, dll.) perlu ditambahkan ke `api-standart/api-error-codes.md`.
