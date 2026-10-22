"""Real backup/restore and SQL invariants in a disposable owned database."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import re
from db_local import ROOT,LOCAL,PORT,NAME,verify_owned,run,sql,owner_env

RESTORE="trainforge_v1_restore_20261021"


def snapshot(db):
    names=sql("SELECT tablename FROM pg_tables WHERE schemaname='trainforge_v1' ORDER BY tablename;",db).splitlines()
    if any(not re.fullmatch('[a-z_]+',x) for x in names):raise RuntimeError("Unexpected table identifier")
    query="SELECT jsonb_object_agg(name,n) FROM ("+" UNION ALL ".join("SELECT '"+name+"' AS name,count(*) AS n FROM trainforge_v1."+name for name in names)+") counts;"
    counts=json.loads(sql(query,db))
    payload=sql("SELECT coalesce(jsonb_agg(to_jsonb(v) ORDER BY asset_id,version_sha),'[]') FROM trainforge_v1.content_versions v;",db)
    return {"counts":counts,"contentRowsSha256":hashlib.sha256(payload.encode()).hexdigest()}


def main():
    state=verify_owned()
    if state["port"]!=PORT or state["database"]!=NAME:raise RuntimeError("Unexpected target")
    if sql("SELECT count(*) FROM pg_database WHERE datname='"+RESTORE+"';")!="0":raise RuntimeError("Restore target already exists; no overwrite/drop performed")
    before=snapshot(NAME)
    backup=LOCAL/"backups";backup.mkdir(exist_ok=True);dump=backup/"trainforge-v1-post-content.dump"
    run("pg_dump",["-h","127.0.0.1","-p",str(PORT),"-U","trainforge_owner","-d",NAME,"-Fc","-f",dump],env=owner_env(),timeout=60)
    sql("CREATE DATABASE "+RESTORE+" OWNER trainforge_migrator;")
    created=True
    try:
        run("pg_restore",["-h","127.0.0.1","-p",str(PORT),"-U","trainforge_owner","-d",RESTORE,"--exit-on-error",dump],env=owner_env(),timeout=60)
        restored=snapshot(RESTORE)
        if before!=restored:raise RuntimeError("Restore count/reference/content mismatch")
        tests="""
BEGIN;
INSERT INTO trainforge_v1.users(id,provider,issuer,subject) VALUES
('00000000-0000-4000-8000-000000000001','fixture','fixture-only','owner-a'),
('00000000-0000-4000-8000-000000000002','fixture','fixture-only','owner-b');
INSERT INTO trainforge_v1.sources(id,name,urls) VALUES('fixture:source','fixture-only','[]');
INSERT INTO trainforge_v1.content_versions(asset_id,version_sha,kind,source_id,title,allowed_operations,payload)
VALUES('fixture:program',repeat('a',64),'program','fixture:source','fixture-only','{}','{}');
INSERT INTO trainforge_v1.program_sessions(program_id,program_sha,session_key) VALUES('fixture:program',repeat('a',64),'fixture');
INSERT INTO trainforge_v1.enrollments(id,user_id,program_id,program_sha,status)
VALUES('00000000-0000-4000-8000-000000000003','00000000-0000-4000-8000-000000000001','fixture:program',repeat('a',64),'active');
INSERT INTO trainforge_v1.schedule_occurrences(id,user_id,enrollment_id,source_session_key,planned_for,timezone,program_id,program_sha)
VALUES('00000000-0000-4000-8000-000000000004','00000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000003','fixture',now(),'UTC','fixture:program',repeat('a',64));
INSERT INTO trainforge_v1.activity_sessions(id,occurrence_id,user_id,state,started_at)
VALUES('00000000-0000-4000-8000-000000000005','00000000-0000-4000-8000-000000000004','00000000-0000-4000-8000-000000000001','started',now());
DO $$ BEGIN
 BEGIN
  INSERT INTO trainforge_v1.activity_sessions(id,occurrence_id,user_id,state,started_at)
  VALUES('00000000-0000-4000-8000-000000000006','00000000-0000-4000-8000-000000000004','00000000-0000-4000-8000-000000000001','paused',now());
  RAISE EXCEPTION 'Duplicate open session accepted';
 EXCEPTION WHEN unique_violation THEN NULL; END;
 BEGIN
  INSERT INTO trainforge_v1.activity_events(id,session_id,user_id,event_type,occurred_at,payload)
  VALUES('00000000-0000-4000-8000-000000000007','00000000-0000-4000-8000-000000000005','00000000-0000-4000-8000-000000000002','fixture',now(),'{}');
  RAISE EXCEPTION 'Cross-owner event accepted';
 EXCEPTION WHEN foreign_key_violation THEN NULL; END;
 BEGIN
  INSERT INTO trainforge_v1.enrollments(id,user_id,program_id,program_sha,status)
  SELECT '00000000-0000-4000-8000-000000000008','00000000-0000-4000-8000-000000000001',asset_id,version_sha,'active' FROM trainforge_v1.content_versions WHERE kind='movement' LIMIT 1;
  RAISE EXCEPTION 'Movement accepted as program';
 EXCEPTION WHEN foreign_key_violation THEN NULL; END;
 BEGIN
  INSERT INTO trainforge_v1.activity_sessions(id,occurrence_id,user_id,state,started_at)
  VALUES('00000000-0000-4000-8000-000000000009','00000000-0000-4000-8000-000000000004','00000000-0000-4000-8000-000000000001','completed',now());
  RAISE EXCEPTION 'Completion without end timestamps accepted';
 EXCEPTION WHEN check_violation THEN NULL; END;
 BEGIN
  INSERT INTO trainforge_v1.schedule_occurrences(id,user_id,enrollment_id,source_session_key,planned_for,timezone,program_id,program_sha)
  VALUES('00000000-0000-4000-8000-000000000010','00000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000003','nonexistent-session',now(),'UTC','fixture:program',repeat('a',64));
  RAISE EXCEPTION 'Occurrence accepted nonexistent prescribed session';
 EXCEPTION WHEN foreign_key_violation THEN NULL; END;
END $$;
ROLLBACK;
"""
        sql(tests,RESTORE)
        if snapshot(RESTORE)!=before:raise RuntimeError("Transactional fixtures survived rollback")
        privileges=json.loads(sql("SELECT json_build_object('runtimeCanCreate',has_schema_privilege('trainforge_runtime','trainforge_v1','CREATE'),'runtimeCanMutateEditorial',has_table_privilege('trainforge_runtime','trainforge_v1.content_versions','UPDATE'),'runtimeCanReadEditorial',has_table_privilege('trainforge_runtime','trainforge_v1.content_versions','SELECT'),'runtimeSuperuser',(SELECT rolsuper FROM pg_roles WHERE rolname='trainforge_runtime'));",NAME))
        if privileges!={"runtimeCanCreate":False,"runtimeCanMutateEditorial":False,"runtimeCanReadEditorial":True,"runtimeSuperuser":False}:raise RuntimeError("Runtime privileges violate policy")
        if snapshot(NAME)!=before:raise RuntimeError("Source DB changed during restore verification")
        result={"result":"PASS","source":"isolated_development","postgres":state["version"],"restoreTarget":RESTORE,"sameCountsAndContent":True,"counts":before["counts"],"contentRowsSha256":before["contentRowsSha256"],"privileges":privileges,"sqlInvariantsChecked":["one_open_session_per_occurrence","cross_owner_event_rejected","movement_not_program","completion_requires_timestamps","occurrence_requires_prescribed_session"],"fixturesPersisted":0,"backupSha256":hashlib.sha256(dump.read_bytes()).hexdigest(),"restoreTargetRemoved":True,"legacyDatabaseAccessed":False,"externalReleaseApproved":False}
    finally:
        # Exact owned throwaway target, created above; no force termination or source reset.
        if created and RESTORE=="trainforge_v1_restore_20261021":sql("DROP DATABASE "+RESTORE+";")
    (ROOT/"docs/execucao/v1/database-verification.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(result))


if __name__=="__main__":main()
