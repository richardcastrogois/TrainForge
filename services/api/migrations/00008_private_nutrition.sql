-- +goose Up
-- Runtime may create a private declaration only through this constrained function.
-- It retains no INSERT/UPDATE/DELETE privilege on editorial food_versions.
-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.create_private_food(
 target_user uuid,target_family uuid,access_digest bytea,
 new_id text,new_sha text,new_name text,new_preparation text,
 base_quantity text,base_unit text,cells jsonb,origin jsonb)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $body$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM trainforge_v1.users u
 JOIN trainforge_v1.auth_families f ON f.user_id=u.id
 JOIN trainforge_v1.access_tokens a ON a.family_id=f.id
 WHERE u.id=target_user AND f.id=target_family AND a.token_hash=access_digest
 AND a.expires_at>clock_timestamp() AND f.revoked_at IS NULL
 FOR UPDATE OF u FOR SHARE OF f)
 THEN RAISE EXCEPTION 'live account required'; END IF;
 IF new_id !~ '^own:[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$'
 OR new_sha !~ '^[a-f0-9]{64}$' OR length(new_name) NOT BETWEEN 1 AND 180
 OR length(new_preparation)>180 OR jsonb_typeof(cells)<>'array'
 OR jsonb_array_length(cells)>32 OR jsonb_typeof(origin)<>'object'
 OR origin->>'origin' IS DISTINCT FROM 'personal'
 OR origin->>'clinicalApproval' IS DISTINCT FROM 'false'
 OR (base_quantity IS NULL)<>(base_unit IS NULL)
 OR (base_quantity IS NOT NULL AND (base_quantity !~ '^[0-9]{1,7}(\.[0-9]{1,6})?$' OR base_quantity::numeric<=0 OR base_unit NOT IN('g','ml')))
 THEN RAISE EXCEPTION 'invalid private declaration'; END IF;
 INSERT INTO trainforge_v1.food_versions(food_id,version_sha,owner_id,name_original,preparation,basis_quantity,basis_unit,nutrients,provenance,name_locale,source_published_version,allowed_operations)
 VALUES(new_id,new_sha,target_user,new_name,new_preparation,base_quantity::numeric,base_unit,cells,origin,'pt','user-declaration-v1','{}');
END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.create_private_food(uuid,uuid,bytea,text,text,text,text,text,text,jsonb,jsonb) FROM PUBLIC;
CREATE INDEX food_entries_day_active_idx ON trainforge_v1.food_entries(user_id,occurred_at,id) WHERE deleted_at IS NULL;
-- No Down: private records are removed by the confirmed account lifecycle.
