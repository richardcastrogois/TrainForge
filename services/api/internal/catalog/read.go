package catalog

import (
	"context"
	"encoding/json"
	"errors"
)

var ErrQuery = errors.New("invalid catalog query")
var ErrMissing = errors.New("catalog item unavailable")
var ErrDependency = errors.New("catalog unavailable")

type CatalogSource struct {
	ID        string   `json:"id"`
	Name      string   `json:"name"`
	Publisher *string  `json:"publisher" extensions:"x-nullable"`
	URLs      []string `json:"urls"`
}
type NameCredit struct {
	TranslationID       *string  `json:"translationId" extensions:"x-nullable"`
	Creators            []string `json:"creators"`
	LicenseURL          *string  `json:"licenseUrl" extensions:"x-nullable"`
	SourceNameUnchanged *bool    `json:"sourceNameUnchanged" extensions:"x-nullable"`
}
type Credits struct {
	Title              *string     `json:"title" extensions:"x-nullable"`
	Creators           []string    `json:"creators"`
	SourceURL          *string     `json:"sourceUrl" extensions:"x-nullable"`
	LicenseURL         *string     `json:"licenseUrl" extensions:"x-nullable"`
	LicenseLabel       *string     `json:"licenseLabel" extensions:"x-nullable"`
	Changes            *string     `json:"changes" extensions:"x-nullable"`
	WarrantyNotice     *string     `json:"warrantyNotice" extensions:"x-nullable"`
	SelectedNameCredit *NameCredit `json:"selectedNameCredit" extensions:"x-nullable"`
}
type CatalogRights struct {
	Label              *string  `json:"label" extensions:"x-nullable"`
	LicenseURL         *string  `json:"licenseUrl" extensions:"x-nullable"`
	Attribution        *string  `json:"attribution" extensions:"x-nullable"`
	Scope              *string  `json:"scope" extensions:"x-nullable"`
	DisplayCredits     Credits  `json:"displayCredits"`
	DeliveryConditions []string `json:"deliveryConditions"`
}
type CatalogAudience struct {
	Population      []string `json:"population" extensions:"x-nullable"`
	Environment     []string `json:"environment" extensions:"x-nullable"`
	SupportRequired *bool    `json:"supportRequired" extensions:"x-nullable"`
	SupportSource   *string  `json:"supportSource" extensions:"x-nullable"`
}
type Label struct {
	ID   *int   `json:"id" extensions:"x-nullable"`
	Name string `json:"name"`
}
type Requirements struct {
	Category  *Label  `json:"category" extensions:"x-nullable"`
	Equipment []Label `json:"equipment"`
	Modality  *string `json:"modality" extensions:"x-nullable"`
}
type Availability struct {
	Consultation bool     `json:"consultation"`
	Practice     bool     `json:"practice"`
	Instruction  bool     `json:"instruction"`
	Media        bool     `json:"media"`
	Reasons      []string `json:"reasons"`
}
type CatalogItem struct {
	ID                     string          `json:"id"`
	VersionID              string          `json:"versionId"`
	Kind                   string          `json:"kind"`
	Title                  *string         `json:"title" extensions:"x-nullable"`
	Locale                 *string         `json:"locale" extensions:"x-nullable"`
	SourcePublishedVersion *string         `json:"sourcePublishedVersion" extensions:"x-nullable"`
	Source                 CatalogSource   `json:"source"`
	Authors                []string        `json:"authors"`
	Rights                 CatalogRights   `json:"rights"`
	Audience               CatalogAudience `json:"audience"`
	Requirements           Requirements    `json:"requirements"`
	Availability           Availability    `json:"availability"`
}
type CatalogPage struct {
	Items      []CatalogItem `json:"items"`
	NextCursor *string       `json:"nextCursor" extensions:"x-nullable"`
	Mode       string        `json:"mode"`
	Notice     string        `json:"notice"`
}
type Filters struct {
	Kinds                                                                  []string
	Limit                                                                  int
	Q, Environment, Population, Modality, Equipment, Category, Mode, After string
}
type CatalogRepository interface {
	List(context.Context, Filters) ([]CatalogItem, error)
	Facets(context.Context) (CatalogFacets, error)
	Detail(context.Context, []string, string, string, string) (CatalogItem, error)
}
type Reader struct{ Repository CatalogRepository }

func (r Reader) List(ctx context.Context, f Filters) (CatalogPage, error) {
	page := CatalogPage{Items: []CatalogItem{}, Mode: f.Mode, Notice: "Consulta de metadados revisados. Ausência de instrução ou mídia não libera prática."}
	if r.Repository == nil {
		return page, ErrDependency
	}
	rows, err := r.Repository.List(ctx, f)
	if err != nil {
		return page, err
	}
	if len(rows) > f.Limit {
		next, err := encodeCursor(rows[f.Limit-1].ID, f)
		if err != nil {
			return page, ErrQuery
		}
		page.NextCursor = &next
		rows = rows[:f.Limit]
	}
	if rows == nil {
		rows = []CatalogItem{}
	}
	page.Items = rows
	return page, nil
}
func (r Reader) Detail(ctx context.Context, kinds []string, id, version, mode string) (CatalogItem, error) {
	if r.Repository == nil {
		return CatalogItem{}, ErrDependency
	}
	return r.Repository.Detail(ctx, kinds, id, version, mode)
}

// Decode only the explicit metadata projection selected by SQL. Never serialize
// editorial payloads, instruction bodies, dose, media URLs or source evidence wholesale.
func decodeMetadata(raw []byte) (CatalogItem, error) {
	var item CatalogItem
	if json.Unmarshal(raw, &item) != nil {
		return item, ErrDependency
	}
	if item.Authors == nil {
		item.Authors = []string{}
	}
	if item.Source.URLs == nil {
		item.Source.URLs = []string{}
	}
	if item.Rights.DisplayCredits.Creators == nil {
		item.Rights.DisplayCredits.Creators = []string{}
	}
	if item.Rights.DeliveryConditions == nil {
		item.Rights.DeliveryConditions = []string{}
	}
	if item.Requirements.Equipment == nil {
		item.Requirements.Equipment = []Label{}
	}
	item.Availability = Availability{Consultation: true, Reasons: []string{
		"Disponível somente para consulta de referência; não é uma orientação de treino.",
		"Instrução, dose e mídia indisponíveis para uso no app.",
	}}
	if len(item.Audience.Population) == 0 {
		item.Availability.Reasons = append(item.Availability.Reasons, "Público não informado pela fonte; não presumir elegibilidade.")
	}
	if len(item.Audience.Environment) == 0 {
		item.Availability.Reasons = append(item.Availability.Reasons, "Ambiente não informado pela fonte; não presumir adaptação para casa, praça ou academia.")
	}
	if item.Audience.SupportRequired == nil {
		item.Availability.Reasons = append(item.Availability.Reasons, "Necessidade de apoio não informada; não presumir autonomia.")
	}
	return item, nil
}

type CatalogFacets struct {
	Environments            []string `json:"environments"`
	Populations             []string `json:"populations"`
	Modalities              []string `json:"modalities"`
	Equipment               []string `json:"equipment"`
	Categories              []string `json:"categories"`
	MovementCount           int      `json:"movementCount"`
	ProgramCount            int      `json:"programCount"`
	UnknownEnvironmentCount int      `json:"unknownEnvironmentCount"`
	UnknownPopulationCount  int      `json:"unknownPopulationCount"`
}

func (r Reader) Facets(ctx context.Context) (CatalogFacets, error) {
	if r.Repository == nil {
		return CatalogFacets{}, ErrDependency
	}
	return r.Repository.Facets(ctx)
}
