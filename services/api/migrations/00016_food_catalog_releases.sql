-- +goose Up
-- Chunked ingestion keeps unpublished rows invisible until an entire signed
-- artifact has passed source checksums, row counts and immutable-version checks.
CREATE TABLE trainforge_v1.food_catalog_releases (
 artifact_sha text PRIMARY KEY REFERENCES trainforge_v1.food_import_batches(artifact_sha),
 version text NOT NULL CHECK(version~'^[a-f0-9]{64}$'),
 manifest_sha text NOT NULL CHECK(manifest_sha~'^[a-f0-9]{64}$'),
 status text NOT NULL CHECK(status IN('staging','active')),
 expected_rows bigint NOT NULL CHECK(expected_rows>0),
 staged_rows bigint NOT NULL DEFAULT 0 CHECK(staged_rows>=0),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 activated_at timestamptz
);
CREATE TABLE trainforge_v1.food_catalog_import_progress (
 artifact_sha text NOT NULL REFERENCES trainforge_v1.food_catalog_releases(artifact_sha),
 source_id text NOT NULL,
 expected_rows bigint NOT NULL CHECK(expected_rows>0),
 imported_rows bigint NOT NULL DEFAULT 0 CHECK(imported_rows>=0 AND imported_rows<=expected_rows),
 complete boolean NOT NULL DEFAULT false,
 PRIMARY KEY(artifact_sha,source_id)
);
CREATE TABLE trainforge_v1.food_catalog_annotations (
 artifact_sha text NOT NULL REFERENCES trainforge_v1.food_catalog_releases(artifact_sha),
 food_id text NOT NULL,
 version_sha text NOT NULL,
 metadata jsonb NOT NULL CHECK(jsonb_typeof(metadata)='object'),
 PRIMARY KEY(artifact_sha,food_id,version_sha),
 FOREIGN KEY(food_id,version_sha) REFERENCES trainforge_v1.food_versions(food_id,version_sha)
);
CREATE INDEX food_catalog_annotation_identity ON trainforge_v1.food_catalog_annotations(food_id,version_sha);
-- Existing source rows/snapshots remain immutable. Enrichment is separate and
-- only active release annotations can affect new calculations or public reads.
