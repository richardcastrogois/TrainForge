package nutrition

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"strings"
	"time"
	"trainforge.local/api/internal/auth"
)

type NutritionStore struct{ Pool *pgxpool.Pool }

func newID() string {
	var b [16]byte
	if _, e := rand.Read(b[:]); e != nil {
		panic("system random unavailable")
	}
	b[6] = (b[6] & 15) | 64
	b[8] = (b[8] & 63) | 128
	return fmt.Sprintf("%x-%x-%x-%x-%x", b[0:4], b[4:6], b[6:8], b[8:10], b[10:16])
}
func digest(v []byte) []byte { d := sha256.Sum256(v); return d[:] }
func (s NutritionStore) begin(ctx context.Context, p auth.Principal, write bool) (pgx.Tx, error) {
	if s.Pool == nil {
		return nil, ErrFoodUnavailable
	}
	tx, e := s.Pool.Begin(ctx)
	if e != nil {
		return nil, ErrFoodUnavailable
	}
	lock := " FOR SHARE OF u,f"
	if write {
		lock = " FOR UPDATE OF u FOR SHARE OF f"
	}
	var id string
	e = tx.QueryRow(ctx, `SELECT u.id::text FROM trainforge_v1.users u
 JOIN trainforge_v1.auth_families f ON f.user_id=u.id JOIN trainforge_v1.access_tokens a ON a.family_id=f.id
 WHERE u.id=$1 AND f.id=$2 AND a.token_hash=$3 AND a.expires_at>clock_timestamp() AND f.revoked_at IS NULL`+lock, p.User.ID, p.FamilyID, p.AccessHash).Scan(&id)
	if e != nil {
		_ = tx.Rollback(ctx)
		if errors.Is(e, pgx.ErrNoRows) {
			return nil, auth.ErrInvalid
		}
		return nil, ErrFoodUnavailable
	}
	return tx, nil
}
func ownFood(id string, in OwnFoodInput) FoodDetail {
	food := FoodDetail{FoodSummary: FoodSummary{ID: id, Name: in.Name, Locale: "pt", Basis: in.Basis, SourceID: "personal", SourceVersion: "user-declaration-v1", Source: Citation{Name: "Informado por você", Publisher: "Titular", Attribution: "Declaração particular, sem revisão editorial ou clínica.", Conditions: []string{}}}, Nutrients: []FoodCell{}, Notice: "Alimento particular; composição declarada pelo titular. Ausências permanecem desconhecidas."}
	for i, n := range in.Nutrients {
		state, raw := "missing", ""
		if n.Value != nil {
			state, raw = "numeric", *n.Value
		}
		col := id + fmt.Sprintf(":%d", i)
		scaling := n.Value != nil && in.Basis.Unit != nil
		food.Nutrients = append(food.Nutrients, FoodCell{Column: col, Name: n.Name, Unit: &n.Unit, State: state, Value: n.Value, Raw: raw, BasisQuantity: in.Basis.Quantity, BasisUnit: in.Basis.Unit, Scaling: scaling, Reasons: []string{}})
	}
	raw, _ := json.Marshal(in)
	food.VersionID = hex.EncodeToString(digest(raw))
	return food
}

const ownProjection = `jsonb_build_object('id',v.food_id,'versionId',v.version_sha,'sourceId','personal','sourceFoodId','','sourcePublishedVersion','user-declaration-v1','nameOriginal',v.name_original,'nameLocale','pt','basis',jsonb_build_object('quantity',v.basis_quantity::text,'unit',v.basis_unit),'source',v.provenance->'source','nutrients',v.nutrients,'notice','Alimento particular; declaração do titular, sem revisão editorial ou clínica.')`

func selectedFood(ctx context.Context, tx pgx.Tx, p auth.Principal, id, version string) (FoodDetail, string, error) {
	var raw []byte
	var result FoodDetail
	e := tx.QueryRow(ctx, "SELECT "+ownProjection+" FROM trainforge_v1.food_versions v WHERE v.food_id=$1 AND v.version_sha=$2 AND v.owner_id=$3", id, version, p.User.ID).Scan(&raw)
	if e == nil {
		if json.Unmarshal(raw, &result) != nil {
			return result, "", ErrFoodUnavailable
		}
		return result, "personal", nil
	}
	if !errors.Is(e, pgx.ErrNoRows) {
		return result, "", ErrFoodUnavailable
	}
	var cells []byte
	var scalingAllowed bool
	e = tx.QueryRow(ctx, "SELECT "+foodProjection+",v.nutrients,'food_quantity_scale'=ANY(v.allowed_operations) FROM trainforge_v1.food_versions v WHERE v.food_id=$1 AND v.version_sha=$2 AND "+foodVisible, id, version).Scan(&raw, &cells, &scalingAllowed)
	if errors.Is(e, pgx.ErrNoRows) {
		return result, "", ErrFoodMissing
	}
	if e != nil || json.Unmarshal(raw, &result.FoodSummary) != nil {
		return result, "", ErrFoodUnavailable
	}
	var nutrients []Nutrient
	if json.Unmarshal(cells, &nutrients) != nil {
		return result, "", ErrFoodUnavailable
	}
	for _, n := range nutrients {
		if validateState(n) != nil {
			return result, "", ErrFoodUnavailable
		}
		var rawText string
		if json.Unmarshal(n.Raw, &rawText) != nil {
			rawText = string(n.Raw)
		}
		result.Nutrients = append(result.Nutrients, FoodCell{Column: n.Column, Name: n.Name, Unit: n.Unit, State: n.State, Value: n.Value, UpperBound: n.UpperBound, Raw: rawText, BasisQuantity: n.BasisQuantity, BasisUnit: n.BasisUnit, Scaling: n.Scaling && scalingAllowed, Reasons: n.Reasons})
	}
	return result, "editorial", nil
}

const entryProjection = `jsonb_build_object('id',v.id,'foodId',v.food_id,'foodVersion',v.food_sha,'quantity',v.quantity::text,'unit',v.unit,'occurredAt',to_char(v.occurred_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),'timezone',v.timezone,'calculation',v.calculation,'deletedAt',v.deleted_at)`

func readEntry(ctx context.Context, tx pgx.Tx, user, id string) (Entry, error) {
	var raw []byte
	var result Entry
	e := tx.QueryRow(ctx, "SELECT "+entryProjection+" FROM trainforge_v1.food_entries v WHERE v.user_id=$1 AND v.id=$2", user, id).Scan(&raw)
	if errors.Is(e, pgx.ErrNoRows) {
		return result, ErrFoodMissing
	}
	if e != nil || json.Unmarshal(raw, &result) != nil {
		return result, ErrFoodUnavailable
	}
	return result, nil
}

// All writes lock the account, revalidate live credentials and store the response
// in the same transaction. A lost response can be retried with the same key.
func (s NutritionStore) Mutate(ctx context.Context, p auth.Principal, op, id, key string, body []byte) (json.RawMessage, int, error) {
	tx, e := s.begin(ctx, p, true)
	if e != nil {
		return nil, 0, e
	}
	defer tx.Rollback(ctx)
	requestHash, keyHash := digest(body), digest([]byte(key))
	var priorHash, priorBody []byte
	var status int
	e = tx.QueryRow(ctx, `SELECT request_hash,response_body,response_status FROM trainforge_v1.idempotency_records
 WHERE user_id=$1 AND operation=$2 AND key_hash=$3 AND expires_at>clock_timestamp()`, p.User.ID, op, keyHash).Scan(&priorHash, &priorBody, &status)
	if e == nil {
		if !equal(priorHash, requestHash) {
			return nil, 0, ErrEntryConflict
		}
		if e = tx.Commit(ctx); e != nil {
			return nil, 0, ErrFoodUnavailable
		}
		return priorBody, status, nil
	}
	if !errors.Is(e, pgx.ErrNoRows) {
		return nil, 0, ErrFoodUnavailable
	}
	status = 200
	var result any
	if op == "own-food" {
		var in OwnFoodInput
		if json.Unmarshal(body, &in) != nil || validateOwn(in) != nil {
			return nil, 0, ErrFoodQuery
		}
		f := ownFood("own:"+newID(), in)
		cells, _ := json.Marshal(f.Nutrients)
		source, _ := json.Marshal(map[string]any{"source": f.Source, "origin": "personal", "clinicalApproval": false, "preparation": in.Preparation})
		_, e = tx.Exec(ctx, `SELECT trainforge_v1.create_private_food($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)`, p.User.ID, p.FamilyID, p.AccessHash, f.ID, f.VersionID, in.Name, in.Preparation, in.Basis.Quantity, in.Basis.Unit, cells, source)
		result = f
		status = 201
	} else {
		var in EntryInput
		if json.Unmarshal(body, &in) != nil {
			return nil, 0, ErrFoodQuery
		}
		var prior Entry
		if id != "" {
			prior, e = readEntry(ctx, tx, p.User.ID, id)
			if e != nil {
				return nil, 0, e
			}
			if prior.DeletedAt != nil || in.Revision != prior.Calculation.Revision || (len(prior.Calculation.Changes) >= 100 && op != "delete-entry:"+id) {
				return nil, 0, ErrEntryConflict
			}
		}
		if op == "delete-entry:"+id {
			if id == "" {
				return nil, 0, ErrFoodQuery
			}
			_, e = tx.Exec(ctx, "UPDATE trainforge_v1.food_entries SET deleted_at=clock_timestamp(),calculation=jsonb_set(calculation,'{revision}',to_jsonb($3::int)) WHERE user_id=$1 AND id=$2", p.User.ID, id, in.Revision+1)
			if e == nil {
				result, e = readEntry(ctx, tx, p.User.ID, id)
			}
		} else {
			if validateEntry(in) != nil {
				return nil, 0, ErrFoodQuery
			}
			if id != "" && (in.FoodID != prior.FoodID || in.FoodVersion != prior.FoodVersion) {
				return nil, 0, ErrEntryConflict
			}
			if id == "" && in.Revision != 0 {
				return nil, 0, ErrFoodQuery
			}
			food, origin, err := selectedFood(ctx, tx, p, in.FoodID, in.FoodVersion)
			if err != nil {
				return nil, 0, err
			}
			calc, err := scaled(food, in, origin)
			if err != nil {
				return nil, 0, err
			}
			if id != "" {
				calc.Revision = in.Revision + 1
				calc.Changes = append(prior.Calculation.Changes, EntryChange{Revision: in.Revision, Quantity: prior.Quantity, Unit: prior.Unit, Preparation: prior.Calculation.Preparation, OccurredAt: prior.OccurredAt, Timezone: prior.Timezone, QuantityEvidence: prior.Calculation.QuantityEvidence, ReplacedAt: time.Now().UTC().Format(time.RFC3339Nano)})
			} else {
				id = newID()
				status = 201
			}
			occurred, _ := time.Parse(time.RFC3339, in.OccurredAt)
			raw, _ := json.Marshal(calc)
			if status == 201 {
				_, e = tx.Exec(ctx, `INSERT INTO trainforge_v1.food_entries(id,user_id,food_id,food_sha,quantity,unit,occurred_at,timezone,calculation) VALUES($1,$2,$3,$4,$5::numeric,$6,$7,$8,$9)`, id, p.User.ID, in.FoodID, in.FoodVersion, in.Quantity, in.Unit, occurred, in.Timezone, raw)
			} else {
				_, e = tx.Exec(ctx, `UPDATE trainforge_v1.food_entries SET quantity=$3::numeric,unit=$4,occurred_at=$5,timezone=$6,calculation=$7 WHERE user_id=$1 AND id=$2`, p.User.ID, id, in.Quantity, in.Unit, occurred, in.Timezone, raw)
			}
			if e == nil {
				result, e = readEntry(ctx, tx, p.User.ID, id)
			}
		}
	}
	if e != nil {
		return nil, 0, ErrFoodUnavailable
	}
	raw, e := json.Marshal(result)
	if e != nil {
		return nil, 0, ErrFoodUnavailable
	}
	_, e = tx.Exec(ctx, `INSERT INTO trainforge_v1.idempotency_records(user_id,operation,key_hash,request_hash,response_status,response_body,expires_at)
 VALUES($1,$2,$3,$4,$5,$6,clock_timestamp()+interval '24 hours')
 ON CONFLICT(user_id,operation,key_hash) DO UPDATE SET request_hash=EXCLUDED.request_hash,response_status=EXCLUDED.response_status,response_body=EXCLUDED.response_body,expires_at=EXCLUDED.expires_at`, p.User.ID, op, keyHash, requestHash, status, raw)
	if e != nil || tx.Commit(ctx) != nil {
		return nil, 0, ErrFoodUnavailable
	}
	return raw, status, nil
}
func equal(a, b []byte) bool { return string(a) == string(b) }

type privateFilter struct {
	Q, After, Day, Zone string
	Limit               int
}

func (s NutritionStore) Foods(ctx context.Context, p auth.Principal, f privateFilter) ([]FoodDetail, error) {
	tx, e := s.begin(ctx, p, false)
	if e != nil {
		return nil, e
	}
	defer tx.Rollback(ctx)
	rows, e := tx.Query(ctx, "SELECT "+ownProjection+" FROM trainforge_v1.food_versions v WHERE owner_id=$1 AND ($2='' OR position(lower($2) in lower(name_original))>0) AND food_id COLLATE \"C\">$3 COLLATE \"C\" ORDER BY food_id COLLATE \"C\" LIMIT $4", p.User.ID, f.Q, f.After, f.Limit+1)
	if e != nil {
		return nil, ErrFoodUnavailable
	}
	out := []FoodDetail{}
	for rows.Next() {
		var raw []byte
		var v FoodDetail
		if rows.Scan(&raw) != nil || json.Unmarshal(raw, &v) != nil {
			rows.Close()
			return nil, ErrFoodUnavailable
		}
		out = append(out, v)
	}
	e = rows.Err()
	rows.Close()
	if e != nil || tx.Commit(ctx) != nil {
		return nil, ErrFoodUnavailable
	}
	return out, nil
}
func (s NutritionStore) Entries(ctx context.Context, p auth.Principal, f privateFilter, summary bool) ([]Entry, error) {
	start, end, e := dayBounds(f.Day, f.Zone)
	if e != nil {
		return nil, e
	}
	tx, e := s.begin(ctx, p, false)
	if e != nil {
		return nil, e
	}
	defer tx.Rollback(ctx)
	var afterTime *time.Time
	afterID := "00000000-0000-0000-0000-000000000000"
	if f.After != "" {
		parts := strings.Split(f.After, "|")
		if len(parts) != 2 {
			return nil, ErrFoodQuery
		}
		t, err := time.Parse(time.RFC3339, parts[0])
		if err != nil || !uuidPattern.MatchString(parts[1]) {
			return nil, ErrFoodQuery
		}
		afterTime = &t
		afterID = parts[1]
	}
	limit := f.Limit + 1
	if summary {
		limit = 101
	}
	rows, e := tx.Query(ctx, "SELECT "+entryProjection+" FROM trainforge_v1.food_entries v WHERE user_id=$1 AND deleted_at IS NULL AND occurred_at>=$2 AND occurred_at<$3 AND ($4::timestamptz IS NULL OR (occurred_at,id)<($4,$5::uuid)) ORDER BY occurred_at DESC,id DESC LIMIT $6", p.User.ID, start, end, afterTime, afterID, limit)
	if e != nil {
		return nil, ErrFoodUnavailable
	}
	out := []Entry{}
	for rows.Next() {
		var raw []byte
		var v Entry
		if rows.Scan(&raw) != nil || json.Unmarshal(raw, &v) != nil {
			rows.Close()
			return nil, ErrFoodUnavailable
		}
		out = append(out, v)
	}
	e = rows.Err()
	rows.Close()
	if e != nil || tx.Commit(ctx) != nil {
		return nil, ErrFoodUnavailable
	}
	return out, nil
}
