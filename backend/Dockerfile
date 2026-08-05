# Image produksi — multi-stage, binary statis, non-root, tanpa toolchain Go.
FROM golang:1.25-alpine AS builder

RUN apk add --no-cache git ca-certificates

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /out/api ./cmd/api
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /out/seed ./cmd/seed

FROM alpine:3.20

RUN apk add --no-cache ca-certificates tzdata && \
    addgroup -S sanctuary && adduser -S sanctuary -G sanctuary

WORKDIR /app
COPY --from=builder /out/api /app/api
COPY --from=builder /out/seed /app/seed
COPY --from=builder /app/apps/api/seeders /app/apps/api/seeders

USER sanctuary
EXPOSE 8080

ENTRYPOINT ["/app/api"]
