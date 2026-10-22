-- +goose Up
-- Opaque tokens contain no personal data. Store only SHA-256 digests.
CREATE TABLE trainforge_v1.access_tokens (
 token_hash bytea PRIMARY KEY CHECK(octet_length(token_hash)=32),
 family_id uuid NOT NULL REFERENCES trainforge_v1.auth_families(id),
 expires_at timestamptz NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX access_family_idx ON trainforge_v1.access_tokens(family_id);
CREATE INDEX access_expiry_idx ON trainforge_v1.access_tokens(expires_at);
-- No Down: recover into a separate database.
