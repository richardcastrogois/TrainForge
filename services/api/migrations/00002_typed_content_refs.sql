-- +goose Up
-- Keep the already applied migration immutable: strengthen its typed references forward.
ALTER TABLE trainforge_v1.content_versions ADD CONSTRAINT content_version_kind_key UNIQUE(asset_id,version_sha,kind);
ALTER TABLE trainforge_v1.program_items ADD COLUMN program_kind text NOT NULL DEFAULT 'program' CHECK(program_kind='program');
ALTER TABLE trainforge_v1.program_items ADD COLUMN movement_kind text NOT NULL DEFAULT 'movement' CHECK(movement_kind='movement');
ALTER TABLE trainforge_v1.program_items ADD CONSTRAINT program_item_program_kind_fk FOREIGN KEY(program_id,program_sha,program_kind) REFERENCES trainforge_v1.content_versions(asset_id,version_sha,kind);
ALTER TABLE trainforge_v1.program_items ADD CONSTRAINT program_item_movement_kind_fk FOREIGN KEY(movement_id,movement_sha,movement_kind) REFERENCES trainforge_v1.content_versions(asset_id,version_sha,kind);
ALTER TABLE trainforge_v1.enrollments ADD COLUMN program_kind text NOT NULL DEFAULT 'program' CHECK(program_kind='program');
ALTER TABLE trainforge_v1.enrollments ADD CONSTRAINT enrollment_program_kind_fk FOREIGN KEY(program_id,program_sha,program_kind) REFERENCES trainforge_v1.content_versions(asset_id,version_sha,kind);
ALTER TABLE trainforge_v1.food_versions ADD CONSTRAINT food_source_fk FOREIGN KEY(source_id) REFERENCES trainforge_v1.sources(id);
