package migrations

import "embed"

// Files is the only migration corpus for this service.
//
//go:embed *.sql
var Files embed.FS
