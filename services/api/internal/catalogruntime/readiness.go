package catalogruntime

import (
	"context"
	"errors"
	"github.com/jackc/pgx/v5/pgxpool"
	"trainforge.local/api/internal/catalogtarget"
)

type Readiness struct{ Pool *pgxpool.Pool }

var ErrNotReady = errors.New("catalog prerequisites unavailable")

func (r Readiness) Ping(ctx context.Context) error {
	if catalogtarget.ActualRole(ctx, r.Pool, catalogtarget.ReaderRole) != nil {
		return ErrNotReady
	}
	var ok bool
	err := r.Pool.QueryRow(ctx, `SELECT
 NOT has_database_privilege(current_user,current_database(),'CREATE')
 AND has_schema_privilege(current_user,'trainforge_v1','USAGE')
 AND NOT has_schema_privilege(current_user,'trainforge_v1','CREATE')
 AND NOT has_schema_privilege(current_user,'public','CREATE')
 AND (SELECT count(*) FROM information_schema.tables WHERE table_schema='trainforge_v1' AND table_type='BASE TABLE')=4
 AND NOT EXISTS(SELECT 1 FROM unnest(ARRAY['sources','content_versions','content_withdrawals','catalog_releases']) t(name)
 WHERE to_regclass('trainforge_v1.'||name) IS NULL OR NOT has_table_privilege(current_user,'trainforge_v1.'||name,'SELECT')
 OR has_table_privilege(current_user,'trainforge_v1.'||name,'INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
 OR has_any_column_privilege(current_user,'trainforge_v1.'||name,'INSERT,UPDATE,REFERENCES'))
 AND to_regclass('public.trainforge_catalog_schema_version') IS NOT NULL
 AND NOT has_table_privilege(current_user,'public.trainforge_catalog_schema_version','SELECT,INSERT,UPDATE,DELETE,TRUNCATE')`).Scan(&ok)
	if err != nil || !ok {
		return ErrNotReady
	}
	// The planner verifies all required columns and permissions without reading rows.
	_, err = r.Pool.Exec(ctx, `SELECT v.asset_id,v.version_sha,v.kind,v.title,v.locale,v.source_published_version,v.allowed_operations,v.payload,v.created_at,s.id,s.name,s.publisher,s.urls,w.asset_id,w.version_sha
 FROM trainforge_v1.content_versions v JOIN trainforge_v1.sources s ON false LEFT JOIN trainforge_v1.content_withdrawals w ON false WHERE false`)
	if err != nil {
		return ErrNotReady
	}
	return nil
}
