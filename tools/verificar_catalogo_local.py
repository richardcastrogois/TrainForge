"""Verify catalog in an isolated fixture DB, then read the actual reviewed local lot."""
import hashlib
import json
import secrets
import subprocess
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request,urlopen
from db_local import sql,NAME,load_env,LOCAL,verify_owned,start
from dev_api import environment,SERVICE,ROOT
from verificar_auth_local import database_url

def snapshot():
    return sql("SELECT count(*)::text||'|'||md5(coalesce(string_agg(asset_id||version_sha,'' ORDER BY asset_id,version_sha),'')) FROM trainforge_v1.content_versions;",NAME)

def fixtures():
    env,go=environment()
    name="trainforge_v1_catalog_test_"+secrets.token_hex(6)
    before=snapshot()
    if sql("SELECT count(*) FROM pg_database WHERE datname='"+name+"';")!="0":
        raise RuntimeError("temporary catalog target exists; refusing overwrite")
    writer=database_url(load_env(LOCAL/"migrate.env")["TF_MIGRATION_DATABASE_URL"],name)
    runtime=database_url(load_env(LOCAL/"api.env")["TF_DATABASE_URL"],name)
    created=False
    try:
        sql("CREATE DATABASE "+name+" OWNER trainforge_migrator;")
        created=True
        env["TF_MIGRATION_DATABASE_URL"]=writer
        subprocess.run([str(go),"run","./cmd/migrate"],cwd=SERVICE,env=env,check=True,timeout=90)
        sql("REVOKE ALL ON DATABASE "+name+" FROM PUBLIC; GRANT CONNECT ON DATABASE "+name+" TO trainforge_runtime; GRANT USAGE ON SCHEMA trainforge_v1 TO trainforge_runtime; GRANT SELECT ON trainforge_v1.sources,trainforge_v1.content_versions,trainforge_v1.content_withdrawals TO trainforge_runtime;",name)
        env["TF_CATALOG_TEST_DATABASE_URL"]=runtime
        env["TF_CATALOG_TEST_WRITER_DATABASE_URL"]=writer
        subprocess.run([str(go),"test","./internal/catalog","-count=1","-v"],cwd=SERVICE,env=env,check=True,timeout=120)
    finally:
        if created:
            sql("DROP DATABASE "+name+";")
    if snapshot()!=before:
        raise RuntimeError("delivered catalog changed during isolated tests")

def request(path,query=None,headers=None):
    req=Request("http://127.0.0.1:8082"+path+("?" + urlencode(query) if query else ""),headers=headers or {})
    try:
        response=urlopen(req,timeout=10)
    except HTTPError as error:
        response=error
    data=response.read()
    status=response.code
    resultHeaders=response.headers
    response.close()
    return status,resultHeaders,json.loads(data) if data else None

def real_lot():
    baseline=snapshot()
    approved=json.loads((ROOT/"content/manifests/pilot-approved.json").read_text(encoding="utf-8"))
    expected={row["assetId"] for row in approved["rows"] if "catalog_metadata" in row["allowedOperations"]}
    items=[]
    query={"limit":17}
    for _ in range(100):
        status,_,page=request("/api/v1/catalog/movements",query)
        if status!=200:
            raise RuntimeError("actual local catalog unavailable")
        items.extend(page["items"])
        if not page["nextCursor"]:
            break
        query["cursor"]=page["nextCursor"]
    else:
        raise RuntimeError("unbounded pagination")
    ids=[item["id"] for item in items]
    if len(ids)!=len(set(ids)) or set(ids)!=expected:
        raise RuntimeError("reviewed manifest coverage mismatch")
    for item in items:
        if set(item)&{"dose","content","media","instructions"}:
            raise RuntimeError("non-metadata projection")
        credits=item["rights"]["displayCredits"]
        if not item["rights"]["attribution"] or not credits["creators"] or not credits["licenseUrl"] or not credits["sourceUrl"] or not credits["changes"] or not credits["warrantyNotice"]:
            raise RuntimeError("required attribution absent")
        if item["availability"]["practice"] or item["availability"]["instruction"] or item["availability"]["media"]:
            raise RuntimeError("unapproved capability exposed")
    first=items[0]
    path="/api/v1/catalog/movements/"+first["id"]
    status,headers,detail=request(path,{"versionId":first["versionId"]})
    if status!=200 or detail["id"]!=first["id"]:
        raise RuntimeError("version detail mismatch")
    if request(path,{"versionId":first["versionId"]},{"If-None-Match":headers["ETag"]})[0]!=304:
        raise RuntimeError("ETag validation failed")
    if request("/api/v1/catalog/movements",{"mode":"practice"})[2]["items"]:
        raise RuntimeError("practice unexpectedly allowed")
    programs=request("/api/v1/catalog/programs")[2]["items"]
    if programs:
        raise RuntimeError("programs absent in this reviewed lot must not be fabricated")
    if request("/api/v1/catalog/movements",{"limit":51})[0]!=400:
        raise RuntimeError("page limit not enforced")
    if request("/api/v1/catalog/movements",{"environment":"home"})[2]["items"]:
        raise RuntimeError("unknown environments inferred as home")
    equipment=next((e["name"] for item in items for e in item["requirements"]["equipment"]),None)
    if equipment:
        subset=request("/api/v1/catalog/movements",{"equipment":equipment,"limit":50})[2]["items"]
        if not subset or any(not any(e["name"].casefold()==equipment.casefold() for e in i["requirements"]["equipment"]) for i in subset):
            raise RuntimeError("source equipment filter mismatch")
    if snapshot()!=baseline:
        raise RuntimeError("read-only API changed catalog")
    return {"reviewedMovementCount":len(items),"programCount":len(programs),"allCreditsVerified":True,
            "practiceCount":0,"realLotUnchanged":True,"immutableVersionAndETagVerified":True,
            "unknownEnvironmentNotInferred":True,"projection":"metadata-only"}

def main():
    verify_owned()
    start()
    fixtures()
    receipt={"scope":"catalog-fixtures-and-real-local-lot","temporaryDatabaseRemoved":True,
             "realGoogleLoginValidated":False,**real_lot()}
    (ROOT/"docs/execucao/v1/catalog-read-verification.json").write_text(json.dumps(receipt,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(receipt))
if __name__=="__main__":
    main()
