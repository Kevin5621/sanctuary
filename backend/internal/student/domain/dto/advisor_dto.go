package dto

// ------------------------------------------------------------------
// Daftar pembimbing milik mahasiswa sendiri.
//
// Satu mahasiswa dapat dibimbing lebih dari satu dosen, dan SEMUANYA memiliki
// hak baca yang sama atas data yang mahasiswa izinkan. Karena itu daftar ini
// dibuka apa adanya ke mahasiswa: janji privasi "pembimbingmu melihat X" hanya
// bermakna kalau mahasiswa tahu persis siapa saja "pembimbingmu" itu.
// ------------------------------------------------------------------

type AdvisorResponse struct {
	AdvisorID      string `json:"advisor_id"`
	FullName       string `json:"full_name"`
	LecturerNumber string `json:"lecturer_number,omitempty"`
	// Email dibuka karena aplikasi ini sengaja bukan kanal pesan: mahasiswa
	// diarahkan menghubungi pembimbing lewat jalur kampus yang biasa.
	Email string `json:"email,omitempty"`
}

// MyAdvisorsResponse mengisi kartu "Pembimbingmu" pada tab Profil.
type MyAdvisorsResponse struct {
	Advisors []AdvisorResponse `json:"advisors"`
	Total    int               `json:"total"`
	// Notice adalah satu kalimat konsekuensi yang ditulis server, bukan klien —
	// sama alasannya dengan Explanation pada "minta dihubungi": janji privasi
	// hanya boleh punya satu rumusan.
	Notice string `json:"notice"`
}
