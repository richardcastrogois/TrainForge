# Graphify — índice estrutural da retomada

**Estado atual — 30/09:** N01–N10 concluídos para pesquisa nos recortes documentados; etapa 01 permanece aberta. N08: oito receitas distintas; N09: cinco guias, 14 exemplos de refeições e seis batidos; N10: quatro guias, oito rascunhos de lições e diário demonstrativo de 13 itens. Verificações: 61 / 59 / 49. Índice acumulado: 147 chamadas / 114 HTTP 200 / 113 hashes; catálogo: 61 fontes/famílias. **Correção: PR06 (Couch to 5K) agora é condicional**, pois os termos específicos Better Health não permitem presumir importação comercial pela OGL geral. Próximo da fila: N11; não iniciado. Retomar pelo dossiê e resumos, sem repetir coletas. Pesquisa não homologa publicação, integração ou adequação individual.

**Fechamento N10 — 30/09/2026:** extração incremental após documentação e correção de direitos PR06: **0 alterados, 42 inalterados, 0 removidos**. Saídas de `lib/` preservadas. N08/N09/N10 reproduzidos sem rede: 61/59/49 verificações; índice 147 chamadas / 114 HTTP 200 / 113 hashes e catálogo 61 fontes. Markdown/JSON/Python da pesquisa não pertencem a este grafo Dart e foram validados separadamente. N11 permanece não iniciado.

**Fechamento N09 — 30/09/2026:** consulta ao nó `createManualPlan`; extração incremental após o fechamento: **0 alterados, 42 inalterados, 0 removidos**. Saídas Dart preservadas; 59 verificações locais e índices de pesquisa atualizados separadamente (137 chamadas / 105 HTTP 200 / 103 hashes). Não houve indexação semântica de documentos. Próximo N10.

**Fechamento N08 — 29/09/2026:** consulta inicial ao nó `createManualPlan`; extração incremental `--code-only --no-cluster`: **0 alterados, 42 inalterados, 0 removidos**. Saídas Dart preservadas; 61 verificações de receitas, índices de pesquisa atualizados separadamente. Markdown/HTML/JSON da pesquisa não foram indexados semanticamente.

**Fechamento N07 — 28/09/2026:** Graphify atualizado após a documentação: **0 alterados, 42 inalterados, 0 removidos** em `lib/`, sem extração semântica; saídas preservadas. Índice de pesquisa atualizado separadamente: 106 chamadas / 78 HTTP 200 / 72 hashes; catálogo 50 fontes/famílias. N06/N07 concluídos para pesquisa; retomar por seus resumos e seguir N08. Documentos, analisadores e artefacto HTML não pertencem ao grafo Dart.

**Fechamento N06 — 28/09/2026:** atualização incremental após a pesquisa: **0 alterados, 42 inalterados, 0 removidos** em `lib/`; saídas preservadas. Retomar por `docs/conteudo/evidencias/2026-09-28/n06-imagens/resumo-imagens.json`. Evidências/Markdown não foram indexados semanticamente. N06 concluído para pesquisa; N07 iniciado.

**Fechamento N05 — 28/09/2026:** atualização incremental de `lib/` executada após concluir e documentar N04/N05: **0 alterados, 42 inalterados, 0 removidos**; saídas preservadas, sem extração semântica nem LLM externo. Índice da pesquisa: 77 chamadas / 51 HTTP 200 / 45 hashes; 46 fontes no catálogo. Cinco perfis N05 e 66 verificações locais. Retomar pelo resumo N05 acima e pelo dossiê; N06 ainda não iniciado.

Os check-ins seguintes são históricos e mantêm as contagens de cada incremento.

**Histórico — fechamento N04 em 28/09:** consulta inicial ao nó `createManualPlan`; atualização incremental após a pesquisa: **0 alterados, 42 inalterados, 0 removidos**. Retomar por `docs/conteudo/evidencias/2026-09-28/n04-fechamento/resumo-fechamento.json`. 24 produtos, quatro marcas, 35 verificações e 27 anteriores. O grafo cobre `lib/`; estes documentos/JSON não foram indexados semanticamente. N04 concluído para pesquisa; N05 iniciado.


**Contrato N04 — 28/09/2026:** consulta inicial reutilizou o nó de criação manual no grafo existente; atualização final `--code-only --no-cluster` concluída: **0 alterados, 42 inalterados, 0 removidos**. O corpus Dart não mudou e as saídas foram preservadas. Novo demonstrador/scripts/evidências não estão indexados por esse grafo: retomar pelo [resumo pequeno](conteudo/evidencias/2026-09-28/n04-contrato-off/resumo-contrato.json), [contrato](conteudo/evidencias/2026-09-28/n04-contrato-off/contrato-nutricional.json) e [dossiê](conteudo/evidencias-para-integracao.md#n04--produtos-vendidos-em-portugal). Campo nutrition v3.6/schema 1004 confirmado; 27 verificações locais; 15 produtos acumulados, três filtros de marca 503 sem repetição. Índice acumulado: 60 chamadas/36 HTTP 200/28 hashes. Commit anterior 104a3bb publicado e conferido em origin/main; este incremento posterior permanece local. N04 aberto; N05 não iniciado.

**Primeiro incremento N04 — 27/09/2026:** consulta inicial ao nó `features_onboarding_data_onboarding_api_createmanualplan` do grafo existente. Atualização incremental final `--code-only --no-cluster`: **0 alterados, 42 inalterados, 0 removidos**, saídas preservadas. A primeira tentativa de validação documental posterior não executou porque a revisão automática atingiu o limite de uso; a retomada pelo mesmo fluxo passou. N04 permanece em andamento, com dez produtos reais e diferença de nutrientes v2/v3.6 ainda não esclarecida. Retomar pelo [resumo N04](conteudo/evidencias/2026-09-27/n04-produtos-portugal/resumo-produtos.json), pela [comparação](conteudo/evidencias/2026-09-27/n04-produtos-portugal/comparacao-v2-v3.json) e pelo [dossiê](conteudo/evidencias-para-integracao.md#n04--produtos-vendidos-em-portugal). Índice de 51 chamadas/32 HTTP 200/19 hashes. Não repetir as quatro coletas para recuperar contexto; documentos/evidências não estão no grafo de `lib/`.

**Fechamento N03 — 27/09/2026:** consulta inicial pontual do nó de criação manual de plano no grafo existente, sem reler o código inteiro. Atualização final `--code-only --no-cluster` concluída em cerca de 2 s: **0 alterados, 42 inalterados, 0 removidos**; saídas preservadas. O grafo é estrutural de `lib/`, não um índice dos novos documentos/JSON. Para retomar sem nova rede, usar o [resumo N03](conteudo/evidencias/2026-09-27/n03-porcoes/resumo-porcoes.json), o [dossiê](conteudo/evidencias-para-integracao.md#n03--quantidades-porções-volume-e-preparo), o [índice de 47 chamadas](conteudo/evidencias/retornos-observados.json) e a [fila](planejamento/etapa-01-pesquisa.md#fila-da-etapa-01-por-nicho). N04 é o próximo foco. Os check-ins abaixo registram estados anteriores.

**Fechamento do dossiê e N01 — 26/09/2026:** consulta inicial reaproveitada, seguida de duas atualizações incrementais: após consolidar o dossiê e ao concluir a pesquisa de identidade alimentar. Ambas: **0 alterados, 42 inalterados, 0 removidos**, saídas preservadas, sem extração semântica. Para retomar a pesquisa, ler o [dossiê de chamadas/retornos](conteudo/evidencias-para-integracao.md), o [índice de 44 registros](conteudo/evidencias/retornos-observados.json), o [resumo N01](conteudo/evidencias/2026-09-26/n01-alimentos/resumo-identidades.json) e a [fila de nichos](planejamento/etapa-01-pesquisa.md#fila-da-etapa-01-por-nicho). N01 está concluído para pesquisa no recorte Ciqual; N02 é o próximo. Esses documentos complementam o grafo de `lib/`, não fazem parte dele.

**Check-in de 26/09/2026:** consulta pontual ao JSON existente de onboarding/planos, complementada pelo catálogo local de fontes. Pilotos e pesquisa em [resumo pequeno](conteudo/evidencias/2026-09-26/pilotos-resumo.json); catálogo em `conteudo/fontes.json` com 45 fontes/famílias. Atualização incremental final: **0 alterados, 42 inalterados, 0 removidos**, saídas preservadas. O grafo continua restrito a `lib/`; não afirmar que indexa os novos scripts/JSON/documentos de pesquisa. Não repetir chamadas OFF falhadas, PDFs ou o grafo completo para retomar este incremento.

**Check-in de 25/09/2026:** inventário de funções, retornos de fontes/APIs e disponibilidade concreta em [cobertura e prioridades](conteudo/cobertura-e-prioridades.md). A consulta `explain` não retornou nesta execução e foi interrompida; usamos uma seleção local de nós/vizinhos de autenticação, exercícios e estatísticas no JSON existente, seguida da conferência pontual dos modelos/builder. Não reenviar o grafo inteiro ou repetir toda a coleta das fontes. Atualização final concluída via runtime Python instalado (`python -m graphify extract ... --code-only --no-cluster`): **0 alterados, 42 inalterados, 0 removidos**; saídas preservadas. Só documentação mudou, portanto não houve extração semântica nem reindexação dos corpora históricos.

**Check-in de 24/09/2026:** consulta pontual inicial a `AuthRepository`; atualização incremental final de `lib/`: **0 alterados, 42 inalterados, 0 removidos**, saídas preservadas. Revisão de visão/pitch/etapas/conteúdo/design futuro apenas documental. R01–R18 são consultados em [visão central](planejamento/README.md), evidências/lacunas em [etapa 01](planejamento/etapa-01-pesquisa.md); não estão indexados pelo grafo Dart. Índices e relatórios reutilizáveis entram no versionamento inicial; caches de extração ficam locais. Não reindexar corpora históricos sem mudança.


**Check-in de 23/09/2026:** consulta inicial de `AuthRepository` reutilizada para orientação. Atualização final incremental de `lib/` com `--code-only --no-cluster`: **0 alterados, 42 inalterados, 0 removidos**; saídas preservadas. O incremento mudou documentação e evidências de pesquisa, não o corpus Dart. Os novos documentos não foram submetidos a extração semântica. Para conteúdo, usar [fontes.json](conteudo/fontes.json) e [consulta local por ID/tema](conteudo/consultar-fontes.py), sem rede nem LLM, em vez de reler tudo. Não reindexar as referências sem mudanças.

Gerado em 09/09/2026 com Graphify **0.9.47**, já instalado nesta máquina. Extração local de código com `--code-only`; sem chamadas a modelos externos para extrair o corpus. Os relatórios registram **0 tokens de entrada e saída da extração**. Isso não significa que esta análise no Codex consumiu zero tokens nem prova um percentual de economia nas próximas conversas.

## Cobertura e artefatos

| Corpus | Arquivos de código | Nós | Arestas | Comunidades | Saídas |
| --- | ---: | ---: | ---: | ---: | --- |
| TrainForge `lib/` | 42 | 470 | 607 | 21 | [Relatório](../graphify-out/GRAPH_REPORT.md), [grafo visual](../graphify-out/graph.html), [JSON](../graphify-out/graph.json) |
| API `src/` | 33 | 193 | 495 | 7 | [Relatório](referencias/api/graphify-out/GRAPH_REPORT.md), [grafo visual](referencias/api/graphify-out/graph.html), [JSON](referencias/api/graphify-out/graph.json) |
| Frontend histórico | 53 | 295 | 422 | 19 | [Relatório](referencias/frontend/graphify-out/GRAPH_REPORT.md), [grafo visual](referencias/frontend/graphify-out/graph.html), [JSON](referencias/frontend/graphify-out/graph.json) |

Raízes reais: `C:\dev\TrainForge\trainforge\lib`, `C:\dev\bootcamp-treinos-api\src` e `C:\dev\bootcamp-treinos-frontend`. A API corresponde ao commit `523f6d9`; frontend a `11407b3`. Na coleta inicial de 09/09, TrainForge ainda não tinha Git; a publicação inicial foi concluída em 24/09, conforme os check-ins posteriores. O arquivo `.graphify_root` em cada saída guarda a raiz de extração.

Foram excluídos o Prisma gerado na API e o cliente Orval gerado na web, além de dependências/builds ignorados pela ferramenta. Na web, foram excluídos explicitamente `.mcp.json`, `.vscode` e `.idea`. Arquivos `.env` e credenciais não fazem parte do corpus. Os grafos de referência foram guardados aqui para não alterar os projetos históricos.

O grafo principal cobre **Dart em `lib/`**, não manifest Android/iOS, pubspec, docs ou banco. O da API cobre código `src/`, não as migrations/schema Prisma. Esses itens foram examinados diretamente e documentados. Figma e documentação não receberam extração semântica no Graphify.

Os relatórios foram finalizados em `cluster-only`, por isso exibem “file stats not available”; a tabela acima complementa essa limitação com os corpora extraídos. As comunidades receberam rótulos legíveis revisados nesta análise, sem modificar nós/arestas. Na API, 43 arestas estão marcadas `INFERRED` pelo extrator; não são comprovação de chamadas em runtime. As arestas dos outros dois grafos estão marcadas `EXTRACTED`.

## Como consultar gastando menos contexto

Comece pelo [guia](../guia-do-projeto.md), escolha o fluxo e consulte somente sua vizinhança no grafo. Depois abra os arquivos correspondentes. Não envie `graph.json` inteiro para o agente a cada pergunta.

Exemplo **verificado** no PowerShell:

```powershell
Set-Location C:\dev\TrainForge\trainforge
graphify explain features_auth_data_auth_repository_authrepository --graph graphify-out/graph.json
```

Esse nó é `AuthRepository`, com nove conexões no grafo. Buscar apenas `AuthRepository` retorna vários candidatos: use o ID completo apresentado pela ferramenta para eliminar ambiguidade. IDs do app relativos a `features/` correspondem a arquivos dentro de `lib/features/`.

`graphify query "..." --budget 500 --graph ...` foi tentado, mas não produziu resultado conclusivo neste ambiente; não está registrado como consulta validada. O HTML, JSON e `explain` estão disponíveis. `--budget` limita a saída dessa consulta, não o consumo total do agente.

Pontos de partida úteis:

| Pergunta | Começar por | Confirmar no código |
| --- | --- | --- |
| Como o login chega ao backend? | AuthRepository, AuthApi, AppDio | AuthUser/AuthStorage e `mobile-auth.ts` |
| Por que a entrada faz chamadas repetidas? | AuthGate, HomePage | Bootstrap, passagem de dados e `initState` |
| Como gerar um plano sem IA? | buildManualWorkoutPlan, CreateWorkoutPlan | Parâmetros recebidos/ignorados e transações |
| Quem pode iniciar/concluir um treino? | Rotas mobile-workout-plans e casos de sessão | Cadeia de proprietário, locks, data e estado |
| Por que mudar plano altera as estatísticas? | GetStats, GetHomeData | Filtro de plano ativo e agregação de sessões |

## Relações que merecem atenção

`AuthRepository` concentra login e armazenamento no cliente. Na API, `getMobileUserFromAuthorizationHeader` tem 16 conexões e `prisma`, 14: são pontos de impacto amplo. Na web, `getProtectedBootstrap` tem 15, refletindo centralização de contexto no Next.js. Muitos hubs visuais são imports/frameworks; grau alto não significa automaticamente um defeito de arquitetura.

A relação mais importante **entre corpora** foi confirmada pela leitura dos contratos: Flutter chama a API ainda localizada no bootcamp. Os três grafos estão separados e não pretendem inferir automaticamente essa ligação HTTP. A documentação técnica registra a cadeia entre eles.

## Atualizar sem indexar conteúdo desnecessário

Para repetir a extração principal, na raiz do app:

```powershell
graphify extract C:\dev\TrainForge\trainforge\lib --code-only --out C:\dev\TrainForge\trainforge
graphify cluster-only C:\dev\TrainForge\trainforge --no-label
```

`--out` recebe a pasta **pai**: o comando acrescenta `graphify-out/`. `--no-label` evita solicitar nomes de comunidades a um backend de LLM; os nomes automáticos podem ficar genéricos e os rótulos revisados podem precisar de reposição. Não usar `label` com provedor externo para uma simples atualização estrutural.

Para os corpora de referência, preservar os filtros usados:

```powershell
graphify extract C:\dev\bootcamp-treinos-api\src --code-only --exclude generated --out C:\dev\TrainForge\trainforge\docs\referencias\api
graphify extract C:\dev\bootcamp-treinos-frontend --code-only --exclude app/_lib/api/fetch-generated --exclude app/_lib/api/fetch-generated.ts --exclude .mcp.json --exclude .vscode --exclude .idea --out C:\dev\TrainForge\trainforge\docs\referencias\frontend
```

As exclusões ficam em `.graphify_build.json`. Antes de uma atualização futura, conferir arquivos e filtros; não aplicar `--force` apenas para suprimir uma proteção da ferramenta. Não indexar o disco inteiro. Se `graphify` não estiver no PATH, o executável encontrado nesta máquina é `C:\Users\richa\.local\bin\graphify.exe`.

## Validação e limites

`diagnose multigraph --json` passou nos três JSONs finais: nenhum endpoint ausente/pendurado, duplicação exata, self-loop ou colapso adicional no grafo já construído. Isso **não recupera arestas perdidas antes da exportação** e não valida a lógica do produto. Os grafos são não direcionados; orientação real das chamadas exige ler os metadados e a fonte.

Para o GitHub na fase 2, decidir quais relatórios/JSONs/HTMLs serão mantidos. Excluir caches, backups datados e metadados com caminhos da máquina do staging; classificar artefatos gerados com regras específicas se forem versionados. Não criar um histórico paralelo de segredos ou configurações de ferramentas.
