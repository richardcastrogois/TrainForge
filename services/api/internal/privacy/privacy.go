package privacy

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"strings"
	"time"
	"trainforge.local/api/internal/auth"
)

var ErrQuery = errors.New("invalid privacy request")
var ErrUnavailable = errors.New("privacy unavailable")
var ErrReauthenticate = errors.New("recent Google login required")
var ErrConfirmation = errors.New("invalid deletion confirmation")

const Confirmation = "EXCLUIR MINHA CONTA"
const IntentTTL = 5 * time.Minute
const RecentLogin = 15 * time.Minute

type Policy struct {
	SessionRetention   string   `json:"sessionRetention"`
	Version            string   `json:"version"`
	AccountDeletion    string   `json:"accountDeletion"`
	BackupRetention    string   `json:"backupRetention"`
	RestoreRequirement string   `json:"restoreRequirement"`
	ErasureLedger      string   `json:"erasureLedger"`
	OtherServices      string   `json:"otherServices"`
	FutureStorage      string   `json:"futureStorage"`
	ExportSections     []string `json:"exportSections"`
	FreshLoginMinutes  int      `json:"freshLoginMinutes"`
	IntentMinutes      int      `json:"intentMinutes"`
}

func CurrentPolicy() Policy {
	return Policy{
		SessionRetention:   "Registros temporários expirados podem permanecer até a manutenção manual. A expiração e a revogação das sessões continuam valendo antes dessa limpeza.",
		Version:            "trainforge.privacy/1",
		AccountDeletion:    "Após sua confirmação, os dados atuais da conta TrainForge são apagados e todas as suas sessões são encerradas.",
		BackupRetention:    "Cópias de segurança antigas podem manter dados anteriores à exclusão. Nesta versão de avaliação, a remoção dessas cópias ainda depende de manutenção manual.",
		RestoreRequirement: "Uma cópia antiga só pode voltar a ser usada depois de aplicar os pedidos de exclusão mais recentes. Sem esses registros atualizados, a recuperação não é liberada.",
		ErasureLedger:      "Mantemos somente um identificador interno da conta e a data da exclusão para impedir que os dados retornem ao recuperar uma cópia de segurança. Esse registro não contém nome, e-mail ou credenciais.",
		OtherServices:      "A conta Google e dados mantidos pelo Google não são apagados por esta ação.",
		FutureStorage:      "Esta versão não envia suas fotos. As credenciais da sessão ficam no armazenamento protegido deste aparelho.",
		ExportSections:     []string{"account", "sessions", "enrollments", "occurrences", "activitySessions", "activityEvents", "foods", "foodEntries", "trainingConfigurations", "meals", "mealItems", "mealVersions"},
		FreshLoginMinutes:  15, IntentMinutes: 5,
	}
}

type ExportFilter struct {
	Section, After string
	Limit          int
}
type ExportPage struct {
	AccountID   string            `json:"accountId"`
	Section     string            `json:"section"`
	Items       []json.RawMessage `json:"items" swaggertype:"array,object"`
	NextCursor  *string           `json:"nextCursor" extensions:"x-nullable"`
	GeneratedAt time.Time         `json:"generatedAt"`
	Notice      string            `json:"notice"`
}
type Intent struct {
	Challenge string    `json:"challenge"`
	ExpiresAt time.Time `json:"expiresAt"`
}
type DeleteRequest struct {
	Confirmation string `json:"confirmation"`
	Challenge    string `json:"challenge"`
}
type IntentRequest struct {
	Confirmation string `json:"confirmation"`
}
type Erased struct {
	AccountID    string    `json:"accountId"`
	Deleted      bool      `json:"deleted"`
	ErasedAt     time.Time `json:"erasedAt"`
	BackupNotice string    `json:"backupNotice"`
}
type Repository interface {
	Export(context.Context, auth.Principal, ExportFilter) (ExportPage, error)
	Intent(context.Context, auth.Principal, []byte) (time.Time, error)
	Delete(context.Context, auth.Principal, []byte) (Erased, error)
}
type Service struct{ Repository Repository }

func tokenHash(raw string) []byte { sum := sha256.Sum256([]byte(raw)); return sum[:] }
func newChallenge() (string, error) {
	raw := make([]byte, 32)
	if _, err := rand.Read(raw); err != nil {
		return "", ErrUnavailable
	}
	return "tfv1_d_" + base64.RawURLEncoding.EncodeToString(raw), nil
}
func parseChallenge(value string) ([]byte, error) {
	if len(value) != len("tfv1_d_")+43 || !strings.HasPrefix(value, "tfv1_d_") {
		return nil, ErrConfirmation
	}
	raw, err := base64.RawURLEncoding.DecodeString(strings.TrimPrefix(value, "tfv1_d_"))
	if err != nil || len(raw) != 32 {
		return nil, ErrConfirmation
	}
	return tokenHash(value), nil
}
func (s Service) Intent(ctx context.Context, p auth.Principal, confirmation string) (Intent, error) {
	if confirmation != Confirmation {
		return Intent{}, ErrConfirmation
	}
	if s.Repository == nil {
		return Intent{}, ErrUnavailable
	}
	token, err := newChallenge()
	if err != nil {
		return Intent{}, err
	}
	expiry, err := s.Repository.Intent(ctx, p, tokenHash(token))
	if err != nil {
		return Intent{}, err
	}
	return Intent{token, expiry}, nil
}
func (s Service) Delete(ctx context.Context, p auth.Principal, r DeleteRequest) (Erased, error) {
	if r.Confirmation != Confirmation {
		return Erased{}, ErrConfirmation
	}
	hash, err := parseChallenge(r.Challenge)
	if err != nil {
		return Erased{}, err
	}
	if s.Repository == nil {
		return Erased{}, ErrUnavailable
	}
	return s.Repository.Delete(ctx, p, hash)
}
func fingerprint(user string, f ExportFilter) string {
	f.After = ""
	raw, _ := json.Marshal(struct {
		User   string
		Filter ExportFilter
	}{user, f})
	sum := sha256.Sum256(raw)
	return hex.EncodeToString(sum[:])
}
func exportCursor(user, key string, f ExportFilter) string {
	raw, _ := json.Marshal(struct{ After, Filter string }{key, fingerprint(user, f)})
	return base64.RawURLEncoding.EncodeToString(raw)
}
