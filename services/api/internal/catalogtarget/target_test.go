package catalogtarget

import (
	"strings"
	"testing"
)

func TestTargetRejectsMainDatabaseForeignRolesAndOverrides(t *testing.T) {
	for _, name := range []string{"PGSERVICE", "PGSERVICEFILE", "PGPASSFILE"} {
		t.Setenv(name, "")
	}
	base := "postgresql://trainforge_catalog_reader:fixture-only@127.0.0.1:15432/trainforge_catalog_test_012345abcdef?sslmode=disable"
	if _, err := Config(base, ReaderRole); err != nil {
		t.Fatal("valid explicit fixture target rejected")
	}
	for _, dsn := range []string{"", "not-a-url", strings.Replace(base, "trainforge_catalog_test_012345abcdef", "trainforge_v1_dev", 1), strings.Replace(base, "127.0.0.1", "localhost", 1), strings.Replace(base, "127.0.0.1", "remote.invalid", 1), strings.Replace(base, "15432", "5432", 1), strings.Replace(base, "trainforge_catalog_reader", "trainforge_runtime", 1), strings.Replace(base, "fixture-only@", "@", 1), strings.Replace(base, "?sslmode=disable", "", 1), base + "&options=-crole%3Dtrainforge_catalog_migrator", base + "&host=remote.invalid", base + "&sslmode=disable", strings.Replace(base, "sslmode=disable", "sslmode=require", 1), strings.Replace(base, "/trainforge_catalog_test_012345abcdef", "", 1)} {
		if _, err := Config(dsn, ReaderRole); err == nil {
			t.Fatal("unsafe target accepted")
		}
	}
	if _, err := Config(strings.Replace(base, ReaderRole, MigratorRole, 1), MigratorRole); err != nil {
		t.Fatal("migrator fixture refused")
	}
	if _, err := Config(base, MigratorRole); err == nil {
		t.Fatal("reader accepted as migrator")
	}
	t.Setenv("PGSERVICEFILE", "fixture-path-must-not-be-read")
	if _, err := Config(base, ReaderRole); err == nil {
		t.Fatal("ambient service configuration accepted")
	}
}
