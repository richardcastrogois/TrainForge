-- +goose Up
CREATE SCHEMA trainforge_v1;

CREATE TABLE trainforge_v1.users (
 id uuid PRIMARY KEY,
 provider text NOT NULL,
 issuer text NOT NULL,
 subject text NOT NULL,
 display_name text,
 email text,
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(provider,issuer,subject)
);
CREATE TABLE trainforge_v1.auth_families (
 id uuid PRIMARY KEY,
 user_id uuid NOT NULL REFERENCES trainforge_v1.users(id),
 revoked_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(id,user_id)
);
CREATE TABLE trainforge_v1.refresh_tokens (
 token_hash bytea PRIMARY KEY CHECK(octet_length(token_hash)=32),
 family_id uuid NOT NULL REFERENCES trainforge_v1.auth_families(id),
 expires_at timestamptz NOT NULL,
 consumed_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX refresh_family_idx ON trainforge_v1.refresh_tokens(family_id);
CREATE TABLE trainforge_v1.sources (
 id text PRIMARY KEY,
 name text NOT NULL,
 publisher text,
 urls jsonb NOT NULL CHECK(jsonb_typeof(urls)='array'),
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE trainforge_v1.content_versions (
 asset_id text NOT NULL,
 version_sha text NOT NULL CHECK(version_sha ~ '^[a-f0-9]{64}$'),
 kind text NOT NULL CHECK(kind IN ('movement','instruction','media','program','collection')),
 source_id text NOT NULL REFERENCES trainforge_v1.sources(id),
 title text,
 locale text,
 source_published_version text,
 allowed_operations text[] NOT NULL DEFAULT '{}',
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 created_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(asset_id,version_sha),
 CHECK(allowed_operations <@ ARRAY['catalog_metadata','instruction_text','media_display','guided_practice','export_dataset']::text[])
);
CREATE INDEX content_catalog_idx ON trainforge_v1.content_versions(kind,asset_id,version_sha);
CREATE INDEX content_source_idx ON trainforge_v1.content_versions(source_id);
CREATE TABLE trainforge_v1.content_withdrawals (
 asset_id text NOT NULL,
 version_sha text NOT NULL,
 reason text NOT NULL,
 withdrawn_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(asset_id,version_sha),
 FOREIGN KEY(asset_id,version_sha) REFERENCES trainforge_v1.content_versions(asset_id,version_sha)
);
CREATE TABLE trainforge_v1.import_batches (
 artifact_sha text PRIMARY KEY CHECK(artifact_sha ~ '^[a-f0-9]{64}$'),
 bundle_id text NOT NULL,
 manifest_sha text NOT NULL,
 imported_assets integer NOT NULL CHECK(imported_assets>=0),
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE trainforge_v1.batch_content (
 artifact_sha text NOT NULL REFERENCES trainforge_v1.import_batches(artifact_sha),
 asset_id text NOT NULL,
 version_sha text NOT NULL,
 PRIMARY KEY(artifact_sha,asset_id,version_sha),
 FOREIGN KEY(asset_id,version_sha) REFERENCES trainforge_v1.content_versions(asset_id,version_sha)
);
-- Editorial sequence and dose are versioned; an enrollment never rewrites them.
CREATE TABLE trainforge_v1.program_items (
 program_id text NOT NULL,
 program_sha text NOT NULL,
 session_key text NOT NULL,
 position integer NOT NULL CHECK(position>=0),
 movement_id text NOT NULL,
 movement_sha text NOT NULL,
 source_dose jsonb,
 PRIMARY KEY(program_id,program_sha,session_key,position),
 FOREIGN KEY(program_id,program_sha) REFERENCES trainforge_v1.content_versions(asset_id,version_sha),
 FOREIGN KEY(movement_id,movement_sha) REFERENCES trainforge_v1.content_versions(asset_id,version_sha)
);
CREATE TABLE trainforge_v1.enrollments (
 id uuid PRIMARY KEY,
 user_id uuid NOT NULL REFERENCES trainforge_v1.users(id),
 program_id text NOT NULL,
 program_sha text NOT NULL,
 status text NOT NULL CHECK(status IN ('active','archived','withdrawn')),
 options jsonb NOT NULL DEFAULT '{}',
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(id,user_id),
 FOREIGN KEY(program_id,program_sha) REFERENCES trainforge_v1.content_versions(asset_id,version_sha)
);
CREATE INDEX enrollment_owner_idx ON trainforge_v1.enrollments(user_id,created_at,id);
CREATE TABLE trainforge_v1.schedule_occurrences (
 id uuid PRIMARY KEY,
 user_id uuid NOT NULL,
 enrollment_id uuid NOT NULL,
 source_session_key text NOT NULL,
 planned_for timestamptz NOT NULL,
 timezone text NOT NULL CHECK(length(timezone)>0),
 UNIQUE(id,user_id),
 UNIQUE(enrollment_id,planned_for,source_session_key),
 FOREIGN KEY(enrollment_id,user_id) REFERENCES trainforge_v1.enrollments(id,user_id)
);
CREATE TABLE trainforge_v1.activity_sessions (
 id uuid PRIMARY KEY,
 occurrence_id uuid NOT NULL,
 user_id uuid NOT NULL,
 state text NOT NULL CHECK(state IN ('started','paused','partial','completed','cancelled')),
 started_at timestamptz NOT NULL,
 ended_at timestamptz,
 completed_at timestamptz,
 UNIQUE(id,user_id),
 FOREIGN KEY(occurrence_id,user_id) REFERENCES trainforge_v1.schedule_occurrences(id,user_id),
 CHECK(completed_at IS NULL OR completed_at>=started_at),
 CHECK(ended_at IS NULL OR ended_at>=started_at),
 CHECK((state='completed')=(completed_at IS NOT NULL)),
 CHECK((state IN ('partial','completed','cancelled'))=(ended_at IS NOT NULL))
);
CREATE UNIQUE INDEX one_open_session_idx ON trainforge_v1.activity_sessions(occurrence_id) WHERE state IN ('started','paused');
CREATE INDEX session_owner_idx ON trainforge_v1.activity_sessions(user_id,started_at,id);
CREATE TABLE trainforge_v1.activity_events (
 id uuid PRIMARY KEY,
 session_id uuid NOT NULL,
 user_id uuid NOT NULL,
 event_type text NOT NULL,
 occurred_at timestamptz NOT NULL,
 payload jsonb NOT NULL,
 FOREIGN KEY(session_id,user_id) REFERENCES trainforge_v1.activity_sessions(id,user_id)
);
CREATE INDEX event_session_idx ON trainforge_v1.activity_events(session_id,occurred_at,id);
CREATE TABLE trainforge_v1.idempotency_records (
 user_id uuid NOT NULL REFERENCES trainforge_v1.users(id),
 operation text NOT NULL,
 key_hash bytea NOT NULL CHECK(octet_length(key_hash)=32),
 request_hash bytea NOT NULL CHECK(octet_length(request_hash)=32),
 response_status integer NOT NULL CHECK(response_status BETWEEN 200 AND 599),
 response_body jsonb,
 expires_at timestamptz NOT NULL,
 PRIMARY KEY(user_id,operation,key_hash)
);
CREATE INDEX idempotency_expiry_idx ON trainforge_v1.idempotency_records(expires_at);
CREATE TABLE trainforge_v1.food_versions (
 food_id text NOT NULL,
 version_sha text NOT NULL CHECK(version_sha ~ '^[a-f0-9]{64}$'),
 source_id text,
 source_food_id text,
 source_row_key text,
 owner_id uuid REFERENCES trainforge_v1.users(id),
 name_original text NOT NULL,
 name_pt text,
 preparation text,
 basis_quantity numeric CHECK(basis_quantity>0),
 basis_unit text CHECK(basis_unit IN ('g','ml')),
 nutrients jsonb NOT NULL CHECK(jsonb_typeof(nutrients)='array'),
 provenance jsonb NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(food_id,version_sha),
 CHECK((source_id IS NOT NULL AND owner_id IS NULL) OR (source_id IS NULL AND owner_id IS NOT NULL)),
 CHECK((basis_quantity IS NULL)=(basis_unit IS NULL))
);
CREATE INDEX food_owner_idx ON trainforge_v1.food_versions(owner_id,food_id);
CREATE INDEX food_name_idx ON trainforge_v1.food_versions(lower(name_original) text_pattern_ops);
CREATE TABLE trainforge_v1.food_entries (
 id uuid PRIMARY KEY,
 user_id uuid NOT NULL REFERENCES trainforge_v1.users(id),
 food_id text NOT NULL,
 food_sha text NOT NULL,
 quantity numeric NOT NULL CHECK(quantity>0),
 unit text NOT NULL CHECK(unit IN ('g','ml')),
 occurred_at timestamptz NOT NULL,
 timezone text NOT NULL CHECK(length(timezone)>0),
 calculation jsonb NOT NULL,
 deleted_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(),
 FOREIGN KEY(food_id,food_sha) REFERENCES trainforge_v1.food_versions(food_id,version_sha)
);
CREATE INDEX food_entry_owner_idx ON trainforge_v1.food_entries(user_id,occurred_at,id);

-- No Down: recovery is restore into a separate database, never an automatic reset.
