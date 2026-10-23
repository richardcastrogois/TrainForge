-- +goose Up
CREATE TABLE trainforge_v1.account_deletion_intents (
 token_hash bytea PRIMARY KEY CHECK(octet_length(token_hash)=32),
 user_id uuid NOT NULL,
 family_id uuid NOT NULL,
 expires_at timestamptz NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(user_id,family_id),
 FOREIGN KEY(family_id,user_id) REFERENCES trainforge_v1.auth_families(id,user_id)
);
CREATE INDEX deletion_intent_expiry_idx ON trainforge_v1.account_deletion_intents(expires_at);
CREATE TABLE trainforge_v1.account_erasures (
 user_id uuid PRIMARY KEY,
 erased_at timestamptz NOT NULL DEFAULT now()
);
-- Deliberately no FK: the minimum restore ledger outlives the erased account.
-- No Down: preserve erasure records and recover only into a separately sanitized DB.

-- Private food deletion is narrowly privileged; runtime retains no DELETE on
-- editorial food_versions. The function authenticates the same live intent.
-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.erase_private_foods(
 target_user uuid,target_family uuid,access_digest bytea,intent_digest bytea)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $body$
BEGIN
 IF NOT EXISTS(
  SELECT 1 FROM trainforge_v1.account_deletion_intents d
  JOIN trainforge_v1.auth_families f ON f.id=d.family_id AND f.user_id=d.user_id
  JOIN trainforge_v1.access_tokens a ON a.family_id=f.id
  WHERE d.token_hash=intent_digest AND d.user_id=target_user AND d.family_id=target_family
  AND d.expires_at>clock_timestamp() AND a.token_hash=access_digest
  AND a.expires_at>clock_timestamp() AND f.revoked_at IS NULL
  AND f.created_at>=clock_timestamp()-interval '15 minutes')
 THEN RAISE EXCEPTION 'live confirmed account erasure required'; END IF;
 DELETE FROM trainforge_v1.food_versions WHERE owner_id=target_user;
END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.erase_private_foods(uuid,uuid,bytea,bytea) FROM PUBLIC;

-- Defense in depth for future private consumption writes: a user may reference
-- editorial food or their own private food, never another user's private row.
-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.check_food_entry_owner() RETURNS trigger
 LANGUAGE plpgsql SET search_path=pg_catalog AS $body$
DECLARE food_owner uuid;
BEGIN
 SELECT owner_id INTO food_owner FROM trainforge_v1.food_versions
 WHERE food_id=NEW.food_id AND version_sha=NEW.food_sha;
 IF food_owner IS NOT NULL AND food_owner<>NEW.user_id
 THEN RAISE EXCEPTION 'food owner mismatch' USING ERRCODE='23514'; END IF;
 RETURN NEW;
END;
$body$;
-- +goose StatementEnd
CREATE TRIGGER food_entry_owner_guard BEFORE INSERT OR UPDATE OF user_id,food_id,food_sha
 ON trainforge_v1.food_entries FOR EACH ROW EXECUTE FUNCTION trainforge_v1.check_food_entry_owner();
REVOKE ALL ON FUNCTION trainforge_v1.check_food_entry_owner() FROM PUBLIC;

CREATE INDEX refresh_expiry_idx ON trainforge_v1.refresh_tokens(expires_at);
CREATE INDEX auth_family_age_idx ON trainforge_v1.auth_families(created_at,id);
