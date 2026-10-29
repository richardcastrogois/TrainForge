package httpapi

// Method is a bounded diagnostic category, never the arbitrary client string.
func methodLabel(method string) string {
	switch method {
	case "GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS":
		return method
	default:
		return "OTHER"
	}
}

// ServeMux patterns come from registered server routes, not URL/path values.
// An early network/admission rejection has no matched route.
func routeLabel(pattern string) string {
	if pattern == "" {
		return "unmatched"
	}
	return pattern
}
