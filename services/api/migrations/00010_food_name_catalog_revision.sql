-- +goose Up
-- A locale revision changes atomically with publication/withdrawal. Cursors can
-- reject a changed lexicon instead of silently mixing two name generations.
CREATE TABLE trainforge_v1.food_name_catalogs (
 locale text PRIMARY KEY CHECK(locale IN('pt-BR','pt-PT','en','es')),
 revision bigint NOT NULL CHECK(revision>=0)
);
INSERT INTO trainforge_v1.food_name_catalogs(locale,revision) VALUES('pt-BR',0),('pt-PT',0),('en',0),('es',0);
-- +goose StatementBegin
CREATE FUNCTION trainforge_v1.bump_food_name_catalog() RETURNS trigger
 LANGUAGE plpgsql SET search_path=pg_catalog AS $body$
BEGIN
 UPDATE trainforge_v1.food_name_catalogs SET revision=revision+1 WHERE locale=NEW.locale;
 RETURN NEW;
END;
$body$;
-- +goose StatementEnd
REVOKE ALL ON FUNCTION trainforge_v1.bump_food_name_catalog() FROM PUBLIC;
CREATE TRIGGER food_name_publication_revision AFTER INSERT ON trainforge_v1.food_name_versions
 FOR EACH ROW EXECUTE FUNCTION trainforge_v1.bump_food_name_catalog();
CREATE TRIGGER food_name_withdrawal_revision AFTER INSERT ON trainforge_v1.food_name_withdrawals
 FOR EACH ROW EXECUTE FUNCTION trainforge_v1.bump_food_name_catalog();
-- No Down: editorial revisions remain monotonic; runtime receives SELECT only.
