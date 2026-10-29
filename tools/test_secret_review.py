from pathlib import Path
import hashlib
import unittest
from secret_review import classify
class ExactNonsecretReview(unittest.TestCase):
 def finding(self,file='fixture.json'):return {'file':file,'rule':'generic-api-key','commit':'a'*40,'line':1}
 def test_exact_context_can_be_reviewed_but_any_change_blocks(self):
  line='"access": "ordinary public research note"'
  review={('fixture.json','generic-api-key',hashlib.sha256(line.encode()).hexdigest()):'natural_language_research_note'}
  self.assertTrue(classify(Path('.'),self.finding(),review,lambda *_:line.encode()).startswith('reviewed_nonsecret:'))
  self.assertEqual(classify(Path('.'),self.finding(),review,lambda *_:(line+' changed').encode()),'requires_review')
 def test_url_query_is_blocking_even_if_registry_is_wrong(self):
  line='"url": "https://example.invalid/file?token=synthetic-not-a-real-token"'
  review={('fixture.json','generic-api-key',hashlib.sha256(line.encode()).hexdigest()):'natural_language_research_note'}
  self.assertEqual(classify(Path('.'),self.finding(),review,lambda *_:line.encode()),'historical_url_query')
 def test_generated_digest_must_match_actual_file_in_same_commit(self):
  content=b'fixture-public-source\n';line='"tools/fixture.py": "'+hashlib.sha256(content).hexdigest()+'",'
  def reader(root,commit,path):return content if path=='tools/fixture.py' else line.encode()
  target=self.finding('docs/arquitetura/inventario-atual.json')
  self.assertEqual(classify(Path('.'),target,{},reader),'verified_source_file_sha256')
  self.assertEqual(classify(Path('.'),target,{},lambda *_:line.encode()),'requires_review')
 def test_missing_source_or_out_of_range_fails_closed(self):
  def reader(*_):raise ValueError('missing')
  self.assertEqual(classify(Path('.'),self.finding(),{},reader),'requires_review')
  item=self.finding();item['line']=5
  self.assertEqual(classify(Path('.'),item,{},lambda *_:b'one line'),'requires_review')
