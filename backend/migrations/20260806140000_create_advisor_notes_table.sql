-- ============================================================
-- Advisor Notes — Catatan Pendampingan & Intervensi Dosen
--
-- Dosen Pembimbing dapat mencatat tindak lanjut pendampingan
-- (misal: sapaan via WA, konsultasi tatap muka, rujukan konseling).
--
-- PRIVASI: Catatan ini milik Dosen yang membuatnya (mentor_id)
-- dan HANYA dapat diakses oleh Dosen tersebut. Tidak pernah dikirim
-- ke Mahasiswa, Kaprodi, atau Admin, dan tidak pernah menyentuh
-- konten privat jurnal/chat mahasiswa.
-- ============================================================

CREATE TABLE IF NOT EXISTS advisor_notes (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    mentor_id        uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    student_id       uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    interaction_date timestamptz NOT NULL DEFAULT now(),
    channel          varchar(32) NOT NULL DEFAULT 'TATAP_MUKA',
    status           varchar(32) NOT NULL DEFAULT 'DISAPA',
    note             text        NOT NULL DEFAULT '',
    created_at       timestamptz NOT NULL DEFAULT now(),
    updated_at       timestamptz NOT NULL DEFAULT now(),
    deleted_at       timestamptz NULL,
    CONSTRAINT chk_advisor_note_channel CHECK (channel IN ('TATAP_MUKA', 'WHATSAPP', 'EMAIL', 'TELEPON', 'LAINNYA')),
    CONSTRAINT chk_advisor_note_status CHECK (status IN ('DISAPA', 'KONSULTASI', 'DIRUJUK', 'STABIL'))
);

CREATE INDEX IF NOT EXISTS idx_advisor_notes_mentor_student
    ON advisor_notes (mentor_id, student_id, interaction_date DESC)
    WHERE deleted_at IS NULL;
