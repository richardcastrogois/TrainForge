"""Verificações de comportamento: sem conectar app, banco ou serviços externos."""
import copy
import json
import tempfile
import threading
import unittest
import urllib.error
import urllib.request
from http.server import ThreadingHTTPServer
from pathlib import Path
from unittest.mock import patch

import painel_projeto as p


class InventoryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.backlog = json.loads(p.read(p.BACKLOG))
        cls.plan = json.loads(p.read(p.PLAN))

    def test_placeholder_paths_match_without_matching_another_action(self):
        self.assertEqual(p.normalized('/mobile/workout-plans/$planId/days/${dayId}'), p.normalized('/mobile/workout-plans/:id/days/:day'))
        self.assertNotEqual(p.normalized('/sessions/$id/events'), p.normalized('/sessions/:id'))

    def test_dynamic_dart_paths_are_not_invented(self):
        with tempfile.TemporaryDirectory() as directory:
            file = Path(directory) / 'api.dart'
            file.write_text("dio.post('/sessions/$id', data: {'quantity': value});\ndio.get(dynamicPath);", encoding='utf-8')
            calls = p.dart_calls(file)
            self.assertEqual(len(calls), 1)
            self.assertEqual(calls[0]['method'], 'POST')
            self.assertEqual(calls[0]['bodyKeys'], ['quantity'])

    def test_real_contract_inventory_and_coverage(self):
        actual = p.scan()
        self.assertTrue(actual['coverage']['apiAvailable'])
        auth = next(c for c in actual['calls'] if c['path'] == '/mobile-auth/google')
        self.assertEqual(auth['method'], 'POST')
        self.assertTrue(auth['matches'])
        self.assertIn('idToken', auth['bodyKeys'])
        self.assertIn('WorkoutSession', [m['name'] for m in actual['models']])
        self.assertTrue(all(c['source']['line'] > 0 for c in actual['calls']))

    def test_missing_backend_is_explicit(self):
        with tempfile.TemporaryDirectory() as directory:
            actual = p.scan(Path(directory))
            # Diretório existe, mas sem index/schema; chamadas ficam não resolvidas.
            self.assertFalse(actual['coverage']['apiAvailable'])
            self.assertEqual(actual['routes'], [])
            self.assertEqual(actual['coverage']['matchedCalls'], 0)
            self.assertEqual(actual['models'], [])

    def test_backlog_rejects_cycle_and_unevidenced_done(self):
        backlog = copy.deepcopy(self.backlog)
        first = backlog['epics'][0]['stories'][0]
        first['dependsOn'] = [first['id']]
        first['status'] = 'done'
        errors = p.validate(backlog, self.plan)
        self.assertTrue(any('cíclica' in e for e in errors))
        self.assertTrue(any('conclusão sem evidência' in e for e in errors))

    def test_source_backlog_and_plan_are_consistent(self):
        self.assertEqual(p.validate(self.backlog, self.plan), [])
        self.assertEqual(p.read(p.BACKLOG.parent / 'backlog.md'), p.backlog_markdown(self.backlog))

    def test_watcher_reloads_changed_planning_without_restart(self):
        with tempfile.TemporaryDirectory() as directory:
            backlog_path = Path(directory) / 'backlog.json'
            backlog_path.write_text(json.dumps(self.backlog), encoding='utf-8')
            with patch.object(p, 'BACKLOG', backlog_path):
                state = p.ProjectState(p.DEFAULT_API)
                before = state.get()
                updated = copy.deepcopy(self.backlog)
                updated['next'] = 'V1-003'
                backlog_path.write_text(json.dumps(updated) + '\n', encoding='utf-8')
                after = state.get()
                self.assertNotEqual(before['revision'], after['revision'])
                self.assertEqual(after['backlog']['next'], 'V1-003')

    def test_http_allowlist_and_host_origin_protection(self):
        server = ThreadingHTTPServer(('127.0.0.1', 0), p.handler(p.ProjectState(p.DEFAULT_API)))
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        base = 'http://127.0.0.1:' + str(server.server_port)
        try:
            with urllib.request.urlopen(base + '/api/health') as response:
                self.assertEqual(json.load(response)['service'], 'project-map')
            for path in ('/.env', '/%2e%2e/AGENTS.md', '/docs/conteudo/fontes.json'):
                with self.assertRaises(urllib.error.HTTPError) as error:
                    urllib.request.urlopen(base + path)
                self.assertEqual(error.exception.code, 404)
            for headers in ({'Host': 'attacker.example'}, {'Origin': 'https://attacker.example'}):
                with self.assertRaises(urllib.error.HTTPError) as error:
                    urllib.request.urlopen(urllib.request.Request(base + '/api/mapa', headers=headers))
                self.assertEqual(error.exception.code, 403)
            with urllib.request.urlopen(base + '/') as response:
                self.assertIn("default-src 'self'", response.headers['Content-Security-Policy'])
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=2)


if __name__ == '__main__':
    unittest.main()
