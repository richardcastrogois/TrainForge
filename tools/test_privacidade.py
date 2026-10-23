"""Safety boundaries of the administrative restore wrapper; no database contacted."""
import contextlib
import io
import unittest
from unittest.mock import patch
import aplicar_exclusoes_restore as restore

class RestoreBoundaryTests(unittest.TestCase):
    def invoke(self, target, results, extra=()):
        with patch("sys.argv", ["restore", "--target-database", target, *extra]), \
             patch.object(restore, "verify_owned") as owned, \
             patch.object(restore, "sql", side_effect=results) as sql, \
             patch.object(restore.subprocess, "run") as run, \
             contextlib.redirect_stdout(io.StringIO()) as output:
            restore.main()
            return owned, sql, run, output.getvalue()

    def test_live_or_unescaped_target_rejected_before_database_access(self):
        for target in ("trainforge_v1_dev", "trainforge_v1_privacy_restore_'", "trainforge_v1_privacy_restore_ABCDEF123456"):
            with self.subTest(target=target), patch.object(restore, "verify_owned") as owned:
                with self.assertRaisesRegex(RuntimeError, "target refused"):
                    with patch("sys.argv", ["restore", "--target-database", target]):
                        restore.main()
                owned.assert_not_called()

    def test_default_preview_never_runs_destructive_command(self):
        _, sql, run, output = self.invoke("trainforge_v1_privacy_restore_abcdef123456", ["1", "0", "1", "7"])
        self.assertEqual(sql.call_count, 4)
        run.assert_not_called()
        self.assertIn('"targetModified": false', output)
        self.assertIn('"sourceErasureRecords": 7', output)

    def test_missing_database_or_active_connections_or_missing_migration_refused(self):
        for results, reason in ((["0"], "does not exist"), (["1", "2"], "has connections"), (["1", "0", "0"], "migrations")):
            with self.subTest(reason=reason), self.assertRaisesRegex(RuntimeError, reason):
                self.invoke("trainforge_v1_privacy_restore_abcdef123456", results, ["--apply"])

if __name__ == "__main__":
    unittest.main()
