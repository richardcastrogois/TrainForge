FROM golang:1.27.3-bookworm@sha256:d9b6a1beb9474adc2a1ce842573639b44b2a0dd49b6669f51d3821baf9ec37c9 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN test "$(go env GOVERSION)" = "go1.27.3" && go mod download && go mod verify
COPY cmd/api/ ./cmd/api/
COPY internal/ ./internal/
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GOTOOLCHAIN=local go build -mod=readonly -tags=timetzdata -trimpath -buildvcs=false -ldflags="-s -w" -o /out/trainforge-api ./cmd/api

FROM scratch
ARG VCS_REF
ARG API_VERSION
LABEL org.opencontainers.image.title="TrainForge API" \
      org.opencontainers.image.source="https://github.com/richardcastrogois/TrainForge" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.version="${API_VERSION}"
COPY --from=build --chmod=0555 /out/trainforge-api /trainforge-api
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
USER 65532:65532
ENV TF_LISTEN_ADDR=0.0.0.0:8082 TF_ENV=production TF_SWAGGER=false
EXPOSE 8082
ENTRYPOINT ["/trainforge-api"]
