-- +goose Up
-- The durable receipt is independent from the 24-hour HTTP replay cache.
CREATE TABLE trainforge_v1.nutrition_sync_state (
 user_id uuid PRIMARY KEY REFERENCES trainforge_v1.users(id) ON DELETE CASCADE,
 sequence bigint NOT NULL DEFAULT 0 CHECK(sequence>=0),
 seeded boolean NOT NULL DEFAULT false
);
CREATE TABLE trainforge_v1.nutrition_changes (
 user_id uuid NOT NULL REFERENCES trainforge_v1.users(id) ON DELETE CASCADE,
 sequence bigint NOT NULL CHECK(sequence>0),
 entity text NOT NULL CHECK(entity IN('food','entry','meal')),
 resource_id text NOT NULL,
 value jsonb NOT NULL CHECK(jsonb_typeof(value)='object'),
 deleted boolean NOT NULL,
 changed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(user_id,sequence)
);
CREATE TABLE trainforge_v1.nutrition_operation_receipts (
 user_id uuid NOT NULL REFERENCES trainforge_v1.users(id) ON DELETE CASCADE,
 operation_id uuid NOT NULL,
 kind text NOT NULL CHECK(kind IN('food.create','entry.create','entry.update','entry.delete','meal.create','meal.update','meal.delete')),
 local_id uuid NOT NULL,
 request_hash bytea NOT NULL CHECK(octet_length(request_hash)=32),
 result jsonb NOT NULL CHECK(jsonb_typeof(result)='object'),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(user_id,operation_id)
);
CREATE UNIQUE INDEX nutrition_local_resource_once ON trainforge_v1.nutrition_operation_receipts(user_id,kind,local_id)
 WHERE kind IN('food.create','entry.create','meal.create');

-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.nutrition_sync_snapshot(target_user uuid,kind text,target_id text)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $body$
DECLARE result jsonb;
BEGIN
 IF kind='food' THEN
  SELECT jsonb_build_object('id',v.food_id,'versionId',v.version_sha,'sourceId','personal','sourceFoodId','',
   'sourcePublishedVersion','user-declaration-v1','nameOriginal',v.name_original,'nameLocale',v.name_locale,
   'basis',jsonb_build_object('quantity',v.basis_quantity::text,'unit',v.basis_unit),'source',v.provenance->'source',
   'nutrients',v.nutrients,'brand',v.provenance->'brand','barcodes',v.provenance->'barcodes',
   'portions',v.provenance->'portions','canonicalNutrients',v.provenance->'canonicalNutrients',
   'notice','Alimento particular; declaração do titular, sem revisão editorial ou clínica.')
  INTO result FROM trainforge_v1.food_versions v WHERE v.owner_id=target_user AND v.food_id=target_id
  ORDER BY v.created_at DESC,v.version_sha DESC LIMIT 1;
 ELSIF kind='entry' THEN
  SELECT jsonb_build_object('id',v.id,'foodId',v.food_id,'foodVersion',v.food_sha,'quantity',v.quantity::text,'unit',v.unit,
   'occurredAt',to_char(v.occurred_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
   'timezone',v.timezone,'calculation',v.calculation,'deletedAt',v.deleted_at)
  INTO result FROM trainforge_v1.food_entries v WHERE v.user_id=target_user AND v.id::text=target_id;
 ELSIF kind='meal' THEN
  SELECT jsonb_build_object('meal',jsonb_build_object('id',m.id,'title',m.title,
   'occurredAt',to_char(m.occurred_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
   'timezone',m.timezone,'revision',m.revision,'totalActiveItems',
    (SELECT count(*) FROM trainforge_v1.meal_items mi JOIN trainforge_v1.food_entries e ON e.id=mi.entry_id AND e.user_id=mi.user_id
     WHERE mi.meal_id=m.id AND mi.user_id=m.user_id AND e.deleted_at IS NULL)),
   'entries',coalesce((SELECT jsonb_agg(trainforge_v1.nutrition_sync_snapshot(target_user,'entry',mi.entry_id::text) ORDER BY mi.position)
    FROM trainforge_v1.meal_items mi WHERE mi.meal_id=m.id AND mi.user_id=m.user_id),'[]'::jsonb),'deletedAt',m.deleted_at)
  INTO result FROM trainforge_v1.meals m WHERE m.user_id=target_user AND m.id::text=target_id;
 ELSE RAISE EXCEPTION 'invalid entity'; END IF;
 RETURN result;
END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.nutrition_sync_snapshot(uuid,text,text) FROM PUBLIC;

-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.nutrition_sync_append(target_user uuid,kind text,target_id text)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $body$
DECLARE current_sequence bigint; snapshot jsonb;
BEGIN
 UPDATE trainforge_v1.nutrition_sync_state SET sequence=sequence+1 WHERE user_id=target_user AND seeded RETURNING sequence INTO current_sequence;
 IF current_sequence IS NULL THEN RETURN; END IF;
 snapshot:=trainforge_v1.nutrition_sync_snapshot(target_user,kind,target_id);
 IF snapshot IS NULL THEN RAISE EXCEPTION 'sync snapshot unavailable'; END IF;
 INSERT INTO trainforge_v1.nutrition_changes(user_id,sequence,entity,resource_id,value,deleted)
 VALUES(target_user,current_sequence,kind,target_id,snapshot,coalesce(snapshot->>'deletedAt','')<>'');
END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.nutrition_sync_append(uuid,text,text) FROM PUBLIC;

-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.nutrition_sync_capture() RETURNS trigger
 LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $body$
DECLARE linked_meal text;
BEGIN
 IF TG_TABLE_NAME='food_versions' THEN
  IF NEW.owner_id IS NOT NULL THEN
   PERFORM trainforge_v1.nutrition_sync_append(NEW.owner_id,'food',NEW.food_id);
  END IF;
 ELSIF TG_TABLE_NAME='food_entries' THEN
  PERFORM trainforge_v1.nutrition_sync_append(NEW.user_id,'entry',NEW.id::text);
  FOR linked_meal IN SELECT meal_id::text FROM trainforge_v1.meal_items WHERE user_id=NEW.user_id AND entry_id=NEW.id LOOP
   PERFORM trainforge_v1.nutrition_sync_append(NEW.user_id,'meal',linked_meal);
  END LOOP;
 ELSIF TG_TABLE_NAME='meal_versions' THEN
  PERFORM trainforge_v1.nutrition_sync_append(NEW.user_id,'meal',NEW.meal_id::text);
 END IF;
 RETURN NEW;
END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.nutrition_sync_capture() FROM PUBLIC;
CREATE TRIGGER nutrition_food_changes AFTER INSERT ON trainforge_v1.food_versions
 FOR EACH ROW EXECUTE FUNCTION trainforge_v1.nutrition_sync_capture();
CREATE TRIGGER nutrition_entry_changes AFTER INSERT OR UPDATE ON trainforge_v1.food_entries
 FOR EACH ROW EXECUTE FUNCTION trainforge_v1.nutrition_sync_capture();
CREATE TRIGGER nutrition_meal_changes AFTER INSERT ON trainforge_v1.meal_versions
 FOR EACH ROW EXECUTE FUNCTION trainforge_v1.nutrition_sync_capture();

-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.nutrition_sync_seed(target_user uuid,target_family uuid,access_digest bytea)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $body$
DECLARE ready boolean; row_id text;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM trainforge_v1.users u JOIN trainforge_v1.auth_families f ON f.user_id=u.id
  JOIN trainforge_v1.access_tokens a ON a.family_id=f.id WHERE u.id=target_user AND f.id=target_family
  AND a.token_hash=access_digest AND a.expires_at>clock_timestamp() AND f.revoked_at IS NULL
  FOR UPDATE OF u FOR SHARE OF f) THEN RAISE EXCEPTION 'live session required'; END IF;
 INSERT INTO trainforge_v1.nutrition_sync_state(user_id) VALUES(target_user) ON CONFLICT DO NOTHING;
 SELECT seeded INTO ready FROM trainforge_v1.nutrition_sync_state WHERE user_id=target_user FOR UPDATE;
 IF ready THEN RETURN; END IF;
 UPDATE trainforge_v1.nutrition_sync_state SET seeded=true WHERE user_id=target_user;
 FOR row_id IN SELECT food_id FROM trainforge_v1.food_versions WHERE owner_id=target_user ORDER BY food_id LOOP
  PERFORM trainforge_v1.nutrition_sync_append(target_user,'food',row_id);
 END LOOP;
 FOR row_id IN SELECT id::text FROM trainforge_v1.food_entries WHERE user_id=target_user ORDER BY id LOOP
  PERFORM trainforge_v1.nutrition_sync_append(target_user,'entry',row_id);
 END LOOP;
 FOR row_id IN SELECT id::text FROM trainforge_v1.meals WHERE user_id=target_user ORDER BY id LOOP
  PERFORM trainforge_v1.nutrition_sync_append(target_user,'meal',row_id);
 END LOOP;
END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.nutrition_sync_seed(uuid,uuid,bytea) FROM PUBLIC;

-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.nutrition_sync_receipt(target_user uuid,target_family uuid,access_digest bytea,
 op_id uuid,op_kind text,local_resource uuid,body_hash bytea,result_body jsonb)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $body$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM trainforge_v1.users u JOIN trainforge_v1.auth_families f ON f.user_id=u.id
  JOIN trainforge_v1.access_tokens a ON a.family_id=f.id WHERE u.id=target_user AND f.id=target_family
  AND a.token_hash=access_digest AND a.expires_at>clock_timestamp() AND f.revoked_at IS NULL
  FOR UPDATE OF u FOR SHARE OF f) THEN RAISE EXCEPTION 'live session required'; END IF;
 INSERT INTO trainforge_v1.nutrition_operation_receipts(user_id,operation_id,kind,local_id,request_hash,result)
 VALUES(target_user,op_id,op_kind,local_resource,body_hash,result_body);
END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.nutrition_sync_receipt(uuid,uuid,bytea,uuid,text,uuid,bytea,jsonb) FROM PUBLIC;
-- Runtime only SELECT/explicit EXECUTE; privacy erasure cascades from users.
-- No Down: durable operations must not be removed by a rollback of application code.
