-- Sanctuary — initial schema
-- Konvensi: Atlas SQL migration, timestamped (YYYYMMDDhhmmss_<description>.sql)
-- Catatan privasi: kolom teks jurnal & chat berada di tabel terpisah dari
-- metrik agregabel, sehingga view/analitik prodi secara struktural tidak
-- pernah menyentuh konten privat.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- roles
-- ============================================================
CREATE TABLE IF NOT EXISTS roles (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code        varchar(32)  NOT NULL,
    name        varchar(64)  NOT NULL,
    description varchar(255) NOT NULL DEFAULT '',
    created_at  timestamptz  NOT NULL DEFAULT now(),
    updated_at  timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT chk_roles_code CHECK (code IN ('STUDENT', 'LECTURER', 'HEAD_OF_PROGRAM', 'ADMIN'))
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_roles_code ON roles (code);

-- ============================================================
-- study_programs
-- ============================================================
CREATE TABLE IF NOT EXISTS study_programs (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code         varchar(32)  NOT NULL,
    name         varchar(128) NOT NULL,
    faculty      varchar(128) NOT NULL DEFAULT '',
    head_user_id uuid NULL,
    created_at   timestamptz  NOT NULL DEFAULT now(),
    updated_at   timestamptz  NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_study_programs_code ON study_programs (code);
CREATE INDEX IF NOT EXISTS idx_study_programs_head ON study_programs (head_user_id);

-- ============================================================
-- users (single table, atribut per-peran nullable)
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id          uuid         NOT NULL REFERENCES roles (id) ON DELETE RESTRICT,
    full_name        varchar(128) NOT NULL,
    email            varchar(160) NOT NULL,
    password_hash    varchar(255) NOT NULL,
    phone            varchar(32)  NOT NULL DEFAULT '',
    avatar_url       varchar(255) NOT NULL DEFAULT '',
    student_number   varchar(32)  NULL,
    cohort_year      int          NULL,
    advisor_id       uuid         NULL REFERENCES users (id) ON DELETE SET NULL,
    lecturer_number  varchar(32)  NULL,
    study_program_id uuid         NULL REFERENCES study_programs (id) ON DELETE SET NULL,
    is_active        boolean      NOT NULL DEFAULT true,
    last_login_at    timestamptz  NULL,
    created_at       timestamptz  NOT NULL DEFAULT now(),
    updated_at       timestamptz  NOT NULL DEFAULT now(),
    deleted_at       timestamptz  NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users (lower(email)) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_student_number ON users (student_number) WHERE student_number IS NOT NULL AND deleted_at IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_lecturer_number ON users (lecturer_number) WHERE lecturer_number IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_users_role ON users (role_id) WHERE deleted_at IS NULL;
-- Index utama query dosen: daftar bimbingan aktif.
CREATE INDEX IF NOT EXISTS idx_users_advisor_active ON users (advisor_id, is_active) WHERE deleted_at IS NULL;
-- Index utama query kaprodi: agregat per prodi & angkatan.
CREATE INDEX IF NOT EXISTS idx_users_program_cohort ON users (study_program_id, cohort_year) WHERE deleted_at IS NULL;

-- FK melingkar (study_programs.head_user_id -> users.id) ditambahkan setelah
-- kedua tabel ada; dibungkus DO block agar migrasi tetap idempotent.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_study_programs_head') THEN
        ALTER TABLE study_programs
            ADD CONSTRAINT fk_study_programs_head
            FOREIGN KEY (head_user_id) REFERENCES users (id) ON DELETE SET NULL;
    END IF;
END $$;

-- ============================================================
-- refresh_tokens (rotasi + deteksi reuse)
-- ============================================================
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash      varchar(64) NOT NULL,
    expires_at      timestamptz NOT NULL,
    revoked_at      timestamptz NULL,
    replaced_by_id  uuid        NULL,
    user_agent      varchar(255) NOT NULL DEFAULT '',
    ip_address      varchar(64)  NOT NULL DEFAULT '',
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_refresh_tokens_hash ON refresh_tokens (token_hash);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_active ON refresh_tokens (user_id) WHERE revoked_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expiry ON refresh_tokens (expires_at);

-- ============================================================
-- audit_logs (wajib untuk setiap akses indikator oleh non-pemilik)
-- ============================================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id    uuid        NOT NULL,
    actor_role  varchar(32) NOT NULL,
    action      varchar(64) NOT NULL,
    resource    varchar(64) NOT NULL,
    resource_id uuid        NULL,
    metadata    jsonb       NULL,
    ip_address  varchar(64) NOT NULL DEFAULT '',
    request_id  varchar(64) NOT NULL DEFAULT '',
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_audit_actor_created ON audit_logs (actor_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_resource ON audit_logs (resource, resource_id);

-- ============================================================
-- student_privacy_settings (gerbang privasi)
-- ============================================================
CREATE TABLE IF NOT EXISTS student_privacy_settings (
    id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    share_level             varchar(24) NOT NULL DEFAULT 'CLOSED',
    allow_early_warning     boolean     NOT NULL DEFAULT false,
    allow_program_statistic boolean     NOT NULL DEFAULT false,
    created_at              timestamptz NOT NULL DEFAULT now(),
    updated_at              timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT chk_share_level CHECK (share_level IN ('CLOSED', 'SUMMARY', 'SUMMARY_TREND'))
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_privacy_user ON student_privacy_settings (user_id);

-- ============================================================
-- student_daily_metrics (data kuantitatif — boleh diagregasi)
-- ============================================================
CREATE TABLE IF NOT EXISTS student_daily_metrics (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          uuid          NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    metric_date      date          NOT NULL,
    mood_score       int           NOT NULL,
    stress_level     int           NOT NULL,
    sleep_hours      numeric(3, 1) NOT NULL,
    academic_trigger varchar(32)   NOT NULL DEFAULT '',
    emotion_label    varchar(24)   NOT NULL DEFAULT '',
    created_at       timestamptz   NOT NULL DEFAULT now(),
    updated_at       timestamptz   NOT NULL DEFAULT now(),
    CONSTRAINT chk_mood_score   CHECK (mood_score BETWEEN 1 AND 5),
    CONSTRAINT chk_stress_level CHECK (stress_level BETWEEN 1 AND 5),
    CONSTRAINT chk_sleep_hours  CHECK (sleep_hours >= 0 AND sleep_hours <= 24)
);
-- Satu check-in per hari per mahasiswa (mendukung backdate, menolak duplikat).
CREATE UNIQUE INDEX IF NOT EXISTS idx_metric_user_date ON student_daily_metrics (user_id, metric_date);
-- Index window analitik EWS & agregat 30/90/120 hari.
CREATE INDEX IF NOT EXISTS idx_metric_date_user ON student_daily_metrics (metric_date, user_id);

-- ============================================================
-- student_journals (KONTEN PRIVAT — owner only)
-- ============================================================
CREATE TABLE IF NOT EXISTS student_journals (
    id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id            uuid          NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    title              varchar(160)  NOT NULL DEFAULT '',
    content            text          NOT NULL,
    emotion_label      varchar(24)   NOT NULL DEFAULT '',
    emotion_confidence numeric(4, 3) NULL,
    sentiment_score    numeric(4, 3) NULL,
    is_crisis_flagged  boolean       NOT NULL DEFAULT false,
    analyzed_at        timestamptz   NULL,
    journal_date       date          NOT NULL,
    created_at         timestamptz   NOT NULL DEFAULT now(),
    updated_at         timestamptz   NOT NULL DEFAULT now(),
    deleted_at         timestamptz   NULL
);
CREATE INDEX IF NOT EXISTS idx_journal_user_created ON student_journals (user_id, journal_date DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_journal_crisis ON student_journals (is_crisis_flagged) WHERE is_crisis_flagged = true AND deleted_at IS NULL;

-- ============================================================
-- student_chat_messages (KONTEN PRIVAT — owner only, AI mock)
-- ============================================================
CREATE TABLE IF NOT EXISTS student_chat_messages (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    session_id        uuid        NOT NULL,
    sender            varchar(8)  NOT NULL,
    content           text        NOT NULL,
    is_crisis_flagged boolean     NOT NULL DEFAULT false,
    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT chk_chat_sender CHECK (sender IN ('USER', 'AI'))
);
CREATE INDEX IF NOT EXISTS idx_chat_user_session ON student_chat_messages (user_id, session_id, created_at);

-- ============================================================
-- dass21_results
-- ============================================================
CREATE TABLE IF NOT EXISTS dass21_results (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    depression_score    int         NOT NULL,
    anxiety_score       int         NOT NULL,
    stress_score        int         NOT NULL,
    depression_severity varchar(24) NOT NULL,
    anxiety_severity    varchar(24) NOT NULL,
    stress_severity     varchar(24) NOT NULL,
    taken_at            timestamptz NOT NULL,
    created_at          timestamptz NOT NULL DEFAULT now(),
    updated_at          timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT chk_dass_severity CHECK (
        depression_severity IN ('NORMAL', 'MILD', 'MODERATE', 'SEVERE', 'EXTREMELY_SEVERE')
        AND anxiety_severity IN ('NORMAL', 'MILD', 'MODERATE', 'SEVERE', 'EXTREMELY_SEVERE')
        AND stress_severity IN ('NORMAL', 'MILD', 'MODERATE', 'SEVERE', 'EXTREMELY_SEVERE')
    )
);
CREATE INDEX IF NOT EXISTS idx_dass_user_taken ON dass21_results (user_id, taken_at DESC);

-- ============================================================
-- student_contact_requests ("minta dihubungi")
-- ============================================================
CREATE TABLE IF NOT EXISTS student_contact_requests (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    advisor_id uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    status     varchar(16) NOT NULL DEFAULT 'OPEN',
    note       varchar(280) NOT NULL DEFAULT '',
    handled_at timestamptz NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT chk_contact_status CHECK (status IN ('OPEN', 'HANDLED', 'CANCELLED'))
);
CREATE INDEX IF NOT EXISTS idx_contact_advisor_status ON student_contact_requests (advisor_id, status);
CREATE UNIQUE INDEX IF NOT EXISTS idx_contact_open_unique ON student_contact_requests (student_id) WHERE status = 'OPEN';

-- ============================================================
-- early_warning_logs (hasil kalkulasi EWS server-side)
-- ============================================================
CREATE TABLE IF NOT EXISTS early_warning_logs (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    advisor_id    uuid        NULL,
    score         int         NOT NULL DEFAULT 0,
    level         varchar(24) NOT NULL,
    indicators    jsonb       NULL,
    is_sufficient boolean     NOT NULL DEFAULT false,
    data_points   int         NOT NULL DEFAULT 0,
    dass_severe   boolean     NOT NULL DEFAULT false,
    evaluated_at  timestamptz NOT NULL,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT chk_ews_level CHECK (level IN ('INSUFFICIENT_DATA', 'NORMAL', 'WATCH', 'RISK', 'INTERVENTION')),
    CONSTRAINT chk_ews_score CHECK (score BETWEEN 0 AND 4)
);
CREATE INDEX IF NOT EXISTS idx_ews_student_evaluated ON early_warning_logs (student_id, evaluated_at DESC);
CREATE INDEX IF NOT EXISTS idx_ews_advisor_level ON early_warning_logs (advisor_id, level);

-- ============================================================
-- emergency_contacts (CRUD Admin, dibaca semua peran)
-- ============================================================
CREATE TABLE IF NOT EXISTS emergency_contacts (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name        varchar(128) NOT NULL,
    phone       varchar(32)  NOT NULL,
    description varchar(500) NOT NULL DEFAULT '',
    is_24_hours boolean      NOT NULL DEFAULT false,
    is_active   boolean      NOT NULL DEFAULT true,
    sort_order  int          NOT NULL DEFAULT 0,
    created_at  timestamptz  NOT NULL DEFAULT now(),
    updated_at  timestamptz  NOT NULL DEFAULT now(),
    deleted_at  timestamptz  NULL
);
CREATE INDEX IF NOT EXISTS idx_emergency_active_sort ON emergency_contacts (is_active, sort_order) WHERE deleted_at IS NULL;
