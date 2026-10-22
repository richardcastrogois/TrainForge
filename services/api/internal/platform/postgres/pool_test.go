package postgres

import (
	"context"
	"strings"
	"testing"
)

func TestRejectsLegacyOrIncompleteConnectionWithoutLeakingDSN(t *testing.T) {
	for _, dsn := range []string{"postgresql://user:fixture-secret@localhost/legacy", "postgresql://", "not a DSN ??"} {
		p, err := Open(context.Background(), dsn, 10)
		if p != nil {
			p.Close()
		}
		if err == nil {
			t.Fatal("unsafe target accepted")
		}
		if strings.Contains(err.Error(), "fixture-secret") {
			t.Fatal("secret leaked")
		}
	}
}
