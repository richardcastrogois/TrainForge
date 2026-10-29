// Command catalog serves a loopback-only editorial authority with its own database.
package main

import (
	"context"
	"log/slog"
	"os"
	"os/signal"
	"syscall"
	"trainforge.local/api/internal/catalogruntime"
)

// @title TrainForge Catalog M1
// @version 0.2.0
// @description Versioned movement/program/collection metadata with its own database. Local routing is explicit; private routes and training execution are excluded.
// @BasePath /
// @schemes http
func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	c, err := catalogruntime.Load(os.Getenv)
	if err != nil {
		logger.Error("catalog_configuration_invalid")
		os.Exit(1)
	}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	if err := catalogruntime.Run(ctx, c, logger); err != nil {
		logger.Error("catalog_stopped")
		os.Exit(1)
	}
}
