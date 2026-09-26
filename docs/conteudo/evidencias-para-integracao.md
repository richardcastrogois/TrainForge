# Evidências de retorno para a implementação

Registro de **26/09/2026**, baseado nas chamadas e arquivos preservados de 22–26/09. Este documento responde **de onde veio, como foi chamado, o que retornou, onde está e o que pode alimentar no app**. Não define os futuros endpoints internos do TrainForge nem afirma que as integrações existem.

Os campos abaixo foram observados em amostras. Presença na amostra não é garantia de obrigatoriedade ou disponibilidade futura do fornecedor. As permissões e limitações continuam no [catálogo por fonte](fontes.json) e em [direitos](direitos-e-acordos.md).

## Como recuperar sem fazer outra chamada

- [Índice de chamadas e hashes](evidencias/retornos-observados.json): **44 registros de chamadas preservadas**, incluindo tentativas sem rede e falhas; 25 respostas HTTP 200. Não são 44 APIs ou 25 fontes diferentes. Inclui as duas leituras XML do nicho N01.
- [Inventariador local](evidencias/inventariar-retornos.py): gera o índice sem rede; conferiu 12 corpos mantidos como arquivos contra o SHA-256 original. Não confundir o hash de um corpo HTTP com o de um JSON reformatado pelo coletor.
- [Pilotos conferidos](evidencias/2026-09-26/pilotos-resumo.json): resultados dos analisadores, separados do retorno original.
- Respostas integrais e planilhas indicadas como **locais** não acompanham o clone Git. Metadados, scripts e resumos permitem localizar/reproduzir legitimamente a coleta. O clone sozinho não contém todos os insumos.

```powershell
# Sem rede: índice, consulta de uma fonte e verificação dos pilotos já guardados.
python docs/conteudo/evidencias/inventariar-retornos.py
python docs/conteudo/consultar-fontes.py --id AL04
python docs/conteudo/evidencias/analisar-pilotos.py
```

No host atual há Python em `C:\Users\richa\AppData\Roaming\uv\tools\graphifyy\Scripts\python.exe`; os scripts usam biblioteca padrão. `analisar-pilotos.py` exige os corpos locais, enquanto `consultar-fontes.py` apenas consulta o índice. As chamadas dos coletores são explícitas; não executá-los só para consultar contexto.

## Convenções que evitam implementar o formato errado

| Camada | Exemplo | Significado |
|---|---|---|
| Metadado da nossa coleta | `url`, `method`, `collectedAtUtc`, `status`, `sha256`, `elapsedSeconds` | Criado pelo script; não são campos da resposta de negócio do fornecedor |
| Envelope local de 22/09 | `data` em `wger-25.json` / `usda-egg-detail.json` | Guarda o corpo da resposta dentro da evidência. A API não devolveu esse envelope adicional |
| Corpo original | wger `results`, USDA `foods`, XLSX CoFID/Ciqual, HTML NHS | Formato externo efetivamente recebido |
| Extração nossa | `sourceId`, `energyKcalEU1169`, `activityCode`, `patternId` | Nomes normalizados pelos scripts; não são automaticamente nomes de campos externos |
| Produto futuro | plano selecionado, gramas consumidos, sessão concluída, metas e histórico | Dados/regras do TrainForge; não aparecem prontos nessas fontes |

Os coletores 0.1 e 0.2 configuram `User-Agent: TrainForgeResearch/0.1 (public data feasibility study)` / `TrainForgeResearch/0.2 (public source feasibility research)` e `Accept: application/json` / `*/*`, respectivamente. O coletor 0.3 usa `TrainForgeResearch/0.3 (content feasibility; local research)` e `Accept: application/json,text/html,application/pdf;q=0.9,*/*;q=0.5`. São configurações dos scripts, não captura de tráfego de cada pedido. A transferência Ciqual por `Invoke-WebRequest` registra o cliente, mas não preserva os headers enviados.

Todos os pedidos inventariados são GET. Apenas USDA usou `api_key=DEMO_KEY`, a chave pública de demonstração; nenhuma chave privada está documentada aqui. Um futuro adaptador deve validar HTTP, tipo de conteúdo, tamanho, identidade, unidade, licença e origem antes de aceitar dados. Nunca converter erro HTTP em catálogo vazio válido.

## EX01 — wger: movimentos e instruções

**Chamadas observadas, 22–23/09, HTTP 200:**

```http
GET https://wger.de/api/v2/exerciseinfo/?limit=25&ordering=id
GET https://wger.de/api/v2/exerciseinfo/?limit=25&offset=300
GET https://wger.de/api/v2/exerciseinfo/?limit=25&offset=600
GET https://wger.de/api/v2/language/
```

Sem autenticação nessas leituras. Paginação externa: `count`, `next`, `previous`, `results[]`. Recebemos **75 IDs distintos**, não todo o catálogo. Os offsets são amostras de conveniência, não garantia de conjunto imutável; uma implementação deve percorrer/verificar a paginação e fixar a versão importada.

| Caminho no corpo HTTP | Retorno observado / utilização possível |
|---|---|
| `results[].id`, `uuid`, `created`, `last_update`, `last_update_global` | Identidade e datas da fonte; preservar para rastreamento/versionamento |
| `category` | Objeto de categoria; não equivale a programa completo nem nível de experiência |
| `muscles[]`, `muscles_secondary[]` | Objetos com `id`, `name`, `name_en`, `is_front`, `image_url_main`, `image_url_secondary`; descrição da região e referências visuais |
| `equipment[]` | Objetos `id`, `name`; ausência de equipamento em alguns itens exige revisão, não adivinhação |
| `translations[]` | `id`, `uuid`, `name`, `exercise`, `description`, `description_source`, `created`, `language`, `aliases`, `notes` e campos de licença/autoria. `description` pode conter HTML: sanitizar ao apresentar |
| `translations[].language` + catálogo `/language/` | ID de idioma; catálogo devolve `id`, `short_name`, `full_name`, `full_name_en`. Na amostra, `7` identifica português, sem certificação pt-PT |
| `images[]` | `id`, `uuid`, `exercise`, `exercise_uuid`, `image`, `thumbnails`, `is_main`, `style`, `is_ai_generated` e créditos/licença por ativo |
| `videos[]` | `id`, `uuid`, `exercise`, `video`, `is_main`, `size`, `duration`, `width`, `height`, `codec`, `codec_long` e créditos/licença |
| `license`, `license_author`, `author_history`, `total_authors_history` | Proveniência do movimento; tradução/mídia têm também seus próprios campos de direito |
| Licença por tradução/ativo | `license`, `license_title`, `license_object_url`, `license_author`, `license_author_url`, `license_derivative_source_url`, `author_history` |

Exemplo de problema real: o ID **1022** mistura traduções que aparentam descrever movimentos diferentes; não publicar automaticamente. Na amostra de 75: seis com português, 37 com imagens, oito com vídeos; quatro imagens marcadas IA. Esses números contam presença de metadados, não inspeção das mídias.

**Não retorna nesta coleta:** programa semanal humano, indicação para dor/cirurgia, progressão individual, séries/cargas adequadas ao utilizador ou licença universal de todos os ativos. Fonte de movimentos não substitui fonte de programas.

**Evidência:** [resumo ampliado](evidencias/wger-amostra-ampliada.json); corpos locais `docs/planejamento/evidencias/wger-25.json`, `wger-languages.json` e `docs/conteudo/evidencias/wger-offset-{300,600}.json`. [Coletor inicial](../planejamento/evidencias/coletar-amostras.py), [expansão](evidencias/coletar-expansao.py).

## EX02 — free-exercise-db: arquivo de exercícios

```http
GET https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json
GET https://api.github.com/repos/yuhonas/free-exercise-db/commits?path=dist/exercises.json&per_page=1
```

HTTP 200 em 22/09; sem autenticação. O primeiro corpo é **um array**, com 876 registros. Cada objeto observado possui `id`, `name`, `force`, `level`, `mechanic`, `equipment`, `primaryMuscles[]`, `secondaryMuscles[]`, `instructions[]`, `category`, `images[]`. As instruções são passos textuais; imagens são caminhos relativos, não objetos completos de mídia licenciada. `force`, `mechanic` e equipamento não devem ser assumidos preenchidos em todo item.

Revisão de arquivo consultada: `79ca7b47d77cd5a6dd7a50440e9f0bf24da6a142`. O download veio de `main`; a consulta de commit foi separada. Isso registra o contexto, mas não prova sozinho que um download por revisão fixa foi executado. Usar revisão fixa e hash no futuro importador.

**Não recebemos** autoria/licença por registro, programa semanal ou validação clínica. Unlicense declarada pelo repositório não resolveu a origem de todas as imagens. Corpo local: `docs/planejamento/evidencias/free-exercise-db.json`; metadado de revisão em `free-exercise-revision.json`; [resumo de auditoria de 25 itens](../planejamento/evidencias/resumo-amostras.json).

## AL01 — USDA: busca e detalhe não têm o mesmo contrato

Chamadas de 22/09, HTTP 200; a URL completa de cada uma está no índice. Exemplos exatos:

```http
GET https://api.nal.usda.gov/fdc/v1/foods/search?api_key=DEMO_KEY&query=rice&pageSize=5&dataType=Foundation%2CSR+Legacy
GET https://api.nal.usda.gov/fdc/v1/food/748967?api_key=DEMO_KEY
```

Também foram usadas buscas `query=milk` e `query=egg`, com os mesmos parâmetros. O retorno `foodSearchCriteria` confirma `Foundation` e `SR Legacy`; foram guardados cinco resultados por busca, 15 IDs distintos. A chave de demonstração não é configuração de produção nem garante capacidade suficiente para o app.

| Recurso/caminho original | O que efetivamente recebemos |
|---|---|
| Busca: raiz | `totalHits`, `currentPage`, `totalPages`, `pageList`, `foodSearchCriteria`, `foods[]`, `aggregations` |
| Busca: `foods[]` | `fdcId`, `description`, `commonNames`, `additionalDescriptions`, `dataType`, `ndbNumber`, `publishedDate`, `foodCategory`; há campos auxiliares de pesquisa e outros arrays |
| Busca: `foodNutrients[]` | Forma plana: `nutrientId`, `nutrientName`, `nutrientNumber`, `unitName`, `value`, dados de derivação/origem, `rank`, `indentLevel`, `foodNutrientId`, `dataPoints`; alguns itens incluem mínimos/máximos/mediana |
| Detalhe: raiz | `fdcId`, `description`, `publicationDate`, `foodNutrients[]`, `foodPortions[]`, `dataType`, `foodClass`, `inputFoods[]`, `foodComponents[]`, `foodAttributes[]`, `nutrientConversionFactors[]`, `ndbNumber`, `isHistoricalReference`, `foodCategory` |
| Detalhe: `foodNutrients[]` | Forma aninhada: `nutrient.id/name/number/unitName/...` e valor `amount` quando presente. Existem itens de agrupamento (`isNutrientLabel`) sem quantidade; não tratá-los como zero |
| Detalhe: `foodPortions[]` | `id`, `dataPoints`, `gramWeight`, `sequenceNumber`, `amount`, `measureUnit.id/name/abbreviation`, e modificadores/datas quando presentes |

**Exemplo confirmado:** alimento **748967**, uma porção com `amount: 1`, `gramWeight: 50.3`, `modifier: "whole without shell"`, unidade `egg`; outra porção de 50 g usa `RACC`. Não são duas formas intercambiáveis de “1 ovo” nem uma recomendação de quantidade. A amostra de busca não traz `foodPortions`; o detalhe trouxe duas.

Selecionar nutrientes por identidade/unidade/método, nunca pela primeira posição. A busca por `milk` também devolve derivados/outros alimentos; confirmar nome e preparo. Quantidade consumida, equivalência pt-PT, fotografia licenciada e dieta não vêm prontos.

**Corpos locais:** `docs/planejamento/evidencias/usda-{rice,milk,egg}.json` e `usda-egg-detail.json`. [Coletor da busca](../planejamento/evidencias/coletar-amostras.py); o detalhe foi uma consulta pontual, registrada no próprio arquivo. Não fingir que o coletor original busca automaticamente todos os detalhes.

## AL05 — CoFID: composição em planilha

```http
GET https://assets.publishing.service.gov.uk/media/60538b91e90e07527df82ae4/McCance_Widdowsons_Composition_of_Foods_Integrated_Dataset_2021..xlsx
```

HTTP 200 em 23/09, 4.629.542 bytes, sem autenticação. O retorno é **XLSX binário**, não JSON. [URL, instante e hash](evidencias/cofid-2021.evidencia.json). Original local `docs/conteudo/evidencias/cofid-2021.xlsx`; [parser](evidencias/analisar-expansao.py) lê ZIP/XML sem executar macros.

Folha `1.3 Proximates`, `xl/worksheets/sheet4.xml` nesta edição; 2.760 linhas de alimentos. Validar folha/cabeçalho ao trocar edição, não confiar eternamente na posição.

| Coluna da edição recebida | Nome criado no extrator | Informação |
|---|---|---|
| A / B / C / D | `sourceId` / `nameOriginal` / `descriptionOriginal` / `groupOriginal` | Código, nome, descrição e grupo da fonte |
| F / G | `dataReferencesOriginal` / `footnoteOriginal` | Referências e observações |
| J / K / L | `proteinG` / `fatG` / `carbohydrateG` | Composição em gramas, preservando a base da tabela |
| M / N | `energyKcal` / `energyKj` | Valores de energia com unidades distintas |
| Z | `fibreAoacG` | Fibra pelo método indicado |

Valores `Tr`, `N` e célula vazia não significam zero. A base descrita é 100 g, com exceções documentadas para bebidas alcoólicas em 100 ml e outras folhas de ácidos gordos; não generalizar a folha inteira sem cabeçalhos/notas.

**Exemplo conferido:** `11-867`, arroz basmati integral cozido sem sal, 131 kcal/100 g; `11-866`, cru, 355 kcal/100 g. A entrada fictícia de teste 150 g resulta em 196,50 ou 532,50 kcal, respectivamente. Isso é cálculo, não porção sugerida. [Piloto de 12 alimentos](evidencias/2026-09-26/alimentacao-piloto.json).

O extrator anterior escolheu 27 linhas por regex: **não é busca portuguesa pronta**, tradução aprovada, composição de uma marca nem uma dieta. Licença identificada: OGL v3.0, observadas exceções. A amostra integral `cofid-amostra.json` permanece local.

## AL04 — Ciqual: metadados e arquivo são retornos distintos

```http
GET https://entrepot.recherche.data.gouv.fr/api/datasets/:persistentId/?persistentId=doi:10.57745/RDMHWY
GET https://entrepot.recherche.data.gouv.fr/api/access/datafile/666260
```

Metadados HTTP 200 em 23/09. A transferência XLSX falhou no certificado pelo Python; funcionou com `Invoke-WebRequest`, validação TLS padrão, recebendo 1.541.998 bytes. Não desligar TLS para reproduzir. [Registro do arquivo](evidencias/ciqual-2025-windows.evidencia.json), [metadados](evidencias/ciqual-2025-metadata.evidencia.json).

O JSON de metadados usa `data.latestVersion`: contém `license` (`etalab 2.0`), blocos de metadados e `files[]`; cada arquivo tem `label` e `dataFile.id/contentType/...`. **`666260` é ID de arquivo, não ID de alimento.** O endpoint devolve XLSX binário; `3484` é a contagem de alimentos lida nesta edição, não um campo de resposta JSON do arquivo.

| Cabeçalho/coluna da planilha recebida | Campo criado na amostra local | Utilização possível |
|---|---|---|
| G `alim_code` / H `alim_nom_fr` / I `alim_nom_sci` | `sourceId` / `nameOriginal` / `scientificName` | Identidade, nome francês, nome científico quando existente |
| K energia UE 1169 / M energia Jones | `energyKcalEU1169` / `energyKcalJones` | Energia por 100 g; métodos distintos não devem ser misturados |
| O proteína Jones / P proteína N×6,25 | `proteinJonesG` / `proteinNx625G` | Preservar método e unidade |
| Q / R / AA | `carbohydrateG` / `fatG` / `fibreG` | Gramas por 100 g |
| AX / BI | `saltG` / `sodiumMg` | Sal em g e sódio em mg; não confundir nem somar como se fossem o mesmo nutriente |

Folha `xl/worksheets/sheet1.xml` nesta edição. Valores numéricos, `-`, `traces`, limites como `<...` e vazios precisam de representação própria. A planilha não trouxe todos os vínculos por alimento/nutriente às fontes que podem existir no XML de composição; esse XML grande não foi coletado. Não inventar rastreabilidade inexistente no recorte.

O depósito também lista XMLs de alimentos, grupos, constituintes e fontes. Em 23/09 apenas a listagem e a planilha tinham sido obtidas; **N01, em 26/09, coletou os XMLs de alimentos e grupos**, descritos abaixo. O XML de composição `666249` continua não obtido. O piloto nutricional inicial escolheu 29 linhas por regex; `25088` é arroz cantonês pré-embalado, não arroz simples. Nomes portugueses e correspondências precisam de trabalho separado.

**Entradas locais:** `ciqual-2025.xlsx`, `ciqual-2025-metadata.json`, `ciqual-amostra.json` em `docs/conteudo/evidencias/`. [Coletor](evidencias/coletar-expansao.py), [parser](evidencias/analisar-expansao.py). Direitos e versão nos metadados guardados; não substituir automaticamente por nova edição.

### N01 — retorno XML de identidade alimentar

Coleta de 26/09, dois HTTP 200, sem autenticação. Cliente `Invoke-WebRequest`, TLS padrão; [coletor](evidencias/coletar-identidades.ps1). Os corpos têm 1.581.031 e 80.421 bytes. MD5 do depósito e SHA-256 locais conferidos. Os registros de [alimentos](evidencias/2026-09-26/n01-alimentos/ciqual-alimentos.evidencia.json) e [grupos](evidencias/2026-09-26/n01-alimentos/ciqual-grupos.evidencia.json) guardam URL, instante, headers e hash.

```http
GET https://entrepot.recherche.data.gouv.fr/api/access/datafile/666252
Accept: application/xml,text/xml
User-Agent: TrainForgeResearch/0.4 (food identity research)

GET https://entrepot.recherche.data.gouv.fr/api/access/datafile/666250
Accept: application/xml,text/xml
User-Agent: TrainForgeResearch/0.4 (food identity research)
```

Esses arquivos podem alimentar um lote local versionado. Não são pesquisas que o celular precise repetir a cada abertura.

| XML/caminho original | Tipo e retorno observado | Uso possível no app |
|---|---|---|
| `TABLE/ALIM/alim_code` | Texto numérico; 3.484 códigos únicos | Identidade acompanhada de fonte/edição |
| `alim_nom_fr`, `alim_nom_eng` | Texto; ambos presentes nos 3.484 alimentos | Nome original, pesquisa e apoio à localização |
| `alim_nom_sci` | Texto; preenchido em 720 registros; vazio nos restantes | Nome científico quando disponível |
| `alim_grp_code`, `alim_ssgrp_code`, `alim_ssssgrp_code` | Textos de 2, 4 e 6 dígitos, com zeros iniciais | Junção pela tupla dos três códigos; não converter para inteiros |
| `facteur_Jones` | Texto decimal de fator | Origem para análise de N02; não é quantidade consumida, caloria ou porção |
| `TABLE/ALIM_GRP` | 138 linhas: três códigos e `alim_grp_nom_fr/eng`, `alim_ssgrp_nom_fr/eng`, `alim_ssssgrp_nom_fr/eng` | Nomes de grupo/subgrupos; `-` e códigos zero não devem virar categorias inventadas |

Trecho real de um elemento, com espaços externos removidos pelo parser:

```xml
<ALIM>
  <alim_code>9100</alim_code>
  <alim_nom_fr>Riz blanc, cru</alim_nom_fr>
  <alim_nom_eng>Rice, white, raw</alim_nom_eng>
  <alim_nom_sci></alim_nom_sci>
  <alim_grp_code>03</alim_grp_code>
  <alim_ssgrp_code>0301</alim_ssgrp_code>
  <alim_ssssgrp_code>030102</alim_ssssgrp_code>
  <facteur_Jones>5.95</facteur_Jones>
</ALIM>
```

O analisador cria **campos nossos**: `sourceKey` (exemplo `ciqual:2025:9100`), `sourceFoodId`, `names.fr/en`, `scientificName`, `classificationCodes`, `classification`, `classificationStatus`, `preparationStructured`, `portugueseName` e `publicationStatus`. Preparo estruturado e nome português ficam nulos; publicação fica `research_only`. Os nomes originais preservam preparo/variante. Espaços e quebras de linha de apresentação são normalizados sem traduzir ou retirar qualificadores.

**Conferências:** todos os IDs e campos de identidade dos 3.484 alimentos correspondem à planilha; zero IDs/nomes franceses duplicados; nove pares de preparo preservados. Na classificação existem 11 códigos não zero de grupo, 65 de subgrupo e 85 do terceiro nível. O alimento `24999`, sobremesa média, usa `00/0000/000000` sem correspondência no arquivo de grupos: manter como classificação desconhecida.

| Código(s) real(is) | Distinção preservada |
|---|---|
| `9100` / `9104` | Arroz branco cru / cozido sem sal adicionado |
| `25088` | Arroz cantonês pré-embalado; prato composto distinto |
| `22000` / `22010` / `22013` | Ovo cru / cozido / em pó |
| `26043` / `26024` | Bacalhau cru / salgado e cozido em água |
| `20516` / `20507` / `20532` | Grão-de-bico seco / cozido / enlatado e escorrido |
| `36017` / `36018` / `36029` | Peito de frango sem pele cru / sem pele grelhado-frito / com pele cru |
| `20048` / `20137` | Tomate enlatado escorrido / sólidos e líquido do tomate em conserva |

Os rótulos portugueses acima explicam as diferenças; **não são a tradução do catálogo aprovada para publicação**. A fonte não entregou nomes em português, códigos de marca, fotos, alergénios ou preparo em campo separado. Os 3.484 registros não provam cobertura de todos os alimentos portugueses.

[Resumo N01](evidencias/2026-09-26/n01-alimentos/resumo-identidades.json), [30 exemplos explícitos](evidencias/2026-09-26/n01-alimentos/amostra-identidades.json), [analisador sem rede](evidencias/analisar-identidades.py). XMLs e normalizado integral ficam em `docs/conteudo/evidencias/2026-09-26/n01-alimentos/raw/`, ignorados pelo Git. Não foram instalados no app/banco.

```powershell
# Sem rede: reconstruir resumo/amostra com os insumos locais.
python docs/conteudo/evidencias/analisar-identidades.py

# Somente para obter os dois insumos, se ausentes; cache de sucesso/falha.
& ./docs/conteudo/evidencias/coletar-identidades.ps1
```

**Resultado N01:** identidade alimentar demonstrada neste recorte. **Próximo: N02**, composição/calorias com método/unidade/ausentes. Tradução pt-PT, medidas, fotos e guias mantêm seus nichos, sem check automático.

## AL02 / AL06 — produtos e fontes sem resposta de negócio

| Tentativa | Resposta efetivamente recebida | O que NÃO temos |
|---|---|---|
| OFF, busca de Portugal v3.6 e v2, 20 produtos, 22/09 | HTTP 503 | Nenhum produto, foto, nutriente ou código validado dessas chamadas |
| OFF v2, 30 produtos, 26/09 | HTTP 503; [URL exata e erro](evidencias/2026-09-26/network/off-portugal-30.evidencia.json) | Nenhuma amostra portuguesa; campos pedidos não são campos recebidos |
| Fineli `GET https://fineli.fi/fineli/api/v1/foods/11060`, 23/09 | HTTP 403; [registro](evidencias/fineli-food-11060.evidencia.json) | Nenhum alimento/composição recebido |

A consulta OFF de 26/09 usou `countries_tags=en:portugal`, `page_size=30`, `sort_by=unique_scans_n` e pediu `code,product_name,product_name_pt,brands,nutriments,serving_size,serving_quantity,nutrition_data_per,countries_tags,last_modified_t,lang,image_front_url,image_nutrition_url,ingredients_text,allergens_tags`. **Essa é a seleção enviada; não uma resposta observada.** Sua URL codificada integral está no índice. [Coletor usado](evidencias/coletar-pilotos.py).

PortFIR, BLS, Frida e outras fontes apenas documentais não possuem corpo amostrado aqui. Não produzir exemplo JSON fictício e apresentá-lo como retorno real. Cada uma mantém estado/data/próxima ação em [fontes.json](fontes.json).

## CI06 — Compêndio: HTML reduzido a código, descrição e MET

Chamadas de 23/09, HTTP 200, sem autenticação: `https://pacompendium.com/running/`, `/walking/`, `/bicycling/`, `/conditioning-exercise/`, `/water-activities/`. Os links completos constam do índice.

O retorno foi **HTML de tabelas**, não API JSON. O coletor criou `sample[].activityCode`, `metOriginal`, `descriptionOriginal`, selecionando quatro linhas por categoria; na água filtrou natação e em condicionamento alguns tipos de força/calisthenics. **20 registros preservados**, sem o HTML integral. Exemplo: código `12010`, MET original `6.0`, combinação de corrida/caminhada com a condição temporal descrita pela fonte.

Esses campos podem fundamentar classificação e estimativas posteriores; não medem calorias de uma pessoa e não constituem programa. Peso, duração e método de estimativa pertencem a outra decisão. Preservar descritor e contexto, sem substituir por um nome genérico que altere a intensidade.

Evidência local `docs/conteudo/evidencias/compendium-*.evidencia.json`, resumo [resumo-expansao.json](evidencias/resumo-expansao.json). O SHA-256 registrado é do HTML original; só restou o recorte da tabela, portanto não pode ser recalculado a partir dele. Uso comercial e atribuição documentados no catálogo da fonte.

## PR06 — programa de corrida NHS

```http
GET https://www.nhs.uk/better-health/get-active/get-running-with-couch-to-5k/couch-to-5k-running-plan/
GET https://digitalcampaignsstorage.blob.core.windows.net/campaigns-cms-prod/documents/c25k_printable_plan.pdf
```

HTTP 200 em 26/09, sem autenticação. Retornos: **HTML e PDF de duas páginas**, sem JSON de sessões. [Coletor](evidencias/coletar-pilotos.py) também guardou os termos e a lista de exclusões NHS. [Analisador](evidencias/analisar-pilotos.py) verifica hashes e extrai `details > summary` (semana/corrida), tempo declarado e linhas `dt`/`dd` (aquecimento, caminhada, corrida, final e desaceleração).

| Campo criado no piloto | Informação comprovada |
|---|---|
| `weeks`, `sessionsPerWeek`, `restDaysBetweenRunsMinimum` | Nove semanas, três sessões por semana, descanso entre corridas |
| `sessions[].week/run/patternId/declaredSecondsExcludingStretches` | 27 sessões, sem duplicar os 12 padrões de intervalos |
| `patterns[].blocks[].phase/activity/seconds` | Sequência numérica extraída, comparada com a tabela PDF; aquecimento/desaceleração separados |
| `endTarget.runningMinutes`, `guaranteedDistanceKm` | 30 minutos de corrida; distância garantida fica nula |
| `stretchDurationSeconds` | Nulo: a fonte orienta alongamentos, mas o piloto não inventa duração |
| `source`, `crossCheckSource`, `rights`, `attribution`, `publicationGaps` | Proveniência e limites da utilização; `releaseStatus` é pesquisa, não publicação aprovada |

**Exemplo:** semana 1, corrida 1, padrão 1: 300 s de aquecimento a caminhar; sete pares de corrida de 60 s/caminhada de 90 s; corrida final de 60 s; 300 s de desaceleração. Total **1.710 s**, sem duração de alongamentos. É transcrição de estrutura da fonte para pesquisa, não treino prescrito ao leitor.

Resultado completo: [corrida-piloto.json](evidencias/2026-09-26/corrida-piloto.json). Original local: `2026-09-26/network/raw/nhs-c25k.html` e `nhs-c25k-table.pdf`, sob a pasta de evidências. Não trouxe áudio de treinador, app NHS, mídia licenciada ou adaptação portuguesa aprovada.

## PR05 — rotina de força NHS

`GET https://www.nhs.uk/live-well/exercise/strength-exercises/`, HTTP 200 em 26/09. **HTML**, com sete seções e 20 passos instrucionais A/B/C. A rotina não define uma periodização completa para academia.

O piloto nosso tem `minimumDaysPerWeek`, `programWeeks`, `sessionMinutes`, `exercises[]`. Cada item contém `sourceOrder`, `sourceName`, `ptDraftKey`, `sets`, `repetitionsMin/Max`, `perSide`, `holdSecondsMaximum`, `restSeconds`, `instructionStepsInSource`, `sourceTextSha256`. `ptDraftKey` é rascunho técnico, não tradução revista. Séries dos cinco primeiros movimentos, descanso e duração global não declarados permanecem nulos.

O JSON guarda parâmetros e contagem de passos; **não contém a instrução completa**. Ela permanece no HTML local `2026-09-26/network/raw/nhs-strength.html`. [Resultado](evidencias/2026-09-26/forca-piloto.json). As fotos da página não foram baixadas/aprovadas. Não mapear um movimento a outro apenas pelo nome: a seção inglesa “Leg extension” precisa ser conferida pelo gesto descrito antes de ligar a um catálogo de academia.

## Outras pesquisas: evidência documental, sem retorno importado

- CDC/Tufts *Growing Stronger*: PDF consultado no leitor web; conflito entre metadado de domínio público e condições no documento. Sem lote importável aprovado.
- Competitive Edge: artigo e correção consultados; programa supervisionado, sequência integral não obtida. Não contar como sessões disponíveis.
- NHLBI: uma receita foi lida na web com ingredientes, quatro porções, preparo e nutrientes; sem coletor/importação do catálogo. O PDF de caminhada tentado deu 404.
- Health Connect, HealthKit, ML Kit, mapas e hosts: documentação técnica consultada; **nenhum retorno real de aparelho, foto, GPS, mapa com chave ou deploy foi coletado**. A [matriz de viabilidade](../planejamento/viabilidade-operacional.md) descreve candidatos, não respostas testadas.

As 45 fichas de fontes incluem referências, incompatibilidades e candidatos sem amostra. Este documento cobre todos os tipos de retorno efetivamente guardados, e o índice lista cada chamada preservada; não transforma pesquisa de site em API testada.

## Requisitos para a implementação futura

1. Separar adaptadores por fonte e por tipo de resposta, mantendo IDs originais, edição, data, hash, unidade, método e licença.
2. Não juntar IDs iguais de fontes diferentes nem unificar alimento cru/cozido, salgado/fresco, drenado/com líquido ou com/sem parte não comestível por semelhança de nome.
3. Guardar dado ausente, traço, limite, erro de fornecedor e ausência real de resultados como estados distintos.
4. Preservar instrução, público, agenda e progressão do programa humano; alterações do utilizador precisam de identidade própria.
5. Consumir um lote local versionado quando permitido. O app não precisa baixar planilhas ou consultar todos os fornecedores em cada abertura.
6. Resolver revisão pt-PT, autorização da mídia e adequação antes da publicação. Cada nicho da [etapa 01](../planejamento/etapa-01-pesquisa.md) deve fechar uma pergunta delimitada; a arquitetura e os contratos definitivos pertencem a etapas posteriores.
