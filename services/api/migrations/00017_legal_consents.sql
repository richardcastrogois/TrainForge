-- +goose Up
-- Append-only record of what each account accepted: document, version and the
-- SHA-256 of the exact text shown. A new row is written per decision; history is
-- kept while the account exists and removed with it (ON DELETE CASCADE).
CREATE TABLE trainforge_v1.legal_consents (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 user_id uuid NOT NULL REFERENCES trainforge_v1.users(id) ON DELETE CASCADE,
 document text NOT NULL CHECK (document IN ('terms','privacy','health_data')),
 version text NOT NULL CHECK (version ~ '^[0-9]{1,3}[.][0-9]{1,3}$'),
 document_sha text CHECK (document_sha IS NULL OR document_sha ~ '^[a-f0-9]{64}$'),
 decision text NOT NULL CHECK (decision IN ('accepted','granted','revoked')),
 app_version text NOT NULL CHECK (char_length(app_version) BETWEEN 1 AND 32),
 locale text NOT NULL CHECK (char_length(locale) BETWEEN 2 AND 16),
 client_recorded_at timestamptz NOT NULL,
 recorded_at timestamptz NOT NULL DEFAULT now(),
 CHECK ((document = 'health_data') = (decision IN ('granted','revoked'))),
 CHECK ((document = 'health_data') = (document_sha IS NULL))
);
CREATE INDEX legal_consents_user_document ON trainforge_v1.legal_consents(user_id, document, recorded_at DESC);
-- Runtime gets SELECT/INSERT only through explicit grants (tools/db_permissions.py).
