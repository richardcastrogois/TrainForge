-- +goose Up
-- Optional declared preference for combining activities in the week (C35). Absent means "decide later".
-- Older confirmed versions stay valid because the key is optional; no row is rewritten.
-- The original validator keeps its body under a new name; the column check and the save routine
-- resolve the public name, which now accepts only the five declared mixes.
ALTER FUNCTION trainforge_v1.valid_training_configuration(jsonb) RENAME TO valid_training_configuration_base;
-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.valid_training_configuration(c jsonb) RETURNS boolean
 LANGUAGE plpgsql STABLE SET search_path=pg_catalog AS $body$
BEGIN
 IF jsonb_typeof(c) IS DISTINCT FROM 'object' THEN RETURN false; END IF;
 IF c ? 'weeklyMix' THEN
  IF jsonb_typeof(c->'weeklyMix') IS DISTINCT FROM 'string'
  OR c->>'weeklyMix' NOT IN('strength_only','strength_walking','strength_mind','complete','balance_mobility') THEN RETURN false; END IF;
  RETURN trainforge_v1.valid_training_configuration_base(c-'weeklyMix');
 END IF;
 RETURN trainforge_v1.valid_training_configuration_base(c);
END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.valid_training_configuration(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION trainforge_v1.valid_training_configuration_base(jsonb) FROM PUBLIC;
ALTER TABLE trainforge_v1.training_configuration_versions
 DROP CONSTRAINT training_configuration_versions_configuration_check,
 ADD CONSTRAINT training_configuration_versions_configuration_check CHECK(trainforge_v1.valid_training_configuration(configuration));
