-- +goose Up
-- Context declared by the account, never an editorial training prescription.
-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.valid_training_configuration(c jsonb) RETURNS boolean
 LANGUAGE plpgsql STABLE SET search_path=pg_catalog AS $body$
DECLARE v jsonb; text_value text; tz text;
BEGIN
 IF jsonb_typeof(c) IS DISTINCT FROM 'object'
 OR NOT(c ?& ARRAY['environments','resources','context','timezone','availability'])
 OR c-ARRAY['environments','resources','context','timezone','availability'] <> '{}'::jsonb
 OR jsonb_typeof(c->'environments') IS DISTINCT FROM 'array'
 OR jsonb_typeof(c->'availability') IS DISTINCT FROM 'array'
 OR jsonb_typeof(c->'resources') IS DISTINCT FROM 'object'
 OR jsonb_typeof(c->'context') IS DISTINCT FROM 'string'
 OR jsonb_typeof(c->'timezone') IS DISTINCT FROM 'string'
 OR octet_length(c::text)>16384 THEN RETURN false; END IF;
 IF jsonb_array_length(c->'environments') NOT BETWEEN 1 AND 3
 OR jsonb_array_length(c->'availability') NOT BETWEEN 1 AND 28
 OR c->>'context' NOT IN('personal','caregiver_break')
 OR NOT((c->'resources') ?& ARRAY['status','items'])
 OR (c->'resources')-ARRAY['status','items'] <> '{}'::jsonb
 OR jsonb_typeof(c#>'{resources,status}') IS DISTINCT FROM 'string'
 OR jsonb_typeof(c#>'{resources,items}') IS DISTINCT FROM 'array'
 THEN RETURN false; END IF;
 FOR v IN SELECT * FROM jsonb_array_elements(c->'environments') LOOP
  IF jsonb_typeof(v)<>'string' OR v#>>'{}' NOT IN('home','park','gym') THEN RETURN false; END IF;
 END LOOP;
 IF (SELECT count(*)<>count(DISTINCT value) FROM jsonb_array_elements(c->'environments')) THEN RETURN false; END IF;
 IF jsonb_array_length(c#>'{resources,items}')>32 THEN RETURN false; END IF;
 IF c#>>'{resources,status}'='declared' THEN
  IF jsonb_array_length(c#>'{resources,items}')=0 THEN RETURN false; END IF;
 ELSIF c#>>'{resources,status}' IN('none','unknown') THEN
  IF jsonb_array_length(c#>'{resources,items}')<>0 THEN RETURN false; END IF;
 ELSE RETURN false; END IF;
 FOR v IN SELECT * FROM jsonb_array_elements(c#>'{resources,items}') LOOP
  IF jsonb_typeof(v)<>'object' OR NOT(v ?& ARRAY['sourceId','equipmentId'])
  OR v-ARRAY['sourceId','equipmentId']<>'{}'::jsonb
  OR jsonb_typeof(v->'sourceId') IS DISTINCT FROM 'string'
  OR jsonb_typeof(v->'equipmentId') IS DISTINCT FROM 'number'
  OR coalesce(v->>'sourceId','')!~'^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$'
  OR coalesce(v->>'equipmentId','')!~'^[1-9][0-9]{0,9}$' THEN RETURN false; END IF;
  IF (v->>'equipmentId')::bigint>2147483647 THEN RETURN false; END IF;
 END LOOP;
 IF (SELECT count(*)<>count(DISTINCT value) FROM jsonb_array_elements(c#>'{resources,items}')) THEN RETURN false; END IF;
 tz:=c->>'timezone';
 IF length(tz) NOT BETWEEN 1 AND 80 THEN RETURN false; END IF;
 IF tz='UTC' THEN NULL;
 ELSIF tz~'^[+-](0[0-9]|1[0-3]):[0-5][0-9]$' OR tz IN('+14:00','-14:00') THEN NULL;
 ELSIF position('/' in tz)>0 AND EXISTS(SELECT 1 FROM pg_timezone_names WHERE name=tz) THEN NULL;
 ELSE RETURN false; END IF;
 FOR v IN SELECT * FROM jsonb_array_elements(c->'availability') LOOP
  IF jsonb_typeof(v)<>'object' OR NOT(v ?& ARRAY['weekday','startTime','minutesAvailable'])
  OR v-ARRAY['weekday','startTime','minutesAvailable']<>'{}'::jsonb
  OR jsonb_typeof(v->'weekday') IS DISTINCT FROM 'number'
  OR jsonb_typeof(v->'minutesAvailable') IS DISTINCT FROM 'number'
  OR coalesce(v->>'weekday','')!~'^[1-7]$'
  OR coalesce(v->>'minutesAvailable','')!~'^[1-9][0-9]{0,3}$' THEN RETURN false; END IF;
  IF (v->>'minutesAvailable')::int>1440 THEN RETURN false; END IF;
  IF v->'startTime'<>'null'::jsonb AND (jsonb_typeof(v->'startTime')<>'string' OR v->>'startTime'!~'^([01][0-9]|2[0-3]):[0-5][0-9]$') THEN RETURN false; END IF;
 END LOOP;
 IF (SELECT count(*)<>count(DISTINCT ((value->>'weekday')||'|'||coalesce(value->>'startTime','unfixed'))) FROM jsonb_array_elements(c->'availability')) THEN RETURN false; END IF;
 RETURN true;
END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.valid_training_configuration(jsonb) FROM PUBLIC;
CREATE TABLE trainforge_v1.training_configuration_versions (
 user_id uuid NOT NULL REFERENCES trainforge_v1.users(id),
 revision integer NOT NULL CHECK(revision>0),
 configuration jsonb NOT NULL CHECK(trainforge_v1.valid_training_configuration(configuration)),
 confirmed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(user_id,revision)
);
-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.preserve_training_configuration() RETURNS trigger
 LANGUAGE plpgsql SET search_path=pg_catalog AS $body$
BEGIN RAISE EXCEPTION 'confirmed training context is immutable'; END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.preserve_training_configuration() FROM PUBLIC;
CREATE TRIGGER immutable_training_configuration BEFORE UPDATE ON trainforge_v1.training_configuration_versions
 FOR EACH ROW EXECUTE FUNCTION trainforge_v1.preserve_training_configuration();

-- Only permitted current metadata contributes resource identities. No dose/media are exposed.
CREATE VIEW trainforge_v1.training_configuration_resources AS
 WITH latest AS(SELECT DISTINCT ON(asset_id) * FROM trainforge_v1.content_versions
 WHERE kind IN('movement','program','collection') ORDER BY asset_id,created_at DESC,version_sha DESC),
 visible AS(SELECT v.* FROM latest v WHERE 'catalog_metadata'=ANY(v.allowed_operations)
 AND v.payload#>>'{rights,operationGrants,catalog_metadata}'='allowed'
 AND v.payload#>>'{review,state}'='reviewed' AND v.payload#>>'{review,rightsVerified}'='true'
 AND v.payload#>>'{review,fidelityChecked}'='true'
 AND NOT EXISTS(SELECT 1 FROM trainforge_v1.content_withdrawals w WHERE w.asset_id=v.asset_id AND w.version_sha=v.version_sha)),
 resources AS(SELECT v.source_id,s.name AS source_name,e->>'name' AS name_original,
 CASE WHEN e->>'id'~'^[1-9][0-9]{0,9}$' THEN (e->>'id')::bigint ELSE NULL END AS equipment_id
 FROM visible v JOIN trainforge_v1.sources s ON s.id=v.source_id
 CROSS JOIN LATERAL jsonb_array_elements(CASE WHEN jsonb_typeof(v.payload#>'{content,equipment}')='array' THEN v.payload#>'{content,equipment}' ELSE '[]'::jsonb END) e
 WHERE jsonb_typeof(e->'id')='number' AND jsonb_typeof(e->'name')='string'
 AND length(btrim(e->>'name')) BETWEEN 1 AND 360 AND e->>'name'!~'[[:cntrl:]]')
 SELECT source_id,equipment_id::integer,min(name_original) AS name_original,min(source_name) AS source_name
 FROM resources WHERE equipment_id BETWEEN 1 AND 2147483647
 GROUP BY source_id,equipment_id HAVING count(DISTINCT name_original)=1;

-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.save_training_configuration(
 target_user uuid,target_family uuid,access_digest bytea,request_doc jsonb,retry_key uuid)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $body$
DECLARE saved_hash bytea; saved_body jsonb; request_digest bytea; retry_digest bytea;
 current_revision integer; expected_revision integer; result jsonb; saved_at timestamptz; item jsonb; item_index integer:=0;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM trainforge_v1.users u JOIN trainforge_v1.auth_families f ON f.user_id=u.id
 JOIN trainforge_v1.access_tokens a ON a.family_id=f.id WHERE u.id=target_user AND f.id=target_family
 AND a.token_hash=access_digest AND a.expires_at>clock_timestamp() AND f.revoked_at IS NULL
 FOR UPDATE OF u FOR SHARE OF f) THEN RAISE EXCEPTION 'live account required' USING ERRCODE='TFA01'; END IF;
 IF retry_key IS NULL OR jsonb_typeof(request_doc) IS DISTINCT FROM 'object'
 OR NOT(request_doc ?& ARRAY['revision','reviewed','configuration'])
 OR request_doc-ARRAY['revision','reviewed','configuration']<>'{}'::jsonb
 OR request_doc->'reviewed' IS DISTINCT FROM 'true'::jsonb
 OR jsonb_typeof(request_doc->'revision') IS DISTINCT FROM 'number'
 OR coalesce(request_doc->>'revision','')!~'^(0|[1-9][0-9]{0,9})$'
 OR NOT trainforge_v1.valid_training_configuration(request_doc->'configuration')
 OR octet_length(request_doc::text)>16384 THEN RAISE EXCEPTION 'invalid training context' USING ERRCODE='TFQ01'; END IF;
 IF (request_doc->>'revision')::bigint>2147483646 THEN RAISE EXCEPTION 'invalid revision' USING ERRCODE='TFQ01'; END IF;
 request_digest:=sha256(convert_to(request_doc::text,'UTF8'));retry_digest:=sha256(convert_to(retry_key::text,'UTF8'));
 SELECT request_hash,response_body INTO saved_hash,saved_body FROM trainforge_v1.idempotency_records
 WHERE user_id=target_user AND operation='training-configuration' AND key_hash=retry_digest AND expires_at>clock_timestamp();
 IF FOUND THEN
  IF saved_hash<>request_digest THEN RAISE EXCEPTION 'configuration retry conflict' USING ERRCODE='TFC01'; END IF;
  RETURN saved_body;
 END IF;
 expected_revision:=(request_doc->>'revision')::int;
 SELECT coalesce(max(revision),0) INTO current_revision FROM trainforge_v1.training_configuration_versions WHERE user_id=target_user;
 IF current_revision<>expected_revision THEN RAISE EXCEPTION 'configuration revision conflict' USING ERRCODE='TFC01'; END IF;
 FOR item IN SELECT * FROM jsonb_array_elements(request_doc#>'{configuration,resources,items}') LOOP
  IF NOT EXISTS(SELECT 1 FROM trainforge_v1.training_configuration_resources r
   WHERE r.source_id=item->>'sourceId' AND r.equipment_id=(item->>'equipmentId')::int) THEN
   RAISE EXCEPTION 'resource_unavailable' USING ERRCODE='TFQ02',DETAIL='configuration.resources.items.'||item_index::text;
  END IF;
  item_index:=item_index+1;
 END LOOP;
 saved_at:=clock_timestamp();
 INSERT INTO trainforge_v1.training_configuration_versions(user_id,revision,configuration,confirmed_at)
 VALUES(target_user,current_revision+1,request_doc->'configuration',saved_at);
 result:=jsonb_build_object('contract','trainforge.training-configuration/1','revision',current_revision+1,'configuration',request_doc->'configuration','confirmedAt',saved_at);
 INSERT INTO trainforge_v1.idempotency_records(user_id,operation,key_hash,request_hash,response_status,response_body,expires_at)
 VALUES(target_user,'training-configuration',retry_digest,request_digest,200,result,clock_timestamp()+interval '24 hours')
 ON CONFLICT(user_id,operation,key_hash) DO UPDATE SET request_hash=EXCLUDED.request_hash,response_status=EXCLUDED.response_status,response_body=EXCLUDED.response_body,expires_at=EXCLUDED.expires_at;
 RETURN result;
END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.save_training_configuration(uuid,uuid,bytea,jsonb,uuid) FROM PUBLIC;
-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.erase_training_configuration(target_user uuid,target_family uuid,access_digest bytea,challenge_digest bytea)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $body$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM trainforge_v1.users u JOIN trainforge_v1.auth_families f ON f.user_id=u.id
 JOIN trainforge_v1.access_tokens a ON a.family_id=f.id WHERE u.id=target_user AND f.id=target_family
 AND a.token_hash=access_digest AND a.expires_at>clock_timestamp() AND f.revoked_at IS NULL
 FOR UPDATE OF u FOR SHARE OF f)
 OR NOT EXISTS(SELECT 1 FROM trainforge_v1.account_deletion_intents WHERE user_id=target_user AND family_id=target_family
 AND token_hash=challenge_digest AND expires_at>clock_timestamp()) THEN RAISE EXCEPTION 'confirmed live erasure required'; END IF;
 DELETE FROM trainforge_v1.training_configuration_versions WHERE user_id=target_user;
END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.erase_training_configuration(uuid,uuid,bytea,bytea) FROM PUBLIC;
-- Runtime gets SELECT and constrained EXECUTE only through explicit local grants.
-- No Down: preserve confirmed history; use the verified account/restore lifecycle.
