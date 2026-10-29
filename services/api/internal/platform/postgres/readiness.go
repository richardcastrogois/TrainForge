package postgres

import (
	"context"
	"errors"
	"github.com/jackc/pgx/v5/pgxpool"
)

var ErrNotReady = errors.New("runtime database prerequisites unavailable")

// Readiness checks compiled API prerequisites without reading private records.
// Missing objects, excessive privileges and database errors all fail closed.
type Readiness struct{ Pool *pgxpool.Pool }

func (p Readiness) Ping(ctx context.Context) error {
	if p.Pool == nil {
		return ErrNotReady
	}
	var ready bool
	err := p.Pool.QueryRow(ctx, readinessSQL, readTables, writeTables, functions).Scan(&ready)
	if err != nil || !ready {
		return ErrNotReady
	}
	return nil
}

var readTables = []string{
	"sources", "content_versions", "content_withdrawals", "program_sessions", "program_items",
	"food_versions", "food_import_batches", "food_batch_versions", "food_withdrawals",
	"food_name_versions", "food_name_withdrawals", "food_name_catalogs",
	"training_configuration_versions", "training_configuration_resources", "meals", "meal_items", "meal_versions",
}
var writeTables = []string{
	"users", "auth_families", "refresh_tokens", "access_tokens", "enrollments",
	"schedule_occurrences", "activity_sessions", "activity_events", "idempotency_records",
	"food_entries", "account_deletion_intents",
}
var functions = []string{
	"save_training_configuration(uuid,uuid,bytea,jsonb,uuid)",
	"erase_training_configuration(uuid,uuid,bytea,bytea)",
	"confirm_meal_group(uuid,uuid,bytea,uuid,integer,text,timestamptz,text,uuid[])",
	"delete_meal_group(uuid,uuid,bytea,uuid,integer)", "erase_meals(uuid,uuid,bytea,bytea)",
	"erase_private_foods(uuid,uuid,bytea,bytea)",
	"create_private_food(uuid,uuid,bytea,text,text,text,text,text,text,jsonb,jsonb)",
}

const readinessSQL = `WITH
ro AS MATERIALIZED (SELECT to_regclass('trainforge_v1.'||name) AS id FROM unnest($1::text[]) AS name),
rw AS MATERIALIZED (SELECT to_regclass('trainforge_v1.'||name) AS id FROM unnest($2::text[]) AS name),
fn AS MATERIALIZED (SELECT to_regprocedure('trainforge_v1.'||name) AS id FROM unnest($3::text[]) AS name),
ledger AS (SELECT to_regclass('trainforge_v1.account_erasures') AS id)
SELECT coalesce(
 (SELECT NOT (rolsuper OR rolcreatedb OR rolcreaterole OR rolreplication OR rolbypassrls) FROM pg_roles WHERE rolname=current_user)
 AND has_schema_privilege(current_user,'trainforge_v1','USAGE')
 AND (SELECT bool_and(id IS NOT NULL AND has_table_privilege(current_user,id,'SELECT')
  AND NOT has_table_privilege(current_user,id,'INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')) FROM ro)
 AND (SELECT bool_and(id IS NOT NULL AND has_table_privilege(current_user,id,'SELECT')
  AND has_table_privilege(current_user,id,'INSERT') AND has_table_privilege(current_user,id,'UPDATE')
  AND has_table_privilege(current_user,id,'DELETE')
  AND NOT has_table_privilege(current_user,id,'TRUNCATE,REFERENCES,TRIGGER')) FROM rw)
 AND (SELECT bool_and(id IS NOT NULL AND has_function_privilege(current_user,id,'EXECUTE')) FROM fn)
 AND (SELECT id IS NOT NULL AND has_table_privilege(current_user,id,'INSERT')
  AND has_column_privilege(current_user,id,'erased_at','SELECT')
  AND NOT has_table_privilege(current_user,id,'UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') FROM ledger), false)`
