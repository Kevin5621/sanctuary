-- Sanctuary — FASE 2 dari 2 (lanjutan 20260810100000_create_student_advisors_table.sql).
--
-- INI DESTRUKTIF DAN TIDAK ADA MIGRASI down. Jangan jalankan file ini sampai
-- FASE 1 sudah di-deploy dan baris di student_advisors sudah diverifikasi
-- COCOK dengan data lama pada lingkungan yang sama (staging DULU, lalu
-- produksi) — lihat query verifikasi di bawah.
--
-- Kode aplikasi (Go) sejak commit yang menambah student_advisors SUDAH TIDAK
-- LAGI membaca atau menulis kedua kolom ini; menunda migrasi ini tidak
-- memengaruhi fungsi aplikasi sama sekali. Jalankan file ini kapan pun sudah
-- yakin, tidak ada tenggat.
--
-- ============================================================
-- Query verifikasi — jalankan SEBELUM apply file ini, harus menghasilkan 0.
-- ============================================================
--
-- -- Setiap advisor_id lama yang non-NULL harus punya padanan di student_advisors:
-- SELECT count(*) FROM users u
-- WHERE u.advisor_id IS NOT NULL AND u.deleted_at IS NULL
--   AND NOT EXISTS (
--     SELECT 1 FROM student_advisors sa
--     WHERE sa.student_id = u.id AND sa.advisor_id = u.advisor_id
--   );
--
-- -- Jumlah baris permintaan "minta dihubungi" tidak boleh berubah (kolom
-- -- advisor_id di tabel ini hanya dihapus, bukan barisnya):
-- SELECT count(*) FROM student_contact_requests;  -- catat angkanya SEBELUM
-- -- lalu bandingkan dengan angka yang sama SESUDAH file ini diterapkan.
--
-- ============================================================

DROP INDEX IF EXISTS idx_users_advisor_active;
ALTER TABLE users DROP COLUMN IF EXISTS advisor_id;

DROP INDEX IF EXISTS idx_contact_advisor_status;
ALTER TABLE student_contact_requests DROP COLUMN IF EXISTS advisor_id;
