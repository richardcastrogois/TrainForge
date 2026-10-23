// privacy-restore sanitizes only a separately restored local DB with the current ledger.
package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/jackc/pgx/v5/pgxpool"
	"os"
	"regexp"
	"time"
	"trainforge.local/api/internal/privacy"
)

func pool(ctx context.Context, key string, source bool) (*pgxpool.Pool, error) {
	cfg, err := pgxpool.ParseConfig(os.Getenv(key))
	if err != nil {
		return nil, errors.New("restore configuration unavailable")
	}
	db := cfg.ConnConfig.Database
	valid := regexp.MustCompile("^trainforge_v1_privacy_restore_[a-f0-9]{12}$").MatchString(db)
	if source {
		valid = db == "trainforge_v1_dev" || regexp.MustCompile("^trainforge_v1_privacy_test_[a-f0-9]{12}$").MatchString(db)
	}
	if !valid || cfg.ConnConfig.Host != "127.0.0.1" || cfg.ConnConfig.Port != 15432 {
		return nil, errors.New("restore boundary refused")
	}
	cfg.MaxConns = 2
	return pgxpool.NewWithConfig(ctx, cfg)
}
func run() error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()
	source, err := pool(ctx, "TF_PRIVACY_LEDGER_SOURCE_DATABASE_URL", true)
	if err != nil {
		return err
	}
	defer source.Close()
	target, err := pool(ctx, "TF_PRIVACY_RESTORE_DATABASE_URL", false)
	if err != nil {
		return err
	}
	defer target.Close()
	var ledgerCount int
	var ledgerStamp string
	if source.QueryRow(ctx, "SELECT count(*),coalesce(max(erased_at)::text,'') FROM trainforge_v1.account_erasures").Scan(&ledgerCount, &ledgerStamp) != nil {
		return errors.New("current erasure ledger unavailable")
	}
	after := ""
	processed := 0
	for {
		rows, err := source.Query(ctx, "SELECT user_id::text,erased_at FROM trainforge_v1.account_erasures WHERE $1='' OR user_id::text>$1 ORDER BY user_id::text LIMIT 500", after)
		if err != nil {
			return errors.New("current erasure ledger unavailable; restore must remain offline")
		}
		records := []privacy.Erasure{}
		for rows.Next() {
			var record privacy.Erasure
			if rows.Scan(&record.UserID, &record.ErasedAt) != nil {
				rows.Close()
				return errors.New("invalid erasure record")
			}
			records = append(records, record)
		}
		err = rows.Err()
		rows.Close()
		if err != nil {
			return errors.New("erasure ledger read failed")
		}
		if len(records) == 0 {
			break
		}
		count, err := privacy.ApplyErasures(ctx, target, records)
		if err != nil {
			return errors.New("restore sanitization incomplete; keep target offline")
		}
		processed += count
		after = records[len(records)-1].UserID
	}
	var finalCount int
	var finalStamp string
	if source.QueryRow(ctx, "SELECT count(*),coalesce(max(erased_at)::text,'') FROM trainforge_v1.account_erasures").Scan(&finalCount, &finalStamp) != nil || finalCount != ledgerCount || finalStamp != ledgerStamp || processed != ledgerCount {
		return errors.New("erasure ledger changed; rerun with source erasures paused before promotion")
	}
	return json.NewEncoder(os.Stdout).Encode(map[string]any{"scope": "separate-local-restore-erasure-gate", "processedErasureRecords": processed, "sourceModified": false, "targetPromoted": false})
}
func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err.Error())
		os.Exit(1)
	}
}
