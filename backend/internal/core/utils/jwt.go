package utils

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"github.com/gilabs/sanctuary/internal/core/apptime"
)

const (
	TokenTypeAccess  = "access"
	TokenTypeRefresh = "refresh"
)

// AccessClaims adalah payload JWT access token.
// Catatan privasi: hanya identitas & otorisasi, tidak ada data klinis.
type AccessClaims struct {
	UserID    string `json:"uid"`
	Role      string `json:"role"`
	ProgramID string `json:"program_id,omitempty"`
	TokenType string `json:"typ"`
	jwt.RegisteredClaims
}

type TokenPair struct {
	AccessToken      string
	RefreshToken     string
	AccessExpiresAt  time.Time
	RefreshExpiresAt time.Time
	RefreshTokenID   string
}

type JWTManager struct {
	secret     []byte
	issuer     string
	accessTTL  time.Duration
	refreshTTL time.Duration
}

func NewJWTManager(secret, issuer string, accessTTL, refreshTTL time.Duration) *JWTManager {
	return &JWTManager{secret: []byte(secret), issuer: issuer, accessTTL: accessTTL, refreshTTL: refreshTTL}
}

func (m *JWTManager) AccessTTL() time.Duration  { return m.accessTTL }
func (m *JWTManager) RefreshTTL() time.Duration { return m.refreshTTL }

// GenerateTokenPair membuat access + refresh token. Refresh token memiliki jti
// yang dipakai sebagai identitas baris pada tabel refresh_tokens (rotasi).
func (m *JWTManager) GenerateTokenPair(userID, role, programID string) (TokenPair, error) {
	now := apptime.Now()
	accessExp := now.Add(m.accessTTL)
	refreshExp := now.Add(m.refreshTTL)
	refreshID := uuid.NewString()

	access, err := m.sign(AccessClaims{
		UserID:    userID,
		Role:      role,
		ProgramID: programID,
		TokenType: TokenTypeAccess,
		RegisteredClaims: jwt.RegisteredClaims{
			ID:        uuid.NewString(),
			Subject:   userID,
			Issuer:    m.issuer,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(accessExp),
		},
	})
	if err != nil {
		return TokenPair{}, err
	}

	refresh, err := m.sign(AccessClaims{
		UserID:    userID,
		Role:      role,
		TokenType: TokenTypeRefresh,
		RegisteredClaims: jwt.RegisteredClaims{
			ID:        refreshID,
			Subject:   userID,
			Issuer:    m.issuer,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(refreshExp),
		},
	})
	if err != nil {
		return TokenPair{}, err
	}

	return TokenPair{
		AccessToken:      access,
		RefreshToken:     refresh,
		AccessExpiresAt:  accessExp,
		RefreshExpiresAt: refreshExp,
		RefreshTokenID:   refreshID,
	}, nil
}

func (m *JWTManager) sign(claims AccessClaims) (string, error) {
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(m.secret)
}

// Parse memverifikasi signature + expiry dan memastikan tipe token sesuai.
func (m *JWTManager) Parse(tokenString, expectedType string) (*AccessClaims, error) {
	claims := &AccessClaims{}
	_, err := jwt.ParseWithClaims(tokenString, claims, func(t *jwt.Token) (any, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return m.secret, nil
	}, jwt.WithIssuer(m.issuer), jwt.WithExpirationRequired())

	if err != nil {
		if errors.Is(err, jwt.ErrTokenExpired) {
			if expectedType == TokenTypeRefresh {
				return nil, NewError(CodeRefreshTokenExpired)
			}
			return nil, NewError(CodeTokenExpired)
		}
		return nil, NewError(CodeTokenInvalid).WithCause(err)
	}

	if claims.TokenType != expectedType {
		return nil, NewError(CodeTokenInvalid)
	}
	return claims, nil
}
