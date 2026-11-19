package postgres

import (
	"strings"

	"github.com/jackc/pgx/v5"
)

// HostedDatabase is the single managed production database outside the owned
// local cluster. Writers reach it only when the operator opts in explicitly
// (TF_HOSTED_TARGET=neon) and the DSN names that exact TLS-protected target.
const HostedDatabase = "trainforge_v1_prod"

// HostedRole owns the hosted schema; there is no separate migrator role there.
const HostedRole = "trainforge_owner"

func HostedTarget(cfg *pgx.ConnConfig, getenv func(string) string) bool {
	if cfg == nil || getenv("TF_HOSTED_TARGET") != "neon" || cfg.TLSConfig == nil {
		return false
	}
	if cfg.Database != HostedDatabase || cfg.User != HostedRole || !strings.HasSuffix(cfg.Host, ".neon.tech") {
		return false
	}
	for _, fallback := range cfg.Fallbacks {
		if fallback.TLSConfig == nil || !strings.HasSuffix(fallback.Host, ".neon.tech") {
			return false
		}
	}
	return true
}
