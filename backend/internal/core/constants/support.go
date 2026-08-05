package constants

// ServiceType adalah jenis layanan bantuan darurat (A-BAN-01).
//
// Dipakai Admin saat mengisi form CRUD dan dipakai aplikasi mahasiswa untuk
// mengelompokkan daftar. Sengaja enum tertutup — bukan teks bebas — agar
// pengelompokan di UI tidak pecah karena salah ketik.
//
// Nilai di sini WAJIB sama dengan CHECK constraint pada
// migrations/20260806120000_add_service_type_to_emergency_contacts.sql.
type ServiceType string

const (
	// ServiceNationalHotline: hotline psikologis nasional (mis. SEJIWA 119 ext 8).
	ServiceNationalHotline ServiceType = "NATIONAL_HOTLINE"
	// ServiceEmergency: panggilan darurat terpadu untuk ancaman keselamatan jiwa.
	ServiceEmergency ServiceType = "EMERGENCY"
	// ServiceCampusCounseling: unit konseling kampus.
	ServiceCampusCounseling ServiceType = "CAMPUS_COUNSELING"
	// ServiceCampusHealth: klinik/poliklinik kampus.
	ServiceCampusHealth ServiceType = "CAMPUS_HEALTH"
	// ServiceAcademicAdvisor: jalur pembimbing akademik.
	ServiceAcademicAdvisor ServiceType = "ACADEMIC_ADVISOR"
	// ServiceOther: default aman saat jenis belum ditentukan Admin.
	ServiceOther ServiceType = "OTHER"
)

var AllServiceTypes = []ServiceType{
	ServiceNationalHotline,
	ServiceEmergency,
	ServiceCampusCounseling,
	ServiceCampusHealth,
	ServiceAcademicAdvisor,
	ServiceOther,
}

var serviceTypeLabel = map[ServiceType]string{
	ServiceNationalHotline:  "Hotline Nasional",
	ServiceEmergency:        "Darurat Terpadu",
	ServiceCampusCounseling: "Konseling Kampus",
	ServiceCampusHealth:     "Klinik Kampus",
	ServiceAcademicAdvisor:  "Pembimbing Akademik",
	ServiceOther:            "Lainnya",
}

func (t ServiceType) String() string { return string(t) }

func (t ServiceType) Label() string {
	if label, ok := serviceTypeLabel[t]; ok {
		return label
	}
	return serviceTypeLabel[ServiceOther]
}

func (t ServiceType) IsValid() bool {
	_, ok := serviceTypeLabel[t]
	return ok
}

// NormalizeServiceType memetakan nilai kosong/tidak dikenal ke OTHER, sehingga
// baris lama (sebelum migrasi) tidak pernah membuat response gagal render.
func NormalizeServiceType(v string) ServiceType {
	t := ServiceType(v)
	if t.IsValid() {
		return t
	}
	return ServiceOther
}

// VerificationMarker adalah penanda manual pada keterangan layanan yang belum
// diverifikasi tim Admin (A-BAN-04 — blocker rilis).
//
// Menampilkan nomor krisis yang salah lebih berbahaya daripada tidak
// menampilkan apa pun, sehingga penanda ini diangkat menjadi flag boolean pada
// response agar UI bisa memberi badge peringatan, bukan sekadar teks mentah.
const VerificationMarker = "[VERIFIKASI]"
