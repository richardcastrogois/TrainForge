package config

import (
	"errors"
	"net"
	"net/netip"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	ListenAddr     string
	DatabaseURL    string
	Environment    string
	MaxConns       int32
	RequestTimeout time.Duration
	GoogleAudience string
	TrustedProxies []netip.Prefix
	Swagger        bool
}

// Load only consumes this service's names; legacy DATABASE_URL is never inherited.
func Load(get func(string) string) (Config, error) {
	c := Config{ListenAddr: "127.0.0.1:8082", Environment: "development", MaxConns: 10, RequestTimeout: 10 * time.Second}
	if v := get("TF_LISTEN_ADDR"); v != "" {
		c.ListenAddr = v
	}
	host, port, err := net.SplitHostPort(c.ListenAddr)
	if err != nil {
		return c, errors.New("invalid TF_LISTEN_ADDR")
	}
	n, err := strconv.Atoi(port)
	if err != nil || n < 1 || n > 65535 {
		return c, errors.New("invalid listen port")
	}
	c.GoogleAudience = strings.TrimSpace(get("TF_GOOGLE_SERVER_CLIENT_ID"))
	if c.GoogleAudience != "" && (!strings.HasSuffix(c.GoogleAudience, ".apps.googleusercontent.com") || strings.ContainsAny(c.GoogleAudience, " ,;\t\r\n")) {
		return c, errors.New("invalid TF_GOOGLE_SERVER_CLIENT_ID")
	}
	if raw := strings.TrimSpace(get("TF_TRUSTED_PROXY_CIDRS")); raw != "" {
		values := strings.Split(raw, ",")
		if len(values) > 16 {
			return c, errors.New("too many trusted proxy prefixes")
		}
		for _, value := range values {
			prefix, err := netip.ParsePrefix(strings.TrimSpace(value))
			if err != nil || prefix.Bits() == 0 {
				return c, errors.New("invalid TF_TRUSTED_PROXY_CIDRS")
			}
			c.TrustedProxies = append(c.TrustedProxies, prefix.Masked())
		}
	}
	c.DatabaseURL = get("TF_DATABASE_URL")
	if v := get("TF_ENV"); v != "" {
		c.Environment = v
	}
	if c.Environment != "development" && c.Environment != "test" && c.Environment != "production" {
		return c, errors.New("invalid TF_ENV")
	}
	if v := get("TF_DB_MAX_CONNS"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil || n < 1 || n > 50 {
			return c, errors.New("invalid TF_DB_MAX_CONNS")
		}
		c.MaxConns = int32(n)
	}
	if v := get("TF_REQUEST_TIMEOUT_SECONDS"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil || n < 1 || n > 30 {
			return c, errors.New("invalid request timeout")
		}
		c.RequestTimeout = time.Duration(n) * time.Second
	}
	if v := get("TF_SWAGGER"); v != "" {
		c.Swagger, err = strconv.ParseBool(v)
		if err != nil {
			return c, errors.New("invalid TF_SWAGGER")
		}
	}
	if c.Swagger && (c.Environment == "production" || (host != "127.0.0.1" && host != "::1" && host != "localhost")) {
		return c, errors.New("interactive Swagger is restricted to local development")
	}
	return c, nil
}
