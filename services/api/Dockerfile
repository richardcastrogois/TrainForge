FROM golang:1.27.4-bookworm@sha256:4fa7c968ba93f1635670522dbb01a2c78150443e1385746924566079f36570ea AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN test "$(go env GOVERSION)" = "go1.27.4" && go mod download && go mod verify
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
