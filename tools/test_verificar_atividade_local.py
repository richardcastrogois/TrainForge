import json
from contextlib import ExitStack
from pathlib import Path
import unittest
from unittest.mock import Mock, patch

import verificar_atividade_local as activity


class ActivityDisposableGuards(unittest.TestCase):
    name = "trainforge_v1_activity_test_012345abcdef"

    def dsn(self, role="runtime", **changes):
        parts = dict(host="127.0.0.1", port="15432", name=self.name, role=role, query="sslmode=disable")
        parts.update(changes)
        return "postgresql://trainforge_{role}:fixture-password@{host}:{port}/{name}?{query}".format(**parts)

    def test_exact_disposable_name_and_roles_are_required(self):
        self.assertEqual(activity.disposable_name(self.name), self.name)
        for name in ["trainforge_v1_dev", "postgres", "trainforge_v1_activity_test_abc", self.name + ";DROP DATABASE postgres", None]:
            with self.subTest(name=name), self.assertRaises(RuntimeError):
                activity.disposable_name(name)
        for role in ("migrator", "runtime"):
            self.assertEqual(activity.target(self.dsn(role), self.name, role), self.dsn(role))

    def test_effective_connection_overrides_and_wrong_destination_are_refused(self):
        invalid = [self.dsn(host="localhost"), self.dsn(host="example.invalid"), self.dsn(port="5432"),
                   self.dsn(name="trainforge_v1_dev"), self.dsn(role="owner"),
                   self.dsn(query="sslmode=disable&host=example.invalid"), self.dsn(query="sslmode=disable&port=5432"),
                   self.dsn(query="sslmode=disable&dbname=trainforge_v1_dev"),
                   self.dsn(query="sslmode=disable&sslmode=prefer"), self.dsn(query=""),
                   self.dsn() + "#fragment", self.dsn().replace("fixture-password", "")]
        for dsn in invalid:
            with self.subTest(target=dsn), self.assertRaises(RuntimeError):
                activity.target(dsn, self.name, "runtime")

    def test_stopped_or_unregistered_cluster_cannot_start_or_create_a_database(self):
        for failing in ("verify_owned", "run"):
            with self.subTest(failing=failing), patch.object(activity, "verify_owned") as owned, \
                    patch.object(activity, "run") as status, patch.object(activity, "sql") as sql, \
                    patch.object(activity, "environment") as environment:
                (owned if failing == "verify_owned" else status).side_effect = RuntimeError("not available")
                with self.assertRaises(RuntimeError):
                    activity.main()
                sql.assert_not_called()
                environment.assert_not_called()
                if failing == "run":
                    self.assertEqual(status.call_args.args[1][-1], "status")

    def test_snapshot_inventories_every_user_table_and_returns_only_digests(self):
        responses = [json.dumps([["public", "trainforge_v1_schema_version"], ["trainforge_v1", "users"],
                                 ["trainforge_v1", "activity_events"]]), "digest-schema", "digest-users", "empty"]
        with patch.object(activity, "sql", side_effect=responses) as sql:
            actual = activity.snapshot()
        self.assertEqual(actual, {"public.trainforge_v1_schema_version": "digest-schema",
                                  "trainforge_v1.users": "digest-users", "trainforge_v1.activity_events": "empty"})
        self.assertEqual(sql.call_count, 4)
        for call in sql.call_args_list:
            self.assertEqual(call.args[1], "trainforge_v1_dev")
        self.assertTrue(all("md5(" in call.args[0] for call in sql.call_args_list[1:]))

    def test_snapshot_rejects_unexpected_identifiers_and_empty_inventory(self):
        for payload in ([], [["trainforge_v1", "users;DROP DATABASE postgres"]], [["public", "bad-name"]]):
            with self.subTest(payload=payload), patch.object(activity, "sql", return_value=json.dumps(payload)) as sql:
                with self.assertRaises(RuntimeError):
                    activity.snapshot()
                self.assertEqual(sql.call_count, 1)

    def test_failure_never_echoes_the_process_command_or_output(self):
        result = type("Result", (), {"returncode": 1, "stdout": json.dumps({
            "Output": "    postgres_test.go:123: token=fixture-secret private-person\n"})})()
        with patch.object(activity.subprocess, "run", return_value=result), self.assertRaises(RuntimeError) as caught:
            activity.checked_process(["go", "token=fixture-secret"], {}, 2)
        self.assertIn("postgres_test.go", str(caught.exception))
        self.assertNotIn("fixture-secret", str(caught.exception))
        self.assertNotIn("private-person", str(caught.exception))

    def isolated_main(self, *, test_action="pass", exists=False, after=None, drop_error=False):
        """Replace every DB/process/credential boundary, not the destination guards."""
        stack = ExitStack()
        self.addCleanup(stack.close)
        owned = stack.enter_context(patch.object(activity, "verify_owned"))
        status = stack.enter_context(patch.object(activity, "run"))
        stack.enter_context(patch.object(activity.secrets, "token_hex", return_value="012345abcdef"))
        before = {"trainforge_v1.users": "same", "public.trainforge_v1_schema_version": "same"}
        snapshots = stack.enter_context(patch.object(activity, "snapshot", side_effect=[before, before if after is None else after]))
        stack.enter_context(patch.object(activity, "load_env", return_value={
            "TF_MIGRATION_DATABASE_URL": self.dsn("migrator", name="trainforge_v1_dev"),
            "TF_DATABASE_URL": self.dsn("runtime", name="trainforge_v1_dev"),
        }))
        sdk = stack.enter_context(patch.object(activity, "environment", return_value=({}, Path("fixture-go"))))
        def query(statement, *args):
            if statement.startswith("SELECT count(*) FROM pg_database"):
                return "1" if exists else "0"
            if drop_error and statement.startswith("DROP DATABASE"):
                raise RuntimeError("fixture drop failed")
            return ""
        sql = stack.enter_context(patch.object(activity, "sql", side_effect=query))
        output = "\n".join(json.dumps({"Action": test_action, "Test": name}) for name in activity.EXPECTED_TESTS)
        process = stack.enter_context(patch.object(activity, "checked_process", side_effect=["", output]))
        grants = stack.enter_context(patch.object(activity, "grant_runtime"))
        receipt = stack.enter_context(patch.object(activity, "RECEIPT", Mock()))
        stack.enter_context(patch("builtins.print"))
        return dict(owned=owned, status=status, snapshots=snapshots, sdk=sdk, sql=sql,
                    process=process, grants=grants, receipt=receipt)

    def test_main_only_migrates_a_fresh_disposable_and_cleans_it_before_receipt(self):
        mocks = self.isolated_main()
        activity.main()
        mocks["sdk"].assert_called_once_with(include_api_env=False)
        mocks["grants"].assert_called_once_with(self.name)
        statements = [call.args[0] for call in mocks["sql"].call_args_list]
        self.assertTrue(any(s.startswith("CREATE DATABASE " + self.name + " ") for s in statements))
        self.assertEqual(statements[-1], "DROP DATABASE " + self.name + ";")
        self.assertTrue(all("trainforge_v1_dev" not in s for s in statements))
        commands = mocks["process"].call_args_list
        self.assertEqual(commands[0].args[0][-2:], ["run", "./cmd/migrate"])
        self.assertIn("-json", commands[1].args[0])
        for call in commands:
            self.assertIn("/" + self.name + "?", call.args[1]["TF_MIGRATION_DATABASE_URL"])
            self.assertNotIn("TF_DATABASE_URL", call.args[1])
        self.assertEqual(mocks["snapshots"].call_count, 2)
        written = json.loads(mocks["receipt"].write_text.call_args.args[0])
        self.assertTrue(written["allDeliveredTablesUnchanged"])
        self.assertFalse(written["deliveredSchemaMigrated"])
        self.assertFalse(written["clusterStartedOrStopped"])

    def test_skipped_sql_drops_fixture_and_cannot_generate_a_success_receipt(self):
        mocks = self.isolated_main(test_action="skip")
        with self.assertRaises(RuntimeError):
            activity.main()
        self.assertEqual(mocks["sql"].call_args_list[-1].args[0], "DROP DATABASE " + self.name + ";")
        self.assertEqual(mocks["snapshots"].call_count, 2)
        mocks["receipt"].write_text.assert_not_called()

    def test_existing_database_is_not_overwritten_or_removed(self):
        mocks = self.isolated_main(exists=True)
        with self.assertRaises(RuntimeError):
            activity.main()
        self.assertEqual(mocks["sql"].call_count, 1)
        mocks["process"].assert_not_called()
        mocks["grants"].assert_not_called()
        mocks["receipt"].write_text.assert_not_called()

    def test_drop_failure_still_checks_delivered_rows_and_never_reports_success(self):
        mocks = self.isolated_main(drop_error=True)
        with self.assertRaises(RuntimeError):
            activity.main()
        self.assertEqual(mocks["snapshots"].call_count, 2)
        mocks["receipt"].write_text.assert_not_called()


if __name__ == "__main__":
    unittest.main()
