package main

import (
	"strings"
	"testing"
)

func TestTargetRequiresExplicitCoreAndMode(t *testing.T) {
	for _, key := range []string{"PGSERVICE", "PGSERVICEFILE", "PGPASSFILE"} {
		t.Setenv(key, "")
	}
	base := "postgresql://trainforge_migrator:fixture-only@127.0.0.1:15432/"
	if _, e := coreTarget(base+"trainforge_v1_dev?sslmode=disable", true); e != nil {
		t.Fatal("owned local target refused")
	}
	if _, e := coreTarget(base+"trainforge_v1_dev?sslmode=disable", false); e == nil {
		t.Fatal("fixture mode accepted real target")
	}
	if _, e := coreTarget(base+"trainforge_v1_config_test_012345abcdef?sslmode=disable", false); e != nil {
		t.Fatal("fixture refused")
	}
	for _, bad := range []string{strings.Replace(base, "127.0.0.1", "external.invalid", 1) + "trainforge_v1_dev?sslmode=disable", base + "postgres?sslmode=disable", base + "trainforge_v1_dev?sslmode=disable&options=x", base + "trainforge_v1_dev?sslmode=disable#x"} {
		if _, e := coreTarget(bad, true); e == nil {
			t.Fatal("unsafe core target accepted")
		}
	}
}
