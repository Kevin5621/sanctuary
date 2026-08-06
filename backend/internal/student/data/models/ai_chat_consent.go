package models

import (
	"time"

	"github.com/gilabs/sanctuary/internal/core/utils"
)

// AIChatConsent mencatat keputusan mahasiswa atas D-5: isi percakapan Terapis
// AI dikirim ke Google Gemini, sebuah layanan pihak ketiga di luar sistem.
//
// Mengapa disimpan di server dan bukan sebagai flag lokal di aplikasi:
//
//   - Flag di klien dapat dihapus, dipalsukan, atau tidak ikut berpindah saat
//     mahasiswa ganti perangkat. Consent yang hilang saat ganti HP akan membuat
//     teks terkirim ke pihak ketiga tanpa persetujuan yang pernah tercatat.
//   - Gate sesungguhnya berada di usecase (lihat ChatUsecase.requireConsent).
//     UI yang menyembunyikan tombol kirim hanyalah lapisan kenyamanan; request
//     yang dibuat manual dengan token valid tetap harus ditolak.
//   - Saat audit etik menanyakan "siapa yang menyetujui, kapan, atas teks
//     pemberitahuan yang mana", baris inilah jawabannya.
type AIChatConsent struct {
	utils.BaseModel

	// UserID unik: satu mahasiswa hanya punya satu keputusan yang berlaku.
	// Perubahan keputusan menimpa baris yang sama (riwayatnya ada di audit log).
	UserID string `gorm:"type:uuid;not null;uniqueIndex:uq_ai_consent_user" json:"user_id"`

	// Status: GRANTED | DENIED. Kolom ini ada karena "belum pernah memutuskan"
	// dan "sudah menolak" adalah dua keadaan yang berbeda: yang pertama harus
	// memunculkan layar consent, yang kedua TIDAK boleh menanyakannya lagi dan
	// langsung menampilkan latihan mandiri.
	Status string `gorm:"size:16;not null" json:"status"`

	// NoticeVersion adalah versi teks pemberitahuan yang benar-benar dibaca
	// mahasiswa saat memutuskan. Bila teksnya berubah secara material (mis.
	// penyedia AI berganti), versi dinaikkan dan consent lama tidak lagi
	// mengizinkan pengiriman — persetujuan atas teks lama bukan persetujuan
	// atas praktik yang baru.
	NoticeVersion string `gorm:"size:32;not null" json:"notice_version"`

	// ConsentedAt hanya terisi bila Status = GRANTED.
	ConsentedAt *time.Time `gorm:"type:timestamptz" json:"consented_at,omitempty"`

	// DecidedAt terisi untuk kedua status — dipakai audit untuk mengetahui
	// kapan mahasiswa terakhir kali menyatakan sikap.
	DecidedAt time.Time `gorm:"type:timestamptz;not null" json:"decided_at"`
}

func (AIChatConsent) TableName() string { return "ai_chat_consents" }

const (
	ConsentStatusGranted = "GRANTED"
	ConsentStatusDenied  = "DENIED"
)

// CurrentNoticeVersion adalah versi teks pemberitahuan pihak ketiga yang
// berlaku sekarang. Naikkan bila isi pemberitahuan berubah material.
const CurrentNoticeVersion = "v1-gemini-2.5-flash"

// AllowsProcessing menjawab satu-satunya pertanyaan yang penting bagi gate:
// bolehkah teks mahasiswa ini dikirim ke pihak ketiga saat ini?
//
// Consent atas versi pemberitahuan LAMA sengaja tidak dianggap cukup.
func (c *AIChatConsent) AllowsProcessing() bool {
	return c != nil &&
		c.Status == ConsentStatusGranted &&
		c.NoticeVersion == CurrentNoticeVersion
}
