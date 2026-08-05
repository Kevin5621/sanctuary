-- ============================================================
-- A-BAN-01 — kolom `service_type` pada emergency_contacts.
--
-- Skema awal (20260805090000_initial_schema.sql) belum punya kolom ini,
-- sehingga form CRUD Admin tidak dapat menyimpan "jenis layanan".
--
-- Nilai enum ditegakkan di aplikasi (constants.ServiceType) DAN di DB lewat
-- CHECK constraint, agar data lama/manual tidak bisa menyisipkan nilai liar.
-- Default 'OTHER' dipilih supaya baris yang sudah ada tetap valid tanpa
-- perlu tebakan klasifikasi — Admin yang menentukan jenis sebenarnya.
--
-- Dijalankan idempotent: aman diulang pada database yang sudah dimigrasi.
-- ============================================================

ALTER TABLE emergency_contacts
    ADD COLUMN IF NOT EXISTS service_type varchar(32) NOT NULL DEFAULT 'OTHER';

-- Nilai kanonik harus sama persis dengan internal/core/constants/support.go.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_emergency_service_type'
    ) THEN
        ALTER TABLE emergency_contacts
            ADD CONSTRAINT chk_emergency_service_type
            CHECK (service_type IN (
                'NATIONAL_HOTLINE',
                'EMERGENCY',
                'CAMPUS_COUNSELING',
                'CAMPUS_HEALTH',
                'ACADEMIC_ADVISOR',
                'OTHER'
            ));
    END IF;
END $$;

-- Layar Bantuan mahasiswa mengelompokkan daftar per jenis, lalu mengurutkan
-- dengan sort_order. Indeks parsial mengikuti pola idx_emergency_active_sort.
CREATE INDEX IF NOT EXISTS idx_emergency_service_type
    ON emergency_contacts (service_type, sort_order)
    WHERE deleted_at IS NULL;

-- Klasifikasi awal untuk baris seed yang sudah terlanjur ada.
-- Hanya menyentuh baris yang masih 'OTHER' agar keputusan Admin tidak tertimpa.
UPDATE emergency_contacts SET service_type = 'NATIONAL_HOTLINE'
    WHERE service_type = 'OTHER' AND phone IN ('119');
UPDATE emergency_contacts SET service_type = 'EMERGENCY'
    WHERE service_type = 'OTHER' AND phone IN ('112');
