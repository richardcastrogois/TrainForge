"""Connection guards for the destructive disposable-name test lifecycle; no DB calls."""
import unittest
from verificar_nomes_alimentares import validate_connection

class NameFixtureTargetTests(unittest.TestCase):
    def test_only_explicit_local_disposable_target_is_allowed(self):
        name = "trainforge_v1_names_test_0123456789ab"
        for role in ["trainforge_migrator", "trainforge_runtime"]:
            validate_connection("postgresql://" + role + ":fixture@127.0.0.1:15432/" + name, role, name)

    def test_real_foreign_or_cross_role_connection_is_rejected(self):
        name = "trainforge_v1_names_test_0123456789ab"
        for dsn in [
            "postgresql://trainforge_migrator:fixture@127.0.0.1:15432/trainforge_v1_dev",
            "postgresql://trainforge_migrator:fixture@remote.invalid:15432/" + name,
            "postgresql://trainforge_migrator:fixture@127.0.0.1:5432/" + name,
            "postgresql://trainforge_runtime:fixture@127.0.0.1:15432/" + name,
            "postgresql://trainforge_migrator:fixture@127.0.0.1:15432/" + name + "_other",
        ]:
            with self.subTest(target=dsn):
                with self.assertRaises(RuntimeError):
                    validate_connection(dsn, "trainforge_migrator", name)

    def test_cleanup_identity_cannot_be_the_real_database(self):
        with self.assertRaises(RuntimeError):
            validate_connection("postgresql://trainforge_migrator:fixture@127.0.0.1:15432/trainforge_v1_dev", "trainforge_migrator", "trainforge_v1_dev")
        with self.assertRaises(RuntimeError):
            validate_connection("postgresql://trainforge_owner:fixture@127.0.0.1:15432/trainforge_v1_names_test_0123456789ab", "trainforge_owner", "trainforge_v1_names_test_0123456789ab")

if __name__ == "__main__":
    unittest.main()
