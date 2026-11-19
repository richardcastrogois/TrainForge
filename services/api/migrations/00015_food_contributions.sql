-- +goose Up
CREATE TABLE trainforge_v1.food_contributions (
 id uuid PRIMARY KEY,
 user_id uuid NOT NULL REFERENCES trainforge_v1.users(id) ON DELETE CASCADE,
 operation_id uuid NOT NULL,
 request_hash bytea NOT NULL CHECK(octet_length(request_hash)=32),
 food jsonb NOT NULL CHECK(jsonb_typeof(food)='object'),
 consent jsonb NOT NULL CHECK(consent->>'accepted'='true' AND consent->>'version'='trainforge.food-contribution/1' AND consent->>'license'='CC0-1.0'),
 status text NOT NULL DEFAULT 'submitted' CHECK(status IN('submitted','withdrawn','approved','rejected')),
 review_note text NOT NULL DEFAULT '' CHECK(char_length(review_note)<=1000),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 reviewed_at timestamptz,
 UNIQUE(user_id,operation_id), UNIQUE(id,user_id)
);
CREATE INDEX contribution_owner_idx ON trainforge_v1.food_contributions(user_id,id);
CREATE TABLE trainforge_v1.food_contribution_media (
 id uuid PRIMARY KEY,
 contribution_id uuid NOT NULL,
 user_id uuid NOT NULL,
 sha256 bytea NOT NULL CHECK(octet_length(sha256)=32),
 media_type text NOT NULL CHECK(media_type='image/jpeg'),
 content bytea NOT NULL CHECK(octet_length(content) BETWEEN 1 AND 4194304),
 width integer NOT NULL CHECK(width BETWEEN 1 AND 4096),
 height integer NOT NULL CHECK(height BETWEEN 1 AND 4096),
 created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(contribution_id,sha256),
 FOREIGN KEY(contribution_id,user_id) REFERENCES trainforge_v1.food_contributions(id,user_id) ON DELETE CASCADE
);

-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.food_contribution_save(target_user uuid,target_family uuid,access_digest bytea,
 target_id uuid,op_id uuid,body_hash bytea,food_body jsonb,consent_body jsonb)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $body$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM trainforge_v1.users u JOIN trainforge_v1.auth_families f ON f.user_id=u.id
 JOIN trainforge_v1.access_tokens a ON a.family_id=f.id WHERE u.id=target_user AND f.id=target_family
 AND a.token_hash=access_digest AND a.expires_at>clock_timestamp() AND f.revoked_at IS NULL
 FOR UPDATE OF u FOR SHARE OF f) THEN RAISE EXCEPTION USING ERRCODE='TFA01',MESSAGE='live session required'; END IF;
 INSERT INTO trainforge_v1.food_contributions(id,user_id,operation_id,request_hash,food,consent)
 VALUES(target_id,target_user,op_id,body_hash,food_body,consent_body);
END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.food_contribution_save(uuid,uuid,bytea,uuid,uuid,bytea,jsonb,jsonb) FROM PUBLIC;

-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.food_contribution_withdraw(target_user uuid,target_family uuid,access_digest bytea,target_id uuid)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $body$
DECLARE current_status text;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM trainforge_v1.users u JOIN trainforge_v1.auth_families f ON f.user_id=u.id
 JOIN trainforge_v1.access_tokens a ON a.family_id=f.id WHERE u.id=target_user AND f.id=target_family
 AND a.token_hash=access_digest AND a.expires_at>clock_timestamp() AND f.revoked_at IS NULL
 FOR UPDATE OF u FOR SHARE OF f) THEN RAISE EXCEPTION USING ERRCODE='TFA01',MESSAGE='live session required'; END IF;
 SELECT status INTO current_status FROM trainforge_v1.food_contributions WHERE id=target_id AND user_id=target_user FOR UPDATE;
 IF current_status IS NULL THEN RAISE EXCEPTION USING ERRCODE='TFM01',MESSAGE='contribution unavailable'; END IF;
 IF current_status='withdrawn' THEN RETURN; END IF;
 IF current_status<>'submitted' THEN RAISE EXCEPTION USING ERRCODE='TFC01',MESSAGE='already reviewed'; END IF;
 UPDATE trainforge_v1.food_contributions SET status='withdrawn',updated_at=clock_timestamp() WHERE id=target_id;
 DELETE FROM trainforge_v1.food_contribution_media WHERE contribution_id=target_id;
END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.food_contribution_withdraw(uuid,uuid,bytea,uuid) FROM PUBLIC;

-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.food_contribution_attach(target_user uuid,target_family uuid,access_digest bytea,
 target_id uuid,media_id uuid,content_hash bytea,content_bytes bytea,pixel_width integer,pixel_height integer)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog AS $body$
DECLARE current_status text;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM trainforge_v1.users u JOIN trainforge_v1.auth_families f ON f.user_id=u.id
 JOIN trainforge_v1.access_tokens a ON a.family_id=f.id WHERE u.id=target_user AND f.id=target_family
 AND a.token_hash=access_digest AND a.expires_at>clock_timestamp() AND f.revoked_at IS NULL
 FOR UPDATE OF u FOR SHARE OF f) THEN RAISE EXCEPTION USING ERRCODE='TFA01',MESSAGE='live session required'; END IF;
 SELECT status INTO current_status FROM trainforge_v1.food_contributions WHERE id=target_id AND user_id=target_user FOR UPDATE;
 IF current_status IS NULL THEN RAISE EXCEPTION USING ERRCODE='TFM01',MESSAGE='contribution unavailable'; END IF;
 IF current_status<>'submitted' THEN RAISE EXCEPTION USING ERRCODE='TFC01',MESSAGE='already reviewed'; END IF;
 IF EXISTS(SELECT 1 FROM trainforge_v1.food_contribution_media WHERE contribution_id=target_id AND sha256=content_hash) THEN RETURN; END IF;
 IF (SELECT count(*) FROM trainforge_v1.food_contribution_media WHERE contribution_id=target_id)>=2 THEN
  RAISE EXCEPTION USING ERRCODE='TFC01',MESSAGE='media limit'; END IF;
 INSERT INTO trainforge_v1.food_contribution_media(id,contribution_id,user_id,sha256,media_type,content,width,height)
 VALUES(media_id,target_id,target_user,content_hash,'image/jpeg',content_bytes,pixel_width,pixel_height);
END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.food_contribution_attach(uuid,uuid,bytea,uuid,uuid,bytea,bytea,integer,integer) FROM PUBLIC;
-- No public moderation route or runtime approval grant. A reviewed export has no author identity.
