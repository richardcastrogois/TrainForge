package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
	"trainforge.local/api/internal/app"
	"trainforge.local/api/internal/platform/config"
	"trainforge.local/api/internal/platform/httpapi"
)

// @title TrainForge API
// @version 0.11.0
// @description Google sessions, privacy, reviewed references, private food declarations, recorded consumption, atomic meals and durable offline nutrition synchronization. No executable training content or prescribed diets.
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
	handler, cleanup, err := app.New(ctx, c, logger)
	if err != nil {
		return err
	}
	defer cleanup()
	server := &http.Server{Addr: c.ListenAddr, Handler: handler, ReadHeaderTimeout: 5 * time.Second, ReadTimeout: 15 * time.Second, WriteTimeout: 15 * time.Second, IdleTimeout: 60 * time.Second, MaxHeaderBytes: 16 << 10}
	go func() {
		<-ctx.Done()
		shutdown, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = server.Shutdown(shutdown)
	}()
	logger.Info("api_listening", "address", c.ListenAddr, "environment", c.Environment)
	if err := httpapi.Serve(server, 1024); err != nil && !errors.Is(err, http.ErrServerClosed) {
		return errors.New("HTTP listener failed")
	}
	return nil
}
