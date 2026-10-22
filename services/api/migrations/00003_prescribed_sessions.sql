-- +goose Up
-- Session keys belong to a specific immutable program version, never to a user.
CREATE TABLE trainforge_v1.program_sessions (
 program_id text NOT NULL,
 program_sha text NOT NULL,
 program_kind text NOT NULL DEFAULT 'program' CHECK(program_kind='program'),
 session_key text NOT NULL,
 source_metadata jsonb NOT NULL DEFAULT '{}' CHECK(jsonb_typeof(source_metadata)='object'),
 PRIMARY KEY(program_id,program_sha,session_key),
 FOREIGN KEY(program_id,program_sha,program_kind) REFERENCES trainforge_v1.content_versions(asset_id,version_sha,kind)
);
ALTER TABLE trainforge_v1.program_items
 ADD CONSTRAINT program_item_session_fk FOREIGN KEY(program_id,program_sha,session_key)
 REFERENCES trainforge_v1.program_sessions(program_id,program_sha,session_key),
 ADD CONSTRAINT source_dose_object CHECK(source_dose IS NULL OR jsonb_typeof(source_dose)='object');
ALTER TABLE trainforge_v1.enrollments ADD CONSTRAINT enrollment_program_owner_key UNIQUE(id,user_id,program_id,program_sha);
-- No occurrences have been imported in this new isolated schema. Adding these
-- columns fails rather than inventing a prescription if unexpected rows exist.
ALTER TABLE trainforge_v1.schedule_occurrences
 ADD COLUMN program_id text NOT NULL,
 ADD COLUMN program_sha text NOT NULL,
 ADD CONSTRAINT occurrence_program_owner_fk FOREIGN KEY(enrollment_id,user_id,program_id,program_sha)
 REFERENCES trainforge_v1.enrollments(id,user_id,program_id,program_sha),
 ADD CONSTRAINT occurrence_prescription_fk FOREIGN KEY(program_id,program_sha,source_session_key)
 REFERENCES trainforge_v1.program_sessions(program_id,program_sha,session_key);
