package config

import "testing"

func TestLocalCatalogConfigurationRequiresKnownModeAndRejectsProduction(t *testing.T) {
	base := map[string]string{"TF_CATALOG_URL": "http://127.0.0.1:18083", "TF_CATALOG_READ_MODE": "local-verified"}
	if _, e := Load(func(k string) string { return base[k] }); e != nil {
		t.Fatal("explicit local rollback refused")
	}
	for _, change := range []map[string]string{{"TF_ENV": "production"}, {"TF_CATALOG_READ_MODE": "fallback"}, {"TF_CATALOG_URL": "http://external.invalid"}, {"TF_CATALOG_URL": ""}} {
		copy := map[string]string{}
		for k, v := range base {
			copy[k] = v
		}
		for k, v := range change {
			copy[k] = v
		}
		if _, e := Load(func(k string) string { return copy[k] }); e == nil {
			t.Fatal("unsafe local catalog mode accepted")
		}
	}
}
