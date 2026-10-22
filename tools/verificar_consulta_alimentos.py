"""Read-only HTTP verification against the real isolated food lot; no user/login fixtures."""
import json
import time
from collections import Counter
from urllib.error import HTTPError
from urllib.parse import urlencode, quote
from urllib.request import Request, urlopen
from db_local import sql, NAME, verify_owned
from dev_api import ROOT

BASE = "http://127.0.0.1:8082"

def request(path, tag=None):
    headers = {"If-None-Match": tag} if tag else {}
    try:
        with urlopen(Request(BASE + path, headers=headers), timeout=20) as response:
            return response.status, dict(response.headers), json.load(response)
    except HTTPError as error:
        return error.code, dict(error.headers), None

def verify():
    verify_owned()
    before = sql("SELECT json_build_array((SELECT count(*) FROM trainforge_v1.users),"
                 "(SELECT count(*) FROM trainforge_v1.food_versions),"
                 "(SELECT md5(string_agg(food_id||version_sha,'' ORDER BY food_id,version_sha)) FROM trainforge_v1.food_versions))::text;", NAME)
    if json.loads(before)[0] != 0:
        raise RuntimeError("Personal accounts present; unattended checkpoint verification refused")
    manifest = json.loads((ROOT / "content/manifests/food-approved.json").read_text(encoding="utf-8"))
    expected = manifest["output"]["rows"]
    status, _, spec = request("/docs/doc.json")
    if status != 200 or spec["info"]["version"] != "0.3.0":
        raise RuntimeError("Wrong API checkpoint")
    operations = sum(method in {"get", "post", "put", "patch", "delete"} for methods in spec["paths"].values() for method in methods)
    if operations != 14 or any("post" in methods for path, methods in spec["paths"].items() if path.startswith("/api/v1/foods")):
        raise RuntimeError("Unexpected food write contract")
    status, _, facets = request("/api/v1/foods/filters")
    if status != 200 or facets["total"] != expected or facets["unknownBasisCount"] != 3:
        raise RuntimeError("Real food coverage differs")
    seen, source_counts, samples = set(), Counter(), {}
    cursor, pages = None, 0
    started = time.monotonic()
    while True:
        query = {"limit": 50}
        if cursor:
            query["cursor"] = cursor
        status, _, page = request("/api/v1/foods?" + urlencode(query))
        if status != 200 or not page["items"] or len(page["items"]) > 50:
            raise RuntimeError("Food pagination failed")
        for item in page["items"]:
            if item["id"] in seen:
                raise RuntimeError("Duplicate food across pages")
            seen.add(item["id"])
            source_counts[item["sourceId"]] += 1
            samples.setdefault(item["sourceId"], item)
        cursor, pages = page["nextCursor"], pages + 1
        if not cursor:
            break
        if pages > 1000:
            raise RuntimeError("Non-terminating cursor")
        if pages == 1 and request("/api/v1/foods?" + urlencode({"limit": 50, "cursor": cursor, "q": "changed"}))[0] != 400:
            raise RuntimeError("Cursor crossed filters")
    if len(seen) != expected or source_counts != Counter({s["id"]: s["count"] for s in facets["sources"]}):
        raise RuntimeError("Source coverage differs")
    states = Counter()
    for item in samples.values():
        path = "/api/v1/foods/" + quote(item["id"], safe="") + "?" + urlencode({"versionId": item["versionId"]})
        status, headers, detail = request(path)
        if status != 200 or not detail["nutrients"] or not detail["source"]["attribution"]:
            raise RuntimeError("Missing food composition or attribution")
        source_cells = json.loads(sql("SELECT nutrients::text FROM trainforge_v1.food_versions WHERE food_id='" + item["id"] + "' AND version_sha='" + item["versionId"] + "';", NAME))
        if len(source_cells) != len(detail["nutrients"]):
            raise RuntimeError("Nutrient cells lost")
        for original, cell in zip(source_cells, detail["nutrients"]):
            for key in ("sourceColumnKey", "sourceRowKey", "nameOriginal", "unit", "state", "value", "upperBound", "basisQuantity", "basisUnit", "declaredColumnBasis", "scalingAllowed", "reasons"):
                if original[key] != cell[key]:
                    raise RuntimeError("Composition field changed")
            states[cell["state"]] += 1
        if request(path, headers.get("Etag", headers.get("ETag")))[0] != 304:
            raise RuntimeError("ETag revalidation failed")
        term = " ".join(item["nameOriginal"].split())
        while len(term.encode("utf-8")) > 100:
            term = term[:-1]
        status, _, search = request("/api/v1/foods?" + urlencode({"q": term, "sourceId": item["sourceId"], "limit": 50}))
        if status != 200 or item["id"] not in {f["id"] for f in search["items"]}:
            raise RuntimeError("Original-name search failed")
    unknown_id = sql("SELECT food_id FROM trainforge_v1.food_versions WHERE owner_id IS NULL AND basis_unit IS NULL ORDER BY food_id LIMIT 1;", NAME)
    status, _, unknown = request("/api/v1/foods/" + quote(unknown_id, safe=""))
    if status != 200 or unknown["basis"] != {"quantity": None, "unit": None} or any(n["basisUnit"] is not None or n["scalingAllowed"] for n in unknown["nutrients"]):
        raise RuntimeError("Unknown basis inferred")
    if request("/api/v1/me")[0] != 401:
        raise RuntimeError("Identity endpoint is not protected")
    after = sql("SELECT json_build_array((SELECT count(*) FROM trainforge_v1.users),"
                "(SELECT count(*) FROM trainforge_v1.food_versions),"
                "(SELECT md5(string_agg(food_id||version_sha,'' ORDER BY food_id,version_sha)) FROM trainforge_v1.food_versions))::text;", NAME)
    if before != after:
        raise RuntimeError("Delivered identity/food versions changed")
    return {"scope": "real-isolated-food-http-read", "apiVersion": "0.3.0", "swaggerOperations": operations,
            "foodCount": len(seen), "sourceCounts": dict(source_counts), "pagesVerified": pages,
            "pageWalkSeconds": round(time.monotonic()-started, 3),
            "detailFieldsComparedToDatabase": True, "sampleNutrientStates": dict(states),
            "unknownBasisPreserved": True, "filterBoundCursorVerified": True,
            "etagVerified": True, "accountsCreated": 0, "consumptionEntriesCreated": 0,
            "deliveredIdentityAndVersionsUnchanged": True, "realGoogleLoginValidated": False}

if __name__ == "__main__":
    result = verify()
    (ROOT / "docs/execucao/v1/food-read-verification.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result))
