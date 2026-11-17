from pathlib import Path
from contextlib import redirect_stdout,redirect_stderr
import hashlib
import io
import json
import stat
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import zipfile
import evidence_store
from secret_ci import safe_findings,scan_result,safe_archive_findings,scan_archives,validated_archives


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


class DocumentaryArchiveGuards(unittest.TestCase):
    def setUp(self):
        temporary=tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root=Path(temporary.name).resolve()
        self.public_line='"access": "ordinary public research note"'
        self.keys=['docs/conteudo/evidencias/fixture.json','docs/old-guide.md']
        self.archives=[]
        for index,name,key in zip(evidence_store.INDEXES,
                ['pesquisas.zip','memoria-documental.zip'],self.keys):
            path=self.root/index
            path.parent.mkdir(parents=True,exist_ok=True)
            archive=path.parent/name
            self.archives.append(archive)
            self.bundle(path,archive,key,self.public_line+'\n')
        self.review={(self.keys[0],'generic-api-key',
                      hashlib.sha256(self.public_line.encode()).hexdigest()):'natural_language_research_note'}
        self.private=self.root/'.local/archive-scan'

    def bundle(self,index,archive,key,text,extra=None):
        value=text.encode('utf-8')
        with zipfile.ZipFile(archive,'w') as bundle:
            bundle.writestr(key,value)
            if extra is not None:bundle.writestr(extra,b'unindexed fixture')
        index.write_text(json.dumps({'schemaVersion':1,'archive':archive.name,
            'files':[{'path':key,'bytes':len(value),'sha256':hashlib.sha256(value).hexdigest()}]}),encoding='utf-8')
        evidence_store._records.cache_clear()

    def finding(self,key=None,archive=None):
        archive=self.archives[0] if archive is None else archive
        return {'RuleID':'generic-api-key','StartLine':1,
                'File':archive.relative_to(self.root).as_posix()+'!'+(key or self.keys[0]),
                'Secret':'private-fixture-secret','Match':'private-fixture-match',
                'Author':'private-fixture-author','Commit':'untrusted-not-a-commit'}

    def scanner(self,reports,code=None,after=None):
        def run(command,**kwargs):
            raw=Path(next(item.split('=',1)[1] for item in command if item.startswith('--report-path=')))
            values=reports.get(command[-1],[])
            raw.write_text(json.dumps(values),encoding='utf-8')
            if after is not None:after(command)
            return subprocess.CompletedProcess(command,
                (1 if values else 0) if code is None else code,
                stdout=b'private-scanner-output')
        return run

    def test_exact_review_uses_original_member_without_publishing_raw_values(self):
        relative=self.archives[0].relative_to(self.root).as_posix()
        current=self.root/self.keys[0]
        current.parent.mkdir(parents=True,exist_ok=True)
        current.write_text('current guide differs from original archived bytes',encoding='utf-8')
        public=io.StringIO()
        with patch('secret_ci.subprocess.run',side_effect=self.scanner({relative:[self.finding()]})) as run,redirect_stdout(public),redirect_stderr(public):
            result=scan_archives('fixture-scanner',self.root,self.private,self.review)
        self.assertEqual(result['candidateCount'],1)
        self.assertEqual(result['blockingCandidateCount'],0)
        self.assertEqual(result['findings'][0],{'rule':'generic-api-key','file':self.keys[0],
            'line':1,'archive':relative,'classification':'reviewed_nonsecret:natural_language_research_note','blocking':False})
        self.assertEqual(len(result['archives']),2)
        self.assertEqual(public.getvalue(),'')
        for private in ['private-fixture-secret','private-fixture-match','private-fixture-author',
                        'private-scanner-output','untrusted-not-a-commit']:
            self.assertNotIn(private,json.dumps(result))
        self.assertEqual(run.call_count,2)
        for call in run.call_args_list:
            self.assertEqual(call.args[0][1],'dir')
            for flag in ['--redact=100','--ignore-gitleaks-allow','--max-archive-depth=2','--report-format=json']:
                self.assertIn(flag,call.args[0])
            self.assertEqual(call.kwargs['cwd'],self.root)
            self.assertEqual(call.kwargs['stdout'],subprocess.PIPE)
            self.assertEqual(call.kwargs['stderr'],subprocess.STDOUT)
        self.assertEqual(len(list(self.private.glob('*-raw.json'))),2)

    def test_known_nonsecret_at_another_indexed_path_is_still_blocking(self):
        key='docs/conteudo/evidencias/different-fixture.json'
        self.bundle(self.root/evidence_store.INDEXES[0],self.archives[0],key,self.public_line+'\n')
        relative=self.archives[0].relative_to(self.root).as_posix()
        with patch('secret_ci.subprocess.run',side_effect=self.scanner({relative:[self.finding(key)]})):
            result=scan_archives('fixture-scanner',self.root,self.private,self.review)
        self.assertEqual(result['blockingCandidateCount'],1)
        self.assertEqual(result['findings'][0]['classification'],'requires_review')

    def test_unknown_value_at_a_reviewed_path_is_blocking(self):
        self.bundle(self.root/evidence_store.INDEXES[0],self.archives[0],self.keys[0],
                    'access=synthetic-unknown-fixture-value\n')
        relative=self.archives[0].relative_to(self.root).as_posix()
        with patch('secret_ci.subprocess.run',side_effect=self.scanner({relative:[self.finding()]})):
            result=scan_archives('fixture-scanner',self.root,self.private,self.review)
        self.assertEqual(result['blockingCandidateCount'],1)
        self.assertEqual(result['findings'][0]['classification'],'requires_review')

    def test_reviewed_path_and_line_do_not_exempt_another_rule(self):
        finding=self.finding();finding['RuleID']='github-pat'
        relative=self.archives[0].relative_to(self.root).as_posix()
        with patch('secret_ci.subprocess.run',side_effect=self.scanner({relative:[finding]})):
            result=scan_archives('fixture-scanner',self.root,self.private,self.review)
        self.assertEqual(result['blockingCandidateCount'],1)
        self.assertEqual(result['findings'][0]['classification'],'requires_review')

    def test_url_query_never_becomes_a_review_exception(self):
        line='"url": "https://example.invalid/file?token=synthetic-fixture"'
        self.bundle(self.root/evidence_store.INDEXES[0],self.archives[0],self.keys[0],line+'\n')
        review={(self.keys[0],'generic-api-key',hashlib.sha256(line.encode()).hexdigest()):'natural_language_research_note'}
        relative=self.archives[0].relative_to(self.root).as_posix()
        with patch('secret_ci.subprocess.run',side_effect=self.scanner({relative:[self.finding()]})):
            result=scan_archives('fixture-scanner',self.root,self.private,review)
        self.assertEqual(result['blockingCandidateCount'],1)
        self.assertEqual(result['findings'][0]['classification'],'historical_url_query')

    def test_unindexed_zip_members_and_zip_slip_block_before_scanner_runs(self):
        for extra in ['docs/unindexed.txt','docs/../../escape.txt','../escape.txt','docs/folder/']:
            self.bundle(self.root/evidence_store.INDEXES[0],self.archives[0],self.keys[0],
                        self.public_line+'\n',extra)
            with self.subTest(extra=extra),patch('secret_ci.subprocess.run') as run:
                with self.assertRaises(ValueError):
                    scan_archives('fixture-scanner',self.root,self.private,self.review)
                run.assert_not_called()

    def test_digest_mismatch_and_missing_index_cannot_pass_empty_scan(self):
        with zipfile.ZipFile(self.archives[0],'w') as bundle:
            bundle.writestr(self.keys[0],b'different indexed bytes')
        with patch('secret_ci.subprocess.run') as run,self.assertRaises(ValueError):
            scan_archives('fixture-scanner',self.root,self.private,self.review)
        run.assert_not_called()
        (self.root/evidence_store.INDEXES[1]).unlink()
        with self.assertRaises(ValueError):validated_archives(self.root)

    def test_symlink_metadata_cannot_hide_an_indexed_member_from_scanner(self):
        info=zipfile.ZipInfo(self.keys[0]);info.create_system=3
        info.external_attr=(stat.S_IFLNK|0o777)<<16
        with zipfile.ZipFile(self.archives[0],'w') as bundle:
            bundle.writestr(info,(self.public_line+'\n').encode())
        with patch('secret_ci.subprocess.run') as run,self.assertRaises(ValueError):
            scan_archives('fixture-scanner',self.root,self.private,self.review)
        run.assert_not_called()

    def test_unindexed_and_wrong_archive_finding_locators_are_rejected(self):
        groups=validated_archives(self.root)
        rows=groups[self.archives[0]]
        wrong=[self.finding('docs/not-indexed.json'),self.finding('../escape.json'),
               self.finding(self.keys[0]+'!nested.json'),self.finding(archive=self.archives[1])]
        for finding in wrong:
            with self.subTest(locator=finding['File']),self.assertRaises(ValueError):
                safe_archive_findings([finding],self.root,self.archives[0],rows)
        for field,value in [('RuleID','invalid\nrule'),('StartLine',True),('StartLine',0),('File','bad\nlocator')]:
            finding=self.finding();finding[field]=value
            with self.subTest(field=field),self.assertRaises(ValueError):
                safe_archive_findings([finding],self.root,self.archives[0],rows)

    def test_scanner_exit_report_mismatch_fails_closed(self):
        relative=self.archives[0].relative_to(self.root).as_posix()
        for code,report in [(2,[]),(1,[]),(0,[self.finding()])]:
            with self.subTest(code=code),patch('secret_ci.subprocess.run',side_effect=self.scanner({relative:report},code)):
                with self.assertRaises(RuntimeError):scan_archives('fixture-scanner',self.root,self.private,self.review)

    def test_archive_mutation_and_public_raw_destination_are_rejected(self):
        changed=False
        def mutate(_command):
            nonlocal changed
            if not changed:
                changed=True
                with zipfile.ZipFile(self.archives[1],'a') as bundle:
                    bundle.writestr('docs/late-addition.txt',b'unindexed late fixture')
        with patch('secret_ci.subprocess.run',side_effect=self.scanner({},after=mutate)),self.assertRaises(ValueError):
            scan_archives('fixture-scanner',self.root,self.private,self.review)
        with self.assertRaises(ValueError):
            scan_archives('fixture-scanner',self.root,self.root/'docs/public-reports',self.review)

    def test_missing_new_report_never_reuses_a_previous_scan(self):
        self.private.mkdir(parents=True)
        (self.private/'archive-0-raw.json').write_text('[]',encoding='utf-8')
        result=subprocess.CompletedProcess(['fixture-scanner'],0,stdout=b'private-scanner-output')
        with patch('secret_ci.subprocess.run',return_value=result),self.assertRaises(FileNotFoundError):
            scan_archives('fixture-scanner',self.root,self.private,self.review)
