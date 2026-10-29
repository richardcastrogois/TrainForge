// Command catalog is the isolated, loopback-only M1 proof. No live API cutover.
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
// @version 0.1.0
// @description Isolated fixture/CI public read projection. No live editorial ownership, private routes, auth, nutrition or training execution. Not a production cutover.
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
