-- +goose Up
-- Editorial localization is independent of food_versions and never rewrites it.
CREATE TABLE trainforge_v1.food_name_versions (
 food_id text NOT NULL CHECK(food_id ~ '^food:[a-f0-9]{64}$'),
 food_version_sha text NOT NULL CHECK(food_version_sha ~ '^[a-f0-9]{64}$'),
 locale text NOT NULL CHECK(locale IN('pt-BR','pt-PT','en','es')),
 version_sha text NOT NULL CHECK(version_sha ~ '^[a-f0-9]{64}$'),
 name text NOT NULL CHECK(length(name) BETWEEN 1 AND 360 AND name=btrim(name)),
 aliases text[] NOT NULL CHECK(cardinality(aliases)<=16 AND array_position(aliases,NULL) IS NULL AND NOT(''=ANY(aliases))),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(food_id,food_version_sha,locale,version_sha),
 FOREIGN KEY(food_id,food_version_sha) REFERENCES trainforge_v1.food_versions(food_id,version_sha),
 CHECK(payload->>'contract' IS NOT DISTINCT FROM 'trainforge.food-names/1'),
 CHECK(payload->>'foodId' IS NOT DISTINCT FROM food_id),
 CHECK(payload->>'foodVersion' IS NOT DISTINCT FROM food_version_sha),
 CHECK(payload->>'locale' IS NOT DISTINCT FROM locale),
 CHECK(payload->>'name' IS NOT DISTINCT FROM name),
 CHECK(payload->'aliases' IS NOT DISTINCT FROM to_jsonb(aliases)),
 CHECK(payload#>>'{review,humanReviewed}' IS NOT DISTINCT FROM 'true'),
 CHECK(payload#>>'{review,scope}' IS NOT DISTINCT FROM 'food_names_and_aliases'),
 CHECK(payload#>>'{review,displayAllowed}' IS NOT DISTINCT FROM 'true'),
 CHECK(payload#>>'{review,searchAllowed}' IS NOT DISTINCT FROM 'true'),
 CHECK((payload#>>'{review,evidenceSha256}') ~ '^[a-f0-9]{64}$' AND payload#>>'{review,evidenceSha256}' IS NOT NULL),
 CHECK((payload#>>'{review,rightsEvidenceSha256}') ~ '^[a-f0-9]{64}$' AND payload#>>'{review,rightsEvidenceSha256}' IS NOT NULL)
);
CREATE INDEX food_name_latest_idx ON trainforge_v1.food_name_versions(food_id,food_version_sha,locale,created_at DESC,version_sha DESC);
CREATE TABLE trainforge_v1.food_name_withdrawals (
 food_id text NOT NULL,
 food_version_sha text NOT NULL,
 locale text NOT NULL,
 version_sha text NOT NULL,
 reason text NOT NULL CHECK(length(btrim(reason)) BETWEEN 1 AND 1000),
 withdrawn_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(food_id,food_version_sha,locale,version_sha),
 FOREIGN KEY(food_id,food_version_sha,locale,version_sha) REFERENCES trainforge_v1.food_name_versions(food_id,food_version_sha,locale,version_sha)
);
-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.preserve_food_name_history() RETURNS trigger
 LANGUAGE plpgsql SET search_path=pg_catalog AS $body$
BEGIN
 RAISE EXCEPTION 'food name history is immutable; append a new version or withdrawal';
END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.preserve_food_name_history() FROM PUBLIC;
CREATE TRIGGER immutable_food_name_versions BEFORE UPDATE OR DELETE ON trainforge_v1.food_name_versions
 FOR EACH ROW EXECUTE FUNCTION trainforge_v1.preserve_food_name_history();
CREATE TRIGGER immutable_food_name_withdrawals BEFORE UPDATE OR DELETE ON trainforge_v1.food_name_withdrawals
 FOR EACH ROW EXECUTE FUNCTION trainforge_v1.preserve_food_name_history();
-- Runtime receives SELECT only through explicit grants, never publication access.
-- No Down: restore into a checked isolated database; never erase editorial history.
