package httpapi

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"github.com/felixge/httpsnoop"
	"log/slog"
	"net/http"
	"regexp"
	"strings"
	"time"
)

type Readiness interface{ Ping(context.Context) error }
type Status struct {
	Status string `json:"status"`
}
type Problem struct {
	Type      string            `json:"type"`
	Title     string            `json:"title"`
	Status    int               `json:"status"`
	Code      string            `json:"code"`
	RequestID string            `json:"requestId"`
	Fields    map[string]string `json:"fields,omitempty"`
}
type requestKey struct{}

func JSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}
func Failure(w http.ResponseWriter, r *http.Request, status int, code string) {
	FailureFields(w, r, status, code, nil)
}
func FailureFields(w http.ResponseWriter, r *http.Request, status int, code string, fields map[string]string) {
	w.Header().Set("Content-Type", "application/problem+json")
	w.WriteHeader(status)
	id, _ := r.Context().Value(requestKey{}).(string)
	_ = json.NewEncoder(w).Encode(Problem{Type: "about:blank", Title: http.StatusText(status), Status: status, Code: code, RequestID: id, Fields: fields})
}

// Live reports whether the actual process is accepting requests.
// @Summary Process liveness
// @Tags operation
// @Produce json
// @Success 200 {object} Status
// @Router /api/v1/health/live [get]
func Live(w http.ResponseWriter, r *http.Request) { JSON(w, http.StatusOK, Status{Status: "alive"}) }

type Server struct{ DB Readiness }

// Ready checks runtime schema and privileges without exposing internal diagnostics.
// @Summary Runtime database prerequisites
// @Tags operation
// @Produce json
// @Success 200 {object} Status
// @Failure 503 {object} Problem
// @Router /api/v1/health/ready [get]
func (s Server) Ready(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), time.Second)
	defer cancel()
	if s.DB == nil || s.DB.Ping(ctx) != nil {
		Failure(w, r, http.StatusServiceUnavailable, "dependency_unavailable")
		return
	}
	JSON(w, http.StatusOK, Status{Status: "ready"})
}

func New(db Readiness, logger *slog.Logger, timeout time.Duration, docs http.Handler, routes ...func(*http.ServeMux)) http.Handler {
	return NewWithNetwork(db, logger, timeout, docs, Network{}, routes...)
}

func NewWithNetwork(db Readiness, logger *slog.Logger, timeout time.Duration, docs http.Handler, network Network, routes ...func(*http.ServeMux)) http.Handler {
	var limits Limiter
	admission := make(chan struct{}, 128)
	mux := http.NewServeMux()
	s := Server{DB: db}
	for _, register := range routes {
		register(mux)
	}
	mux.HandleFunc("GET /api/v1/health/live", Live)
	mux.HandleFunc("GET /api/v1/health/ready", s.Ready)
	if docs != nil {
		mux.Handle("GET /docs/", docs)
	}
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) { Failure(w, r, http.StatusNotFound, "route_not_found") })
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := rand.Text()
		ctx, cancel := context.WithTimeout(context.WithValue(r.Context(), requestKey{}, id), requestTimeout(r, timeout))
		defer cancel()
		r = r.WithContext(ctx)
		w.Header().Set("X-Request-Id", id)
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("Cache-Control", "no-store")
		r.Body = http.MaxBytesReader(w, r.Body, requestBodyLimit(r))
		metrics := httpsnoop.CaptureMetricsFn(w, func(w http.ResponseWriter) {
			defer func() {
				if recover() != nil {
					logger.Error("request_failed", "requestId", id)
					Failure(w, r, http.StatusInternalServerError, "internal_error")
				}
			}()
			peer, secure, err := network.Resolve(r)
			if err != nil {
				Failure(w, r, 400, "invalid_proxy_headers")
				return
			}
			if network.RequireTLS && !secure {
				Failure(w, r, 426, "https_required")
				return
			}
			if !limits.Allow(peer, 240) {
				limited(w, r)
				return
			}
			select {
			case admission <- struct{}{}:
				defer func() { <-admission }()
			default:
				w.Header().Set("Retry-After", "1")
				Failure(w, r, 503, "server_busy")
				return
			}
			mux.ServeHTTP(w, r)
		})
		logger.Info("http_request", "requestId", id, "method", methodLabel(r.Method),
			"route", routeLabel(r.Pattern), "status", metrics.Code,
			"durationMs", float64(metrics.Duration)/float64(time.Millisecond), "responseBytes", metrics.Written)
	})
}

// Domain handlers keep their own strict schema/size checks. Only these explicit
// upload/batch routes need a larger outer ceiling than the legacy 64 KiB.
func requestBodyLimit(r *http.Request) int64 {
	if r.Method == http.MethodPost && r.URL.Path == "/api/v1/me/nutrition/sync" {
		return 2 << 20
	}
	if r.Method == http.MethodPost {
		parts := strings.Split(strings.Trim(r.URL.Path, "/"), "/")
		if len(parts) == 6 && parts[0] == "api" && parts[1] == "v1" && parts[2] == "me" && parts[3] == "food-contributions" && len(parts[4]) == 36 && parts[5] == "media" {
			return 4 << 20
		}
	}
	return 64 << 10
}

var catalogExportPath = regexp.MustCompile(`^/api/v1/food-catalog/exports/([a-f0-9]{64}/)?[A-Za-z0-9_.-]+[.]jsonl[.]gz$`)

func requestTimeout(r *http.Request, normal time.Duration) time.Duration {
	if (r.Method == http.MethodGet || r.Method == http.MethodHead) && r.URL.RawQuery == "" &&
		(r.URL.Path == "/api/v1/food-catalog/archive" || catalogExportPath.MatchString(r.URL.Path)) {
		return 30 * time.Minute
	}
	return normal
}
