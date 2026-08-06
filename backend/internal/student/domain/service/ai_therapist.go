package service

import "context"

// ------------------------------------------------------------------
// AITherapist — port ke model bahasa pihak ketiga (Gemini 2.5 Flash).
//
// Antarmuka ini sengaja dibuat sekecil EmotionAnalyzer, dengan alasan yang
// sama: usecase tidak boleh tahu penyedia mana yang dipakai. Mengganti Gemini
// dengan penyedia lain — atau mematikannya sama sekali di lingkungan test —
// tidak boleh menyentuh satu baris pun aturan bisnis chat.
//
// Catatan privasi (D-5): implementasi antarmuka ini MENGIRIM TEKS MAHASISWA
// KELUAR DARI SISTEM. Karena itu satu-satunya pemanggilnya, ChatUsecase.Send,
// wajib memastikan consent sudah tercatat SEBELUM memanggil Reply. Jangan
// memanggil port ini dari tempat lain tanpa melewati gate yang sama.
// ------------------------------------------------------------------

// ChatTurn adalah satu giliran percakapan yang dikirim sebagai konteks.
type ChatTurn struct {
	// FromStudent membedakan giliran mahasiswa dari balasan model.
	FromStudent bool
	Text        string
}

type AITherapist interface {
	// Reply mengembalikan balasan model atas history (lama → baru).
	//
	// Error dari method ini TIDAK boleh membuat request gagal total: pesan
	// mahasiswa sudah terlanjur ditulis dan harus tetap tersimpan. Pemanggil
	// bertanggung jawab menerjemahkannya menjadi balasan fallback.
	Reply(ctx context.Context, history []ChatTurn) (string, error)
}
