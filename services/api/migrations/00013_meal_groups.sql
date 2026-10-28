-- +goose Up
-- Grouping references the original intakes. Existing intakes stay ungrouped.
ALTER TABLE trainforge_v1.food_entries ADD CONSTRAINT food_entry_owner_key UNIQUE(id,user_id);
CREATE TABLE trainforge_v1.meals (
 id uuid PRIMARY KEY,
 user_id uuid NOT NULL REFERENCES trainforge_v1.users(id),
 title text NOT NULL CHECK(char_length(title)<=80 AND btrim(title)=title AND title!~'[[:cntrl:]]'),
 occurred_at timestamptz NOT NULL CHECK(occurred_at>='1900-01-01 00:00:00+00' AND occurred_at<'2101-01-01 00:00:00+00'),
 timezone text NOT NULL CHECK(char_length(timezone) BETWEEN 1 AND 80),
 revision integer NOT NULL CHECK(revision>0),
 deleted_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(id,user_id)
);
CREATE INDEX meal_owner_time_idx ON trainforge_v1.meals(user_id,occurred_at DESC,id DESC);
CREATE TABLE trainforge_v1.meal_items (
 entry_id uuid PRIMARY KEY,
 user_id uuid NOT NULL,
 meal_id uuid NOT NULL,
 position integer NOT NULL CHECK(position BETWEEN 0 AND 31),
 UNIQUE(meal_id,position),
 FOREIGN KEY(entry_id,user_id) REFERENCES trainforge_v1.food_entries(id,user_id) ON DELETE CASCADE,
 FOREIGN KEY(meal_id,user_id) REFERENCES trainforge_v1.meals(id,user_id) ON DELETE CASCADE
);
CREATE INDEX meal_item_owner_idx ON trainforge_v1.meal_items(user_id,meal_id,position);
CREATE TABLE trainforge_v1.meal_versions (
 meal_id uuid NOT NULL,
 user_id uuid NOT NULL,
 revision integer NOT NULL CHECK(revision>0),
 title text NOT NULL,
 occurred_at timestamptz NOT NULL,
 timezone text NOT NULL,
 entry_ids uuid[] NOT NULL CHECK(cardinality(entry_ids) BETWEEN 1 AND 32),
 deleted boolean NOT NULL,
 confirmed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 PRIMARY KEY(meal_id,revision),
 FOREIGN KEY(meal_id,user_id) REFERENCES trainforge_v1.meals(id,user_id) ON DELETE CASCADE
);
CREATE INDEX meal_version_owner_idx ON trainforge_v1.meal_versions(user_id,meal_id,revision);
-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.confirm_meal_group(target_user uuid,target_family uuid,access_digest bytea,
 target_meal uuid,expected_revision integer,new_title text,new_time timestamptz,new_zone text,items uuid[])
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $body$
DECLARE current_group trainforge_v1.meals%ROWTYPE; ids uuid[];
BEGIN
 IF NOT EXISTS(SELECT 1 FROM trainforge_v1.users u JOIN trainforge_v1.auth_families f ON f.user_id=u.id
 JOIN trainforge_v1.access_tokens a ON a.family_id=f.id WHERE u.id=target_user AND f.id=target_family
 AND a.token_hash=access_digest AND a.expires_at>clock_timestamp() AND f.revoked_at IS NULL
 FOR UPDATE OF u FOR SHARE OF f) THEN RAISE EXCEPTION 'live account required' USING ERRCODE='TFA01'; END IF;
 IF expected_revision IS NULL OR expected_revision<0 OR expected_revision>=2147483647
 OR new_title IS NULL OR char_length(new_title)>80 OR btrim(new_title)<>new_title OR new_title~'[[:cntrl:]]'
 OR new_time IS NULL OR new_time<'1900-01-01 00:00:00+00' OR new_time>='2101-01-01 00:00:00+00'
 OR new_zone IS NULL OR char_length(new_zone) NOT BETWEEN 1 AND 80
 OR NOT(new_zone='UTC' OR new_zone~'^[+-](0[0-9]|1[0-3]):[0-5][0-9]$' OR new_zone IN('+14:00','-14:00')
 OR (position('/' in new_zone)>0 AND EXISTS(SELECT 1 FROM pg_timezone_names WHERE name=new_zone)))
 THEN RAISE EXCEPTION 'invalid meal' USING ERRCODE='TFQ01'; END IF;
 IF expected_revision=0 THEN
  IF items IS NULL OR cardinality(items) NOT BETWEEN 1 AND 32
  OR (SELECT count(DISTINCT x) FROM unnest(items) x)<>cardinality(items)
  OR EXISTS(SELECT 1 FROM unnest(items) x LEFT JOIN trainforge_v1.food_entries e ON e.id=x AND e.user_id=target_user
    WHERE e.id IS NULL OR e.deleted_at IS NOT NULL)
  OR EXISTS(SELECT 1 FROM trainforge_v1.meal_items WHERE entry_id=ANY(items)) THEN
   RAISE EXCEPTION 'invalid meal items' USING ERRCODE='TFQ01';
  END IF;
  INSERT INTO trainforge_v1.meals(id,user_id,title,occurred_at,timezone,revision)
  VALUES(target_meal,target_user,new_title,new_time,new_zone,1);
  INSERT INTO trainforge_v1.meal_items(entry_id,user_id,meal_id,position)
   SELECT x,target_user,target_meal,(n-1)::int FROM unnest(items) WITH ORDINALITY AS t(x,n);
 ELSE
  SELECT * INTO current_group FROM trainforge_v1.meals WHERE id=target_meal AND user_id=target_user FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'meal unavailable' USING ERRCODE='TFM01'; END IF;
  IF current_group.deleted_at IS NOT NULL OR current_group.revision<>expected_revision THEN
   RAISE EXCEPTION 'meal revision conflict' USING ERRCODE='TFC01';
  END IF;
  IF items IS NOT NULL THEN RAISE EXCEPTION 'membership change requires a separate command' USING ERRCODE='TFQ01'; END IF;
  UPDATE trainforge_v1.meals SET title=new_title,occurred_at=new_time,timezone=new_zone,revision=revision+1
   WHERE id=target_meal AND user_id=target_user;
 END IF;
 SELECT array_agg(entry_id ORDER BY position) INTO ids FROM trainforge_v1.meal_items WHERE meal_id=target_meal AND user_id=target_user;
 INSERT INTO trainforge_v1.meal_versions(meal_id,user_id,revision,title,occurred_at,timezone,entry_ids,deleted)
 VALUES(target_meal,target_user,expected_revision+1,new_title,new_time,new_zone,ids,false);
END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.confirm_meal_group(uuid,uuid,bytea,uuid,integer,text,timestamptz,text,uuid[]) FROM PUBLIC;
-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.delete_meal_group(target_user uuid,target_family uuid,access_digest bytea,target_meal uuid,expected_revision integer)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $body$
DECLARE current_group trainforge_v1.meals%ROWTYPE; ids uuid[]; now_time timestamptz:=clock_timestamp();
BEGIN
 IF NOT EXISTS(SELECT 1 FROM trainforge_v1.users u JOIN trainforge_v1.auth_families f ON f.user_id=u.id
 JOIN trainforge_v1.access_tokens a ON a.family_id=f.id WHERE u.id=target_user AND f.id=target_family
 AND a.token_hash=access_digest AND a.expires_at>clock_timestamp() AND f.revoked_at IS NULL
 FOR UPDATE OF u FOR SHARE OF f) THEN RAISE EXCEPTION 'live account required' USING ERRCODE='TFA01'; END IF;
 SELECT * INTO current_group FROM trainforge_v1.meals WHERE id=target_meal AND user_id=target_user FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'meal unavailable' USING ERRCODE='TFM01'; END IF;
 IF expected_revision IS NULL OR expected_revision<1 OR expected_revision>=2147483647 THEN
  RAISE EXCEPTION 'invalid revision' USING ERRCODE='TFQ01'; END IF;
 IF current_group.deleted_at IS NOT NULL OR current_group.revision<>expected_revision THEN
  RAISE EXCEPTION 'meal revision conflict' USING ERRCODE='TFC01'; END IF;
 SELECT array_agg(entry_id ORDER BY position) INTO ids FROM trainforge_v1.meal_items WHERE meal_id=target_meal AND user_id=target_user;
 UPDATE trainforge_v1.food_entries e SET deleted_at=now_time,calculation=jsonb_set(calculation,'{revision}',to_jsonb((calculation->>'revision')::int+1))
 WHERE e.user_id=target_user AND e.id=ANY(ids) AND e.deleted_at IS NULL;
 UPDATE trainforge_v1.meals SET deleted_at=now_time,revision=revision+1 WHERE id=target_meal AND user_id=target_user;
 INSERT INTO trainforge_v1.meal_versions(meal_id,user_id,revision,title,occurred_at,timezone,entry_ids,deleted)
 VALUES(target_meal,target_user,expected_revision+1,current_group.title,current_group.occurred_at,current_group.timezone,ids,true);
END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.delete_meal_group(uuid,uuid,bytea,uuid,integer) FROM PUBLIC;
-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.erase_meals(target_user uuid,target_family uuid,access_digest bytea,challenge_digest bytea)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $body$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM trainforge_v1.users u JOIN trainforge_v1.auth_families f ON f.user_id=u.id
 JOIN trainforge_v1.access_tokens a ON a.family_id=f.id WHERE u.id=target_user AND f.id=target_family
 AND a.token_hash=access_digest AND a.expires_at>clock_timestamp() AND f.revoked_at IS NULL
 FOR UPDATE OF u FOR SHARE OF f)
 OR NOT EXISTS(SELECT 1 FROM trainforge_v1.account_deletion_intents WHERE user_id=target_user AND family_id=target_family
 AND token_hash=challenge_digest AND expires_at>clock_timestamp()) THEN RAISE EXCEPTION 'confirmed live erasure required'; END IF;
 DELETE FROM trainforge_v1.meals WHERE user_id=target_user;
END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.erase_meals(uuid,uuid,bytea,bytea) FROM PUBLIC;
-- Runtime receives SELECT and explicit EXECUTE, never direct meal DML.
-- Metadata versions are immutable to the runtime. Account erasure removes all versions.
-- No Down: restore separately and reapply the account erasure ledger.
