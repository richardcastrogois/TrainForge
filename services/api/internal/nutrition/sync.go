package nutrition

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"io"
	"strconv"
	"strings"
)

const SyncContract = "trainforge.nutrition-sync/1"

// An operation identity survives application restarts and the HTTP replay cache.
type SyncOperation struct {
	OperationID string          `json:"operationId"`
	Kind        string          `json:"kind"`
	LocalID     string          `json:"localId"`
	RemoteID    string          `json:"remoteId,omitempty"`
	Revision    *int            `json:"expectedRevision,omitempty"`
	DependsOn   []string        `json:"dependsOn,omitempty"`
	Body        json.RawMessage `json:"body" swaggertype:"object"`
}
type SyncPush struct {
	Contract   string          `json:"contract"`
	Operations []SyncOperation `json:"operations"`
}
type SyncResult struct {
	OperationID string          `json:"operationId"`
	Status      string          `json:"status"`
	LocalID     string          `json:"localId"`
	RemoteID    string          `json:"remoteId,omitempty"`
	Revision    int             `json:"revision,omitempty"`
	Value       json.RawMessage `json:"value,omitempty" swaggertype:"object"`
	Code        string          `json:"code,omitempty"`
}
type SyncPushResult struct {
	Contract string       `json:"contract"`
	Results  []SyncResult `json:"results"`
}
type SyncChange struct {
	Sequence string          `json:"sequence"`
	Entity   string          `json:"entity"`
	ID       string          `json:"id"`
	Value    json.RawMessage `json:"value" swaggertype:"object"`
	Deleted  bool            `json:"deleted"`
}
type SyncPage struct {
	Contract   string       `json:"contract"`
	Items      []SyncChange `json:"items"`
	Cursor     string       `json:"cursor"`
	NextCursor string       `json:"nextCursor"`
	HasMore    bool         `json:"hasMore"`
}

func (p SyncPush) Validate() error {
	if p.Contract != SyncContract || len(p.Operations) < 1 || len(p.Operations) > 32 {
		return ErrFoodQuery
	}
	seen := map[string]bool{}
	for _, op := range p.Operations {
		if !uuidPattern.MatchString(op.OperationID) || !uuidPattern.MatchString(op.LocalID) || seen[op.OperationID] || len(op.Body) == 0 || len(op.Body) > 64<<10 || len(op.DependsOn) > 32 {
			return ErrFoodQuery
		}
		seen[op.OperationID] = true
		switch op.Kind {
		case "food.create", "entry.create", "entry.update", "entry.delete", "meal.create", "meal.update", "meal.delete":
		default:
			return ErrFoodQuery
		}
		if op.RemoteID != "" && !uuidPattern.MatchString(op.RemoteID) && !privateFoodPattern.MatchString(op.RemoteID) {
			return ErrFoodQuery
		}
		if op.Revision != nil && (*op.Revision < 0 || *op.Revision >= 2147483647) {
			return ErrFoodQuery
		}
		deps := map[string]bool{}
		for _, id := range op.DependsOn {
			if !uuidPattern.MatchString(id) || id == op.OperationID || deps[id] {
				return ErrFoodQuery
			}
			deps[id] = true
		}
	}
	return nil
}

func syncDecode(raw []byte, target any) error {
	d := json.NewDecoder(bytes.NewReader(raw))
	d.UseNumber()
	if uniqueJSON(d) != nil || d.Decode(new(any)) != io.EOF {
		return ErrFoodQuery
	}
	d = json.NewDecoder(bytes.NewReader(raw))
	d.DisallowUnknownFields()
	if d.Decode(target) != nil || d.Decode(new(any)) != io.EOF {
		return ErrFoodQuery
	}
	return nil
}

func syncCursor(user string, sequence int64) string {
	return base64.RawURLEncoding.EncodeToString([]byte(user + ":" + strconv.FormatInt(sequence, 10)))
}
func parseSyncCursor(user, cursor string) (int64, error) {
	if cursor == "" {
		return 0, nil
	}
	if len(cursor) > 160 {
		return 0, ErrFoodQuery
	}
	raw, e := base64.RawURLEncoding.DecodeString(cursor)
	parts := strings.Split(string(raw), ":")
	if e != nil || len(parts) != 2 || parts[0] != user || parts[1] == "" {
		return 0, ErrFoodQuery
	}
	n, e := strconv.ParseInt(parts[1], 10, 64)
	if e != nil || n < 0 || strconv.FormatInt(n, 10) != parts[1] {
		return 0, ErrFoodQuery
	}
	return n, nil
}
