from pathlib import Path
import unittest
from secret_ci import safe_findings,scan_result


class SecretReportGuards(unittest.TestCase):
    def fixture(self):
        return {'RuleID':'github-pat','File':'fixture.txt','StartLine':3,'Commit':'a'*40,
                'Secret':'synthetic-secret-do-not-publish','Match':'private-match',
                'Author':'private-name','Email':'private@example.invalid','Message':'private-message'}

    def test_whitelist_drops_all_sensitive_and_unknown_fields(self):
        report=safe_findings([self.fixture()],Path.cwd())
        self.assertEqual(report,[{'rule':'github-pat','file':'fixture.txt','line':3,'commit':'a'*40}])
        for private in ['synthetic-secret-do-not-publish','private-match','private-name','private@example.invalid','private-message']:
            self.assertNotIn(private,str(report))

    def test_bad_shapes_and_escaping_paths_fail_instead_of_passing_scan(self):
        with self.assertRaises(ValueError):safe_findings({},Path.cwd())
        for key,value in [('File','../escape'),('File','foo\nsecret'),('RuleID','secret\n'),('StartLine',True),('StartLine',0),('Commit','not-a-commit')]:
            record=self.fixture();record[key]=value
            with self.subTest(key=key,value=value),self.assertRaises(ValueError):safe_findings([record],Path.cwd())

    def test_scanner_errors_never_become_zero_candidates_success(self):
        self.assertEqual(scan_result(0,[]),0)
        self.assertEqual(scan_result(1,[{}]),1)
        for code,findings in [(1,[]),(2,[]),(0,[{}]),(-1,[])]:
            with self.subTest(code=code),self.assertRaises(RuntimeError):scan_result(code,findings)
