-- +goose Up
-- This schema name is retained only to reuse the existing SQL adapter in a
-- different database. No private/API tables or production data are copied.
CREATE SCHEMA trainforge_v1;
REVOKE ALL ON SCHEMA trainforge_v1 FROM PUBLIC;
CREATE TABLE trainforge_v1.sources(
 id text PRIMARY KEY,name text NOT NULL,publisher text,
 urls jsonb NOT NULL CHECK(jsonb_typeof(urls)='array'),created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE trainforge_v1.content_versions(
 asset_id text NOT NULL,version_sha text NOT NULL CHECK(version_sha ~ '^[a-f0-9]{64}$'),
 kind text NOT NULL CHECK(kind IN('movement','program','collection')),
 source_id text NOT NULL REFERENCES trainforge_v1.sources(id),title text,locale text,source_published_version text,
 allowed_operations text[] NOT NULL DEFAULT '{}',payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 created_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(asset_id,version_sha),
 CHECK(allowed_operations <@ ARRAY['catalog_metadata','instruction_text','media_display','guided_practice','export_dataset']::text[]));
CREATE INDEX catalog_latest_idx ON trainforge_v1.content_versions(asset_id,created_at DESC,version_sha DESC);
CREATE TABLE trainforge_v1.content_withdrawals(
 asset_id text NOT NULL,version_sha text NOT NULL,reason text NOT NULL,withdrawn_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(asset_id,version_sha),FOREIGN KEY(asset_id,version_sha) REFERENCES trainforge_v1.content_versions(asset_id,version_sha));
REVOKE ALL ON ALL TABLES IN SCHEMA trainforge_v1 FROM PUBLIC;
GRANT USAGE ON SCHEMA trainforge_v1 TO trainforge_catalog_reader;
GRANT SELECT ON trainforge_v1.sources,trainforge_v1.content_versions,trainforge_v1.content_withdrawals TO trainforge_catalog_reader;
