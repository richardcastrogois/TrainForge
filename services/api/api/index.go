// Package handler is the Vercel serverless entry point. Every route of the API
// is rewritten here (vercel.json).
package handler

import (
	"net/http"

	"trainforge.local/api/serverless"
)

func Handler(w http.ResponseWriter, r *http.Request) {
	serverless.ServeHTTP(w, r)
}
