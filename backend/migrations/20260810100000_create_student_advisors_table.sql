-- Sanctuary — satu mahasiswa dapat dibimbing lebih dari satu dosen.
--
-- Sebelum ini relasi bimbingan disimpan sebagai kolom tunggal users.advisor_id,
-- sehingga secara struktural mustahil ada pembimbing kedua. Relasi dipindahkan
-- ke tabel pasangan agar kardinalitasnya benar (many-to-many).
--
-- FASE 1 dari 2 — SENGAJA TIDAK DESTRUKTIF.
-- Migrasi ini hanya MENAMBAH (tabel baru + backfill + index) dan tidak
-- menyentuh kolom lama sama sekali. Kode aplikasi sudah sepenuhnya berpindah
-- ke student_advisors dan tidak lagi membaca/menulis users.advisor_id maupun
-- student_contact_requests.advisor_id — kolom lama menjadi mati (dead) tapi
-- tetap ada sebagai jaring pengaman selama masa verifikasi.
--
-- FASE 2 (file terpisah, 20260810100001_drop_legacy_advisor_columns.sql)
-- baru men-drop kolom lama, dan HANYA dijalankan setelah baris di
-- student_advisors diverifikasi cocok dengan data lama di lingkungan
-- tersebut (lihat komentar di file itu untuk query verifikasinya).
--
-- Catatan privasi: tabel ini murni administratif (SIAPA membimbing SIAPA).
-- Setiap pembimbing pada satu mahasiswa memiliki hak baca yang SAMA — tetap
-- disaring student_privacy_settings milik mahasiswa itu, tanpa pengecualian.

-- ============================================================
-- student_advisors
-- ============================================================
CREATE TABLE IF NOT EXISTS student_advisors (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id  uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    advisor_id  uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    -- Jejak siapa yang mengalokasikan (kaprodi). NULL untuk data hasil migrasi.
    assigned_by uuid        NULL REFERENCES users (id) ON DELETE SET NULL,
    assigned_at timestamptz NOT NULL DEFAULT now(),
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);

-- Pasangan tidak boleh ganda: dua baris identik berarti satu dosen terhitung
-- dua kali pada beban bimbingan dan tampil dobel di daftar mahasiswa.
CREATE UNIQUE INDEX IF NOT EXISTS idx_student_advisors_pair
    ON student_advisors (student_id, advisor_id);
-- Index utama query dosen: daftar bimbingan aktif.
CREATE INDEX IF NOT EXISTS idx_student_advisors_advisor ON student_advisors (advisor_id);
-- Index utama query mahasiswa & kaprodi: daftar pembimbing seorang mahasiswa.
CREATE INDEX IF NOT EXISTS idx_student_advisors_student ON student_advisors (student_id);

-- ============================================================
-- Backfill dari kolom lama (kolomnya TETAP ADA setelah ini)
-- ============================================================
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'advisor_id'
    ) THEN
        INSERT INTO student_advisors (student_id, advisor_id, assigned_at)
        SELECT id, advisor_id, created_at
        FROM users
        WHERE advisor_id IS NOT NULL AND deleted_at IS NULL
        ON CONFLICT (student_id, advisor_id) DO NOTHING;
    END IF;
END $$;

-- ============================================================
-- Index baru untuk pola query "minta dihubungi" yang sekarang dibaca lewat
-- student_advisors, bukan kolom advisor_id pada tabel ini. Menambah index
-- baru aman dilakukan sekarang; index lama (idx_contact_advisor_status) baru
-- dihapus di FASE 2 bersamaan dengan kolomnya.
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_contact_student_status
    ON student_contact_requests (student_id, status);

-- student_contact_requests.advisor_id tadinya NOT NULL. Kode aplikasi sejak
-- migrasi ini TIDAK LAGI mengisi kolom tersebut (tujuan permintaan dibaca
-- lewat student_advisors) — tanpa DROP NOT NULL di sini, setiap permintaan
-- "minta dihubungi" BARU akan gagal INSERT selama masa jeda sebelum FASE 2
-- (drop kolom) dijalankan. Ditemukan lewat pengujian: seeder gagal dengan
-- error null-constraint saat migrasi ini diterapkan sendirian tanpa FASE 2.
ALTER TABLE student_contact_requests ALTER COLUMN advisor_id DROP NOT NULL;
