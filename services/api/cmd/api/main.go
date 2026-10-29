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
	"trainforge.local/api/internal/auth"
	"trainforge.local/api/internal/catalog"
	"trainforge.local/api/internal/catalogbridge"
	"trainforge.local/api/internal/nutrition"
	"trainforge.local/api/internal/platform/config"
	"trainforge.local/api/internal/platform/httpapi"
	"trainforge.local/api/internal/platform/postgres"
	"trainforge.local/api/internal/privacy"
	_ "trainforge.local/api/internal/swaggerdocs"
	"trainforge.local/api/internal/trainingconfig"
)

// @title TrainForge API
// @version 0.9.0
// @description Google sessions, privacy, reviewed movement and food references, private food declarations, explicitly recorded consumption and atomic meal grouping. Meal routes require schema13. No executable training content or prescribed diets.
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
		db = postgres.Readiness{Pool: pool}
	}
	var docs http.Handler
	if c.Swagger {
		docs = httpSwagger.Handler(httpSwagger.URL("/docs/doc.json"), httpSwagger.PersistAuthorization(false))
	}
	verifier, err := auth.NewGoogle(c.GoogleAudience)
	if err != nil {
		return err
	}
	var repository auth.Repository
	if pool != nil {
		repository = auth.Postgres{Pool: pool}
	}
	network := httpapi.Network{RequireTLS: c.Environment == "production", TrustedProxies: c.TrustedProxies}
	authentication := &auth.Handler{Service: auth.Service{Verifier: verifier, Repository: repository}, Network: &network}
	var catalogRepository catalog.CatalogRepository
	if pool != nil {
		catalogRepository = catalog.CatalogPostgres{Pool: pool}
	}
	catalogHTTP := catalog.CatalogHandler{Reader: catalog.Reader{Repository: catalogRepository}}
	var foodRepository nutrition.FoodRepository
	if pool != nil {
		foodRepository = nutrition.FoodPostgres{Pool: pool}
	}
	foodHTTP := nutrition.FoodHandler{Reader: nutrition.FoodReader{Repository: foodRepository}}
	var privacyRepository privacy.Repository
	if pool != nil {
		privacyRepository = privacy.Postgres{Pool: pool}
	}
	privacyHTTP := &privacy.Handler{Service: privacy.Service{Repository: privacyRepository}, Authorize: authentication.Service.Authorize}
	nutritionHTTP := &nutrition.EntryHandler{Store: nutrition.NutritionStore{Pool: pool}, Names: nutrition.FoodPostgres{Pool: pool}, Authorize: authentication.Service.Authorize}
	trainingStore := trainingconfig.Postgres{Pool: pool}
	catalogRoutes := catalogHTTP.Register
	if c.CatalogURL != "" {
		bridge, e := catalogbridge.New(c.CatalogURL)
		if e != nil {
			return e
		}
		catalogRoutes = bridge.Register
		if c.CatalogReadMode == "local-verified" {
			catalogRoutes = bridge.LocalVerified(pool, catalogHTTP.Register)
		}
		trainingStore.CatalogGuard = bridge.CheckProjection
		db = catalogbridge.Readiness{Core: db, Catalog: bridge, Pool: pool}
	}
	trainingHTTP := &trainingconfig.Handler{Service: trainingconfig.Service{Repository: trainingStore}, ResourceStore: trainingStore, Authorize: authentication.Service.Authorize}
	server := &http.Server{Addr: c.ListenAddr, Handler: httpapi.NewWithNetwork(db, logger, c.RequestTimeout, docs, network, authentication.Register, catalogRoutes, foodHTTP.Register, privacyHTTP.Register, nutritionHTTP.Register, trainingHTTP.Register), ReadHeaderTimeout: 5 * time.Second, ReadTimeout: 15 * time.Second, WriteTimeout: 15 * time.Second, IdleTimeout: 60 * time.Second, MaxHeaderBytes: 16 << 10}
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
