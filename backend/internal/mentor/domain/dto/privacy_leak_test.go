package dto_test

// C-15 — pengaman kebocoran privasi otomatis.
//
// Test ini adalah jaring pengaman paling murah untuk I-1 dan D-6: ia GAGAL bila
// seseorang menambahkan field yang membawa teks tulisan mahasiswa ke DTO yang
// dibaca Dosen Pembimbing atau Kaprodi.
//
// Pendekatannya memindai SUMBER (go/ast), bukan daftar tipe yang ditulis manual.
// Alasannya penting: daftar manual hanya melindungi struct yang diingat penulis
// test, sedangkan kebocoran justru datang dari struct BARU yang ditambahkan
// enam bulan kemudian. Dengan memindai seluruh deklarasi struct di package
// terkait, struct baru otomatis ikut terjaga tanpa ada yang perlu mengingat.
//
// Kalau test ini gagal: perbaiki DTO-nya, jangan longgarkan denylist-nya.

import (
	"encoding/json"
	"go/ast"
	"go/parser"
	"go/token"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	mentordto "github.com/gilabs/sanctuary/internal/mentor/domain/dto"
)

// guardedPackages adalah permukaan data yang mengalir ke peran SELAIN pemilik
// data. Ketiganya dipindai relatif terhadap direktori package ini.
var guardedPackages = map[string]string{
	"mentor/domain/dto":        ".",
	"program/domain/dto":       filepath.Join("..", "..", "..", "program", "domain", "dto"),
	"mentor/data/repositories": filepath.Join("..", "..", "data", "repositories"),
}

// forbiddenFragments adalah potongan nama yang menandakan konten tulisan
// mahasiswa. Dicocokkan sebagai substring case-insensitive pada nama field Go
// maupun tag json-nya.
//
//   - "note"       -> student_contact_requests.note (D-6)
//   - "content"    -> isi jurnal & pesan chat (I-1)
//   - "journal"    -> apa pun yang membawa jurnal ke DTO peran lain
//   - "chat"       -> percakapan Terapis AI
//   - "transcript" -> bentuk lain dari percakapan
//
// Catatan: "message" TIDAK masuk daftar karena dipakai pesan k-anonymity
// ("Data belum cukup") yang aman, sedangkan pesan chat sudah tertangkap oleh
// "chat" dan "content".
var forbiddenFragments = []string{"note", "content", "journal", "chat", "transcript"}

func TestGuardedPackagesHaveNoPrivateContentFields(t *testing.T) {
	for label, dir := range guardedPackages {
		fset := token.NewFileSet()
		pkgs, err := parser.ParseDir(fset, dir, nil, parser.ParseComments)
		if err != nil {
			t.Fatalf("%s: gagal mem-parse package: %v", label, err)
		}
		if len(pkgs) == 0 {
			t.Fatalf("%s: tidak ada package ditemukan di %s — path pemindaian salah", label, dir)
		}

		scanned := 0
		for _, pkg := range pkgs {
			for fileName, file := range pkg.Files {
				if strings.HasSuffix(fileName, "_test.go") {
					continue
				}
				ast.Inspect(file, func(n ast.Node) bool {
					typeSpec, ok := n.(*ast.TypeSpec)
					if !ok {
						return true
					}
					structType, ok := typeSpec.Type.(*ast.StructType)
					if !ok {
						return true
					}
					scanned++
					checkStructFields(t, label, typeSpec.Name.Name, structType)
					return true
				})
			}
		}

		if scanned == 0 {
			t.Errorf("%s: tidak ada struct yang terpindai — pemindai kehilangan target, "+
				"jaring pengaman ini jadi tidak berarti", label)
		}
	}
}

func checkStructFields(t *testing.T, pkgLabel, structName string, st *ast.StructType) {
	t.Helper()

	for _, field := range st.Fields.List {
		tag := ""
		if field.Tag != nil {
			tag = field.Tag.Value
		}

		for _, name := range field.Names {
			if fragment, hit := matchForbidden(name.Name); hit {
				t.Errorf(
					"KEBOCORAN PRIVASI (C-15): %s.%s memiliki field %q yang mengandung %q.\n"+
						"Teks yang ditulis mahasiswa tidak boleh keluar ke peran lain (I-1 / D-6).\n"+
						"Perbaiki DTO-nya — jangan longgarkan test ini.",
					pkgLabel, structName, name.Name, fragment,
				)
			}
		}
		if fragment, hit := matchForbidden(tag); hit {
			t.Errorf(
				"KEBOCORAN PRIVASI (C-15): %s.%s memiliki tag %s yang mengandung %q.",
				pkgLabel, structName, tag, fragment,
			)
		}
	}
}

func matchForbidden(value string) (string, bool) {
	lowered := strings.ToLower(value)
	for _, fragment := range forbiddenFragments {
		if strings.Contains(lowered, fragment) {
			return fragment, true
		}
	}
	return "", false
}

// ------------------------------------------------------------------
// Pemeriksaan pada level JSON — memastikan bentuk yang benar-benar dikirim ke
// klien tidak memuat alasan permintaan dihubungi (D-6).
// ------------------------------------------------------------------

func TestContactRequestResponsesCarryOnlyNameAndTime(t *testing.T) {
	// Teks ini mewakili isi student_contact_requests.note pada seeder.
	const secretNote = "Ingin berdiskusi soal beban tugas minggu ini."

	responses := map[string]any{
		"ContactRequestItemResponse": mentordto.ContactRequestItemResponse{
			RequestID:   "req-1",
			StudentID:   "student-1",
			FullName:    "Gita Anindya",
			RequestedAt: "2026-08-06T09:00:00Z",
		},
		"AdviseeListItemResponse": mentordto.AdviseeListItemResponse{
			StudentID:             "student-1",
			FullName:              "Gita Anindya",
			ShareLevel:            "CLOSED",
			HasOpenContactRequest: true,
			ContactRequestedAt:    strPtr("2026-08-06T09:00:00Z"),
		},
		"StudentIndicatorResponse": mentordto.StudentIndicatorResponse{
			StudentID:             "student-1",
			FullName:              "Gita Anindya",
			ShareLevel:            "CLOSED",
			HasOpenContactRequest: true,
			ContactRequestedAt:    strPtr("2026-08-06T09:00:00Z"),
		},
	}

	for name, response := range responses {
		encoded, err := json.Marshal(response)
		if err != nil {
			t.Fatalf("%s: gagal marshal: %v", name, err)
		}
		if strings.Contains(string(encoded), secretNote) {
			t.Errorf("%s membocorkan isi note ke response dosen (D-6): %s", name, encoded)
		}

		var decoded map[string]any
		if err := json.Unmarshal(encoded, &decoded); err != nil {
			t.Fatalf("%s: gagal unmarshal: %v", name, err)
		}
		for key := range decoded {
			if fragment, hit := matchForbidden(key); hit {
				t.Errorf("%s: kunci JSON %q mengandung %q — tidak boleh ada di response dosen",
					name, key, fragment)
			}
		}
	}
}

// TestClosedStudentWithContactRequestExposesNoIndicator mengunci D-7 pada level
// bentuk data: mahasiswa Tertutup yang menekan "minta dihubungi" tetap muncul,
// tetapi barisnya tidak boleh membawa satu angka kondisi pun.
func TestClosedStudentWithContactRequestExposesNoIndicator(t *testing.T) {
	item := mentordto.AdviseeListItemResponse{
		StudentID:             "student-closed",
		FullName:              "Fajar Ramadhan",
		ShareLevel:            "CLOSED",
		PrivacyNotice:         "Mahasiswa memilih untuk tidak membagikan data kondisi.",
		HasOpenContactRequest: true,
		ContactRequestedAt:    strPtr("2026-08-06T09:00:00Z"),
	}

	if item.EWS != nil {
		t.Error("mahasiswa CLOSED tidak boleh membawa ringkasan EWS")
	}
	if item.LastCheckinDate != nil {
		t.Error("mahasiswa CLOSED tidak boleh membocorkan tanggal check-in terakhir")
	}
	if !item.HasOpenContactRequest {
		t.Error("D-7: permintaan dihubungi harus tetap tampil walau share_level CLOSED")
	}
	if item.PrivacyNotice == "" {
		t.Error("L-BIM-05: state CLOSED wajib punya keterangan jujur, bukan tampil sebagai Normal")
	}
}

// TestEWSSummaryIsPointerSoClosedRendersAsNull menjaga L-BIM-05: field EWS harus
// nullable agar klien dapat membedakan "tidak berbagi" dari "Normal".
// Kalau tipenya berubah menjadi nilai (bukan pointer), CLOSED akan ter-serialisasi
// sebagai level kosong dan mudah salah dirender sebagai "Normal".
func TestEWSSummaryIsPointerSoClosedRendersAsNull(t *testing.T) {
	for _, target := range []struct {
		name  string
		typ   reflect.Type
		field string
	}{
		{"AdviseeListItemResponse", reflect.TypeOf(mentordto.AdviseeListItemResponse{}), "EWS"},
		{"StudentIndicatorResponse", reflect.TypeOf(mentordto.StudentIndicatorResponse{}), "EWS"},
	} {
		field, ok := target.typ.FieldByName(target.field)
		if !ok {
			t.Fatalf("%s: field %s tidak ditemukan", target.name, target.field)
		}
		if field.Type.Kind() != reflect.Ptr {
			t.Errorf("%s.%s harus pointer agar state CLOSED ter-serialisasi sebagai null (L-BIM-05), bukan %s",
				target.name, target.field, field.Type.Kind())
		}
		if strings.Contains(field.Tag.Get("json"), "omitempty") {
			t.Errorf("%s.%s tidak boleh omitempty: klien harus melihat \"ews\": null secara eksplisit, "+
				"bukan field yang hilang", target.name, target.field)
		}
	}
}

func strPtr(v string) *string { return &v }
