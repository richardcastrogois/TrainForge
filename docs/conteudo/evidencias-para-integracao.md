# Evidências de retorno para a implementação

Registro de **26/09/2026**, baseado nas chamadas e arquivos preservados de 22–26/09. Este documento responde **de onde veio, como foi chamado, o que retornou, onde está e o que pode alimentar no app**. Não define os futuros endpoints internos do TrainForge nem afirma que as integrações existem.

Os campos abaixo foram observados em amostras. Presença na amostra não é garantia de obrigatoriedade ou disponibilidade futura do fornecedor. As permissões e limitações continuam no [catálogo por fonte](fontes.json) e em [direitos](direitos-e-acordos.md).

## Como recuperar sem fazer outra chamada

- [Índice de chamadas e hashes](evidencias/retornos-observados.json): **51 registros de chamadas preservadas**, incluindo tentativas sem rede e falhas; 32 respostas HTTP 200. Não são 51 APIs ou 32 fontes diferentes. Inclui N01/N03 e os quatro GETs do primeiro incremento N04.
- [Inventariador local](evidencias/inventariar-retornos.py): gera o índice sem rede; conferiu 19 corpos mantidos como arquivos contra o SHA-256 original. Não confundir o hash de um corpo HTTP com o de um JSON reformatado pelo coletor.
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

O detalhe retornou `status: success`, `result.id: product_found`, `errors: []`, `warnings: []` e `product`; código, marca e nome conferem com a busca. Porém **`nutriments` veio vazio**, com a mesma projeção solicitada. Ainda não foi demonstrado se a diferença vem do schema, de `fields`, da versão ou de outro comportamento. Não completar com zero nem substituir silenciosamente o valor de outra versão. O retorno usa `nutrition_data_per: 100g` mesmo no exemplo de embalagem em ml; também não inferir densidade por essa combinação.

### O que temos e o que falta

**Temos:** primeira amostra real de produtos marcados para Portugal, rastreabilidade completa, disponibilidade/ausência dos campos medida e identidade de um código confirmada por detalhe. O [analisador](evidencias/analisar-produtos-portugal.py) reconfere os quatro hashes, contagens, unicidade, país, dígitos e resposta de negócio, sem rede.

**Falta para fechar N04:** conferir o schema nutricional e a projeção do detalhe antes de nova chamada pontual; definir uma amostra justificada que cubra marcas/categorias relevantes em Portugal; documentar produto não encontrado, busca vazia e falhas para o futuro adaptador. Não ampliar para fotografias/alergénios/receitas de outros nichos neste incremento.

**Direitos:** o guia oficial aponta ODbL para a base, DbCL para conteúdos individuais e CC BY-SA para imagens, com possíveis direitos de terceiros. Atribuição e tratamento de base derivada continuam decisões de publicação; não foram homologados nesta coleta. Nenhuma imagem foi solicitada e não houve contato, cadastro ou publicação externa. [Guia primário de licenças](https://openfoodfacts.github.io/openfoodfacts-server/api/tutorials/license-be-on-the-legal-side/).

Reprodução local: `python docs/conteudo/evidencias/analisar-produtos-portugal.py`. Não executar o coletor para reler contexto: os quatro resultados e as falhas antigas já estão preservados.

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
