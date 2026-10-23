"""Read-only/anonymous V1-013 smoke against the actual isolated service; no accounts created."""
import json
from urllib.error import HTTPError
from urllib.request import Request,urlopen
from db_local import sql,NAME,verify_owned
from dev_api import ROOT

def request(path,method="GET",body=None):
    data=None if body is None else json.dumps(body).encode()
    try:
        with urlopen(Request("http://127.0.0.1:8082"+path,data=data,method=method,
                             headers={"Content-Type":"application/json","X-Forwarded-For":"203.0.113.42"}),timeout=10) as r:
            return r.status,dict(r.headers),json.load(r)
    except HTTPError as e:
        return e.code,dict(e.headers),None

def main():
    verify_owned()
    before=sql("SELECT json_build_array((SELECT count(*) FROM trainforge_v1.users),"
               "(SELECT count(*) FROM trainforge_v1.food_entries),"
               "(SELECT count(*) FROM trainforge_v1.account_deletion_intents),"
               "(SELECT count(*) FROM trainforge_v1.account_erasures))::text;",NAME)
    status,headers,policy=request("/api/v1/privacy")
    if status!=200 or headers.get("Cache-Control")!="no-store" or len(policy["exportSections"])!=8 or not policy["sessionRetention"]:
        raise RuntimeError("Actual privacy policy contract failed")
    checks={}
    for method,path,body in [("GET","/api/v1/me/export",None),
                             ("POST","/api/v1/me/deletion-intent",{"confirmation":"EXCLUIR MINHA CONTA"}),
                             ("DELETE","/api/v1/me",{"confirmation":"EXCLUIR MINHA CONTA","challenge":"invalid"})]:
        status,_,_=request(path,method,body)
        if status!=401:
            raise RuntimeError("Anonymous private operation accepted")
        checks[method+" "+path]=status
    status,_,spec=request("/docs/doc.json")
    operations=sum(method in {"get","post","put","patch","delete"} for methods in spec["paths"].values() for method in methods)
    if status!=200 or spec["info"]["version"]!="0.4.0" or operations!=18:
        raise RuntimeError("Privacy Swagger mismatch")
    _,_,catalog=request("/api/v1/catalog/filters")
    _,_,foods=request("/api/v1/foods/filters")
    if catalog["movementCount"]!=73 or foods["total"]!=6369:
        raise RuntimeError("Editorial coverage changed")
    after=sql("SELECT json_build_array((SELECT count(*) FROM trainforge_v1.users),"
              "(SELECT count(*) FROM trainforge_v1.food_entries),"
              "(SELECT count(*) FROM trainforge_v1.account_deletion_intents),"
              "(SELECT count(*) FROM trainforge_v1.account_erasures))::text;",NAME)
    if before!=after:
        raise RuntimeError("Delivered private rows changed")
    receipt={"scope":"actual-isolated-privacy-public-http","apiVersion":"0.4.0","swaggerOperations":18,
             "anonymousChecks":checks,"policyNoStoreVerified":True,"movementCount":73,"foodCount":6369,
             "deliveredPrivateCountsUnchanged":True,"accountsCreated":0,"accountsDeleted":0,
             "realGoogleLoginValidated":False}
    (ROOT/"docs/execucao/v1/privacy-http-verification.json").write_text(json.dumps(receipt,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(receipt))

if __name__=="__main__":
    main()
