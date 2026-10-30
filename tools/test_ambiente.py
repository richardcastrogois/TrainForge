import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

import ambiente


class EnvironmentSafety(unittest.TestCase):
    def test_stop_paths_cannot_escape_registered_directory(self):
        with tempfile.TemporaryDirectory() as folder:
            base = Path(folder)
            self.assertEqual(ambiente.stop_path(str(base/'api-stop-0123456789abcdef.flag'),
                                               base, r'api-stop-[a-f0-9]{16}\.flag').parent, base.resolve())
            for value in ['', str(base/'../other.flag'), str(base/'anything.env')]:
                with self.subTest(value=value), self.assertRaises(RuntimeError):
                    ambiente.stop_path(value, base, r'api-stop-[a-f0-9]{16}\.flag')

    def test_other_checkout_listener_is_not_stopped(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder)/'runtime.json'
            path.write_text(json.dumps({'root': 'other-checkout'}))
            with mock.patch.object(ambiente.database, 'verify_owned'), \
                 mock.patch.object(ambiente, 'listening', return_value=True), \
                 mock.patch.object(ambiente.android, 'STATE', path), \
                 mock.patch.object(Path, 'touch', side_effect=AssertionError('must not mutate')):
                with self.assertRaises(RuntimeError):
                    ambiente.stop_plan()

    def test_start_order_never_calls_catalog_activation(self):
        calls = []
        with mock.patch.object(ambiente.database, 'start', side_effect=lambda: calls.append('db')), \
             mock.patch.object(ambiente.catalog, 'owned_state', return_value={'fixture': True}), \
             mock.patch.object(ambiente.catalog, 'start_reader', side_effect=lambda _: calls.append('catalog')), \
             mock.patch.object(ambiente.catalog, 'activate', side_effect=AssertionError('no migration')), \
             mock.patch.object(ambiente.android, 'paths', return_value={}), \
             mock.patch.object(ambiente.android, 'start', side_effect=lambda _: calls.append('android')):
            ambiente.start()
        self.assertEqual(calls, ['db', 'catalog', 'android'])

    def test_database_does_not_stop_when_service_refuses_to_exit(self):
        with tempfile.TemporaryDirectory() as folder:
            flag = Path(folder)/'owned.flag'
            with mock.patch.object(ambiente, 'stop_plan', return_value=[('api', flag, 8082)]), \
                 mock.patch.object(ambiente.android, 'wait_for', side_effect=RuntimeError('still running')), \
                 mock.patch.object(ambiente.database, 'run', side_effect=AssertionError('db must survive')):
                with self.assertRaises(RuntimeError):
                    ambiente.stop()
            self.assertTrue(flag.exists())


if __name__ == '__main__':
    unittest.main()
