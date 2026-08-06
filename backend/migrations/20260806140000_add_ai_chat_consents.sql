-- ============================================================
-- ai_chat_consents (D-5 / M-AI-01)
--
-- Gate persetujuan pengiriman teks percakapan ke Google Gemini.
-- Tanpa baris GRANTED atas notice_version yang berlaku, endpoint
-- /students/me/chats menolak request di sisi server.
--
-- Tabel student_chat_messages TIDAK disentuh migrasi ini — strukturnya
-- sudah ada sejak skema awal dan sudah memuat kolom yang dibutuhkan
-- (session_id, sender, content, is_crisis_flagged).
-- ============================================================
CREATE TABLE IF NOT EXISTS ai_chat_consents (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    status         varchar(16) NOT NULL,
    notice_version varchar(32) NOT NULL,
    consented_at   timestamptz NULL,
    decided_at     timestamptz NOT NULL,
    created_at     timestamptz NOT NULL DEFAULT now(),
    updated_at     timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT chk_ai_consent_status CHECK (status IN ('GRANTED', 'DENIED')),
    -- Integritas gate: status GRANTED wajib membawa waktu persetujuan, dan
    -- penolakan tidak boleh menyimpan waktu persetujuan. Aturan ini ditegakkan
    -- basis data, bukan hanya aplikasi, agar tidak ada jalur tulis (termasuk
    -- seeder atau perbaikan manual) yang dapat membuat baris rancu.
    CONSTRAINT chk_ai_consent_granted_has_time CHECK (
        (status = 'GRANTED' AND consented_at IS NOT NULL)
        OR (status = 'DENIED' AND consented_at IS NULL)
    )
);

-- Satu keputusan yang berlaku per mahasiswa; perubahan sikap menimpa baris ini.
CREATE UNIQUE INDEX IF NOT EXISTS uq_ai_consent_user ON ai_chat_consents (user_id);
