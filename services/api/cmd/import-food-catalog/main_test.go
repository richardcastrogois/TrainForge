package main

import (
	"bytes"
	"testing"
)

func TestCatalogImporterRejectsUnknownOperationWithoutDatabase(t *testing.T) {
	called := false
	e := run([]string{"--operation", "publish-everything"}, func(string) string { called = true; return "" }, &bytes.Buffer{})
	if e == nil || called {
		t.Fatal("unknown operation reached database configuration")
	}
}
