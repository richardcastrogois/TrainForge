-- +goose Up
CREATE TABLE trainforge_v1.catalog_releases(
 revision bigint PRIMARY KEY CHECK(revision>0 AND revision<=2147483647),
 digest text NOT NULL CHECK(digest ~ '^[a-f0-9]{64}$'),
 previous_digest text NOT NULL CHECK(previous_digest='' OR previous_digest ~ '^[a-f0-9]{64}$'),
 package_digest text NOT NULL CHECK(package_digest=digest),
 published_at timestamptz NOT NULL DEFAULT clock_timestamp());
-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.preserve_catalog_release() RETURNS trigger
 LANGUAGE plpgsql SET search_path=pg_catalog AS $body$
BEGIN RAISE EXCEPTION 'catalog release is immutable'; END;
$body$;
-- +goose StatementEnd
CREATE TRIGGER immutable_catalog_release BEFORE UPDATE OR DELETE ON trainforge_v1.catalog_releases
 FOR EACH ROW EXECUTE FUNCTION trainforge_v1.preserve_catalog_release();
REVOKE ALL ON FUNCTION trainforge_v1.preserve_catalog_release() FROM PUBLIC;
REVOKE ALL ON trainforge_v1.catalog_releases FROM PUBLIC;
GRANT SELECT ON trainforge_v1.catalog_releases TO trainforge_catalog_reader;

CREATE TRIGGER immutable_catalog_source BEFORE UPDATE OR DELETE ON trainforge_v1.sources
 FOR EACH ROW EXECUTE FUNCTION trainforge_v1.preserve_catalog_release();
CREATE TRIGGER immutable_catalog_version BEFORE UPDATE OR DELETE ON trainforge_v1.content_versions
 FOR EACH ROW EXECUTE FUNCTION trainforge_v1.preserve_catalog_release();
CREATE TRIGGER immutable_catalog_withdrawal BEFORE UPDATE OR DELETE ON trainforge_v1.content_withdrawals
 FOR EACH ROW EXECUTE FUNCTION trainforge_v1.preserve_catalog_release();
