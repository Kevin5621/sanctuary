package utils

import (
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"

	"golang.org/x/crypto/bcrypt"
)

// HashPassword memakai bcrypt cost default (10) — cukup untuk beban akademik.
func HashPassword(plain string) (string, error) {
	b, err := bcrypt.GenerateFromPassword([]byte(plain), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(b), nil
}

func VerifyPassword(hashed, plain string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hashed), []byte(plain)) == nil
}

// HashToken menyimpan refresh token sebagai SHA-256 (jangan simpan token mentah).
func HashToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}

// RandomToken dipakai untuk CSRF token (double-submit cookie).
func RandomToken(nBytes int) (string, error) {
	b := make([]byte, nBytes)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(b), nil
}

// SecureCompare membandingkan string secara constant-time.
func SecureCompare(a, b string) bool {
	return subtle.ConstantTimeCompare([]byte(a), []byte(b)) == 1
}

// MaskEmail dipakai pada logging agar data pribadi tidak bocor ke log.
func MaskEmail(email string) string {
	for i, c := range email {
		if c == '@' {
			if i <= 1 {
				return "*" + email[i:]
			}
			return string(email[0]) + "***" + email[i:]
		}
	}
	return "***"
}
