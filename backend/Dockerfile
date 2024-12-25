ARG GO_VERSION=1.23
FROM golang:${GO_VERSION} AS base
RUN apt-get update && \
    apt-get install -y \
    git g++ musl-dev sqlite3 libsqlite3-dev && \
    rm -rf /var/lib/apt/lists/*

FROM base AS init
WORKDIR /app


FROM base AS dev
WORKDIR /app
COPY . /app
ENV CGO_ENABLED=1
ENV GIN_MODE="debug"

# RUN go install github.com/99designs/gqlgen@latest && \
#     go install github.com/volatiletech/sqlboiler/v4@latest && \
#     go install github.com/volatiletech/sqlboiler/v4/drivers/sqlboiler-sqlite3@latest && \
#     go install github.com/golang/mock/mockgen@latest

FROM base AS builder
ARG API_PORT
WORKDIR /app

COPY src/ ./
RUN go mod download
RUN go build -o backend .
ENV GIN_MODE="release"
RUN CGO_ENABLED=0 GOOS=linux go build -o backend .


FROM gcr.io/distroless/static-debian12 AS runner
COPY --from=builder --chown=nonroot:nonroot /app/backend /backend
EXPOSE ${API_PORT}
ENV GIN_MODE="release"
USER nonroot
CMD ["./backend"]