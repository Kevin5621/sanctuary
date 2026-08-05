package utils

// ------------------------------------------------------------------
// K-Anonymity guard.
//
// Aturan Sanctuary: angka agregat prodi HANYA boleh dihitung/dikeluarkan
// bila ukuran kelompok >= K_ANONYMITY_MIN_GROUP (default 5).
// Bila kurang, response tetap 200 dengan is_sufficient=false agar UI dapat
// menampilkan state "Data belum cukup" tanpa memperlakukannya sebagai error.
// ------------------------------------------------------------------

const fallbackKAnonymityMinGroup = 5

var configKAnonymityMinGroup = fallbackKAnonymityMinGroup

// ConfigureKAnonymity dipanggil sekali dari config saat startup.
func ConfigureKAnonymity(minGroup int) {
	if minGroup > 0 {
		configKAnonymityMinGroup = minGroup
	}
}

func KAnonymityMinGroup() int { return configKAnonymityMinGroup }

// IsGroupSufficient mengecek ambang k-anonymity.
func IsGroupSufficient(groupSize int) bool { return groupSize >= configKAnonymityMinGroup }

// AggregateGuard adalah amplop standar untuk seluruh response agregat
// (dashboard kaprodi, kondisi kelompok dosen, laporan angkatan).
type AggregateGuard struct {
	IsSufficient    bool   `json:"is_sufficient"`
	GroupSize       int    `json:"group_size"`
	MinimumGroup    int    `json:"minimum_group_size"`
	InsufficientMsg string `json:"message,omitempty"`
}

// NewAggregateGuard membangun guard sekaligus pesan siap tampil.
func NewAggregateGuard(groupSize int) AggregateGuard {
	g := AggregateGuard{
		IsSufficient: IsGroupSufficient(groupSize),
		GroupSize:    groupSize,
		MinimumGroup: configKAnonymityMinGroup,
	}
	if !g.IsSufficient {
		g.InsufficientMsg = "Data belum cukup"
		// Ukuran kelompok asli tidak boleh dibocorkan saat di bawah ambang,
		// karena angka kecil sendiri sudah bersifat re-identifying.
		g.GroupSize = 0
	}
	return g
}
