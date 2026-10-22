-- +goose Up
ALTER TABLE trainforge_v1.food_versions
 ADD COLUMN source_published_version text,
 ADD COLUMN name_locale text,
 ADD COLUMN allowed_operations text[] NOT NULL DEFAULT '{}',
 ADD CONSTRAINT food_allowed_operations CHECK(allowed_operations <@ ARRAY['food_catalog','food_composition','food_quantity_scale']::text[]),
 ADD CONSTRAINT food_provenance_object CHECK(jsonb_typeof(provenance)='object');

CREATE TABLE trainforge_v1.food_import_batches (
 artifact_sha text PRIMARY KEY CHECK(artifact_sha ~ '^[a-f0-9]{64}$'),
 bundle_id text NOT NULL,
 manifest_sha text NOT NULL CHECK(manifest_sha ~ '^[a-f0-9]{64}$'),
 review_sha text NOT NULL CHECK(review_sha ~ '^[a-f0-9]{64}$'),
 imported_foods integer NOT NULL CHECK(imported_foods>=0),
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE trainforge_v1.food_batch_versions (
 artifact_sha text NOT NULL REFERENCES trainforge_v1.food_import_batches(artifact_sha),
 food_id text NOT NULL,
 version_sha text NOT NULL,
 PRIMARY KEY(artifact_sha,food_id,version_sha),
 FOREIGN KEY(food_id,version_sha) REFERENCES trainforge_v1.food_versions(food_id,version_sha)
);
CREATE TABLE trainforge_v1.food_withdrawals (
 food_id text NOT NULL,
 version_sha text NOT NULL,
 reason text NOT NULL,
 withdrawn_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(food_id,version_sha),
 FOREIGN KEY(food_id,version_sha) REFERENCES trainforge_v1.food_versions(food_id,version_sha)
);

-- Editorial food tables remain read-only to runtime; private food writes are future V1-020 work.
-- No Down: preserve source versions and recover through a checked backup/restore.
