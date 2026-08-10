package dto

// ------------------------------------------------------------------
// "Minta dihubungi" — isyarat aktif dari mahasiswa ke dosen pembimbing.
//
// Menekan tombol ini adalah persetujuan yang eksplisit dan spesifik, sehingga
// permintaan tetap sampai ke pembimbing walau tingkat berbagi mahasiswa
// Tertutup. Yang sampai hanya nama dan waktu — Note di bawah adalah catatan
// untuk diri sendiri dan tidak pernah masuk ke response dosen.
// ------------------------------------------------------------------

type CreateContactRequestRequest struct {
	Note string `json:"note" binding:"omitempty,max=280"`
}

type ContactRequestResponse struct {
	ID        string `json:"id"`
	Status    string `json:"status"`
	Note      string `json:"note,omitempty"`
	CreatedAt string `json:"created_at"`
	IsOpen    bool   `json:"is_open"`
}

// ContactRequestStateResponse dipakai kartu "minta dihubungi" pada klien:
// satu request memberi tahu apakah tombolnya boleh ditekan dan apa artinya.
type ContactRequestStateResponse struct {
	HasOpenRequest bool                    `json:"has_open_request"`
	Request        *ContactRequestResponse `json:"request"`

	// Advisors adalah SELURUH pembimbing yang akan melihat permintaan ini.
	// Dikirim sebagai daftar, bukan satu nama: mahasiswa berhak tahu persis
	// siapa saja yang menerima isyaratnya sebelum menekan tombolnya.
	Advisors   []AdvisorResponse `json:"advisors"`
	CanRequest bool              `json:"can_request"`

	// Explanation menjelaskan persis apa yang dosen lihat, supaya mahasiswa
	// tahu batasnya sebelum menekan tombol.
	Explanation string `json:"explanation"`
}
