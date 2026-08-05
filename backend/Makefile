.PHONY: dev run build test seed migrate docker-up docker-down docker-logs docker-seed docker-reset

# ---- Local (tanpa Docker) — butuh PostgreSQL/Redis lokal & .env terisi ----

# Setara "pnpm dev": jalankan API dengan hot reload.
dev:
	@command -v air >/dev/null 2>&1 || go install github.com/air-verse/air@latest
	air -c .air.toml

run:
	go run ./cmd/api

seed:
	go run ./cmd/seed

# Menjalankan SELURUH migrasi berurutan nama file (timestamp-prefixed), bukan
# hanya skema awal — kalau tidak, migrasi baru diam-diam tidak pernah terpakai.
# Tiap file ditulis idempotent sehingga aman diulang.
migrate:
	@for f in $$(ls migrations/*.sql | sort); do \
		echo "[migrate] $$f"; \
		psql -v ON_ERROR_STOP=1 "$$(grep DB_DSN .env | cut -d '=' -f2-)" -f $$f || exit 1; \
	done

build:
	go build -o ./tmp/api ./cmd/api

test:
	go test ./...

# ---- Docker Compose — Postgres + Redis + API (hot reload di dalam container) ----

# docker compose up -d SUDAH menjalankan API dengan hot reload (Dockerfile.dev + air).
# Target ini hanya alias yang lebih jelas namanya.
docker-up:
	docker compose up -d

docker-down:
	docker compose down

docker-logs:
	docker compose logs -f api

# Migrasi skema di dalam network compose (host db, bukan localhost).
docker-migrate:
	@for f in $$(ls migrations/*.sql | sort); do \
		echo "[migrate] $$f"; \
		docker compose exec -T db psql -v ON_ERROR_STOP=1 -U sanctuary -d sanctuary -f - < $$f || exit 1; \
	done

# Seeder di dalam container (memakai ENV compose: DB_DSN=...@db:5432/...).
docker-seed:
	docker compose exec api go run ./cmd/seed

# Reset total: hentikan stack dan hapus volume data (destruktif).
docker-reset:
	docker compose down -v
