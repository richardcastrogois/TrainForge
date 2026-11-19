// Package handler is the Vercel serverless entry point. Every route of the API
// is rewritten here (vercel.json); the handler is assembled once per instance.
package handler

import (
	"context"
	"log/slog"
	"net/http"
	"os"
	"sync"

	"trainforge.local/api/internal/app"
	"trainforge.local/api/internal/platform/config"
)

var (
	once    sync.Once
	routed  http.Handler
	initErr error
)

func setup() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	c, err := config.Load(os.Getenv)
	if err != nil {
		initErr = err
		logger.Error("api_config_invalid", "reason", err.Error())
		return
	}
	// The pool lives for the warm instance; Vercel freezes it between requests.
	routed, _, initErr = app.New(context.Background(), c, logger)
	if initErr != nil {
		logger.Error("api_init_failed", "reason", initErr.Error())
	}
}

// Handler receives requests from the Vercel edge, which replaces any
// client-supplied X-Forwarded-For/Proto. The socket peer is the local runtime
// bridge, declared as the only trusted proxy (TF_TRUSTED_PROXY_CIDRS=127.0.0.1/32).
func Handler(w http.ResponseWriter, r *http.Request) {
	once.Do(setup)
	if initErr != nil {
		http.Error(w, `{"error":"service_unavailable"}`, http.StatusServiceUnavailable)
		return
	}
	r.RemoteAddr = "127.0.0.1:0"
	routed.ServeHTTP(w, r)
}
