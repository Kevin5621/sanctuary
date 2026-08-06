package dto

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email,max=160"`
	Password string `json:"password" binding:"required,min=8,max=128"`
}

// RegisterStudentRequest adalah pendaftaran mandiri mahasiswa.
//
// Peran TIDAK ADA di payload ini: endpoint /auth/register selalu membuat akun
// STUDENT. Akun dosen & kaprodi hanya lahir dari kelola akun Admin, sehingga
// tidak ada jalur bagi pendaftar untuk memilih perannya sendiri.
type RegisterStudentRequest struct {
	FullName             string `json:"full_name" binding:"required,min=3,max=128"`
	Email                string `json:"email" binding:"required,email,max=160"`
	Password             string `json:"password" binding:"required,min=8,max=128"`
	PasswordConfirmation string `json:"password_confirmation" binding:"required,min=8,max=128"`
	StudentNumber        string `json:"student_number" binding:"required,min=3,max=32"`
	CohortYear           int    `json:"cohort_year" binding:"required,gte=2000,lte=2100"`
	StudyProgramID       string `json:"study_program_id" binding:"required,uuid"`
	Phone                string `json:"phone" binding:"omitempty,max=32"`
}

// RefreshRequest hanya dipakai klien native; klien web mengirim refresh token
// lewat cookie HttpOnly sehingga body boleh kosong.
type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"omitempty,max=1024"`
}

// StudyProgramResponse mengisi dropdown program studi. Dapat diakses tanpa
// sesi karena formulir pendaftaran membutuhkannya sebelum akun ada — isinya
// murni data referensi kampus, tanpa satu pun atribut pengguna.
type StudyProgramResponse struct {
	ID      string `json:"id"`
	Code    string `json:"code"`
	Name    string `json:"name"`
	Faculty string `json:"faculty,omitempty"`
}

// UserResponse tidak pernah memuat data klinis.
type UserResponse struct {
	ID             string  `json:"id"`
	FullName       string  `json:"full_name"`
	Email          string  `json:"email"`
	Phone          string  `json:"phone,omitempty"`
	AvatarURL      string  `json:"avatar_url,omitempty"`
	Role           string  `json:"role"`
	RoleLabel      string  `json:"role_label"`
	TabCount       int     `json:"tab_count"`
	StudentNumber  *string `json:"student_number,omitempty"`
	LecturerNumber *string `json:"lecturer_number,omitempty"`
	CohortYear     *int    `json:"cohort_year,omitempty"`
	AdvisorID      *string `json:"advisor_id,omitempty"`
	StudyProgramID *string `json:"study_program_id,omitempty"`
	StudyProgram   *string `json:"study_program,omitempty"`
	IsActive       bool    `json:"is_active"`
	LastLoginAt    *string `json:"last_login_at,omitempty"`
}

// SessionResponse adalah payload login/refresh.
// AccessToken & RefreshToken HANYA diisi untuk klien native (X-Client-Type: mobile);
// untuk klien web keduanya kosong karena dikirim via cookie HttpOnly.
type SessionResponse struct {
	User             UserResponse `json:"user"`
	AccessToken      string       `json:"access_token,omitempty"`
	RefreshToken     string       `json:"refresh_token,omitempty"`
	AccessExpiresAt  string       `json:"access_expires_at"`
	RefreshExpiresAt string       `json:"refresh_expires_at"`
	CSRFToken        string       `json:"csrf_token,omitempty"`
}
