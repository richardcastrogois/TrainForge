"""Negative HTTP checks against the real local API; never creates test users."""
import json
from urllib.request import Request, urlopen
from urllib.error import HTTPError
from dev_api import ROOT
def main():
    results=[]
    for method,path,body,expected in [
        ("GET","/api/v1/health/ready",None,200),("GET","/api/v1/me",None,401),
        ("POST","/api/v1/auth/google",{"idToken":"invalid-negative-probe"},401),
        ("POST","/api/v1/auth/refresh",{"refreshToken":"invalid-negative-probe"},401),
        ("POST","/api/v1/auth/logout",{"refreshToken":"invalid-negative-probe"},204)]:
        req=Request("http://127.0.0.1:8082"+path,data=None if body is None else json.dumps(body).encode(),
                    method=method,headers={"Content-Type":"application/json"})
        try:
            response=urlopen(req,timeout=10)
        except HTTPError as error:
            response=error
        if response.code!=expected:
            raise RuntimeError(path+" unexpected status "+str(response.code))
        if response.headers.get("Cache-Control")!="no-store":
            raise RuntimeError("missing no-store")
        results.append({"method":method,"path":path,"status":response.code})
        response.close()
    with urlopen("http://127.0.0.1:8082/docs/doc.json",timeout=10) as response:
        spec=json.load(response)
    count=sum(len(v) for v in spec["paths"].values())
    required={"/api/v1/auth/google","/api/v1/auth/refresh","/api/v1/auth/logout","/api/v1/me","/api/v1/health/live","/api/v1/health/ready"}
    if not required.issubset(spec["paths"]):
        raise RuntimeError("missing implemented auth/health Swagger operations")
    receipt={"scope":"real-local-process-negative-auth","results":results,"swaggerOperations":count,
             "realGoogleLoginValidated":False,"syntheticUserCreated":False}
    (ROOT/"docs/execucao/v1/auth-http-verification.json").write_text(json.dumps(receipt,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(receipt))
if __name__=="__main__":
    main()
