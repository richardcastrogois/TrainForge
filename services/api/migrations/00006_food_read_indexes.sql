-- +goose Up
CREATE INDEX food_latest_idx ON trainforge_v1.food_versions(food_id,created_at DESC,version_sha DESC);
CREATE INDEX food_batch_lookup_idx ON trainforge_v1.food_batch_versions(food_id,version_sha);

-- No Down: additive read indexes only.
