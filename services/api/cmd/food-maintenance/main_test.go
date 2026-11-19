package main

import (
	"bytes"
	"strings"
	"testing"
)

func TestMaintenanceRejectsUnsafeOrUnconfirmedBeforeConnection(t *testing.T) {
	for _, args := range [][]string{{"--operation", "approve", "--id", "00000000-0000-4000-8000-000000000001"}, {"--operation", "export-approved", "--confirm", "unrelated"}, {"--operation", "unknown"}, {"--operation", "show"}} {
		if e := run(args, func(string) string { return "" }, &bytes.Buffer{}); e == nil {
			t.Fatal("unsafe command accepted")
		}
	}
	e := run([]string{}, func(string) string { return "postgres://user:secret@example.invalid/database" }, &bytes.Buffer{})
	if e == nil || strings.Contains(e.Error(), "secret") {
		t.Fatal("unsafe target or credential leakage")
	}
}
