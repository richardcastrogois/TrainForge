import unittest
import json
from prepare_history_remediation import sanitize
class HistoryRemediationBoundaries(unittest.TestCase):
 def test_only_credential_query_is_removed_and_json_format_preserved(self):
  original=b'{\n  "url": "https://example.invalid/file?token=synthetic-placeholder&download=true",\n  "title": "Original source",\n  "sha256": "unchanged"\n}\n'
  result,count=sanitize(original)
  self.assertEqual(count,1);self.assertEqual(result,original.replace(b'?token=synthetic-placeholder&download=true',b''));self.assertEqual(json.loads(result)['title'],'Original source')
 def test_pagination_and_noncredential_urls_stay_byte_identical(self):
  for raw in [b'{"url":"https://example.invalid/list?limit=25&offset=50"}',b'{"text":"ordinary reference"}',b'{"url":"https://example.invalid/list?api_key=DEMO_KEY&query=food"}',b'{"url":"https://example.invalid/file"}']:
   self.assertEqual(sanitize(raw),(raw,0))
 def test_presigned_query_and_multiple_urls_are_removed_without_changing_notes(self):
  raw=json.dumps({'links':['https://example.invalid/a?X-Amz-Signature=synthetic-placeholder','https://example.invalid/b?access_token=synthetic-placeholder'],'note':'Keep attribution'}).encode()
  result,count=sanitize(raw);self.assertEqual(count,2);doc=json.loads(result);self.assertEqual(doc['links'],['https://example.invalid/a','https://example.invalid/b']);self.assertEqual(doc['note'],'Keep attribution')
