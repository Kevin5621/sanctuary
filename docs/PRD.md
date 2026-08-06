# PRD — Sanctuary

Aplikasi kesehatan mental mahasiswa berbasis analisis emosi IndoBERT.
Dokumen ini adalah **sumber kebenaran fitur** sekaligus **papan progres**.

- Arsitektur, cara menjalankan, dan detail teknis → [`README.md`](../README.md)
- Standar API yang wajib diikuti → [`api-standart/`](../api-standart/)
- Dokumen ini hanya bicara **apa yang dibangun, aturannya, dan sudah sampai mana**.

**Untuk agen AI:** baca §1–§3 dulu (invariant yang tidak boleh dilanggar), lalu langsung ke tabel §5–§9 untuk status per fitur. Setiap fitur punya ID stabil (`M-BER-01`) — pakai ID itu saat melapor progres, bukan nama layar.

Legenda status: `✅` selesai & terpakai · `🟡` sebagian (lihat catatan) · `⬜` belum mulai · `🔒` diblokir keputusan (lihat §4)

Terakhir disegarkan: 2026-08-06

---

## 1. Ringkasan produk

**Masalah.** Mahasiswa yang sedang tidak baik-baik saja jarang datang sendiri ke konselor. Kampus baru tahu setelah terlambat — nilai anjlok, hilang dari kelas, atau lebih buruk.

**Solusi.** Aplikasi refleksi harian untuk mahasiswa yang, dengan izin eksplisit mahasiswa, memberi dosen pembimbing **sinyal** kapan seseorang perlu disapa — tanpa pernah membocorkan apa yang ditulisnya.

**Tolok ukur keberhasilan.**

| Ukuran | Target |
|---|---|
| Mahasiswa check-in mood ≥ 4 hari/minggu | 40% pengguna aktif |
| Mahasiswa memilih share level ≠ `CLOSED` | 50% |
| Dosen menindaklanjuti status `INTERVENTION` < 3 hari | 80% |
| Kebocoran konten privat (jurnal/chat) ke peran lain | **0 — kegagalan mutlak jika > 0** |

**Bukan tujuan (non-goals).** Aplikasi ini **bukan alat diagnosis**, bukan pengganti konselor, bukan kanal pesan dosen–mahasiswa, dan bukan alat penilaian akademik. Skor DASS-21 adalah skrining, bukan vonis. IndoBERT ±77% akurat — cukup untuk memicu percakapan, tidak cukup untuk menyimpulkan.

---

## 2. Invariant — aturan yang tidak boleh dilanggar fitur apa pun

Kelima aturan ini ditegakkan **server-side**. Klien hanya mengikuti; klien tidak pernah jadi penjaga.

| # | Invariant | Penegak |
|---|---|---|
| **I-1** | Teks jurnal & chat AI hanya dapat dibaca pemiliknya. Tidak ada peran yang dikecualikan, termasuk admin. | Rute `/students/me/*` · `PrivateContentGuard()` · repository tanpa method lintas-pengguna · tabel teks terpisah dari tabel metrik |
| **I-2** | Indikator wellbeing per individu hanya untuk dosen pembimbingnya sendiri, dan hanya bila `share_level ≠ CLOSED`. | `mentor_usecase` + `AggregateOnly()` |
| **I-3** | Tren mingguan hanya bila `share_level = SUMMARY_TREND`. | idem |
| **I-4** | Angka agregat tidak keluar bila kelompok < 5 mahasiswa — termasuk ukuran kelompoknya sendiri. | `utils.NewAggregateGuard()` |
| **I-5** | Default privasi mahasiswa baru adalah **paling tertutup** (`CLOSED`, kedua izin `false`). Berbagi selalu opt-in. | `DefaultPrivacySetting` |

**Kenapa ketat.** Kalau mahasiswa curiga tulisannya dibaca dosen, ia berhenti menulis jujur — dan sumber datanya mati sendiri. Privasi di sini bukan fitur tambahan, ia prasyarat agar produknya bekerja.

---

## 3. Peran & hak akses

| Peran | Tugas | Data yang dilihat | Tab |
|---|---|---|---|
| **Mahasiswa** | Mencatat & merefleksi kondisi diri | Miliknya sendiri, penuh | 4 + Terapis AI |
| **Dosen Pembimbing** | Menyapa yang perlu disapa | Indikator bimbingannya, sebatas izin | 3 |
| **Kaprodi** | Keputusan tingkat prodi | Angka agregat, k ≥ 5 | 4 |
| **Admin** | Menjaga nomor layanan tetap hidup | Tidak ada data mahasiswa | 2 |

Satu akun = tepat satu peran. Peran menentukan shell yang dibuka setelah login.

### 3.1 Matriks akses

| Data | Mahasiswa (pemilik) | Dosen | Kaprodi | Admin |
|---|---|---|---|---|
| Teks jurnal & chat AI | ✅ penuh | ❌ tidak ada jalur API | ❌ | ❌ |
| Indikator kondisi individu | ✅ | ⚠️ sesuai `share_level` | ❌ | ❌ |
| Tren mingguan | ✅ | ⚠️ hanya `SUMMARY_TREND` | ❌ | ❌ |
| Status EWS | ✅ | ⚠️ butuh `allow_early_warning` | ❌ (sebaran agregat saja) | ❌ |
| Agregat kelompok | — | ⚠️ k ≥ 5 | ⚠️ k ≥ 5 | ❌ |
| Layanan darurat | 📖 baca | 📖 baca | 📖 baca | ✏️ CRUD |

### 3.2 Kendali privasi mahasiswa

Satu-satunya jalan data wellbeing keluar dari akun mahasiswa.

| `share_level` | Yang dosen terima |
|---|---|
| `CLOSED` — Tertutup | tidak ada apa pun |
| `SUMMARY` — Ringkasan | indikator kondisi, tanpa tren |
| `SUMMARY_TREND` — Ringkasan + Tren | indikator + grafik tren mingguan |

Dua izin terpisah, dapat dimatikan sendiri-sendiri:

- `allow_early_warning` — boleh muncul di daftar "perlu disapa" dosen. Otomatis mati saat `CLOSED`.
- `allow_program_statistic` — ikut dihitung pada agregat kaprodi.

### 3.3 Yang tidak dapat dilakukan tiap peran

**Dosen:** membaca jurnal (tanpa pengecualian) · membaca chat AI · mengirim pesan lewat aplikasi (kontak dilakukan di luar aplikasi) · melihat mahasiswa yang bukan bimbingannya · melihat mahasiswa `CLOSED`.

**Kaprodi:** membuka indikator per mahasiswa · melihat nama pada data kondisi · membaca jurnal/chat.

**Admin:** melihat data mahasiswa apa pun (indikator maupun agregat) · membaca jurnal/chat.

---

## 4. Keputusan yang perlu diambil

Titik-titik di mana dokumen fungsi, skema DB, dan kode belum sepakat. Rekomendasi sudah dipilih; **ubah baris ini kalau tidak setuju**, karena fitur di bawah dibangun mengikutinya.

| ID | Isu | Rekomendasi | Dampak |
|---|---|---|---|
| **D-1** | Dokumen menyebut data "tersimpan di perangkat mahasiswa", tetapi arsitektur adalah **full online** — semua di PostgreSQL. | Terima full online. Yang dijamin bukan *lokasi* melainkan *keterbacaan*: hanya pemilik yang bisa membaca (I-1). **Copy di aplikasi wajib diperbaiki** — jangan pernah menulis "tersimpan di perangkatmu", tulis "hanya kamu yang bisa membacanya". Berbohong soal ini merusak kepercayaan yang jadi fondasi produk. | Copy layar Privasi & Onboarding |
| **D-2** | Dokumen menyebut **4 label emosi** IndoBERT; `constants/privacy.go` mendefinisikan **7**. | Model IndoBERT mengeluarkan 4 label kanonik: `JOY`, `SAD`, `ANGRY`, `ANXIOUS`. `NEUTRAL` dipakai saat confidence < ambang. `CALM` & `TIRED` adalah label **mood check-in manual**, bukan keluaran model — pisahkan kedua himpunan agar "Tentang model ini" tidak menyesatkan. | `constants`, layar edukasi model, EWS #2 |
| **D-3** | EWS #2 menghitung "emosi negatif" — dari analisis jurnal, mood check-in, atau keduanya? | **Hanya dari analisis jurnal.** Mood check-in sudah diwakili indikator #1; mencampurnya membuat satu hari buruk dihitung dua kali. | `ews_usecase` |
| **D-4** | Indikator "kurang tidur" tidak menyebut ambang jam maupun jendela waktu. | `sleep_hours < 5` pada **≥ 2 malam dalam 7 hari terakhir**. Sudah sesuai kode; kunci di config `EWS_LOW_SLEEP_*`. | — (sudah selaras) |
| **D-5** | Terapis AI mengirim teks ke Google Gemini — teks keluar dari sistem, bertentangan dengan semangat I-1. | Wajib **consent sekali di awal** yang menjelaskan bahwa isi percakapan diproses layanan pihak ketiga, plus opsi menolak (tab tetap ada, isinya latihan mandiri). Tanpa ini, tab Terapis AI tidak boleh rilis. | 🔒 memblokir `M-AI-*` |
| **D-6** | `student_contact_requests.note` ada di skema, tapi dosen "hanya melihat nama dan waktu, tanpa sebab". | Kolom tetap ada (mahasiswa boleh menulis untuk dirinya sendiri) tetapi **tidak pernah masuk response dosen**. Tambahkan test yang gagal bila `note` bocor. | `mentor_dto` |
| **D-7** | Mahasiswa `CLOSED` menekan "minta dihubungi" — muncul di daftar dosen atau tidak? | **Muncul.** Menekan tombol itu adalah persetujuan eksplisit dan spesifik, mengalahkan `share_level`. Yang muncul hanya nama + waktu, tanpa indikator apa pun. | `mentor_usecase` |
| **D-8** | Backdate check-in mood dan jurnal — sampai berapa lama ke belakang? | Maksimal **7 hari**. Lebih jauh dari itu ingatan sudah tidak akurat dan hanya mengotori EWS. | `daily_metric_usecase`, `journal_usecase` |
| **D-9** | Metrik kaprodi "jumlah mahasiswa perlu intervensi" — angka kecil bisa menunjuk orang. | Tampilkan sebagai **persentase** dari kelompok yang sudah lolos k ≥ 5, bukan hitungan mentah. | `program_usecase` |
| **D-10** | `emergency_contacts` global, dokumen bilang "berlaku seluruh pengguna program studi". | Biarkan global — deployment saat ini satu kampus. Kolom `study_program_id` ditambahkan hanya bila multi-prodi benar-benar datang. | — |

---

## 5. Mahasiswa

### 5.1 Beranda — `M-BER` ✅

Beranda kini menjadi **satu-satunya tempat check-in diisi** (dipindah dari tab Mood).
Alasannya: check-in adalah tindakan harian yang harus ada di layar pertama, sementara riwayat adalah tempat merenung yang dibuka sesekali.

| ID | Fitur | BE | FE | Catatan |
|---|---|:--:|:--:|---|
| M-BER-01 | Sapaan bernama (dari `/auth/me`) | ✅ | ✅ | |
| M-BER-02 | Ringkasan kondisi hari ini | ✅ | ✅ | `GET /students/me/daily-metrics/weekly-summary` + `current_streak` |
| M-BER-03 | Kalender mood mingguan | ✅ | ✅ | hari kosong = state "belum check-in" |
| M-BER-04 | Pintasan ke skrining DASS-21 | ✅ | ✅ | |
| M-BER-05 | Empty state pengguna baru | ✅ | ✅ | `isFirstTime` → ajakan check-in pertama, bukan kalender kosong |
| M-BER-06 | **Form check-in** (bottom sheet) | ✅ | ✅ | pilihan skala/emosi/pemicu/batas backdate dari `GET …/options` |
| M-BER-07 | Mode ubah check-in hari ini | ✅ | ✅ | upsert per tanggal; sheet terbuka terisi nilai lama |

**Catatan perubahan perilaku.** Pintasan mood di header dulu langsung menyimpan dengan `stress=2, sleep=7.0` yang tidak pernah diisi siapa pun. Sekarang pintasan itu **membuka form dengan mood terpilih**, tidak menyimpan diam-diam — dua angka karangan tadi ikut dibaca indikator EWS `LOW_SLEEP_NIGHTS`, dan dosen akan menerima sinyal yang tidak dimaksudkan siapa pun.

### 5.2 Mood — `M-MOOD` ✅ (riwayat saja)

| ID | Fitur | BE | FE | Catatan |
|---|---|:--:|:--:|---|
| M-MOOD-01 | ~~Check-in harian di tab ini~~ | — | — | **dipindah ke `M-BER-06`** |
| M-MOOD-02 | Pemilih tanggal untuk hari yang terlewat | ✅ | ✅ | batas backdate dari server (`max_backdate_days`), divalidasi ulang di usecase |
| M-MOOD-03 | Grafik ritme mood | ✅ | ✅ | `GET …/stats?period_days=30\|90\|120` |
| M-MOOD-04 | Sebaran emosi | ✅ | ✅ | dari label check-in; sebaran hasil model ada di `M-PRO-02` |
| M-MOOD-05 | Satu check-in per hari (ubah, bukan duplikat) | ✅ | ✅ | unique index + upsert |
| M-MOOD-06 | **Kalender mood bulanan** | ✅ | ✅ | `GET …/monthly?month=YYYY-MM`, navigasi antar bulan |
| M-MOOD-07 | Pemicu tersering + rangkaian check-in | ✅ | ✅ | `top_triggers`, `current_streak`, `longest_streak` |
| M-MOOD-08 | State "Data belum cukup" (< 3 titik) | ✅ | ✅ | server tidak mengirim rata-rata sama sekali saat belum cukup |

### 5.3 Jurnal — `M-JUR` ✅ (kecuali model sungguhan)

| ID | Fitur | BE | FE | Catatan |
|---|---|:--:|:--:|---|
| M-JUR-01 | Tulis / lihat / hapus catatan bebas | ✅ | ✅ | |
| M-JUR-02 | Tombol Analisis Emosi | 🟡 | ✅ | alurnya lengkap, analyzer-nya masih **leksikon mock** (`mock-lexicon-v1`) |
| M-JUR-03 | **IndoBERT sungguhan** menggantikan mock | ⬜ | — | interface `EmotionAnalyzer` sengaja kecil; penggantian tidak menyentuh usecase maupun klien |
| M-JUR-04 | Saran latihan coping sesuai emosi terdeteksi | ✅ | ✅ | |
| M-JUR-05 | Deteksi tanda krisis otomatis + kartu bantuan | ✅ | ✅ | kartu krisis tampil paling atas dan menautkan ke layanan bantuan |
| M-JUR-06 | Tanggal mundur (maks 7 hari, D-8) | ✅ | ✅ | |
| M-JUR-07 | Daftar jurnal berhalaman | ✅ | ✅ | |
| M-JUR-08 | Simpan tanpa analisis | ✅ | ✅ | analisis adalah pilihan pemiliknya, bukan syarat untuk boleh bercerita |

### 5.4 Profil — `M-PRO` 🟡

| ID | Menu | BE | FE | Catatan |
|---|---|:--:|:--:|---|
| M-PRO-01 | **Skrining DASS-21** — riwayat, tren, pengisian baru | ✅ | ✅ | katalog soal & ambang di server; klien hanya kirim jawaban mentah |
| M-PRO-02 | **Riwayat Analisis Emosi** — hasil + tren | ✅ | ✅ | `GET …/journals/emotion-history` |
| M-PRO-03 | **Tentang model ini** — IndoBERT, 4 label (D-2), akurasi ±77%, batasan | — | ✅ | teks wajib disesuaikan setelah D-2 |
| M-PRO-04 | **Butuh bantuan sekarang** — nomor darurat & konseling | ✅ | ✅ | tersambung API; empty state jujur (A-BAN-03) |
| M-PRO-05 | **Latihan menenangkan diri** — napas, grounding, refleksi | — | 🟡 | latihan napas ✅; grounding & refleksi ⬜ (murni klien, tanpa backend) |
| M-PRO-06 | **Privasi & Berbagi Data** | ✅ | ✅ | 3 tingkat + 2 izin; 5 test cubit lulus |
| M-PRO-07 | Pengingat harian (nyala/mati + jam) | — | ⬜ | notifikasi lokal, tanpa backend |
| M-PRO-08 | Mode gelap | — | 🟡 | `ThemeCubit` persisten sudah ada & dipakai tab Profil Dosen/Kaprodi/Admin; tab Profil Mahasiswa belum memasang `DarkModeCard` |
| M-PRO-09 | Kebijakan privasi | — | ⬜ | wajib selaras D-1 dan D-5 |

### 5.5 Terapis AI — `M-AI` 🔒 diblokir D-5

| ID | Fitur | BE | FE | Catatan |
|---|---|:--:|:--:|---|
| M-AI-01 | Consent pihak ketiga sebelum pemakaian pertama | ⬜ | ⬜ | **prasyarat rilis tab ini** |
| M-AI-02 | Percakapan dengan Gemini 2.5 Flash | ⬜ | 🟡 | tabel `student_chat_messages` siap; UI masih dummy; belum ada endpoint & integrasi |
| M-AI-03 | Riwayat hingga 100 giliran | ⬜ | ⬜ | pemangkasan di sisi server |
| M-AI-04 | Kartu bantuan otomatis saat terdeteksi tanda krisis | ⬜ | ⬜ | pakai leksikon krisis yang sama dengan jurnal |
| M-AI-05 | Chat berada di bawah `PrivateContentGuard` (I-1) | ⬜ | — | jangan sampai rute ini lolos dari guard |

### 5.6 Lintas-tab mahasiswa — `M-X`

| ID | Fitur | BE | FE | Catatan |
|---|---|:--:|:--:|---|
| M-X-01 | Tombol "minta dihubungi" pembimbing | ✅ | ✅ | satu permintaan OPEN per mahasiswa; berlaku walau `CLOSED` (D-7). Penjelasan batas dikirim server, bukan ditulis ulang klien |
| M-X-02 | Batalkan permintaan | ✅ | ✅ | status → `CANCELLED` |
| M-X-03 | Onboarding privasi saat login pertama | ⬜ | ⬜ | jelaskan default tertutup, jangan paksa berbagi |

---

## 6. Dosen Pembimbing

Peran **pemantau, bukan pembaca**: yang diterima hasil hitungan, bukan tulisan.

### 6.1 Tab Bimbingan — `L-BIM` 🟡

| ID | Fitur | BE | FE | Catatan |
|---|---|:--:|:--:|---|
| L-BIM-01 | Daftar bimbingan terurut tingkat perhatian | ✅ | ✅ | urutan dari server, klien tidak mengurut ulang |
| L-BIM-02 | Status EWS per mahasiswa | ✅ | ✅ | `EwsLevelBadge`; tanpa izin → badge "peringatan dini nonaktif", bukan Normal |
| L-BIM-03 | Daftar "minta dihubungi" — **nama & waktu saja** | ✅ | ✅ | `note` dihentikan sejak repository Go & tidak diurai entitas Dart |
| L-BIM-04 | Halaman detail per mahasiswa | ✅ | ✅ | `student_detail_page.dart` — tunduk `share_level`, grafik tren hanya SUMMARY_TREND |
| L-BIM-05 | State `CLOSED` ditampilkan jujur ("mahasiswa memilih tidak berbagi"), bukan sebagai "Normal" | ✅ | ✅ | `ClosedShareCard`; dijaga `dosen_privacy_test.dart` |

### 6.2 Tab Kondisi — `L-KON` 🟡

| ID | Fitur | BE | FE | Catatan |
|---|---|:--:|:--:|---|
| L-KON-01 | Agregat kelompok bimbingan | ✅ | ✅ | `InsufficientDataCard` bila k < 5 — null tidak pernah jadi 0 |
| L-KON-02 | Sebaran tingkat perhatian | ✅ | ✅ | seeder ditambah 2 mahasiswa agar ambang EWS terpenuhi & fitur ini bisa diuji |
| L-KON-03 | Sebaran emosi hasil analisis jurnal | ✅ | ✅ | label saja; entitas `EmotionShare` tidak punya slot untuk teks |
| L-KON-04 | Pemilih periode 30 / 90 / 120 hari | ✅ | ✅ | |

### 6.3 Tab Profil — `L-PRO` 🟡

| ID | Fitur | BE | FE | Catatan |
|---|---|:--:|:--:|---|
| L-PRO-01 | Identitas akun | ✅ | ✅ | dari `/auth/me` |
| L-PRO-02 | Jumlah mahasiswa bimbingan | ✅ | ✅ | `GET /mentors/me/profile` |
| L-PRO-03 | Daftar batas akses yang berlaku | ✅ | ✅ | teks dari server (`access_limits`), dirender `AccessLimitsCard` |
| L-PRO-04 | Mode gelap | — | ✅ | `ThemeCubit` + secure storage; persisten, bukan `ThemeMode.system` |

### 6.4 Early Warning System — `EWS` ✅

Implementasi: [`ews_usecase.go`](../backend/internal/mentor/domain/usecase/ews_usecase.go) — `Calculate` murni, terpisah dari I/O, 8 unit test lulus.

| Indikator | Menyala bila | Status |
|---|---|:--:|
| `LOW_MOOD_STREAK` | mood ≤ 2 **lebih dari** 5 hari berturut-turut (hari tanpa check-in memutus rangkaian) | ✅ |
| `NEGATIVE_EMOTION_RATIO` | emosi negatif > 60%, minimal 4 hasil analisis jurnal (D-3) | ✅ |
| `DASS_WORSENING` | total skor naik, atau muncul kategori Severe yang sebelumnya tidak ada | 🟡 tidak pernah terpicu sampai `M-PRO-01` ada |
| `LOW_SLEEP_NIGHTS` | tidur < 5 jam pada ≥ 2 malam dalam 7 hari (D-4) | ✅ |

| Skor | Level | Label |
|---|---|---|
| 0 | `NORMAL` | Normal |
| 1 | `WATCH` | Waspada |
| 2 | `RISK` | Risiko |
| ≥ 3 | `INTERVENTION` | Perlu Intervensi |

Dua pengecualian, keduanya sudah terimplementasi:

1. DASS-21 tingkat **Severe / Extremely Severe** → langsung `INTERVENTION`, berapa pun indikator lain.
2. Data harian < 4 titik → `INSUFFICIENT_DATA` / "Data belum cukup" — **tidak pernah** `NORMAL`. Menyebut seseorang "Normal" padahal datanya kosong adalah kegagalan produk, bukan sekadar bug tampilan.

Hasil disimpan di `early_warning_logs` (kolom `indicators` jsonb, tanpa teks jurnal) agar daftar bimbingan bisa diurutkan tanpa hitung ulang. Log hari ini dianggap masih berlaku.

---

## 7. Kaprodi

Kondisi prodi dalam angka, tanpa identitas siapa pun.

| ID | Tab / Fitur | BE | FE | Catatan |
|---|---|:--:|:--:|---|
| K-DAS-01 | Rata-rata mood prodi | ✅ | ✅ | |
| K-DAS-02 | Jumlah perlu intervensi → **persentase** (D-9) | ✅ | ✅ | kartu diberi penanda "persentase" agar tidak terbaca sebagai jumlah orang |
| K-DAS-03 | Jumlah aktif 7 hari terakhir | ✅ | ✅ | |
| K-DAS-04 | Rata-rata tingkat stres | ✅ | ✅ | |
| K-DAS-05 | Rata-rata jam tidur | ✅ | ✅ | |
| K-DAS-06 | Jumlah yang sudah mengisi skrining | 🟡 | ✅ | FE siap; angkanya tetap bergantung `M-PRO-01` |
| K-DAS-07 | Sebaran tingkat perhatian | ✅ | ✅ | dikirim sebagai **persentase** — hitungan per level akan membatalkan D-9 lewat pintu belakang |
| K-PEM-01 | Daftar dosen + beban bimbingan | ✅ | ✅ | jumlah bimbingan bukan data wellbeing → tidak kena k-anonymity. "Mahasiswa berisiko per dosen" pada versi dummy DIHAPUS — itu data kondisi kelompok kecil |
| K-LAP-01 | Ringkasan per angkatan | ✅ | ✅ | angkatan < 5 → "Data belum cukup", tanpa jumlah anggota |
| K-LAP-02 | Ekspor laporan | ⬜ | ⬜ | opsional; tetap tunduk k ≥ 5 |
| K-PRO-01 | Identitas + jumlah mahasiswa terdaftar + batas akses | ✅ | ✅ | `GET /programs/me/profile` |

**k-anonimitas.** Sebuah angka agregat tidak ditampilkan bila kelompoknya < 5 mahasiswa — pada kelompok kecil, rata-rata praktis menunjuk individu. Yang dikembalikan: `200` dengan `is_sufficient:false`, **tanpa satu angka pun**, termasuk ukuran kelompoknya sendiri. Config menolak nilai < 5.

---

## 8. Admin

Pengelola konfigurasi, bukan pengawas. Admin mengelola aturan, bukan orang.

| ID | Fitur | BE | FE | Catatan |
|---|---|:--:|:--:|---|
| A-BAN-01 | CRUD layanan bantuan: nama, telepon, keterangan, jenis, 24 jam, aktif, urutan | ✅ | ✅ | form + list tersambung API; `service_type` lewat migrasi `20260806120000` + enum & CHECK constraint |
| A-BAN-02 | Nonaktif hanya terlihat admin | ✅ | ✅ | berlaku juga pada `GET /:id` — non-Admin menerima `EMERGENCY_CONTACT_NOT_FOUND`, bukan datanya |
| A-BAN-03 | Daftar kosong → mahasiswa melihat "nomor layanan belum diatur" | ✅ | ✅ | 4 nomor hardcoded di `bantuan_darurat_page.dart` DIHAPUS — sekarang murni dari API |
| A-BAN-04 | Verifikasi nomor bertanda `[VERIFIKASI]` sebelum rilis | 🟡 | ✅ | `needs_verification` → badge di layar Admin & Mahasiswa + banner blocker. **Verifikasi nomornya sendiri tetap tugas manual — masih blocker rilis** |
| A-PRO-01 | Identitas + daftar batas akses | ✅ | ✅ | batas akses ditulis klien: tidak ada endpoint profil admin, dan membuatnya berarti membangun jalur API untuk peran yang justru tidak boleh punya akses |

Perubahan berlaku untuk seluruh pengguna begitu tersimpan (D-10: cakupan global).

---

## 9. Fondasi lintas peran

| ID | Fitur | Status | Catatan |
|---|---|:--:|---|
| C-01 | Login, refresh token berotasi, logout, `/auth/me` | ✅ | `SELECT … FOR UPDATE`, rate limit per IP + per email |
| C-02 | Amplop response `{success, data, meta}` + error code UPPER_SNAKE | ✅ | |
| C-03 | Gerbang peran di router Flutter (4/3/4/2 tab) | ✅ | murni UX — otorisasi tetap di backend |
| C-04 | Middleware RBAC + privacy + `AggregateOnly` | ✅ | |
| C-05 | Rate limit Redis fixed-window, fail-closed | ✅ | |
| C-06 | CSRF double-submit (web) / Bearer (native) | ✅ | penyimpangan disengaja, lihat README §2 |
| C-07 | Audit log setiap pembukaan indikator & akses agregat | ✅ | tidak pernah memuat konten privat |
| C-08 | `apptime` sebagai satu-satunya sumber waktu | ✅ | `time.Now()` terlarang — agar EWS dapat diuji |
| C-09 | Ambang bisnis di config, bukan hardcode | ✅ | |
| C-10 | Responsif: bottom nav (mobile) / NavigationRail (tablet & desktop) | ✅ | Build terverifikasi: **Android** (APK debug+release, AAB), **Linux** (debug+release), **Web**. iOS belum dibuat — butuh mesin macOS |
| C-11 | Claymorphism design system | ✅ | `ClayContainer`, `ClayCard`, `ClayButton` |
| C-12 | Kode error khusus Sanctuary didokumentasikan | ⬜ | `PRIVATE_CONTENT_FORBIDDEN`, `INSUFFICIENT_GROUP_SIZE`, dll. belum masuk `api-error-codes.md` |
| C-13 | URL staging/production sungguhan | ⬜ | masih placeholder `sanctuary.ac.id`. Satu paket dengan `applicationId` Android yang masih `com.example.sanctuary` dan keystore release yang masih memakai kunci debug — ketiganya harus diganti sebelum rilis |
| C-14 | Duplikat `privacy_settings_page.dart` | ✅ | versi `features/mahasiswa` dihapus (state lokal, kode `SUMMARY_ONLY` yang bahkan tidak ada di backend); tab Profil kini menunjuk `features/privacy` yang tersambung cubit |
| C-15 | Test kebocoran privasi otomatis | 🟡 | BE: `privacy_leak_test.go` memindai sumber (go/ast) DTO dosen & kaprodi + repository mentor. FE: `dosen_privacy_test.dart` (14 test) menjaga CLOSED≠Normal, null≠0, dan `note` tidak terurai. Belum mencakup permukaan mahasiswa |

---

## 10. Peta endpoint

Base `/api/v1`. `me` selalu berarti pemilik token — tidak ada endpoint yang menerima id mahasiswa dari klien untuk konten privat.

| Method | Path | Akses | Status |
|---|---|---|:--:|
| POST | `/auth/login`, `/auth/refresh` | publik (rate-limited) | ✅ |
| POST/GET | `/auth/logout`, `/auth/me` | terautentikasi | ✅ |
| GET/PUT | `/students/me/privacy-settings` | Mahasiswa | ✅ |
| GET | `/students/me/privacy-settings/options` | Mahasiswa | ✅ |
| POST | `/students/me/daily-metrics` | Mahasiswa | ✅ upsert per tanggal |
| GET | `/students/me/daily-metrics/options` | Mahasiswa | ✅ skala, emosi, pemicu, batas backdate |
| GET | `/students/me/daily-metrics/weekly-summary` | Mahasiswa | ✅ |
| GET | `/students/me/daily-metrics/monthly?month=YYYY-MM` | Mahasiswa | ✅ M-MOOD-06 |
| GET | `/students/me/daily-metrics/stats?period_days=30` | Mahasiswa | ✅ M-MOOD-03/04/07 |
| GET/POST | `/students/me/journals` | Mahasiswa (`PrivateContentGuard`) | ✅ |
| GET/DELETE | `/students/me/journals/:id` | Mahasiswa (pemilik) | ✅ |
| POST | `/students/me/journals/:id/analyze` | Mahasiswa (pemilik) | 🟡 mock analyzer |
| GET | `/students/me/journals/emotion-history` | Mahasiswa | ✅ M-PRO-02 |
| GET | `/students/me/dass21/questions` | Mahasiswa | ✅ katalog soal dari server |
| GET/POST | `/students/me/dass21` | Mahasiswa | ✅ M-PRO-01 (skoring server-side) |
| GET/POST | `/students/me/chats` | Mahasiswa (`PrivateContentGuard`) | ⬜ M-AI-02 |
| GET/POST/DELETE | `/students/me/contact-requests` | Mahasiswa | ✅ M-X-01/02 |
| GET | `/mentors/me/students` | Dosen | ✅ |
| GET | `/mentors/me/students/:id` | Dosen (wajib pembimbingnya) | ✅ |
| GET | `/mentors/me/condition?period_days=30\|90\|120` | Dosen (k ≥ 5) | ✅ |
| GET | `/mentors/me/contact-requests` | Dosen | ✅ nama + waktu saja |
| GET | `/mentors/me/profile` | Dosen | ✅ L-PRO-02..03 |
| GET | `/programs/me/dashboard`, `/advisors`, `/reports/cohorts` | Kaprodi (k ≥ 5) | ✅ |
| GET | `/programs/me/profile` | Kaprodi | ✅ K-PRO-01 |
| GET | `/support/emergency-contacts` | semua peran | ✅ |
| POST/PUT/DELETE | `/support/emergency-contacts[/:id]` | Admin | ✅ |
| GET | `/support/service-types` | semua peran | ✅ pilihan `service_type` untuk form Admin |

---

## 11. Urutan pengerjaan

Diurutkan berdasarkan apa yang membuka jalan bagi yang lain, bukan berdasarkan kemudahan.

**Tahap 1 — Menutup lingkaran data mahasiswa.** ✅ selesai.
Seluruh fitur mahasiswa (kecuali Terapis AI) tersambung API, tanpa data contoh di klien. Indikator EWS ke-3 (`DASS_WORSENING`) kini punya sumber data.

**Tahap 2 — Membuat sinyal terpakai.** Data sudah masuk; sekarang dosen harus bisa membacanya.
`L-BIM-01..05` · `L-KON-01..04` · `L-PRO-02..03` · `C-15` (perluas ke permukaan mahasiswa)

**Tahap 3 — Tingkat prodi & konfigurasi.**
`K-DAS-*` · `K-PEM-01` · `K-LAP-01` · `A-BAN-01..03`

**Tahap 4 — AI & penghalusan.**
`D-5` diputuskan → `M-AI-01..05` · `M-JUR-03` (IndoBERT sungguhan) · `M-PRO-05, 07, 08, 09`

**Blocker rilis — tidak bisa dinegosiasikan.**
`A-BAN-04` (nomor darurat terverifikasi) · `C-15` (test kebocoran) · `D-1` (copy privasi jujur) · `D-5` (consent AI) · `C-13` (URL sungguhan) · **signing Android** (`applicationId` masih `com.example.*`, release masih ditandatangani kunci debug)

---

## 12. Catatan penutup

Yang keluar dari akun mahasiswa hanya **hasil hitungan**, tidak pernah **tulisannya**. Rancangan ini disengaja: memberi tahu dosen tanpa izin akan membuat mahasiswa berhenti menulis dengan jujur, dan hal itu mematikan sumber datanya sendiri.

Setiap fitur baru harus lulus satu pertanyaan sebelum ditulis: *apakah ini bisa membuat seorang mahasiswa menyesal telah jujur?* Kalau iya, rancangannya salah — bukan mahasiswanya.
