# Graphify — índice estrutural da retomada

**Check-in de 24/09/2026:** consulta pontual inicial a `AuthRepository`; atualização incremental final de `lib/`: **0 alterados, 42 inalterados, 0 removidos**, saídas preservadas. Revisão de visão/pitch/etapas/conteúdo/design futuro apenas documental. R01–R18 são consultados em [visão central](planejamento/README.md), evidências/lacunas em [etapa 01](planejamento/etapa-01-pesquisa.md); não estão indexados pelo grafo Dart. Índices e relatórios reutilizáveis entram no versionamento inicial; caches de extração ficam locais. Não reindexar corpora históricos sem mudança.


**Check-in de 23/09/2026:** consulta inicial de `AuthRepository` reutilizada para orientação. Atualização final incremental de `lib/` com `--code-only --no-cluster`: **0 alterados, 42 inalterados, 0 removidos**; saídas preservadas. O incremento mudou documentação e evidências de pesquisa, não o corpus Dart. Os novos documentos não foram submetidos a extração semântica. Para conteúdo, usar [fontes.json](conteudo/fontes.json) e [consulta local por ID/tema](conteudo/consultar-fontes.py), sem rede nem LLM, em vez de reler tudo. Não reindexar as referências sem mudanças.

Gerado em 09/09/2026 com Graphify **0.9.47**, já instalado nesta máquina. Extração local de código com `--code-only`; sem chamadas a modelos externos para extrair o corpus. Os relatórios registram **0 tokens de entrada e saída da extração**. Isso não significa que esta análise no Codex consumiu zero tokens nem prova um percentual de economia nas próximas conversas.

## Cobertura e artefatos

| Corpus | Arquivos de código | Nós | Arestas | Comunidades | Saídas |
| --- | ---: | ---: | ---: | ---: | --- |
| TrainForge `lib/` | 42 | 470 | 607 | 21 | [Relatório](../graphify-out/GRAPH_REPORT.md), [grafo visual](../graphify-out/graph.html), [JSON](../graphify-out/graph.json) |
| API `src/` | 33 | 193 | 495 | 7 | [Relatório](referencias/api/graphify-out/GRAPH_REPORT.md), [grafo visual](referencias/api/graphify-out/graph.html), [JSON](referencias/api/graphify-out/graph.json) |
| Frontend histórico | 53 | 295 | 422 | 19 | [Relatório](referencias/frontend/graphify-out/GRAPH_REPORT.md), [grafo visual](referencias/frontend/graphify-out/graph.html), [JSON](referencias/frontend/graphify-out/graph.json) |

Raízes reais: `C:\dev\TrainForge\trainforge\lib`, `C:\dev\bootcamp-treinos-api\src` e `C:\dev\bootcamp-treinos-frontend`. A API corresponde ao commit `523f6d9`; frontend a `11407b3`. TrainForge ainda não tem Git. O arquivo `.graphify_root` em cada saída guarda a raiz de extração.

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
