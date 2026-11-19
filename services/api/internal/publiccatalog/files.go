// Package publiccatalog distributes only signed public catalog artifacts.
package publiccatalog

import (
	"archive/zip"
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"time"
	"trainforge.local/api/internal/nutrition"
	"trainforge.local/api/internal/platform/httpapi"
)

type Manifest = nutrition.CatalogManifest

// SignedManifestEnvelope describes the exact signed JSON served to clients.
// Payload is base64-encoded manifest JSON; its signature covers those bytes.
type SignedManifestEnvelope struct {
	KeyID     string `json:"keyId"`
	Payload   string `json:"payload" format:"byte"`
	Signature string `json:"signature" format:"byte"`
}

type Files struct {
	Directory, ExportsDirectory, ArchivePath string
	Active                                   func(context.Context, Manifest) bool
	slots                                    chan struct{}
	once                                     sync.Once
	verification                             sync.Mutex
	verified                                 map[string]verifiedFile
}

type verifiedFile struct {
	info     os.FileInfo
	identity string
}

var exportFilename = regexp.MustCompile(`^[A-Za-z0-9_.-]+[.]jsonl[.]gz$`)
var artifactSHA = regexp.MustCompile(`^[a-f0-9]{64}$`)

func (f *Files) Register(m *http.ServeMux) {
	m.HandleFunc("GET /api/v1/food-catalog/manifest", f.ServeManifest)
	m.HandleFunc("GET /api/v1/food-catalog/archive", f.ServeArchive)
	m.HandleFunc("GET /api/v1/food-catalog/exports/{file}", f.ServeExport)
	m.HandleFunc("GET /api/v1/food-catalog/exports/{artifact}/{file}", f.ServeVersionedExport)
}

// ServeManifest returns the active signed manifest without modifying its bytes.
// @Summary Read the signed public food catalog manifest
// @Description Public metadata for the exact active distribution. Payload and Ed25519 signature are base64 encoded; clients verify against their installed trust root. Cached for 300 seconds. No account authentication is required.
// @Tags food-catalog
// @Produce json,application/problem+json
// @Param If-None-Match header string false "Quoted SHA-256 ETag of the signed manifest payload"
// @Success 200 {object} SignedManifestEnvelope
// @Success 304
// @Header 200,304 {string} ETag "Quoted SHA-256 of the signed manifest payload"
// @Header 200,304 {string} Cache-Control "public, max-age=300"
// @Failure 503 {object} httpapi.Problem "Distribution is unconfigured, untrusted or inactive"
// @Router /api/v1/food-catalog/manifest [get]
func (f *Files) ServeManifest(w http.ResponseWriter, r *http.Request) { f.serve(w, r) }

// ServeArchive streams only the verified manifest and its declared payload.
// @Summary Download the signed public food catalog update
// @Description ZIP containing exactly manifest.json and the signed catalog payload. Requires an active release and matching archive identity. Transfers use bounded memory, at most four concurrent download slots and a 30-minute request deadline; supports Range and HEAD. No account authentication is required.
// @Tags food-catalog
// @Produce application/zip,application/problem+json,text/plain
// @Param Range header string false "HTTP byte range, for example bytes=0-1048575"
// @Param If-Range header string false "ETag or last-modified date for resumable downloads"
// @Param If-None-Match header string false "Previously received ETag"
// @Success 200 {file} file "Verified catalog update ZIP"
// @Success 206 {file} file "Requested ZIP byte range"
// @Success 304
// @Header 200,206 {string} ETag "Quoted SHA-256 of the signed manifest payload"
// @Header 206 {string} Content-Range "Requested byte range and complete archive size"
// @Failure 416 {string} string "HTTP range is not satisfiable"
// @Failure 503 {object} httpapi.Problem "Distribution unavailable, integrity check failed or all download slots busy"
// @Router /api/v1/food-catalog/archive [get]
func (f *Files) ServeArchive(w http.ResponseWriter, r *http.Request) { f.serve(w, r) }

// ServeExport streams one source export declared by the current signed manifest.
// @Summary Download a source export from the current food catalog
// @Description Serves only a declared gzip JSONL source after verifying signed size, SHA-256 and active release. Query parameters are rejected. Supports Range and HEAD, four shared download slots and a 30-minute request deadline. Use the artifact-specific route to retain an older catalog source offer.
// @Tags food-catalog
// @Produce application/gzip,application/problem+json,text/plain
// @Param file path string true "Exact export filename declared by the signed manifest, ending in .jsonl.gz"
// @Param Range header string false "HTTP byte range"
// @Param If-Range header string false "ETag or last-modified date for resumable downloads"
// @Param If-None-Match header string false "Previously received export ETag"
// @Success 200 {file} file "Verified gzip JSONL source export"
// @Success 206 {file} file "Requested export byte range"
// @Success 304
// @Header 200,206 {string} ETag "Quoted SHA-256 of this source export"
// @Header 206 {string} Content-Range "Requested byte range and complete export size"
// @Failure 404 {object} httpapi.Problem "Export is undeclared, malformed or has query parameters"
// @Failure 416 {string} string "HTTP range is not satisfiable"
// @Failure 503 {object} httpapi.Problem "Current release unavailable, file integrity failed or download slots busy"
// @Router /api/v1/food-catalog/exports/{file} [get]
func (f *Files) ServeExport(w http.ResponseWriter, r *http.Request) { f.serve(w, r) }

// ServeVersionedExport preserves source offers for older active distributions.
// @Summary Download a source export for an exact food catalog artifact
// @Description Artifact is the distributed catalog SHA-256 from the installed signed manifest, not the raw SQLite checksum. The archived manifest must match this artifact and an active release, verified using the server trust root. Only declared source files are served; query parameters are rejected. Supports Range and HEAD, four shared download slots and a 30-minute request deadline.
// @Tags food-catalog
// @Produce application/gzip,application/problem+json,text/plain
// @Param artifact path string true "Lowercase 64-character SHA-256 of the signed distributed catalog artifact" minLength(64) maxLength(64)
// @Param file path string true "Exact export filename declared by this artifact manifest, ending in .jsonl.gz"
// @Param Range header string false "HTTP byte range"
// @Param If-Range header string false "ETag or last-modified date for resumable downloads"
// @Param If-None-Match header string false "Previously received export ETag"
// @Success 200 {file} file "Verified gzip JSONL source export for the requested artifact"
// @Success 206 {file} file "Requested export byte range"
// @Success 304
// @Header 200,206 {string} ETag "Quoted SHA-256 of this source export"
// @Header 206 {string} Content-Range "Requested byte range and complete export size"
// @Failure 404 {object} httpapi.Problem "Artifact is unknown, untrusted, mismatched or inactive, or export request is invalid"
// @Failure 416 {string} string "HTTP range is not satisfiable"
// @Failure 503 {object} httpapi.Problem "Source file unavailable, integrity check failed or download slots busy"
// @Router /api/v1/food-catalog/exports/{artifact}/{file} [get]
func (f *Files) ServeVersionedExport(w http.ResponseWriter, r *http.Request) { f.serve(w, r) }

func small(path string) ([]byte, error) {
	file, e := os.Open(path)
	if e != nil {
		return nil, e
	}
	defer file.Close()
	stat, e := file.Stat()
	if e != nil || !stat.Mode().IsRegular() || stat.Size() > 2<<20 {
		return nil, errors.New("invalid catalog metadata")
	}
	return io.ReadAll(io.LimitReader(file, 2<<20))
}

// The trust root is installed with the server. It never comes from an upload.
func (f *Files) manifest() ([]byte, Manifest, error) {
	return f.manifestIn(f.Directory)
}

func (f *Files) manifestIn(directory string) ([]byte, Manifest, error) {
	var payload Manifest
	if f.Directory == "" || directory == "" {
		return nil, payload, errors.New("catalog distribution unconfigured")
	}
	path := filepath.Join(directory, "manifest.json")
	payload, e := nutrition.VerifyCatalogManifest(path, filepath.Join(f.Directory, "trust.json"))
	if e != nil {
		return nil, payload, e
	}
	raw, e := small(path)
	return raw, payload, e
}

// An archived release carries only public data and a signed manifest. Its key
// always comes from the installed server trust root, never the release folder.
func (f *Files) manifestForArtifact(artifact string) ([]byte, Manifest, string, error) {
	if f.ExportsDirectory == "" || !artifactSHA.MatchString(artifact) {
		return nil, Manifest{}, "", errors.New("catalog artifact unavailable")
	}
	directory := filepath.Join(f.ExportsDirectory, artifact)
	_, e := os.Stat(filepath.Join(directory, "manifest.json"))
	if e == nil {
		raw, m, e := f.manifestIn(directory)
		if e != nil || m.SHA256 != artifact {
			return nil, Manifest{}, "", errors.New("archived catalog identity invalid")
		}
		return raw, m, directory, nil
	}
	if !os.IsNotExist(e) {
		return nil, Manifest{}, "", errors.New("archived catalog unavailable")
	}
	// Before the operator archives the current release, preserve the existing
	// public exports layout. Historical identities never resolve through latest.
	raw, m, e := f.manifest()
	if e != nil || m.SHA256 != artifact {
		return nil, Manifest{}, "", errors.New("catalog artifact unavailable")
	}
	return raw, m, f.ExportsDirectory, nil
}

func (f *Files) serve(w http.ResponseWriter, r *http.Request) {
	// Set the transfer deadline before any multi-GB verification. The request
	// context still cancels bounded reads promptly on disconnect/shutdown.
	_ = http.NewResponseController(w).SetWriteDeadline(time.Now().Add(30 * time.Minute))
	artifact := r.PathValue("artifact")
	if r.PathValue("file") != "" && (r.URL.RawQuery != "" || !exportFilename.MatchString(r.PathValue("file"))) {
		httpapi.Failure(w, r, 404, "catalog_export_unavailable")
		return
	}
	var raw []byte
	var manifest Manifest
	var e error
	exportsDirectory := f.ExportsDirectory
	if artifact != "" {
		raw, manifest, exportsDirectory, e = f.manifestForArtifact(artifact)
	} else {
		raw, manifest, e = f.manifest()
	}
	if e != nil || f.Active == nil || !f.Active(r.Context(), manifest) {
		if artifact != "" {
			httpapi.Failure(w, r, 404, "catalog_export_unavailable")
			return
		}
		httpapi.Failure(w, r, 503, "catalog_not_published")
		return
	}
	w.Header().Set("ETag", `"`+manifest.ManifestSHA+`"`)
	w.Header().Set("X-Content-Type-Options", "nosniff")
	if r.URL.Path == "/api/v1/food-catalog/manifest" {
		w.Header().Set("Cache-Control", "public, max-age=300")
		if r.Header.Get("If-None-Match") == w.Header().Get("ETag") {
			w.WriteHeader(http.StatusNotModified)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write(raw)
		return
	}
	f.once.Do(func() { f.slots = make(chan struct{}, 4) })
	select {
	case f.slots <- struct{}{}:
		defer func() { <-f.slots }()
	default:
		w.Header().Set("Retry-After", "60")
		httpapi.Failure(w, r, 503, "catalog_download_busy")
		return
	}
	path := f.ArchivePath
	expectedSHA := ""
	expectedSize := int64(0)
	filename := "catalog-update.zip"
	if filenameValue := r.PathValue("file"); filenameValue != "" {
		if !exportFilename.MatchString(filenameValue) {
			httpapi.Failure(w, r, 404, "catalog_export_unavailable")
			return
		}
		found := false
		for _, export := range manifest.Exports {
			if export.File == filenameValue && export.Bytes > 0 && len(export.SHA256) == 64 {
				found = true
				expectedSHA = export.SHA256
				expectedSize = export.Bytes
				break
			}
		}
		if !found || exportsDirectory == "" {
			httpapi.Failure(w, r, 404, "catalog_export_unavailable")
			return
		}
		filename = filenameValue
		path = filepath.Join(exportsDirectory, filename)
	}
	if path == "" {
		httpapi.Failure(w, r, 503, "catalog_archive_unavailable")
		return
	}
	file, e := os.Open(path)
	if os.IsNotExist(e) && expectedSHA != "" && exportsDirectory == f.ExportsDirectory {
		// The publish tool moves source exports into the immutable release folder
		// to retain ODbL source offers without copying multi-GB files.
		path = filepath.Join(f.ExportsDirectory, manifest.SHA256, filename)
		file, e = os.Open(path)
	}
	if e != nil {
		httpapi.Failure(w, r, 503, "catalog_file_unavailable")
		return
	}
	defer file.Close()
	info, e := file.Stat()
	if e != nil || !info.Mode().IsRegular() || (expectedSize > 0 && info.Size() != expectedSize) {
		httpapi.Failure(w, r, 503, "catalog_file_unavailable")
		return
	}
	identity := manifest.ManifestSHA + ":" + expectedSHA
	if e = f.verify(r.Context(), path, file, info, identity, func() error {
		if expectedSHA == "" {
			return verifyArchive(r.Context(), file, info, raw, manifest)
		}
		digest := sha256.New()
		if _, e := io.CopyBuffer(digest, contextReader{r.Context(), file}, make([]byte, 64<<10)); e != nil {
			return e
		}
		if hex.EncodeToString(digest.Sum(nil)) != expectedSHA {
			return errors.New("catalog export hash mismatch")
		}
		return nil
	}); e != nil {
		httpapi.Failure(w, r, 503, "catalog_file_integrity_failed")
		return
	}
	if _, e = file.Seek(0, io.SeekStart); e != nil {
		httpapi.Failure(w, r, 503, "catalog_file_unavailable")
		return
	}
	// Catalog transfers outlive ordinary JSON requests. Keep memory bounded and
	// preserve HTTP Range support; short API calls retain the normal deadline.
	if expectedSHA == "" {
		w.Header().Set("Content-Type", "application/zip")
	} else {
		w.Header().Set("ETag", `"`+expectedSHA+`"`)
		w.Header().Set("Content-Type", "application/gzip")
	}
	w.Header().Set("Cache-Control", "public, max-age=300")
	w.Header().Set("Content-Disposition", `attachment; filename="`+filename+`"`)
	http.ServeContent(w, r, filename, info.ModTime(), file)
}

type contextReader struct {
	ctx    context.Context
	source io.Reader
}

func (r contextReader) Read(p []byte) (int, error) {
	if e := r.ctx.Err(); e != nil {
		return 0, e
	}
	return r.source.Read(p)
}

func (f *Files) verify(ctx context.Context, path string, file *os.File, info os.FileInfo, identity string, check func() error) error {
	// A cached verification belongs to one immutable artifact/file identity, not
	// merely its name. Range requests do not rehash gigabytes on every retry.
	f.verification.Lock()
	defer f.verification.Unlock()
	if e := ctx.Err(); e != nil {
		return e
	}
	if prior, ok := f.verified[path]; ok && prior.identity == identity && prior.info.Size() == info.Size() && prior.info.ModTime().Equal(info.ModTime()) && os.SameFile(prior.info, info) {
		return nil
	}
	if e := check(); e != nil {
		return e
	}
	after, e := file.Stat()
	if e != nil || after.Size() != info.Size() || !after.ModTime().Equal(info.ModTime()) {
		return errors.New("catalog changed during verification")
	}
	if f.verified == nil {
		f.verified = map[string]verifiedFile{}
	}
	f.verified[path] = verifiedFile{info, identity}
	return nil
}

func verifyArchive(ctx context.Context, file *os.File, info os.FileInfo, manifestRaw []byte, m Manifest) error {
	archive, e := zip.NewReader(file, info.Size())
	if e != nil || len(archive.File) != 2 || archive.Comment != "" {
		return errors.New("catalog archive must contain only manifest and payload")
	}
	var foundManifest, foundPayload bool
	for _, entry := range archive.File {
		if entry.FileInfo().IsDir() || entry.Mode()&os.ModeSymlink != 0 || entry.Comment != "" || entry.Flags&1 != 0 {
			return errors.New("unsupported catalog archive entry")
		}
		switch entry.Name {
		case "manifest.json":
			if foundManifest || entry.UncompressedSize64 > 2<<20 {
				return errors.New("duplicate or oversized manifest")
			}
			foundManifest = true
			reader, e := entry.Open()
			if e != nil {
				return e
			}
			raw, e := io.ReadAll(io.LimitReader(contextReader{ctx, reader}, (2<<20)+1))
			closeErr := reader.Close()
			if e != nil || closeErr != nil || !bytes.Equal(bytes.TrimSpace(raw), bytes.TrimSpace(manifestRaw)) {
				return errors.New("archive manifest does not match configured signed manifest")
			}
		case m.File:
			if foundPayload || entry.UncompressedSize64 != uint64(m.Bytes) || strings.ContainsAny(entry.Name, "/\\") {
				return errors.New("archive payload size mismatch")
			}
			foundPayload = true
			reader, e := entry.Open()
			if e != nil {
				return e
			}
			digest := sha256.New()
			count, e := io.CopyBuffer(digest, contextReader{ctx, reader}, make([]byte, 64<<10))
			closeErr := reader.Close()
			if e != nil || closeErr != nil || count != m.Bytes || hex.EncodeToString(digest.Sum(nil)) != m.SHA256 {
				return errors.New("archive payload checksum mismatch")
			}
		default:
			return errors.New("undeclared archive entry")
		}
	}
	if !foundManifest || !foundPayload {
		return errors.New("catalog archive incomplete")
	}
	return nil
}
