# Evidências de retorno para a implementação

Registro iniciado em **26/09/2026 e atualizado em 30/09/2026**, baseado nas chamadas e arquivos preservados de 22–30/09. Este documento responde **de onde veio, como foi chamado, o que retornou, onde está e o que pode alimentar no app**. Não define os futuros endpoints internos do TrainForge nem afirma que as integrações existem.

Os campos abaixo foram observados em amostras. Presença na amostra não é garantia de obrigatoriedade ou disponibilidade futura do fornecedor. As permissões e limitações continuam no [catálogo por fonte](fontes.json) e em [direitos](direitos-e-acordos.md).

## Como recuperar sem fazer outra chamada

- [Índice de chamadas e hashes](evidencias/retornos-observados.json): **147 registros de chamadas preservadas, 114 respostas HTTP 200**, incluindo tentativas sem rede, falhas, dois casos negativos 404 e EUR-Lex 202 sem texto legal utilizável. Não são 147 APIs nem 114 fontes distintas. N10 acrescentou 10 tentativas, incluindo uma URL 404 corrigida pelo link oficial; reutilizou três políticas e uma página anterior.
- [Inventariador local](evidencias/inventariar-retornos.py): gera o índice sem rede; conferiu 113 corpos mantidos como arquivos contra o SHA-256 original. Não confundir o hash de um corpo HTTP com o de um JSON reformatado pelo coletor.
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

**Resultado N01:** identidade alimentar demonstrada neste recorte. N02 amplia a composição abaixo. Tradução pt-PT, medidas, fotos e guias mantêm seus nichos, sem check automático.

### N02 — composição nutricional e campos utilizáveis

Reanálise local em 26/09/2026 da **mesma planilha Ciqual 2025 recebida em 23/09**, com SHA-256 conferido. Nenhum alimento foi novamente transferido. A chamada XLSX e seus metadados estão na seção AL04 acima. O [analisador N02](evidencias/analisar-composicao.py) cruza os IDs com N01, lê todos os valores e produz:

- [Dicionário dos 74 campos](evidencias/2026-09-26/n02-composicao/dicionario-composicao.json): cabeçalho literal, coluna, unidade, base, método, contagens e chave sugerida quando definida.
- [Resumo de cobertura](evidencias/2026-09-26/n02-composicao/resumo-composicao.json): resultado integral e limites.
- [30 exemplos](evidencias/2026-09-26/n02-composicao/amostra-composicao.json): mesmos IDs selecionados em N01, com valores e qualificadores.
- [Comparação Ciqual/USDA/CoFID](evidencias/2026-09-26/n02-composicao/comparacao-contratos.json): diferenças efetivamente observadas nos arquivos locais.

O normalizado integral fica em `docs/conteudo/evidencias/2026-09-26/raw/n02-composicao-normalizada.json`, excluído do Git. É material de pesquisa, não seed do app.

**Retorno comprovado:** 3.484 IDs de alimentos × 74 campos = **257.816 células**. São 151.981 valores numéricos, 83.246 desconhecidos, 2.514 traços e 20.075 limites superiores exclusivos. Entre os numéricos há **30.870 zeros expressos pela fonte**; não são valores preenchidos pelo analisador. O fator de Jones, coluna CF, fica separado dos 74 campos nutricionais.

| Campo sugerido do app | Coluna real | Unidade/base | Numéricos / ausentes / traço / limite |
|---|---|---|---|
| `energyKcalEu` | K | kcal / 100 g | 3.339 / 143 / 2 / 0 |
| `energyKjEu` | J | kJ / 100 g | 3.339 / 143 / 2 / 0 |
| `proteinNx625G` | P | g / 100 g | 3.451 / 29 / 4 / 0 |
| `carbohydrateG` | Q | g / 100 g | 3.272 / 70 / 134 / 8 |
| `fatG` | R | g / 100 g | 3.283 / 20 / 15 / 166 |
| `sugarsG` | S | g / 100 g | 2.996 / 223 / 205 / 60 |
| `fibreG` | AA | g / 100 g | 3.239 / 70 / 45 / 130 |
| `saturatedFatG` | AF | g / 100 g | 3.093 / 248 / 8 / 135 |
| `saltG` | AX | g / 100 g | 3.141 / 190 / 2 / 151 |
| `sodiumMg` | BI | mg / 100 g | 2.929 / 402 / 4 / 149 |

**Seleção para implementação futura:** usar esse conjunto de dez campos como base da ficha nutricional, com energia K/J e proteína P identificadas pelo método. Guardar também os 74 campos originais para detalhe técnico, incluindo minerais, vitaminas, ácidos gordos e formas específicas de folato/vitamina D. Não somar variantes de um mesmo nutriente nem tratar µg, mg e g como a mesma unidade. Não escolher uma coluna pela posição depois de uma atualização sem conferir o cabeçalho e a edição.

Há **3.006 alimentos com K/P/Q/R numéricos simultaneamente** e **2.205 com os dez campos numéricos**. A disponibilidade de um nome em N01 não garante calorias ou micronutrientes completos. Esses números medem preenchimento do arquivo, não qualidade clínica, adequação individual ou cobertura portuguesa.

**Métodos conferidos:** a [documentação oficial Ciqual 2025, seção 3.3.6](https://ciqual.anses.fr/cms/sites/default/files/inline-files/Table%20Ciqual%202025%20doc%20FR_2025_11_19.pdf) distingue a energia calculada com proteína N×6,25 da calculada com fatores de Jones. Fibra, álcool, polióis e ácidos orgânicos também entram no método da fonte; não substituir a energia publicada por uma conta simplificada de três macros. Algumas estimativas internas usadas pelo fornecedor não são publicadas como valores dos nutrientes. Portanto, energia conhecida não autoriza preencher os campos ausentes com zero. A consulta documental foi via web; não houve novo corpo HTTP dessa documentação arquivado no índice então com 44 chamadas; a expansão N03 não inclui uma nova cópia desse PDF Ciqual.

Exemplo real: arroz branco cru `9100` tem **350 kcal** na coluna K e **348 kcal** na M; são métodos diferentes. O arroz branco cozido `9104` tem **155 kcal**, proteína P **3,31 g**, hidratos Q **33,2 g**, gordura R **0,7 g**, açúcares S em **traços** e frutose T **< 0,08 g**, por 100 g. Não trocar o registro cru pelo cozido nem arredondar o limite para zero.

Formato **criado pelo analisador**, não resposta de uma API Ciqual:

```json
{
  "sourceFoodId": "9104",
  "valuesBySourceColumn": {
    "K": {"raw": "155", "status": "numeric", "valueDecimal": "155", "limitDecimal": null},
    "S": {"raw": "traces", "status": "trace", "valueDecimal": null, "limitDecimal": null},
    "T": {"raw": "< 0,08", "status": "below_limit", "valueDecimal": null, "limitDecimal": "0.08"}
  }
}
```

O dicionário fornece unidade/base/método para cada coluna. A planilha não fornece IDs de constituintes: `sourceNutrientId` fica nulo; K é uma coordenada desta edição, não um ID de nutriente inventado. `valueDecimal` e `limitDecimal` são strings decimais exatas; o valor original é preservado. Os estados são: `numeric` (inclui zero), `unknown`, `trace` e `below_limit`. Valores desconhecidos não recebem zero nem são copiados de um alimento parecido. O importador falha diante de um formato não reconhecido.

**Diferenças que a implementação deve respeitar:** USDA usa IDs de nutrientes e `foodNutrients[].amount`; as linhas de agrupamento podem não ter `amount` e não são nutrientes zerados. A busca tem outro formato. CoFID usa outras colunas, convenções e bases: a evidência registra exceções de 100 ml para bebidas alcoólicas e folhas de ácidos gordos. Não reutilizar cegamente o parser Ciqual. “Hidratos por diferença” e “hidratos disponíveis” não são equivalências automáticas. Não combinar nutrientes de duas fontes pelo nome traduzido do alimento.

```powershell
# Reconstrução local; sem chamada externa e sem alterar app/banco.
python docs/conteudo/evidencias/analisar-composicao.py
```

**Fechamento N02:** composição, campos, métodos, unidades, cobertura e semântica de ausentes demonstrados neste recorte. Falta homologação editorial/pt-PT, integração e proveniência bibliográfica por célula, que o XLSX não entrega. Nada disso foi marcado como implementado. **N03**, concluído abaixo em 27/09, tratou quantidades consumidas, unidades, porções e limites de conversão; metas pessoais e dietas pertencem a outros nichos.

### N03 — quantidades, porções, volume e preparo

**Pesquisa concluída no recorte abaixo em 27/09/2026**, após validação do N02. O piloto preparado em 26/09 não tinha sido executado: a revisão automática falhou por esgotamento de cota. Na retomada, passou e foi ampliado. Esta conclusão define regras demonstradas e limites de conversão; não disponibiliza uma tabela universal de medidas nem implementa o diário no app.

**Artefatos para implementação futura:** [resumo](evidencias/2026-09-27/n03-porcoes/resumo-porcoes.json), [casos com valores reais](evidencias/2026-09-27/n03-porcoes/casos-porcoes.json), [26 verificações](evidencias/2026-09-27/n03-porcoes/validacao-porcoes.json), [duplicidade CoFID](evidencias/2026-09-27/n03-porcoes/duplicidades-cofid.json), [analisador](evidencias/analisar-porcoes.py). O [piloto inicial](evidencias/2026-09-27/n03-porcoes/piloto-inicial.json) é preservado como passo anterior, não como estado final.

#### Chamadas novas e formato recebido

Foram três GETs em 27/09, todos HTTP 200. O [coletor](evidencias/coletar-porcoes.ps1) usa TLS padrão, `User-Agent: TrainForgeResearch/0.5 (portion research)` e `Accept: application/json,application/pdf,text/html`; guarda sucessos/falhas e não repete automaticamente. A autenticação da API usa apenas a chave pública de demonstração. Os corpos integrais ficam em `docs/conteudo/evidencias/2026-09-27/raw/`, ignorados pelo Git.

| Origem/chamada | Retorno observado | Registro com data, headers e SHA-256 |
|---|---|---|
| `GET https://api.nal.usda.gov/fdc/v1/food/171942?api_key=DEMO_KEY` | JSON, 33.327 bytes; bebida de arroz sem açúcar, `SR Legacy`. ID já encontrado na busca local anterior | [USDA 171942](evidencias/2026-09-27/n03-porcoes/usda-rice-drink.evidencia.json) |
| [Guia CoFID 2021](https://assets.publishing.service.gov.uk/media/60538e66d3bf7f03249bac58/McCance_and_Widdowsons_Composition_of_Foods_integrated_dataset_2021.pdf) | PDF, 777.103 bytes; páginas 7 e 9 conferidas para bases e fatores | [Guia CoFID](evidencias/2026-09-27/n03-porcoes/cofid-guide.evidencia.json) |
| [USDA Foundation Foods Documentation](https://fdc.nal.usda.gov/Foundation_Foods_Documentation/) | HTML, 162.792 bytes; seções Weights e Limits of Quantification | [Guia USDA](evidencias/2026-09-27/n03-porcoes/usda-foundation-guide.evidencia.json) |

A primeira URL antiga do guia CoFID, ainda indexada pela pesquisa web, não abriu nessa ferramenta. O link atual foi obtido na [publicação oficial](https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid) e funcionou. Não repetir o endereço antigo.

`foodPortions[0]` do alimento USDA `171942` trouxe **`id: 89598`, `amount: 8`, `gramWeight: 240`, `dataPoints: 3`**, `measureUnit.id: 9999`, `measureUnit.name: "undetermined"` e `modifier: "fl oz (approximate weight, 1 serving)"`. Os 240 g correspondem às oito unidades descritas pela fonte. Quatro dessas unidades correspondem a 120 g; metade da porção não pesa 240 g. O peso é aproximado e a descrição original deve acompanhar a seleção. Não substituir silenciosamente por “copo de 250 ml” ou “chávena portuguesa”.

A chamada antiga USDA `748967`, reaproveitada sem rede, tem duas porções distintas: `193781` para ovo inteiro sem casca, 1 unidade/50,3 g, e `312625` para RACC, 1/50 g. A segunda é uma referência regulatória, não outro peso intercambiável de um ovo.

#### Fatores que já estavam na planilha CoFID

A aba `1.2 Factors` corresponde a `xl/worksheets/sheet3.xml`; a composição a `sheet4.xml`. A coluna A é o código, B o nome, C a descrição, **H a proporção comestível e I a densidade relativa**. A planilha de 23/09 foi reutilizada e seu hash reconferido.

**Correção da contagem anterior:** cada aba tem 2.760 linhas alimentares e 2.759 IDs distintos. O código **`13-669` aparece duas vezes em ambas**, associado a berinjela assada em óleo e a agrião cru; os nomes/valores originais estão no artefato de duplicidade. O piloto registra as duas linhas e exclui esse ID, sem escolher uma arbitrariamente. Restam **2.758 IDs com correspondência única** entre as abas. Nesse conjunto, 2.724 proporções comestíveis são numéricas e 34 desconhecidas; apenas 54 densidades relativas são numéricas, contra 2.704 desconhecidas. A contagem antiga “2.760 alimentos” media linhas, não identidade única validada.

O guia CoFID define a proporção comestível como a fração restante após descarte e a densidade relativa como uma razão em relação à água. Ela é adimensional: **1,03 não é, por si só, uma medição documentada de 1,03 g/ml**. Sem condições/densidade de referência ou outra relação massa-volume comprovada, esta pesquisa não habilita conversão automática de ml para g. A própria planilha diferencia bases por 100 g, bebidas alcoólicas por 100 ml e certas folhas por 100 g de ácidos gordos; esses denominadores não podem ser misturados. [Fonte: guia CoFID, páginas 7 e 9](https://assets.publishing.service.gov.uk/media/60538e66d3bf7f03249bac58/McCance_and_Widdowsons_Composition_of_Foods_integrated_dataset_2021.pdf).

Exemplo de dupla aplicação a evitar: `14-898`, amêndoas pesadas com casca, já traz **205 kcal por 100 g nessa condição** e informa origem calculada de `14-896`, miolo, com 554 kcal/100 g. O fator comestível é 0,37. A relação 554 × 0,37 = 204,98 explica o valor publicado arredondado. Aplicar 0,37 novamente sobre 205 daria 75,85 kcal e estaria errado para esse registro.

#### Regras demonstradas e retorno esperado

As quantidades a seguir são entradas fictícias de verificação aritmética, não porções recomendadas.

| Entrada e origem | Resultado esperado | Condição |
|---|---|---|
| 150 g do arroz cozido Ciqual `9104`, 155 kcal/100 g | 232,5 kcal | Usar a ficha do alimento/preparo efetivamente pesado |
| 0,15 kg do mesmo alimento | Mesmo resultado | Converter apenas dentro da dimensão massa |
| 250 ml da cerveja CoFID `17-506`, 30 kcal/100 ml | 75 kcal | Exemplo para verificar base volumétrica nativa, não sugestão de consumo |
| 2 ovos da porção USDA `193781` | 100,6 g | Preservar alimento, porção e descrição “sem casca” |
| 4 unidades da medida descrita na porção USDA `89598` | 120 g e 56,4 kcal | `massa = quantidade / amount × gramWeight`; peso aproximado; energia da mesma ficha |
| Frutose `< 0,08 g/100 g`, massa de 150 g | `< 0,12 g` | O limite permanece exclusivo, não vira uma quantidade exata |
| Açúcar em traços ou nutriente desconhecido | Estado preservado | Não converter para zero |
| 100 g de amêndoas já pesadas com casca `14-898` | 205 kcal | Não reaplicar o fator comestível |

Para uma base de 100 g, o método usa valor × massa/100; os pesos de porção Foundation Foods se referem à parte comestível, e as porções pertencem ao tipo de dado/alimento. A documentação USDA também informa que limites de quantificação podem ser guardados num campo próprio com valor do componente igual a zero: um futuro adaptador deve conferir esse qualificador antes de interpretar zero. [Fonte: USDA, Weights e Limits of Quantification](https://fdc.nal.usda.gov/Foundation_Foods_Documentation/).

Campos que o aplicativo precisará preservar: `sourceId`, versão, `foodId`, preparo/condição, nutriente/método/unidade, quantidade e unidade da base, quantidade/unidade consumida, `portionId`, `amount`, `gramWeight`, descrição da medida, aproximação e origem da conversão. Esses nomes são proposta de contrato interno, não campos já existentes no backend.

Resultados sem conversão devem ser explícitos: `needs_source_conversion` para dimensões diferentes ou medida genérica; `portion_food_mismatch` para porção de outro alimento; `invalid_quantity` para zero/negativo/não finito/entrada inválida. São resultados do protótipo de pesquisa; a interface futura deverá permitir corrigir, pesar ou escolher outra medida válida.

Para somas, manter **subtotal conhecido** e estado `incomplete` quando houver ausentes/traços/limites. Um limite superior só é calculável no recorte testado quando todos os termos forem numéricos ou limites conhecidos, com a mesma unidade e definição de nutriente. Não somar energia ou nutrientes de métodos incompatíveis automaticamente. Conservar decimais durante o cálculo e arredondar apenas na apresentação; arredondar limites para fora, sem transformar `< 0,004` em `< 0,00`.

**O que temos:** cálculo por massa e volume nativo, duas fichas USDA com três registros de porção auditados, fatores CoFID com cobertura medida, tratamento de parte comestível, erros, estados e arredondamento demonstrados em 26 verificações. **O que falta:** tabela ampla de medidas caseiras em Portugal, condições de densidade suficientes para conversões gerais, rendimentos/retenção por preparo e validação editorial das medidas apresentadas. Não deduzir rendimento cru→cozido pela razão entre calorias de duas fichas; preferir a ficha e o peso do preparo consumido. Esses limites continuam registrados para implementação/expansão.

```powershell
# Pesquisa reproduzível, sem rede; requer os insumos locais documentados.
python docs/conteudo/evidencias/analisar-porcoes.py
# Somente para obter os três insumos se ausentes; falhas também ficam em cache.
powershell -File docs/conteudo/evidencias/coletar-porcoes.ps1
```

## N04 — produtos vendidos em Portugal

**[x] Pesquisa N04 concluída em 28/09/2026, com limites explícitos.** A amostra acumulada tem **24 produtos únicos**. Os quatro recortes de marca foram observados: Pingo Doce (5), Continente (3), Mimosa (3) e Compal (3), além dos dez produtos iniciais. Esses recortes são de conveniência; não medem cobertura de mercado nem validam rótulos atuais. [Resumo](evidencias/2026-09-28/n04-fechamento/resumo-fechamento.json), [amostra e proveniência](evidencias/2026-09-28/n04-fechamento/amostra-complementar.json), [35 verificações](evidencias/2026-09-28/n04-fechamento/validacao-fechamento.json).

As buscas menores de Continente/Mimosa responderam 200; Compal continuou 503 na v2. A alternativa oficial **Search-a-licious** trouxe três Compal com país/marca conferidos; a leitura direta v3.6 de `5601151964804` confirmou o produto. Foram oito novas chamadas: sete 200, um 503 preservado, oito hashes. O contrato nutricional anterior foi reproduzido: 27 verificações passaram. Índice acumulado após N04: 68 chamadas / 43 HTTP 200 / 36 hashes.

### Chamadas complementares e interpretação

- `GET https://world.openfoodfacts.org/api/v2/search`: `countries_tags=en:portugal`, `brands_tags=continente` ou `mimosa`, `page_size=3` e projeção curta, sem ordenar. Campos exatos, URL codificada e headers em [requisicoes.json](evidencias/2026-09-28/n04-fechamento/requisicoes.json) e metadados correspondentes. Retorno `products[]`; marcas são texto em `brands`.
- `GET https://search.openfoodfacts.org/search`: `q=brands:"compal" AND countries_tags:"en:portugal"`, `langs=pt,en`, `page_size=3`, `fields` explícitos. Contrato descoberto em `/openapi.json`; retorno `hits[]`, não `products[]`, e `brands` é lista. `count=96` é do índice do fornecedor, não uma auditoria de 96 produtos. [Chamada](evidencias/2026-09-28/n04-fechamento/n04-compal-searchalicious.evidencia.json), [OpenAPI preservado](evidencias/2026-09-28/n04-fechamento/n04-search-openapi.evidencia.json).
- `GET https://world.openfoodfacts.org/api/v3.6/product/5601151964804`: o detalhe tem `last_modified_t=1774951185`, enquanto a busca tinha `1712929968`. **Revalidar o detalhe ao selecionar um resultado**; não tratar o índice como revisão atual. A v3.6 devolveu `brands_tags=["xx:compal"]` e `tags_sources.brands.packaging.tags=["xx:Compal"]`; a busca devolveu `compal`. Preservar namespace, versão e origem, sem comparar tags brutas entre versões como se fossem idênticas. [Detalhe](evidencias/2026-09-28/n04-fechamento/n04-compal-product.evidencia.json).
- Contagens informadas, não auditadas integralmente: Continente 2.357, Mimosa 177, Compal 96 no índice alternativo; Pingo Doce 1.778 no incremento anterior. Não somar essas contagens como cobertura portuguesa.

### Decisão de reutilização para implementação futura

O uso comercial está previsto na [ODbL, seção 3.1](https://opendatacommons.org/licenses/odbl/1-0/), condicionado às obrigações da licença. A base é ODbL 1.0; conteúdo individual DbCL 1.0; imagens têm termos separados. Atribuição deve acompanhar os dados exibidos, com links para fonte/licença. Um catálogo público derivado deverá cumprir compartilhamento e acesso legível por máquina conforme as seções 4.4–4.6. Não incorporar diários privados à base derivada. A separação de tabelas por si só não prova independência jurídica. [Decisão e requisitos](evidencias/2026-09-28/n04-fechamento/decisao-reutilizacao.json), [termos oficiais preservados](evidencias/2026-09-28/n04-fechamento/n04-off-reuse-terms.evidencia.json).

Escolha de pesquisa: **OFF é candidato demonstrado para consulta de produto embalado, com confirmação, atribuição e estados de ausência/falha**. Não há homologação de mercado, SLA, aprovação editorial ou integração Flutter/API/banco. Registro manual deve continuar possível. Direitos das fotografias foram investigados no N06 abaixo; sem liberação integral. O problema operacional da busca Compal permanece registrado; a alternativa foi demonstrada, não apagou a falha.

Reproduzir sem rede: `python -X utf8 docs/conteudo/evidencias/analisar-fechamento-n04.py`. Coleta limitada: [coletar-nichos-off.py](evidencias/coletar-nichos-off.py), manifestos [principal](evidencias/2026-09-28/n04-fechamento/requisicoes.json) e [alternativa](evidencias/2026-09-28/n04-fechamento/alternativa.json). Cache guarda falhas e sucessos; não executar para recuperar contexto. Corpos integrais permanecem locais e ignorados pelo Git.

### Histórico do contrato — antes do fechamento

**Snapshot intermediário de 28/09, superado pelo fechamento N04 acima:** o contrato nutricional foi esclarecido e o demonstrador local validado. N04 permanece **em andamento** pela cobertura incompleta dos filtros de marca. O primeiro incremento de 27/09 está publicado no commit [`104a3bb`](https://github.com/richardcastrogois/TrainForge/commit/104a3bb69403e76a16e8f655549d010779466a40); o avanço abaixo é posterior e local. A coleta antiga mais abaixo é histórica.

### Resolução do contrato e estados — 28/09

O [changelog oficial](https://openfoodfacts.github.io/openfoodfacts-server/api/ref-api-and-product-schema-change-log/) registra mudança da estrutura nutricional a partir da API 3.5/schema 1003 e a evolução para schema 1004 na 3.6. O título de data da entrada 3.5 contém uma grafia inválida na fonte; não a corrigimos ou usamos como data confiável. A leitura real da 3.6, com **`nutrition` na projeção**, confirmou os dados do produto já observado. [Corpo/metadados do changelog](evidencias/2026-09-28/n04-contrato-off/off-schema-changelog.evidencia.json).

**Chamada corrigida:** `GET https://world.openfoodfacts.org/api/v3.6/product/5449000054227`, parâmetro `fields=code,product_name,brands,countries_tags,nutrition,nutriments,schema_version,quantity,product_quantity,product_quantity_unit,serving_quantity,serving_quantity_unit,no_nutrition_data`. HTTP 200, 4.612 bytes. [URL completa/data/hash](evidencias/2026-09-28/n04-contrato-off/off-product-nutrition-v36.evidencia.json). `User-Agent: TrainForgeResearch/0.7 (+https://github.com/richardcastrogois/TrainForge; N04 research)`; `Accept: application/json,text/html`. Mesmo limite de 25 s/1 MiB, TLS padrão e cache de falhas/sucessos.

| Caminho realmente recebido | Valor observado / uso futuro |
|---|---|
| `product.schema_version` | `1004`; o demonstrador rejeita schema desconhecido |
| `product.nutriments` | `{}`; não é prova de que o produto carece de nutrientes |
| `product.nutrition.aggregated_set.per` / `preparation` | `100g` / `as_sold`; conservar a base e a condição |
| `...aggregated_set.nutrients.energy-kcal` | `value: 42`, `value_computed: 42.4`, `unit: kcal`, `source: packaging`, `source_index: 0`, `source_per: 100g` |
| `product.nutrition.input_sets[0]` | Origem `packaging`, base explícita `per_quantity: 100`, `per_unit: g`; valores e `value_string` recebidos |
| `product.nutrition.input_sets[1]` | Origem `packaging`, `per: serving`, `per_quantity: 250`, `per_unit: ml`; energia informada 105 kcal e hidratos 27 g |
| `product.nutrition.input_sets[2]` | Origem `estimate`; açúcares adicionados 11,1 g, `modifier: ~`; não substituir pelo valor agregado 0 da embalagem nem ocultar que é estimativa |

A busca v2 trazia 42 kcal na base `_100g` e 26,5 g de hidratos na porção calculada. O novo `input_sets[1]` traz **27 g informados**, que o demonstrador preserva. Não sobrescrever valores de origens/métodos distintos. A embalagem é 1 L, mas isso não transforma a base agregada de 100 g em 100 ml; para a porção em ml, usar somente a base explícita do conjunto correspondente. Esta pesquisa não habilita conversão livre massa/volume.

**Outro cuidado observado:** `nova-group` apareceu como 1,6 no agregado e 4 no conjunto de porção. Não é grandeza nutricional a ser escalada. O demonstrador inclui apenas nutrientes explicitamente previstos, exclui esse campo e preserva os originais no corpo auditável; não corrige silenciosamente a classificação nem a apresenta como validada.

Implementação de pesquisa: [analisar-contrato-off.py](evidencias/analisar-contrato-off.py). Saída [contrato-nutricional.json](evidencias/2026-09-28/n04-contrato-off/contrato-nutricional.json), com origem, caminhos externos, valores decimais, informado/calculado, unidade, base, condição, índices de origem e qualificador. Não é o contrato já implementado no backend. **27 verificações passaram**, usando os retornos preservados e casos locais sintéticos para valores inválidos, projeção ausente e schema desconhecido. [Validação](evidencias/2026-09-28/n04-contrato-off/validacao-contrato.json).

### Cobertura dirigida e falhas preservadas

Antes da coleta, foram escolhidos quatro filtros de conveniência: duas marcas de supermercado (Continente/Pingo Doce) e duas marcas alimentares (Mimosa/Compal), sempre com país Portugal. Isso busca diversidade, não constitui amostragem estatística. Endpoint `GET /api/v2/search`, com `countries_tags=en:portugal`, `brands_tags=<filtro>`, `page_size=5`, `page=1`, `sort_by=unique_scans_n`. A projeção adiciona `brands_tags` e `categories_tags` aos campos anteriores; os metadados guardam a URL literal.

| Filtro / caso | Retorno real | Evidência |
|---|---|---|
| `brands_tags=pingo-doce` | 200; cinco códigos únicos, todos com país/marca esperados; `count: 1778` informado pelo fornecedor | [Chamada](evidencias/2026-09-28/n04-contrato-off/off-brand-pingo-doce.evidencia.json), [amostra](evidencias/2026-09-28/n04-contrato-off/amostra-dirigida.json) |
| `brands_tags=continente` | 503; cobertura desse filtro não medida | [Falha](evidencias/2026-09-28/n04-contrato-off/off-brand-continente.evidencia.json) |
| `brands_tags=mimosa` | 503; cobertura desse filtro não medida | [Falha](evidencias/2026-09-28/n04-contrato-off/off-brand-mimosa.evidencia.json) |
| `brands_tags=compal` | 503; cobertura desse filtro não medida | [Falha](evidencias/2026-09-28/n04-contrato-off/off-brand-compal.evidencia.json) |
| Marca sintética `trainforge-validation-absent-20260928`, `page_size=1` | 200, `count: 0`, lista vazia: estado `empty` | [Chamada](evidencias/2026-09-28/n04-contrato-off/off-empty-search-fixture.evidencia.json) |
| Código sintético `0000000000000` | 404; normalizado pela fonte para `00000000`, com `invalid_code`, `product_not_found` e aviso de normalização; priorizar correção do código | [Chamada](evidencias/2026-09-28/n04-contrato-off/off-missing-product-fixture.evidencia.json) |
| Código sintético `9500000001232`, dígito de controlo válido | 404, produto não encontrado: estado `not_found`. Não se presume que o código esteja atribuído | [Chamada](evidencias/2026-09-28/n04-contrato-off/off-missing-valid-gtin-fixture.evidencia.json) |

Os cinco itens novos cobrem muesli, tortitas de grão-de-bico, granola, bolachas e cereais; são **15 códigos únicos acumulados** com a amostra anterior, não 15 marcas nem cobertura nacional completa. Categorias/nome não foram corrigidos ou traduzidos. As três falhas 503 são indisponibilidade, não evidência de ausência dessas marcas. Casos sintéticos não entram nas contagens de cobertura.

[Estados observados](evidencias/2026-09-28/n04-contrato-off/estados-observados.json): `found`, `search_results`, `empty`, `invalid_code`, `not_found`, `provider_unavailable`; entradas inválidas/429 também têm verificação local, identificada como sintética. Não confundir HTTP 200 com produto encontrado ou HTTP 404 composto com código válido inexistente.

**Fechamento deste incremento:** nove novas chamadas, quatro HTTP 200, três 503 e dois 404 esperados; nove corpos/hashes preservados. Contrato resolvido para o produto observado, normalização e estados demonstrados, amostra ampliada. **N04 não recebe check de conclusão:** falta obter/avaliar os três filtros indisponíveis ou uma alternativa oficial de cobertura, além de decisões de atribuição/base derivada e revisão editorial antes da publicação. Não repetir falhas para recuperar contexto. [Resumo de retomada](evidencias/2026-09-28/n04-contrato-off/resumo-contrato.json).

### Primeiro incremento — 27/09 (histórico)

**Em andamento — 27/09/2026.** A pedido do autor, N03 foi reproduzido novamente: 26 verificações passaram. N04 começou com uma amostra pequena para respeitar a cota restante. Não foi encerrado nem iniciamos N05. [Resumo](evidencias/2026-09-27/n04-produtos-portugal/resumo-produtos.json), [amostra](evidencias/2026-09-27/n04-produtos-portugal/amostra-produtos.json), [comparação das versões](evidencias/2026-09-27/n04-produtos-portugal/comparacao-v2-v3.json).

### Chamadas, retorno e prova

O [coletor N04](evidencias/coletar-produtos-portugal.ps1) executou **quatro GETs; todos HTTP 200**. Guarda sucessos/falhas, tem timeout de 25 s e limite de buffer de 1 MiB; não usa credenciais nem repete falhas. Headers: `Accept: application/json,text/html` e `User-Agent: TrainForgeResearch/0.6 (+https://github.com/richardcastrogois/TrainForge; N04 research)`. Corpos em `2026-09-27/raw/` são locais e ignorados pelo Git.

| GET | Resultado | Evidência |
|---|---|---|
| `https://openfoodfacts.github.io/openfoodfacts-server/api/` | Documentação HTML, 67.582 bytes | [Data/hash/chamada](evidencias/2026-09-27/n04-produtos-portugal/off-api-guide.evidencia.json) |
| `https://openfoodfacts.github.io/openfoodfacts-server/api/tutorials/license-be-on-the-legal-side/` | Guia de licenças HTML, 43.523 bytes | [Data/hash/chamada](evidencias/2026-09-27/n04-produtos-portugal/off-license-guide.evidencia.json) |
| `https://world.openfoodfacts.org/api/v2/search` com parâmetros abaixo | JSON, 28.667 bytes; dez produtos | [URL completa, data e hash](evidencias/2026-09-27/n04-produtos-portugal/off-portugal-10.evidencia.json) |
| `https://world.openfoodfacts.org/api/v3.6/product/5449000054227` com os mesmos `fields` | JSON, 978 bytes; produto encontrado | [URL completa, data e hash](evidencias/2026-09-27/n04-produtos-portugal/off-product-observed.evidencia.json) |

Busca: `countries_tags=en:portugal`, `page_size=10`, `page=1`, `sort_by=unique_scans_n`. Projeção `fields`: `code,product_name,product_name_pt,brands,countries_tags,lang,quantity,product_quantity,product_quantity_unit,serving_size,serving_quantity,serving_quantity_unit,nutrition_data_per,nutriments,last_modified_t`. O código do detalhe foi escolhido da primeira linha recebida, sem inventar um código de exemplo.

**Correção do histórico:** a documentação consultada distingue busca estruturada v2 de leitura de produto v3.6. A chamada antiga `/api/v3.6/search` não demonstra um endpoint de busca válido. As tentativas v2 anteriores também responderam 503 e continuam preservadas; a causa exata da falha não foi determinada. A documentação cita limites globais que podem produzir 503; isso não prova bloqueio desta conta/IP. Limites documentados nesta consulta: 10 buscas e 15 leituras de produto por minuto/IP; não usar busca a cada tecla. [Documentação primária](https://openfoodfacts.github.io/openfoodfacts-server/api/).

### O que efetivamente recebemos

- Envelope v2: `count: 22688`, `page: 1`, `page_count: 10`, `page_size: 10`, `skip: 0` e `products`. **22.688 é a contagem informada pela busca nesse momento**, não itens que auditamos nem prova de cobertura integral do mercado português.
- Dez códigos distintos, preservados como strings; dez verificações aritméticas de dígito de controlo passaram. Isso não verifica titularidade da marca ou autenticidade do produto.
- Todos os dez têm a marcação `en:portugal`; seis têm `product_name_pt` não vazio, nove têm marca e nove têm quantidade de porção. Nome em português não comprova revisão pt-PT. Filtro de país não comprova fabricação portuguesa nem disponibilidade atual numa loja.
- Todos trazem energia numérica na busca. É uma primeira página ordenada por popularidade de leituras, com marcas internacionais; não amostra representativa por marca/categoria.

| Código original | Campo/nome recebido | Exemplo de limitação |
|---|---|---|
| `5449000054227` | Coca-Cola Original Taste; `product_name_pt: Sabor Original`; embalagem 1 L, porção 250 ml | Busca tem `energy-kcal_100g: 42` e `energy-kcal_serving: 105`; detalhe v3.6 tem `nutriments: {}` |
| `20724696` | Amandes décortiquées; `product_name_pt: Amêndoas natural` | `brands` vazio; não inventar marca pela descrição |
| `8000500426494` | Nutella Plant-Based; Ferrero, Nutella | Nome português não recebido |
| `3045140105502` | Chocolat au lait; Milka | Nome português vazio e porção não recebida |

O detalhe retornou `status: success`, `result.id: product_found`, `errors: []`, `warnings: []` e `product`; código, marca e nome conferem com a busca. Porém **`nutriments` veio vazio**, com a mesma projeção solicitada. Na coleta de 27/09, a causa ainda não estava demonstrada; a resolução de 28/09 acima confirmou o campo `nutrition` da nova estrutura. Não completar com zero nem substituir silenciosamente o valor de outra versão. O retorno usa `nutrition_data_per: 100g` mesmo no exemplo de embalagem em ml; também não inferir densidade por essa combinação.

### O que temos e o que falta

**Temos:** primeira amostra real de produtos marcados para Portugal, rastreabilidade completa, disponibilidade/ausência dos campos medida e identidade de um código confirmada por detalhe. O [analisador](evidencias/analisar-produtos-portugal.py) reconfere os quatro hashes, contagens, unicidade, país, dígitos e resposta de negócio, sem rede.

**Pendências registradas em 27/09:** schema/projeção, amostra por marcas/categorias e estados sem resultado. Em 28/09, contrato e estados foram demonstrados; cobertura segue parcial pelos três filtros 503, conforme o resumo atual acima. Não ampliar para fotografias/alergénios/receitas de outros nichos neste incremento.

**Direitos:** o guia oficial aponta ODbL para a base, DbCL para conteúdos individuais e CC BY-SA para imagens, com possíveis direitos de terceiros. Atribuição e tratamento de base derivada continuam decisões de publicação; não foram homologados nesta coleta. Nenhuma imagem foi solicitada e não houve contato, cadastro ou publicação externa. [Guia primário de licenças](https://openfoodfacts.github.io/openfoodfacts-server/api/tutorials/license-be-on-the-legal-side/).

Reprodução local: `python docs/conteudo/evidencias/analisar-produtos-portugal.py`. Não executar o coletor para reler contexto: os quatro resultados e as falhas antigas já estão preservados.

## N05 — ingredientes, alergénios e restrições alimentares

**[x] Pesquisa concluída em 28/09/2026, com limites explícitos.** Cinco fichas reais, escolhidas por contrastes úteis, foram observadas; a taxonomia do fornecedor tem 27 entradas, incluindo os 14 grupos europeus e a sentinela `en:none`. **66 verificações locais passaram**, separando corpos reais de casos sintéticos de ausência, conflito e formato inválido. [Resumo](evidencias/2026-09-28/n05-ingredientes/resumo-ingredientes.json), [amostras exatas e interpretação separadas](evidencias/2026-09-28/n05-ingredientes/amostra-ingredientes.json), [verificações](evidencias/2026-09-28/n05-ingredientes/validacao-ingredientes.json).

### Origem e chamada reproduzível

Fonte de produtos: **Open Food Facts e colaboradores, AL02**. Foram usados códigos já observados no N04, sem pesquisa de produtos novos. `GET https://world.openfoodfacts.org/api/v3.6/product/{code}`, sem credencial ou dados pessoais, com projeção explícita. Exemplo real: `5603722505607` — Leite Sem Lactose Meio-Gordo. [Manifesto completo](evidencias/2026-09-28/n05-ingredientes/plano-coleta.json) e [metadados desse exemplo](evidencias/2026-09-28/n05-ingredientes/n05-lactose-free.evidencia.json) guardam a URL codificada, os headers, status, data, bytes e SHA-256.

Campos solicitados: `code`, `product_name`, `product_name_pt`, `lang`, `ingredients_text`, `ingredients_text_pt`, `ingredients`, `ingredients_tags`, `ingredients_analysis_tags`, `allergens`, `allergens_tags`, `allergens_from_ingredients`, `allergens_from_user`, `traces`, `traces_tags`, `labels`, `labels_tags`, `tags_sources`, `ingredients_n`, `unknown_ingredients_n`, `ingredients_percent_analysis`, `ingredients_with_specified_percent_n`, `additives_tags`, `schema_version`, `last_modified_t`, `states_tags`, `data_quality_warnings_tags`, `data_quality_errors_tags`.

Headers: `User-Agent: TrainForgeResearch/0.8 (+https://github.com/richardcastrogois/TrainForge; public-source research)`, `Accept: application/json,text/html,text/plain`, `Accept-Encoding: identity`. Coletor com TLS padrão, timeout de 25 s, limite de 2 MiB e cache de falhas/sucessos, sem retry. Intervalo de 7 s entre consultas ao servidor principal. Nove chamadas novas: **oito HTTP 200 e uma HTTP 202**; nove corpos/hashes preservados. A chamada EUR-Lex 202 não forneceu texto legal utilizável e não foi tratada como sucesso de conteúdo. O guia oficial da Comissão Europeia de fevereiro de 2026 foi obtido; a validação jurídica consolidada de exceções permanece para antes de alegações regulatórias no produto.

### O que cada campo permite devolver no app

| Retorno observado | Uso pretendido | Regra de interpretação |
|---|---|---|
| `ingredients_text`, `ingredients_text_pt` e `lang` | Mostrar a lista recebida e sua língua declarada | Transcrição não verificada, potencialmente comunitária/OCR. Renderizar como texto escapado; não executar HTML nem assegurar que `_pt` seja português correto |
| `ingredients[]`, inclusive sublistas | Explicar ingredientes e subingredientes, preservando ordem e caminhos | Árvore analisada automaticamente pelo fornecedor. `is_in_taxonomy=0` e termos não reconhecidos exigem revisão; árvore não é uma receita validada |
| `percent`, `percent_estimate`, `quantity_estimate`, `percent_min/max` | Diferenciar quantidade informada de estimativa | Nunca substituir `percent` pelo estimado ou usar estimativas para reconstruir receitas, doses ou quantidades de alergénio |
| `allergens_tags` | Sinalizar presença reportada | Pode reunir declarações e análise automática. Não é laudo nem prova de ausência dos demais alergénios |
| `traces_tags` | Exibir aviso de possível presença | Guardar separado dos ingredientes/alergénios reportados; não apagar por uma alegação vegana ou sem lactose |
| `tags_sources.{allergens,traces,labels}.{source}` | Explicar origem por campo e revisão | Preservar `packaging`, `ingredients` e fontes futuras, seus `tags` e `last_updated_t`. `packaging` é a origem atribuída pela base, não uma auditoria do fabricante |
| `labels_tags` | Mostrar alegações recebidas, como sem lactose/sem glúten | Distinguir etiqueta reportada de certificação verificada; tags agregadas podem incluir ancestrais de taxonomia |
| `ingredients_analysis_tags` | Explicar classificação automática e incerteza | Vegano, não vegano, talvez e desconhecido são estados diferentes. Essa classificação não equivale a aprovação para alergia |
| `unknown_ingredients_n`, `data_quality_*`, `states_tags` | Expor dados incompletos e necessidade de confirmação | Zero ingredientes desconhecidos não prova completude, correção do rótulo ou ausência de contaminação |
| `code`, `schema_version`, `last_modified_t` e data da coleta | Rastrear produto, versão e atualização | Preservar código como texto e revalidar detalhes; alteração de composição pode manter o código |

Nas cinco respostas v3.6, `allergens` e `traces` antigos **não vieram**, embora as listas `*_tags` tenham vindo. Não interpretar ausência do campo antigo como ausência de alergénio. Um campo pode estar ausente, nulo, vazio ou preenchido: o demonstrador conserva essa diferença. Não há garantia de que todas as próximas fichas tenham esses campos.

### Casos reais que mudam a implementação

| Produto observado | Evidência recebida | Consequência para a interface futura |
|---|---|---|
| Mimosa Leite Meio-Gordo `5601049132995` | Campo `ingredients_text_pt` contém `Milk`; um ingrediente desconhecido no analisador | Indicar idioma declarado e dado não revisto. Não apresentar a etiqueta `_pt` como tradução validada |
| Mimosa Sem Lactose `5603722505607` | `en:no-lactose` em labels; `en:milk` em alergénios; texto informa leite e lactase | Manter a alegação sem lactose e o aviso de leite simultaneamente; não criar selo de adequação para alergia a leite |
| Pingo Doce Muesli `5607047006795` | Glúten/frutos de casca rija reportados; vestígios de leite, mostarda, amendoim e soja; cinco ingredientes não reconhecidos | Exibir presença e possíveis vestígios separadamente. Preservar `pt:Frutos secos` para revisão, sem descartar por não estar no mapa |
| Compal Pêssego `5601151964804` | `allergens_tags=[]`, `traces_tags=["en:none"]`, um ingrediente não reconhecido | Resultado de alergénios fica **desconhecido**, com a declaração da fonte sobre vestígios visível; não devolver “seguro para todos” |
| Nutella Plant-Based `8000500426494` | Análise `en:vegan`; alergénios frutos de casca rija/soja; vestígios de leite; texto em inglês | Mostrar preferência alimentar e advertências em blocos distintos; classificação vegana não apaga vestígios |

Outro contraste observado: a aveia do muesli tem `percent=45` e `percent_estimate=45.5`. Na ficha sem lactose, `percent_estimate=25` para lactase é uma estimativa do analisador; **não há `percent` declarado para esse ingrediente**. Não transformar esses números em gramas reais, composição comprovada ou informação para decisão clínica. As amostras preservam o corpo relevante e a interpretação em propriedades separadas.

### Taxonomia, restrições e linguagem

O [guia da Comissão Europeia](https://food.ec.europa.eu/food-safety/campaign-2026/allergies_en) identifica 14 grupos de declaração: cereais com glúten, crustáceos, ovos, peixe, amendoim, soja, leite, frutos de casca rija, aipo, mostarda, sésamo, dióxido de enxofre/sulfitos, tremoço e moluscos. O [mapa local](evidencias/2026-09-28/n05-ingredientes/grupos-alergenios.json) confronta esses grupos com a [taxonomia OFF preservada](evidencias/2026-09-28/n05-ingredientes/n05-off-allergens-taxonomy.evidencia.json).

Os 14 IDs têm nome português na taxonomia, mas a qualidade não é uniforme: `en:nuts` vem como **“nozes”**, mais estreito que o grupo. A proposta de UI usa “Frutos de casca rija”, mantendo o termo original e a necessidade de revisão editorial. Há 12 outras entradas e `en:none`; o vocabulário não deve ser confundido com lista universal de alergias. Não foram encontrados relacionamentos `parents` nessa taxonomia baixada: não inventar uma hierarquia executável.

Separar no modelo futuro: **alergia declarada pelo utilizador**, **intolerância/restrição declarada**, **preferência alimentar** e **orientação clínica externa**. Não converter diagnóstico em restrição automática. Sem lactose não resolve alergia a leite; alegações sem glúten, veganas ou religiosas exigem o seu próprio contexto e confirmação. Não foram amostradas certificações halal/kosher nem critérios terapêuticos, de FODMAP, doença renal ou metas alimentares. Esses estados permanecem desconhecidos, não aprovados por esta pesquisa. Planos/dietas e educação possuem nichos próprios.

### Estados e limites do demonstrador

O [analisador local](evidencias/analisar-ingredientes.py) mantém:

- `reported_presence`: sinal positivo de alergénio, com origem; `possible_presence_reported`: aviso de vestígio separado.
- `unknown`: campo ausente/nulo/vazio sem informação positiva. Não oferece um estado automático “alimento seguro”.
- `source_claim_none`: `en:none` preservado como alegação da fonte, com `clinicalAbsenceConfirmed=false`.
- Contradição entre `en:none` e tags positivas: conservar ambos, destacar revisão, sem eliminar o sinal positivo.
- Alegações de preferência, análise automática e revisão humana como conceitos separados; `clinicalSuitability=not_assessed`.

Os 66 checks incluem hashes, cinco contratos reais, os 14 IDs, diferenças de percentagens, subingredientes, origem e idioma, além de casos sintéticos identificados: campo ausente/nulo/vazio, conflito, tags fora do mapa, código divergente, schema desconhecido, tipos inválidos e texto com marcação. São verificações do contrato de pesquisa; não testes de precisão clínica, de produto, de interface ou da população portuguesa.

Reproduzir sem rede: `python -X utf8 docs/conteudo/evidencias/analisar-ingredientes.py`. Corpos integrais ficam em `2026-09-28/raw/`, local/ignorado; metadados e subconjuntos com atribuição permitem retomada. Restrições de reutilização são as do N04. O [guia técnico OFF](https://openfoodfacts.github.io/openfoodfacts-server/api/tutorials/get-ingredient-related-analysis/) reconhece limitações de análise por idioma e exige revisão do OCR; não tratar as classificações automáticas como informação integralmente humana.

**O que temos:** uma fonte gratuita demonstrada, chamadas/retornos reais, origem por campo, vocabulário inicial, estados e recusas reproduzíveis. **O que falta para publicar:** revisão de rótulos/fabricantes e pt-PT, atualização de fichas, implementação de confirmação e privacidade, tratamentos de receitas/alimentos sem embalagem, análise de exceções legais e qualquer adequação individual. O nicho fecha a pesquisa de dados; não libera prescrição, certificação ou app. **Sequência realizada: N06 está concluído para pesquisa na secção abaixo.**

## N06 — fotografias de alimentos, produtos e pratos

**[x] Concluído para pesquisa em 28/09/2026 no recorte abaixo.** [Resumo](evidencias/2026-09-28/n06-imagens/resumo-imagens.json), [11 candidatos e créditos](evidencias/2026-09-28/n06-imagens/amostra-imagens.json), [revisão visual](evidencias/2026-09-28/n06-imagens/revisao-visual.json) e [validação](evidencias/2026-09-28/n06-imagens/validacao-imagens.json). São três produtos OFF, sete ficheiros Commons, oito imagens inspecionadas, 22 chamadas preservadas/200/hashes e 23 verificações funcionais locais. Duas imagens só têm metadados; o catálogo de sementes foi rejeitado antes de baixar a imagem. Fotografias brutas ficam locais; a amostra versionada contém metadados e créditos.

### Como foi chamado e o que chegou

Os quatro `plano-*.json` da pasta N06 guardam URLs completas, projeções, finalidade e escopo; cada `*.evidencia.json` conserva método GET, cabeçalhos, data UTC, resposta, tamanho e SHA-256. O [coletor existente](evidencias/coletar-nichos-off.py) reutiliza cache, limita resposta/tempo e não repete falhas. Leituras públicas sem chave. A consulta do Commons pede só um ou dois resultados por busca, pois `extmetadata` é dispendioso. [Contrato oficial Imageinfo](https://www.mediawiki.org/wiki/API:Imageinfo).

| Fonte / chamada | Campos observados | Utilização e limite |
|---|---|---|
| OFF `GET /api/v3.6/product/{code}.json?fields=...` | `selected_images.{front,ingredients,nutrition,packaging}.{display,small,thumb}.{idioma}`; `images.selected.{papel}.{idioma}.{imgid,rev,sizes}`; `images.uploaded.{imgid}.{uploader,uploaded_t}`; schema 1004 | URL por papel/idioma; revisão e dimensão; conta que enviou a imagem. Uploader não prova autoria; o papel packaging é informação da embalagem, não sinónimo de fotografia frontal |
| Commons `GET /w/api.php?action=query&generator=search&gsrnamespace=6&gsrlimit=2&prop=imageinfo&iiprop=url|size|mime|sha1|extmetadata|timestamp|user&iiurlwidth=480&format=json&formatversion=2` | `query.pages[].{pageid,title,imageinfo[]}` com URL, miniatura, página de descrição, dimensões, MIME, SHA-1 do original, timestamp, uploader e `extmetadata` | Crédito vem de `Artist`/`Credit`, não do bot que fez upload. Licença e restrições são por ficheiro; HTML recebido vira texto escapado na interface |
| GET da URL devolvida da miniatura | Oito respostas JPEG/200, bytes e SHA-256 locais | Decodificação e inspeção confirmadas nesta data. SHA-1 de original Commons não deve ser comparado com SHA-256 da miniatura. Disponibilidade futura não garantida; quatro miniaturas Commons pedidas a 480 px vieram com 500 px reais, enquanto o prato pequeno ficou em 240 px |

Preferir URLs explícitas do fornecedor. `selected_images` continua presente, mas os metadados v3.6 estão em `images.selected` e `images.uploaded`, diferentes de exemplos antigos. O demonstrador confere revisão/URL para **este** schema e recusa mudança desconhecida. Nunca inventar revisão. Falta de imagem → ícone próprio com descrição; indisponibilidade → manter dados textuais. O [guia OFF](https://openfoodfacts.github.io/openfoodfacts-server/api/how-to-download-images/) recomenda tamanho adequado, poucas transferências sequenciais e dataset específico para volume maior. Não baixar imagens completas na navegação normal; cache/expiração por revisão e alternativa sem rede ficam para implementação.

### Correspondência comprovada e problemas reais

- **Leite Mimosa `5601049132995`:** frente PT, revisão 85, uploader `macrofactor`; foto verde/branca coincide com variante meio-gordo. Ingredientes só EN na projeção; fallback precisa ser explícito e identificado.
- **Compal `5601151964804`:** frente PT, revisão 5; foto identifica néctar de pêssego. Não representa um copo medido.
- **Nutella Plant-Based `8000500426494`:** URL simples de ingredientes aponta EN, embora a seleção tenha PT, revisão 147/imgid 20. O bloco PT aparece na foto com ingredientes e aviso de possível leite; não foi executado OCR. A frente não tem PT. Não substituir uma foto de ingredientes por capa.
- **Banana `22552194`:** autor Wilfredor, CC BY-SA 3.0, cachos com casca. **Arroz `43976882`:** Douglas Perkins, CC0, tigela de arroz cozido. Nenhuma foto prova massa, preparação exata ou ligação a um ID Ciqual.
- **Arroz `158198806`:** CC BY-SA 4.0; título diz brown rice, mas a composição visível precisa revisão antes de vincular a um alimento integral específico.
- **Bacalhau à Brás `4010846`:** autor Adriao, CC BY-SA 3.0, visual coerente com o prato nomeado; original de apenas 240 × 117 px. Aceitável como referência de miniatura, insuficiente para detalhe amplo. Não recebemos receita, rendimento nem nutrientes com a fotografia.
- Busca genérica por refeição portuguesa com peixe trouxe **carne com batatas/cerveja** e **catálogo de sementes**. Rejeitados para o uso procurado. A busca dirigida por título resolveu a identidade do prato. Nenhuma busca deve publicar associações automaticamente.

### Direitos e decisão de uso

OFF declara fotografias CC BY-SA 3.0, separadas da base ODbL e conteúdo DbCL; o [termo preservado no N04](evidencias/2026-09-28/n04-fechamento/n04-off-reuse-terms.evidencia.json) ressalva marcas e outros direitos. Commons exige conferir cada ficheiro; uploader pode não ser o criador. [Política de reutilização](https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia).

CC0 permite reutilização comercial sem atribuição exigida pela dedicação, mas mantemos origem. CC BY exige crédito/licença; CC BY-SA também impõe condições à adaptação partilhada. Não concluir que todo o app tem a licença da fotografia. Créditos incluem título, criador, página original, licença/versão e alterações; não sugerir apoio do autor. Os quatro resumos oficiais foram preservados: [CC0](https://creativecommons.org/publicdomain/zero/1.0/), [CC BY 2.0](https://creativecommons.org/licenses/by/2.0/), [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/), [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). `releaseApproved=false` em todos os candidatos: não houve homologação independente de titularidade, direitos de terceiros ou catálogo completo.

**O que temos:** caminho gratuito demonstrado para embalagem, alimento genérico e prato, variantes por idioma/tamanho, atribuição e rejeição de resultados incoerentes. **O que falta:** seleção por alimento do catálogo de lançamento, ligação editorial aos IDs nutricionais, fotografias melhores onde necessário, revisão de direitos/idioma, cache e interface de créditos. Não temos reconhecimento de alimento, gramas ou calorias por fotografia. N07 pode começar; N06 não aprova essas capacidades futuras.

Reproduzir sem rede: `python docs/conteudo/evidencias/analisar-imagens.py` (Python com Pillow, disponível no runtime local; requer raw local). As verificações incluem idioma ausente, fallback, tipo de foto, revisões conflitantes, schema desconhecido, URL não confiável, crédito HTML, autor distinto do uploader, exclusão por correspondência, hashes e decodificação. Casos de falha sintéticos estão identificados no script.

## N07 — ensinar a ler uma embalagem

**[x] Concluído para pesquisa em 28/09/2026.** [Resumo](evidencias/2026-09-28/n07-rotulos/resumo-rotulos.json), [12 lições com fontes](evidencias/2026-09-28/n07-rotulos/conteudo-didatico.json), [referência visual própria](evidencias/2026-09-28/n07-rotulos/guia-rotulos.html), [31 verificações](evidencias/2026-09-28/n07-rotulos/validacao-rotulos.json) e [conferência de apresentação](evidencias/2026-09-28/n07-rotulos/validacao-visual.json). Não é implementação do aplicativo nem alteração do Figma.

### Origem e retorno efetivamente obtido

| Fonte / chamada GET pública | O que retornou e sustenta | Limite |
|---|---|---|
| [Comissão Europeia — declaração nutricional](https://food.ec.europa.eu/food-safety/labelling-and-nutrition/food-information-consumers-legislation/nutrition-labelling_en), `n07-eu-nutricao` | HTML/200 preservado; valores por 100 g/ml, porção adicional e nutrientes da tabela | Usada a secção de declaração; cronogramas políticos antigos de 2020 não tratados como novidade de 2026 |
| [Comissão Europeia — rótulos, campanha 2026](https://food.ec.europa.eu/food-safety/campaign-2026/labelling_en), `n07-eu-guia` | HTML/200; identificação, ingredientes, alergénios, quantidade e instruções | Guia geral; exceções legais e legislação consolidada completa não foram homologadas |
| [EFSA — datas](https://www.efsa.europa.eu/en/safe2eat/food-date-labelling), `n07-efsa-datas` | HTML/200; distinguir segurança e qualidade, respeitando conservação | Não fornece validade específica por lote nem autoriza consumo automático após data |
| [NHS — rótulos](https://www.nhs.uk/live-well/eat-well/food-guidelines-and-food-labels/how-to-read-food-labels/), `n07-nhs-rotulos` | HTML/200; porção indicada pode diferir da consumida | Apoio didático britânico; seus semáforos não foram adotados como norma portuguesa |
| [British Nutrition Foundation — interpretação](https://www.nutrition.org.uk/creating-a-healthy-diet/food-labelling/), `n07-bnf-rotulos` | HTML/200; subconjuntos nutricionais e referência geral distinta de meta individual | Sem copiar imagens/guia integral, endosso ou prescrição individual |

[Manifesto inicial](evidencias/2026-09-28/n07-rotulos/plano-coleta.json) e [complemento](evidencias/2026-09-28/n07-rotulos/plano-complemento.json) especificam como chamar. Metadados `*.evidencia.json` guardam URL, cabeçalhos, UTC, status/erro e hash. Sete chamadas preservadas: cinco 200/corpos/hashes e duas falhas de certificado em Your Europe (`status=null`). Não desativámos TLS, não repetimos as falhas e não as tratámos como páginas vazias. Leitura auxiliar via web não foi contada como resposta HTTP preservada. Uma URL antiga de referência NHS devolveu 404 na exploração web; não sustenta conteúdo.

**Estas fontes devolvem HTML editorial, não JSON com dieta ou cálculos personalizados.** `conteudo-didatico.json` é organização proposta pelo TrainForge, distinguida dos retornos originais: `sources` identifica instituição/chamada/secção/limite; `lessons` contém título, linguagem simples, detalhe opcional, IDs de fonte e necessidade visual; `examples` separa base, unidade, estado, pacote, porção e consumo. Todos os exemplos são fictícios e `releaseApproved=false`. As fontes são humanas; a síntese pt-PT é rascunho assistido por agente, ainda sem revisão profissional independente.

### O que o app poderá ensinar e apresentar

As 12 lições cobrem localizar a tabela; comparar bases iguais; calcular quantidade consumida; separar pacote/porção; entender unidades; evitar dupla contagem; ler ingredientes; preservar avisos; distinguir referências de metas; datas; preparação; informação ausente. Cada lição tem sua fonte e a distinção entre fato editorial e regra proposta pelo projeto.

O exemplo A separa pacote de 300 g, porção de 30 g e consumo de 45 g: com 200 kcal/100 g, são respectivamente 600, 60 e 90 kcal. O exemplo B usa 42 kcal/100 ml e 250 ml: 105 kcal. São exercícios aritméticos, sem produto real ou recomendação de quantidade. A lista fictícia de ingredientes é outro recorte didático, não uma receita correspondente aos números. O material inclui unidades junto dos valores, detalhe expansível, destaque textual e alternativa a valores não informados. A tabela pode deslocar horizontalmente em ecrãs pequenos, também pelo teclado.

Para implementação futura, usar a base, estado e quantidade exatos do N03/N04, a proveniência/ausências do N05 e as imagens/créditos do N06. Não somar subconjuntos de nutrientes; não transformar dados ausentes em zero; não converter g/ml ou cru/cozido sem prova. O app deve guardar fonte e revisão da lição, confirmação do rótulo pelo utilizador e correções próprias separadas. Essas são decisões de contrato futuro, não campos que uma API educativa devolveu prontos.

**O que temos:** cinco guias institucionais acessíveis, lições rastreáveis, exemplos próprios conferidos matematicamente e visualmente, tratamento de unidades e desconhecidos. **O que falta:** revisão editorial independente de pt-PT, regras/exceções completas se quisermos alegações jurídicas, conteúdo para crianças/situações clínicas, OCR e sincronização dessas lições com o produto. Nenhuma dieta, classificação clínica ou receita completa foi aprovada. A pesquisa N08 foi concluída em 29/09 na secção seguinte.

Reproduzir sem rede: `python -X utf8 docs/conteudo/evidencias/analisar-rotulos.py`. Os 31 checks cobrem quantidades/base/preparo, valores negativos/não finitos/desconhecidos, subconjuntos, arredondamento, fontes reais e falhas preservadas; cinco hashes conferidos separadamente. A [verificação visual](evidencias/2026-09-28/n07-rotulos/validar-guia.cjs) usou Comet instalado em modo headless, perfil temporário, duas dimensões e zero erros de script; não usou a sessão pessoal nem fez instalações. Não é teste de acessibilidade completo ou teste do aplicativo.

## N08 — Receitas humanas: dados, origem e reutilização

**Concluído para pesquisa em 29/09/2026**, no recorte de oito receitas distintas, nove páginas de receita (uma comparação entre versões), políticas e alternativas. Foram **21 chamadas preservadas, 19 HTTP 200, dois HTTP 403 e 21 corpos com hash conferido**; 61 verificações locais passaram. Não se trata de oito receitas liberadas para lançamento. [Resumo](evidencias/2026-09-29/n08-receitas/resumo-receitas.json), [campos/amostras](evidencias/2026-09-29/n08-receitas/amostra-receitas.json), [analisador](evidencias/analisar-receitas.py).

**Resposta à pergunta do nicho:** há um candidato gratuito demonstrado para **texto de receitas humanas via MedlinePlus**, cuja política inclui expressamente Healthy recipes no conteúdo de domínio público. A amostra ainda exige conferência nutricional, localização e direitos por ativo. NHLBI continua condicional; DGS é referência portuguesa; receitas Healthier Families e TheMealDB não têm autorização automática para o uso comercial gratuito pretendido. Não foi encontrada/validada nesta rodada uma API que resolva todas as camadas.

### Como foi chamado e o que veio

Os quatro manifestos complementares e o plano inicial na pasta N08 guardam URLs, objetivo e extensão. Todos os pedidos são **GET HTTPS sem chave/autenticação**, pelo coletor `coletar-nichos-off.py`: timeout 25 s, limite 2 MiB, cache de sucesso/falha e nenhum retry. Corpos HTML em `../raw/`, ignorados no Git; as projeções versionadas são nossas. A fonte não devolveu os nossos campos `sourceId`, `releaseApproved` ou `clinicalSuitability`.

| Fonte / conteúdo observado | Retorno concreto | Utilidade e limite |
|---|---|---|
| NHLBI, Braised Cod With Leeks | 9 ingredientes, 4 passos; 4 porções; 15 min preparo + 25 min cocção; 158 kcal por porção, proteína 17 g | HTML `h2`, `ul/ol`, tabelas `th/td`; origem editorial Deliciously Healthy Dinners. Oz, C e unidades inteiras não são automaticamente gramas |
| NHLBI, Lentil Soup | 12 ingredientes, 5 passos; 11 porções de 1 C; 151 kcal, proteína 9 g por porção | Caldo, legumes e lentilhas; preservar medida/unidade original e base por porção |
| NHLBI, Apple Coffee Cake | 10 ingredientes, 5 passos; 20 porções; 188 kcal | Ficha não informa proteína/carboidratos/fibra. O preparo inclui repouso; não somar só dois campos e prometer tempo total |
| DGS, Canelone de bacalhau | 15 ingredientes, orientações, 4 pessoas, 30 min; HTML + JSON-LD Article | Já em português. Não há tabela nutricional do prato: **164 kcal/100 g refere-se ao grão-de-bico**, não ao canelone. JSON-LD autor “Programa” não prova revisão nominal |
| NHS Healthier Families, aveia / massa com salmão / chilli | 8/11/12 ingredientes, 3/6/3 passos, quatro porções cada; 294/465/400 kcal por porção | `script[type=application/ld+json]`, `@type=Recipe`; útil como comparação técnica, bloqueado para importação comercial sem licença específica |
| MedlinePlus, Lentil Confetti Salad | 11 ingredientes, 7 passos; 6 porções; 2/3 cup (140 g); 160 kcal, gordura 6 g, hidratos 22 g, proteína publicada 1 g, fibra 5 g por porção | HTML, autoria institucional e Food Hero creditados; política explícita favorece piloto textual. Preservar 1 g e pedir conferência, não “corrigir” por palpite |
| Food Hero, mesma salada | 4 cups de rendimento; 8 passos visíveis; `Recipe` JSON-LD com ingredientes concatenados e instruções quebradas por vírgulas | Comparação de versão, **não uma nona receita distinta**. Não usar JSON-LD só porque existe; validar estrutura contra HTML |

A ficha NHS contém `name`, `publisher`, `datePublished`, `recipeCategory`, `recipeIngredient[]`, `recipeInstructions` (string), `recipeYield`, `prepTime`, `cookTime`, `totalTime`, `nutrition`, `suitableForDiet` e `image`. Na amostra, `nutrition` inclui `calories`, `proteinContent`, `carbohydrateContent`, `sugarContent`, `fatContent`, `saturatedFatContent`; **fibra, sal, kJ e a declaração da base estão no HTML**, ausentes desse objeto. A aveia declara `cookTime: null` e `totalTime: PT10M`, embora exija uma noite no frigorífico. Rótulo de dieta não é certificação de ausência de alergénios.

### Decisão de direitos por camada

- **NU15 / MedlinePlus:** a [política da NLM](https://medlineplus.gov/about/using/usingcontent/) lista receitas saudáveis como domínio público. Guardar autoria/proveniência, URL, versão e crédito institucional; validar cada ativo e jurisdição de lançamento. Essa política não é uma licença para extrair todas as fotos nem todos os textos do Food Hero. Fotos/logos não foram importados. Catálogo classificado **candidato**, não aprovado.
- **NU03 / NHLBI:** [política própria](https://www.nhlbi.nih.gov/about/contact/trademark-branding-and-logo) favorece informação de domínio público, mas pede preservar produtos formatados e evitar publicidade/endosso. A tradução, a apresentação com anúncios e a mídia continuam condicionais. Não afirmar que a existência da receita homologa um plano diário.
- **NU14 / Healthier Families:** os [termos específicos](https://www.nhs.uk/healthier-families/terms-and-conditions/) exigem licença para fins comerciais, restringem modificações e links além da página inicial. A exclusão Change4Life resolve hoje para Healthier Families; **não aplicar OGL do NHS geral a esse catálogo**. URLs de receita ficam neste dossiê como evidência da pesquisa, não como estratégia de distribuição no produto.
- **NU01 / DGS:** receita recebida pelo coletor, mas licença comercial aberta não demonstrada. A página web de pesquisa apresentou desafio de verificação; o GET local recebeu a receita real. Acesso não é autorização.
- **NU06 / TheMealDB:** [termos](https://www.themealdb.com/terms_of_use.php) continuam exigindo assinatura para publicar app em loja. Nenhuma chave foi adquirida e nenhuma receita da API foi importada.
- **NU07 / USDA:** alternativa Team Nutrition retornou 403; MyPlate não acessível pelo navegador de pesquisa. Não contar catálogo nem supor encerramento do serviço com base em espelhos de terceiros. **NU16 / Food Hero:** a página de critérios também retornou 403; registrar o limite, sem retry ou inferência de critérios não lidos.

### Contrato necessário para a implementação futura

| Grupo | Guardar / devolver | Recusa ou estado explícito |
|---|---|---|
| Identidade e revisão | ID interno, URL original, instituição/autor declarado, título/idioma, data da coleta/hash e versão | Instituição ≠ profissional identificado que reviu a tradução; atualização da fonte não substitui versão guardada |
| Ingredientes | Texto original; quantidade/unidade; fração/intervalo/opcional; estado cru/cozido/escorrido; ID alimentar **só com correspondência validada** | “Uma unidade”, chávena/colher e alimentos sem preparo identificado não recebem massa inventada. Gramas/ml não se somam |
| Preparo | Passos na ordem humana, notas separadas, segurança/armazenamento e equipamentos quando presentes | String plana/array fragmentado não vira passo a passo sem verificar HTML; temperatura/tempo de segurança não pode desaparecer na tradução |
| Rendimento e registo | Número de porções da receita, descrição/massa da porção quando informada, quantidade que o utilizador consumiu separada | Massa final desconhecida impede nutrientes por 100 g. Multiplicar nutrientes pela fração só quando a base e a versão corresponderem |
| Nutrientes | Valor, unidade, base, origem e ausente/desconhecido; conservar valor declarado e cálculo derivado separados | Troca de ingrediente, versão ou quantidade invalida assumir os mesmos nutrientes. Soma de macros não substitui energia publicada |
| Tempo | Preparo ativo, cocção, espera e total informado, com ressalva quando não cobre a espera | Não dizer “pronto em 10 min” para receita noturna |
| Direitos e mídia | Decisão por texto/tradução/foto/vídeo; crédito e atualização | Falta de foto não bloqueia receita textual elegível; presença de URL não autoriza reuso/hotlink |
| Adequação | Preferências declaradas, fonte e limites; instrução para conferir ingredientes/rótulos | Sem classificar receita como tratamento, isenta de alergénios ou adequada a todos. Nome “saudável” não é prova para condição individual |

**O que temos:** amostras completas, retorno exato por campo, política de um candidato textual gratuito, alternativas comparadas, erros e divergências reproduzíveis. **O que falta:** lote de lançamento, tradução pt-PT revista, nutrientes conferidos, cobertura cultural portuguesa, direitos de fotos e política de atualização/adaptação. Os ingredientes ainda não estão associados aos IDs Ciqual/OFF; receitas não se tornaram dietas nem recomendações automáticas. **Próximo: N09**, guias humanos para ganhar peso. N13 tratará planos alimentares completos.

## N09 — Alimentação para ganhar peso

**Concluído para pesquisa em 30/09/2026**, no recorte de educação geral e limites de contexto. Cinco guias efetivamente recebidos; 10 chamadas preservadas, oito HTTP 200, dois 406 explicados, 10 hashes e três políticas anteriores verificadas. [Resumo e 59 verificações](evidencias/2026-09-30/n09-ganho-peso/resumo-ganho-peso.json), [guias, 14 exemplos, seis batidos e nove rascunhos de lições](evidencias/2026-09-30/n09-ganho-peso/conteudo-guiado.json). Os guias são institucionais humanos; as lições pt-PT são **síntese editorial assistida por agente, sem revisão profissional**, e não novas dietas ou receitas geradas.

### Origem e retorno observado

| Fonte e chamada | O que efetivamente veio | Aplicação possível / limite |
| --- | --- | --- |
| NU17 — [NHS, Healthy ways to gain weight](https://www.nhs.uk/live-well/healthy-weight/managing-your-weight/healthy-ways-to-gain-weight/) | HTML, público adulto, listas de orientações, encaminhamentos, revisão 28/03/2023 e prazo 28/03/2026; referência geral de 300–500 kcal adicionais/dia | Educação sobre variedade, distribuição de refeições e contexto. A faixa não determina a necessidade individual; prazo de revisão exibido passou e requer conferência editorial |
| NU18 — [VA, Healthy Ways to Add Calories](https://www.nutrition.va.gov/NUTRITION/docs/UpdatedPatientEd/HealthyWaystoAddCaloriesJul2026.pdf) | PDF de duas páginas, julho/2026; nove grupos de opções, 14 exemplos com energia/proteína, campos pessoais de meta **em branco** | Biblioteca de exemplos humanos; valores atribuídos à fonte, não tabela universal nem prescrição diária |
| NU18 — [VA, Create Your Own Smoothie](https://www.nutrition.va.gov/NUTRITION/docs/UpdatedPatientEd/CreateYourOwnSmoothieJun2024.pdf) | PDF de duas páginas, junho/2024; grupos de ingredientes e seis exemplos nomeados | Ensinar organização e registo; não retorna nutrientes, massa final ou rendimento completo de cada bebida. Suplementos/marcas citados não são obrigatórios nem recomendados pelo TrainForge |
| NU19 — [BDA/ICUsteps, pouco apetite](https://www.bda.uk.com/resource/dont-feel-hungry-feel-full-when-eating.html) | HTML de 15/06/2020; experiência de pessoas após cuidados intensivos e orientação dietética | Referência de recuperação após doença crítica, **não guia geral** de ganho muscular; não misturar conselhos de fortificação deste contexto com recomendações gerais |
| NU20 — [NICE CG32](https://www.nice.org.uk/guidance/cg32/chapter/Recommendations) | Guideline profissional em HTML; recomendações 1.4.5–1.4.8 delimitam risco de realimentação e necessidade de profissionais treinados | Referência de limites; nenhuma dose, equação clínica ou protocolo transferido para motor do app |

Os dois PDFs foram conferidos visualmente nas quatro páginas, incluindo alinhamento de kcal/proteína nas 14 linhas e metas individuais em branco. O JSON guarda a descrição original de cada exemplo VA, página/linha e valores da fonte: por exemplo, iogurte com granola/caju **416 kcal / 29 g**, sanduíche de ovo **512 / 18,6 g** e pasta com pesto/frango **535 / 30 g**. Não houve recálculo independente por marca/ingrediente; quantidades caseiras incompletas impedem assumir precisão nutricional para a versão portuguesa. Alterar ingredientes requer nova composição, não reutilizar o total.

### Como chamou e como reproduzir

- Manifestos na pasta `evidencias/2026-09-30/n09-ganho-peso/`: `plano-coleta.json`, `plano-complemento.json`, `plano-pdf-gate.json` e `plano-pdf-smoothie.json`. Cada item registra URL e finalidade; metadados `.evidencia.json` contêm método, cabeçalhos, status, URL final, SHA-256, tamanho e caminho do corpo.
- GET público, sem credencial. HTML usa `Accept: application/json,text/html,text/plain`; PDF usa **`Accept: application/pdf`**. O servidor VA respondeu 406 ao cabeçalho anterior; o corpo indicou MIME incompatível. Uma chamada isolada com o cabeçalho correto demonstrou a solução, aplicada ao segundo PDF. IDs e respostas originais foram preservados, sem sobrescrever falhas ou repetir tentativas cegamente.
- O coletor passou a aceitar apenas esse override explícito de MIME. A extensão `.pdf` dos arquivos de erro não prova formato: o analisador exige status 200, cabeçalho e assinatura `%PDF` antes de extrair.
- `python -X utf8 docs/conteudo/evidencias/analisar-ganho-peso.py`: sem rede, requer `pypdf`, `pdfplumber` e raw local; valida hashes, negociação, tabelas e vínculos de fontes. A inspeção visual não é refeita por esse comando. O clone contém os resultados e scripts; não contém os textos integrais/captura local.

### Direitos, contexto e campos futuros

A [licença geral NHS](https://www.nhs.uk/our-policies/terms-and-conditions/) e as [exclusões](https://www.nhs.uk/our-policies/terms-and-conditions/content-not-licensed-for-re-use/) foram reutilizadas de N08, junto da OGL v3. O texto geral NU17 é candidato sob essas condições. Tradução é adaptação e não herda aprovação clínica do NHS; atribuição e versão precisam acompanhar o conteúdo, sem alegar endosso. Calculadoras, imagens/logos e campanhas vinculadas continuam separados; o link para Healthier Families não concede licença às receitas da campanha.

A [política VA](https://department.va.gov/copyright-policy/) permite distinguir obra produzida por funcionário federal de material com direitos cedidos/terceiros. Textos institucionais desses folhetos são candidatos para revisão por ativo, sem redistribuir logos/fotos ou promover marcas. A [política BDA](https://www.bda.uk.com/about-us/website/copyright.html) não autoriza incorporar o guia em produto comercial; NU19 fica como referência. NU20 também fica como referência, sem licença comercial demonstrada nesta rodada.

Proposta para implementação futura, **não contrato de API já existente**: `sourceId`, `guideId`, versão, URL/hash, público, fundamento, estado da tradução/revisão, lições vinculadas à fonte, porções/ingredientes confirmados, proveniência de eventual meta informada e campos opcionais do diário. `dailyKcalTarget` continua `null`; objetivo “ganhar peso” não permite inventá-lo. A ingestão declarada pelo utilizador deve ser calculada com os contratos N02/N03/N05, e não por uma afirmação isolada de que certo alimento faz ganhar peso.

O conjunto diferencia oito cenários editoriais: adulto geral, ganho muscular, perda involuntária, recuperação após doença crítica, ingestão mínima/prolongadamente reduzida, menor de idade, gravidez e contexto desconhecido. **Não é instrumento de triagem clínica validado.** Contextos especiais não recebem automaticamente um plano de adulto; a localização dos encaminhamentos para Portugal ainda exige revisão.

**Temos:** caminho de conteúdo humano gratuito para revisão (NHS geral e texto VA), exemplos rastreáveis, estrutura de lições e limites explícitos. **Falta:** revisão nutricional/pt-PT e direitos por ativo selecionado, equivalência de ingredientes/medidas locais, metas individuais fundamentadas, programas alimentares completos (N13), ganho muscular/performance (N12), integração e aprovação de lançamento. N09 está concluído no recorte de pesquisa; **N10 é o próximo**, sem encerrar a etapa 01.

## N10 — Alimentação para perder peso

**Concluído para pesquisa em 30/09/2026:** quatro guias institucionais recebidos, oito rascunhos de lições e exemplos rastreáveis. Dez chamadas, nove HTTP 200, um 404 preservado, dez hashes e quatro evidências anteriores conferidas; **49 verificações**. [Resumo](evidencias/2026-09-30/n10-perda-peso/resumo-perda-peso.json) e [retornos/projeções/limites](evidencias/2026-09-30/n10-perda-peso/conteudo-guiado.json). Não fornece dieta individual, meta automática ou programa clínico pronto; as lições são síntese editorial assistida por agente, ainda sem revisão profissional pt-PT.

### Fontes, fundamento humano e dados observados

| Fonte e chamada GET | Retorno efetivo | Utilidade e limite |
| --- | --- | --- |
| NU21 — [NHS, orientações gerais](https://www.nhs.uk/live-well/healthy-weight/managing-your-weight/tips-to-help-you-lose-weight/) | HTML com escolhas, listas e datas; última revisão 17/03/2023, prazo 17/03/2026 | Educação sobre bebidas, rótulos e hábitos. A faixa semanal apresentada é referência geral, nunca padrão individual; o prazo de revisão exibido já passou |
| NU22 — [CDC, Steps for Losing Weight](https://www.cdc.gov/healthy-weight-growth/losing-weight/index.html) | HTML de 17/01/2025, cinco etapas, exemplos de objetivos comportamentais e acompanhamento | Integra alimentação, movimento, sono e contexto. Não comprova eficácia clínica do TrainForge; adaptação textual condicionada aos direitos |
| NU23 — [NIDDK, escolha de programa](https://www.niddk.nih.gov/health-information/weight-management/choosing-a-safe-successful-weight-loss-program) | HTML revisto em fevereiro/2024; critérios de prova, adequação, apoio e manutenção; referências bibliográficas | Ajuda a avaliar a qualidade de um programa. A página informa revisão por cientistas/especialistas e agradece a Samuel Klein; isso não é revisão da nossa adaptação |
| NU23 — [NIDDK, porções](https://www.niddk.nih.gov/health-information/weight-management/just-enough-food-portions) | HTML revisto em julho/2021; exemplos de quantidade, tabela de diário, contextos doméstico/externo e orçamento; agradece a Carla Miller | Conteúdo textual candidato para ensino. Usa rótulos/unidades dos EUA e referências de 2020–2025: localizar e rever atualidade, sem copiar fotos nem pressupor equivalência europeia |
| NU24 — [Better Health, oferta de plano](https://www.nhs.uk/better-health/lose-weight/) | Página anuncia app de 12 semanas; **zero semanas internas importadas** | Evidência comparativa de oferta, não um programa disponível no TrainForge; licença comercial específica exigida |

**Exemplo concreto da fonte NIDDK:** 280 kcal por porção declarada, duas porções consumidas, total aritmético **560 kcal**. Não há massa em gramas demonstrada para converter livremente o “cup”. O diário ilustrativo tem **13 itens**, seis colunas (hora, alimento, quantidade, calorias estimadas, local e contexto de fome/motivo) e soma **2.916 kcal**, conferida contra o total publicado. Uma quantidade de sanduíche está ausente e permanece nula; água tem zero kcal explícito, não ausência. Esse dia exemplifica registo e contexto: **não é uma dieta indicada nem uma meta de 2.916 kcal**. Valores por item não viram composição universal por 100 g.

A extração resolveu as células `rowspan` da própria tabela; caso contrário, horário/local/calorias mudariam de coluna nas linhas seguintes. O JSON guarda índice da linha, alimento, quantidade publicada e energia da fonte, sem inventar pesos ou plano alimentar. O cálculo de consumo real continuará dependente de N02/N03 e de ingredientes/quantidades confirmados.

### Chamada e reprodução

- Manifestos: `evidencias/2026-09-30/n10-perda-peso/plano-coleta.json` e `plano-link-canonico.json`. GET público, sem chave, com `Accept: application/json,text/html,text/plain`, TLS padrão, 25 s, até 2 MiB e sem retry automático.
- A URL curta inicialmente tentada para porções retornou **404**; o link existente no guia NIDDK indicou `/just-enough-food-portions`, que respondeu 200. A falha permanece registrada sob outro ID; não significa indisponibilidade do NIDDK nem foi sobrescrita.
- `.evidencia.json` registra URL inicial/final, método, cabeçalhos, status, data UTC, tamanho, SHA-256 e corpo local. São páginas e tabelas HTML, **não APIs JSON de dietas**. `conteudo-guiado.json` é projeção nossa, não retorno original.
- Reproduzir: `python -X utf8 docs/conteudo/evidencias/analisar-perda-peso.py`, biblioteca padrão e raw local, sem rede. Confere hashes, títulos, datas, cinco etapas CDC, tabela/total, políticas e vínculo antigo do PR06. Texto integral de terceiros fica apenas em raw ignorado.

### Direitos e correção da conclusão anterior

NHS geral (NU21) usa a política OGL já guardada em N08, com exclusões e condições de adaptação/atribuição. A [política NIDDK](https://www.niddk.nih.gov/copyright) permite reproduzir a maioria do texto, excluindo certos materiais conjuntos/gráficos; versões editadas precisam remover logos e não sugerir endosso ou aconselhamento médico específico. Esses textos são candidatos, não conteúdo aprovado para todas as pessoas.

A [política CDC](https://www.cdc.gov/other/agencymaterials.html) exige crédito, ausência de endosso, informação de que a origem é gratuita e preservação do conteúdo substantivo, além de ressalvas de terceiros e jurisdição. **NU22 fica condicional para a adaptação pt-PT.** Não equiparar domínio público federal dos EUA a licença irrestrita de qualquer foto, tradução ou uso em Portugal.

Os [termos Better Health](https://www.nhs.uk/better-health/terms-and-conditions/) exigem licença comercial; a [EULA do app](https://www.nhs.uk/better-health/apps-terms-and-conditions/) restringe app/documentos ao uso pessoal e limita tradução/adaptação. **NU24 é incompatível com o caminho comercial gratuito demonstrado**, mesmo quando o app é gratuito ao consumidor.

Isso também corrige **PR06 — Couch to 5K**: o HTML recebido em 26/09 aponta, no próprio rodapé, os termos Better Health agora guardados. A conclusão anterior baseada apenas na OGL geral foi retirada; catálogo, gerador do piloto e resumo derivado passam a indicar **direitos condicionais**, aguardando permissão específica/exceção para texto e PDF exatos. Os 27 registos e suas verificações técnicas permanecem válidos como pesquisa; nenhuma autorização comercial foi obtida. Os corpos originais e check-ins históricos ficam preservados, acompanhados desta correção atual.

### O que a futura experiência pode receber e o que falta

A estrutura proposta organiza `guideId/sourceId`, instituição, público, versão/data, hash/URL, base editorial, direitos por ativo, rascunho/revisão pt-PT e lições relacionadas. O diário receberá alimento, quantidade/unidade, horário e contexto opcional, respeitando os contratos nutricionais anteriores. Retorno útil: explicar uma comparação, calcular consumo confirmado e mostrar evolução de ações escolhidas; não converter objetivo declarado em dieta, prazo garantido ou diagnóstico.

`individualEnergyTargetKcal` e `individualWeightLossTargetKg` ficam nulos. As faixas gerais das fontes permanecem identificadas como referências, com `applyAutomatically: false`. Contextos de menoridade, gravidez, condições médicas, dietas especiais, transtornos alimentares ou dados desconhecidos não podem receber silenciosamente o percurso de adulto geral; essas fronteiras são propostas editoriais, não triagem clínica validada. Texto gratuito também não substitui o apoio profissional descrito por um programa estruturado.

**Temos:** guias humanos e conteúdo candidato, critérios de avaliação, exemplos aritméticos e de diário, campos de proveniência e direitos específicos. **Falta:** revisão/localização nutricional pt-PT, aprovação por ativo, programa alimentar completo com apoio apropriado, metas individualizadas fundamentadas, integração e validação do produto. **Próximo da fila: N11 — manutenção, hábitos e qualidade alimentar**; não iniciado neste incremento. A etapa 01 continua aberta.

## AL02 / AL06 — histórico de respostas sem negócio

| Tentativa | Resposta efetivamente recebida | O que NÃO temos |
|---|---|---|
| OFF, busca de Portugal v3.6 e v2, 20 produtos, 22/09 | HTTP 503 | Nenhum produto, foto, nutriente ou código validado dessas chamadas |
| OFF v2, 30 produtos, 26/09 | HTTP 503; [URL exata e erro](evidencias/2026-09-26/network/off-portugal-30.evidencia.json) | Nenhuma amostra portuguesa; campos pedidos não são campos recebidos |
| Fineli `GET https://fineli.fi/fineli/api/v1/foods/11060`, 23/09 | HTTP 403; [registro](evidencias/fineli-food-11060.evidencia.json) | Nenhum alimento/composição recebido |

A consulta OFF de 26/09 usou `countries_tags=en:portugal`, `page_size=30`, `sort_by=unique_scans_n` e pediu `code,product_name,product_name_pt,brands,nutriments,serving_size,serving_quantity,nutrition_data_per,countries_tags,last_modified_t,lang,image_front_url,image_nutrition_url,ingredients_text,allergens_tags`. **Essa é a seleção enviada; não uma resposta observada.** Sua URL codificada integral está no índice. [Coletor usado](evidencias/coletar-pilotos.py).

Para AL02, a primeira amostra válida está no N04 acima; os registros anteriores permanecem históricos. PortFIR, BLS, Frida e outras fontes apenas documentais não possuem corpo amostrado aqui. Não produzir exemplo JSON fictício e apresentá-lo como retorno real. Cada uma mantém estado/data/próxima ação em [fontes.json](fontes.json).

## CI06 — Compêndio: HTML reduzido a código, descrição e MET

Chamadas de 23/09, HTTP 200, sem autenticação: `https://pacompendium.com/running/`, `/walking/`, `/bicycling/`, `/conditioning-exercise/`, `/water-activities/`. Os links completos constam do índice.

O retorno foi **HTML de tabelas**, não API JSON. O coletor criou `sample[].activityCode`, `metOriginal`, `descriptionOriginal`, selecionando quatro linhas por categoria; na água filtrou natação e em condicionamento alguns tipos de força/calisthenics. **20 registros preservados**, sem o HTML integral. Exemplo: código `12010`, MET original `6.0`, combinação de corrida/caminhada com a condição temporal descrita pela fonte.

Esses campos podem fundamentar classificação e estimativas posteriores; não medem calorias de uma pessoa e não constituem programa. Peso, duração e método de estimativa pertencem a outra decisão. Preservar descritor e contexto, sem substituir por um nome genérico que altere a intensidade.

Evidência local `docs/conteudo/evidencias/compendium-*.evidencia.json`, resumo [resumo-expansao.json](evidencias/resumo-expansao.json). O SHA-256 registrado é do HTML original; só restou o recorte da tabela, portanto não pode ser recalculado a partir dele. Uso comercial e atribuição documentados no catálogo da fonte.

## PR06 — programa de corrida NHS

**Correção em 30/09 (N10): direitos comerciais condicionais.** O rodapé do HTML original liga aos termos específicos Better Health, que exigem licença comercial; a conclusão OGL anterior não libera a importação. Ver [evidência e correção](#n10--alimentação-para-perder-peso). Piloto e contagens técnicas preservados; sem publicação aprovada.

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
