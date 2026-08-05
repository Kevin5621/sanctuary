package constants

// Role adalah kode peran aplikasi (disimpan pada tabel roles.code).
type Role string

const (
	RoleStudent       Role = "STUDENT"         // Mahasiswa
	RoleLecturer      Role = "LECTURER"        // Dosen Pembimbing
	RoleHeadOfProgram Role = "HEAD_OF_PROGRAM" // Kaprodi
	RoleAdmin         Role = "ADMIN"           // Admin
)

func (r Role) String() string { return string(r) }

// AllRoles dipakai seeder & validasi.
var AllRoles = []Role{RoleStudent, RoleLecturer, RoleHeadOfProgram, RoleAdmin}

var roleDisplayName = map[Role]string{
	RoleStudent:       "Mahasiswa",
	RoleLecturer:      "Dosen Pembimbing",
	RoleHeadOfProgram: "Kaprodi",
	RoleAdmin:         "Admin",
}

// DisplayName mengembalikan label bahasa Indonesia untuk sebuah role.
func (r Role) DisplayName() string {
	if name, ok := roleDisplayName[r]; ok {
		return name
	}
	return string(r)
}

// TabCount adalah jumlah tab shell navigation per peran (kontrak dengan Flutter router).
func (r Role) TabCount() int {
	switch r {
	case RoleStudent:
		return 4 // Beranda, Mood, Jurnal, Profil (+ AI slot sebagai overlay route)
	case RoleLecturer:
		return 3 // Bimbingan, Kondisi, Profil
	case RoleHeadOfProgram:
		return 4 // Dashboard, Pembimbing, Laporan, Profil
	case RoleAdmin:
		return 2 // Bantuan, Profil
	default:
		return 0
	}
}

func IsValidRole(code string) bool {
	for _, r := range AllRoles {
		if string(r) == code {
			return true
		}
	}
	return false
}
