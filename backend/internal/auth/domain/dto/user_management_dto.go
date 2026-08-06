package dto

// Kelola akun Admin (A-AKN-01..03).
//
// Cakupannya sengaja sempit: hanya akun dosen & kaprodi. Mahasiswa mendaftar
// sendiri lewat /auth/register, dan akun Admin baru tidak dapat dibuat lewat
// API sama sekali.

type CreateStaffUserRequest struct {
	FullName string `json:"full_name" binding:"required,min=3,max=128"`
	Email    string `json:"email" binding:"required,email,max=160"`
	Password string `json:"password" binding:"required,min=8,max=128"`
	// Role hanya menerima LECTURER atau HEAD_OF_PROGRAM (constants.StaffRoles).
	Role string `json:"role" binding:"required"`
	// LecturerNumber (NIDN) opsional: sebagian dosen baru belum memilikinya saat
	// akun dibuat, dan menahan pembuatan akun karena itu hanya akan memancing
	// admin mengisi nomor asal-asalan.
	LecturerNumber string `json:"lecturer_number" binding:"omitempty,min=3,max=32"`
	StudyProgramID string `json:"study_program_id" binding:"required,uuid"`
	Phone          string `json:"phone" binding:"omitempty,max=32"`
	IsActive       *bool  `json:"is_active" binding:"required"`
}

type UpdateStaffUserRequest struct {
	FullName       string `json:"full_name" binding:"required,min=3,max=128"`
	LecturerNumber string `json:"lecturer_number" binding:"omitempty,min=3,max=32"`
	StudyProgramID string `json:"study_program_id" binding:"required,uuid"`
	Phone          string `json:"phone" binding:"omitempty,max=32"`
	IsActive       *bool  `json:"is_active" binding:"required"`
	// Password opsional — diisi hanya saat Admin menyetel ulang kata sandi.
	// Kosong berarti kata sandi lama tetap berlaku.
	Password string `json:"password" binding:"omitempty,min=8,max=128"`
}

// ManagedUserResponse adalah baris pada daftar kelola akun.
//
// Sengaja TIDAK memuat satu pun atribut kondisi/wellbeing: halaman ini murni
// administratif, dan Admin memang tidak berhak melihat data klinis siapa pun.
type ManagedUserResponse struct {
	ID             string  `json:"id"`
	FullName       string  `json:"full_name"`
	Email          string  `json:"email"`
	Phone          string  `json:"phone,omitempty"`
	Role           string  `json:"role"`
	RoleLabel      string  `json:"role_label"`
	LecturerNumber *string `json:"lecturer_number,omitempty"`
	StudyProgramID *string `json:"study_program_id,omitempty"`
	StudyProgram   *string `json:"study_program,omitempty"`
	IsActive       bool    `json:"is_active"`
	LastLoginAt    *string `json:"last_login_at,omitempty"`
	CreatedAt      string  `json:"created_at"`
}

// RoleOptionResponse mengisi dropdown peran pada formulir Admin, sehingga
// daftar peran yang boleh dibuat berasal dari server — satu sumber kebenaran
// dengan constants.StaffRoles.
type RoleOptionResponse struct {
	Value string `json:"value"`
	Label string `json:"label"`
}
