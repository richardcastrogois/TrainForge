package main

import (
	"context"
	"errors"
	"github.com/jackc/pgx/v5/pgxpool"
	httpSwagger "github.com/swaggo/http-swagger/v2"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
	"trainforge.local/api/internal/platform/config"
	"trainforge.local/api/internal/platform/httpapi"
	"trainforge.local/api/internal/platform/postgres"
	_ "trainforge.local/api/internal/swaggerdocs"
)

// @title TrainForge API
// @version 0.1.0
// @description Actual local foundation; health endpoints only. No training/authentication functionality implied.
// @BasePath /
// @schemes http https
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	if err := run(logger); err != nil {
		logger.Error("api_stopped", "reason", err.Error())
		os.Exit(1)
	}
}
func run(logger *slog.Logger) error {
	c, err := config.Load(os.Getenv)
	if err != nil {
		return err
	}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	var pool *pgxpool.Pool
	var db httpapi.Readiness
	if c.DatabaseURL != "" {
		pool, err = postgres.Open(ctx, c.DatabaseURL, c.MaxConns)
		if err != nil {
			return err
		}
		defer pool.Close()
		db = pool
	}
	var docs http.Handler
	if c.Swagger {
		docs = httpSwagger.Handler(httpSwagger.URL("/docs/doc.json"), httpSwagger.PersistAuthorization(false))
	}
	server := &http.Server{Addr: c.ListenAddr, Handler: httpapi.New(db, logger, c.RequestTimeout, docs), ReadHeaderTimeout: 5 * time.Second, ReadTimeout: 15 * time.Second, WriteTimeout: 15 * time.Second, IdleTimeout: 60 * time.Second, MaxHeaderBytes: 16 << 10}
	go func() {
		<-ctx.Done()
		shutdown, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = server.Shutdown(shutdown)
	}()
	logger.Info("api_listening", "address", c.ListenAddr, "environment", c.Environment)
	if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		return errors.New("HTTP listener failed")
	}
	return nil
}
