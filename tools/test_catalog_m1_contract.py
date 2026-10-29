import copy
import json
from pathlib import Path
import unittest
from gerar_catalogo_m1_swagger import validate_contract,PATHS

class CatalogContractBoundary(unittest.TestCase):
 def test_fixture_rejects_extra_routes_methods_auth_and_schema_drift(self):
  base={'paths':{p:{'get':{'responses':{'200':{'description':'fixture'}}}} for p in PATHS},'definitions':{'httpapi.Status':{'type':'object'}}}
  validate_contract(base,copy.deepcopy(base))
  for change in ['path','method','auth','definition']:
   bad=copy.deepcopy(base)
   if change=='path':bad['paths']['/api/v1/me']={'get':{}}
   if change=='method':bad['paths']['/api/v1/catalog/filters']['post']={}
   if change=='auth':bad['securityDefinitions']={'BearerAuth':{}}
   if change=='definition':bad['definitions']['httpapi.Status']['type']='string'
   with self.subTest(change=change),self.assertRaises(ValueError):validate_contract(base,bad)
 def test_generated_public_contract_matches_current_API(self):
  root=Path(__file__).resolve().parents[1]
  original=json.loads((root/'contracts/generated/swagger-v1.json').read_text(encoding='utf-8'))
  isolated=json.loads((root/'contracts/generated/catalog-m1.swagger.json').read_text(encoding='utf-8'))
  validate_contract(original,isolated)
