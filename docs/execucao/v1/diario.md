# Diário de execução V1

## 21/10/2026 — preparação inicial (histórica, seguida da revisão abaixo)

- Pesquisa consolidada em commit local `57f623a`; nenhuma publicação remota nesta etapa.
- Inspeção estática Flutter/Fastify/Prisma, proposta Go modular, contratos e modelo lógico; não implementados.
- Backlog canônico com12 épicos/43 histórias, todas `todo`. Próxima história V1-001.
- Pontos de entrada reorganizados, snapshots históricos preservados. Ferramentas do painel e inventário separados de código do aplicativo.
- Resultado final de validação desta entrega em [validacao-planejamento.md](validacao-planejamento.md).

Próximas entradas devem registrar somente ações/resultados efetivos, com história e evidência.

## 21/10/2026 — revisão solicitada: documentação no repositório e Swagger por comentários

- Autor determinou remover o painel local e substituí-lo por documentação arquitetural dinâmica, consultável sem servidor por quem clona o projeto.
- Serviço local encerrado; arquivos do painel/lançador/testes específicos removidos. Diagnóstico, contratos, pesquisa e backlog preservados e atualizados.
- Geração determinística Markdown/Mermaid com caminhos relativos; backend Fastify é referência capturada com commit/hashes, sem acesso implícito a outro checkout.
- Comentários/DTOs Go tornam-se fonte do Swagger; JSON/YAML são derivados. Serviço Go ainda ausente; ferramenta informa pendência e não cria spec fictícia.
- V1-003 em andamento pela publicação e validação da CI no remoto ainda pendentes; V1-008 foi revisada, sem implementação do backend.
- Resultado da verificação local desta revisão em [validação](validacao-planejamento.md). Sem push, deploy, banco, instalação persistente de dependência do app ou alteração funcional Flutter.

## 21/10/2026 — respostas do autor sobre o APK de avaliação

- Registrada a [direção do piloto](decisoes-piloto.md): avaliar o app inteiro por cenários, com conteúdo real e lacunas visíveis, em APKs durante o desenvolvimento. Não aguardar o produto completo nem restringir a avaliação a uma jornada pequena.
- Conteúdo conforme disponibilidade/direitos: fotos e vídeos juntos ou separados, ausência de mídia/instrução explícita. Autonomia como objetivo, sem inventar adaptações ou remover apoio exigido pela fonte.
- Alimentação: cobertura ampla pesquisada, busca por texto e cadastro próprio real; origem, unidades, nutrientes ausentes e privacidade separados do catálogo editorial.
- V1-001 em andamento: decisões registradas, manifesto e matriz de cenários ainda por construir/conferir. Não marcada concluída. Critérios de019/020/022/025 e checkpoints de034/036 ajustados; nomes/rotas de domínio seguem propostas de implementação.
- Custo de conteúdo reformulado ao autor e ainda sem resposta registrada nesta revisão. Nenhuma compra, contato, instalação, mudança funcional Flutter/Go, migration, deploy ou APK executado.
- Validação documental: `python tools/gerar_documentacao.py --write --check` passou com geração reproduzível, backlog/dependências/requisitos/entradas/links locais; `python -m unittest discover -s tools -p test_documentacao.py` passou com13testes. Não são testes do aplicativo nem de conteúdo/prática.

## 21/10/2026 — custo esclarecido, nova pista e conclusão documental V1-001

- Autor permite avaliar alternativas pagas de pagamento único e valor baixo, com condições apresentadas antes da decisão; teto numérico/compra não aprovados. A pendência de resposta citada na entrada anterior foi resolvida.
- Pista ExerciseDB OSS/completo, wger, WorkoutX e marketplaces conferida em páginas oficiais e evidências locais. [Comparação e limites](../../conteudo/avaliacao-apis-exercicios-2026-10-21.md): OSS não comercial; cache não universal; WorkoutX exercícios por assinatura, compra única Body Scan é outro produto; ExerciseDB.io é fornecedor distinto com compra única anunciada. Sem conta, contato, compra, download de mídia ou contorno de barreira.
- [Manifesto candidato](../../../content/manifests/pilot-candidates.json):331famílias/46Ns/34componentes documentais, incluindo22famílias alimentares; não331fornecedores homologados nem34programas completos. [Matriz](matriz-cenarios.md):24cenários e coberturaR01–R18; estados honestos e APK incremental.
- `python tools/validar_manifesto_piloto.py`: PASS,1248checagens de referências, ponteiros, hashes, cobertura e estados; [recibo](verificacao-manifesto.json). Nenhum item runtime aprovado/importado. V1-001 concluída nesse escopo documental, próxima V1-002; V1-003 continua em andamento pela CI remota.
- Flutter, Go, banco, infraestrutura e APK não foram implementados/alterados nesta rodada. Nenhuma compra, novo contato ou publicação. Gerar/conferir derivados e executar suíte documental existente após esta atualização.

- A suíte documental detectou uma premissa antiga no caso negativo `test_cycles_and_done_without_evidence_are_rejected`: a primeira história agora possui evidência real. O teste passou a esvaziar explicitamente `completionEvidence` na cópia inválida, mantendo a rejeição de conclusão sem prova e de ciclo; nenhuma regra de validação foi relaxada.

- Verificação final após regeneração:13testes documentais passaram, `python tools/gerar_documentacao.py --write --check` passou e `git diff --check` passou. Validador do manifesto passou novamente; nenhuma evidência de execução do app foi criada.

## 21/10/2026 — limite de custo e alternativas gratuitas

- Autor considerou os valores anteriores inviáveis e indicou cerca deUS$19 em pagamento único como possibilidade; priorizar gratuitas, sem assinatura nem compra por inferência. A decisão é mais específica que o limite ainda indefinido dos registros anteriores.
- Nova pista conferida em fontes primárias: OSS não comercial/cache por plano; RapidAPI tem fornecedores distintos e múltiplos objetos de cobrança; exercicios-bd-ptbr é candidato de textoCC0 com imagens excluídas; RepDB permite uso comercial in-app gratuito com crédito, mas declara imagens deIA e não tem pt na camada gratuita. Sem adoção automática, scraping, download de mídia, cadastro ou cartão.
- [Comparação atualizada](../../conteudo/avaliacao-apis-exercicios-2026-10-21.md). As331famílias históricas e a conclusão documental V1-001 são preservadas; novas pistas são suplementos, não programas aprovados nem retorno indiscriminado àsN. Nenhuma mudança funcional no app/API/banco.

## 21/10/2026 — continuação efetiva de conteúdo da etapa01

- Autor pediu seguir na etapa01 após fixar prioridade gratuita/cerca deUS$19 em compra única. V1-002Go não foi iniciada; execução segue V1-004/005, sem reabrirN01–N46.
- V1-004: schema editorial, validação do domínio e permissões por operação; movimento, instrução, mídia, protocolo original e coleção distintos. Dose ausente não vira zero; UUID não vira versão publicada; contexto e apoio preservados.
- Preparação local:109movimentos/práticas,329registros textuais,68referências de mídia,1protocolo-fonte e5coleções.512ativos,14bloqueios específicos,0aprovações de runtime e0downloads de mídia. Conteúdo de terceiros derivado fica em `content/local/`, fora do Git; matriz/fila/relatórios são metadados.
- Alimentação:3.484registrosCiqual e2.887por código+nomeCoFID;13tabelasCoFID preservadas, com fatores e bases100gFood/100gFA/exceção alcoólicos100ml separados. Código13-669 duplicado em dois alimentos preservado com conflito;15valoresCoFID não interpretados não foram convertidos silenciosamente.
- Auditoria independente:512ponteiros e1.069.660células originais conferidos; schema acompanha contrato, validador local é de domínio e não alega implementar todo JSONSchema.17testes semânticos isolados verificam permissões/ausências/unidades/apoio, sem fixtures no lote entregue.
- [Resultado, caminhos e próximos passos](../../conteudo/preparacao-local-2026-10-21.md). V1-004 concluída no escopo de contrato/preparação; V1-005 em andamento pela fila real. V1-006/019não concluídas; sem escrita emDB, alteração Flutter/Go, provisão cloud, compra ou APK. Conferência final de geração/testes registrada após execução.

- Conferência final:30testes de conteúdo/documentação passaram; geração e auditoria local passaram; `git diff --check` sem erro. Três arquivos locais derivados de terceiros confirmados como ignorados pelo Git. Commit local autorizado: `chore: prepare real pilot content and editorial review`; sem push.

## 21/10/2026 — primeira revisão efetiva para consulta

- Preparação anterior salva no commit local `7748f18`, sem push. Revisão documental continuou na mesma etapa, identificada como trabalho do agenteCodex, sem revisor humano/profissional presumido.
- Seis textosPTwger conferidos; dois textos preservados para consulta. Outros quatro têm pendências específicas de redação, suficiência ou variante. Movimento1670 retido pela divergência título/corpo;1022 mantém bloqueio anterior.
- Projeção separada:73metadados/2textos,0prática,0mídia,0entregaAPK validada;437ativos fora da projeção. Cada decisão presa ao hash do objeto e com créditos/condições próprios. Nenhuma nova tradução/dose/instrução completada porIA.
- Corrigido desvio do contrato em20ativos: mapas de exceções saem da etiqueta escalar de licença para `sourceRightsFacts`, preservados. Validador e caso de regressão acrescentados; originais intactos.
- [Resultado e limites](../../conteudo/revisao-consulta-2026-10-21.md). TermosCCBYSA3/4conferidos em fontes primárias, sem copiar seus textos integrais. V1-005 permanece em andamento;006/019/Go/banco/Flutter/APK não concluídos por esta revisão.
- Primeira execução de37testes detectou somente inventário gerado desatualizado após novas ferramentas; regenerar e conferir antes do commit. Resultado final registrado após execução.

- Conferência final:37testes passaram; auditoria de512ativos/1.069.660células passou; checks de preparação e revisão passaram. Mapa documental regenerado/conferido e diff sem erro. Quatro arquivos derivados locais continuam ignorados. Commit local autorizado desta revisão: `chore: review pilot consultation content`; sem push.

## 21/10/2026 — fechamento integral da triagem e início da fundação

- Autor pediu concluir etapas em sequência. V1-005 teve512disposições completas:73metadados/439excluídos,0ensino/prática. Dois textos anteriormente selecionados foram retirados da publicação instrucional por autoria profissional não comprovada. Fim da triagem não equivale à liberação dos excluídos.
- V1-002: Go modular, banco isolado e Goose escolhidos; cópiaGo1.27.3portátil validada porSHA256eexecução da versão, sem alterarGo/PATHglobais. Docker existente iniciado em segundo plano; conexão ainda sendo verificada, sem reiniciar outros projetos.
- [Saída da etapa01](etapa-01-fechamento.md), [decisão](../../arquitetura/decisao-go-v1.md). Próxima007;003transversal mantém pendência de publicação. Nenhuma migration, usuário real, treino novo ou APK simulados.


## Continuação21–22/10 — M1 local

Go1.27.3portátil instalado/verificado; serviço modular `services/api`, net/http+pgx, requestID/limites/timeouts/shutdown e health/live vsready. Docker falhou no socketInference; usar binários nativosPostgreSQL17.5 em cluster separado15432, sem tocar legado. Três migrations Goose e grants separados aplicados; PostgreSQLpatch deve atualizar antes de staging.

Importador validou artefato/allowlist, transação e versão imutável; encontrou bug real de CRLF no hash preparado pelo Python, corrigido para bytes LF com regressão.73metadados importados, reimportações sem duplicar, zero usuários/treinos/consumos. Backup restaurado noutra base, contagens/hash iguais e cinco restrições testadas; fixtures revertidas/base temporária removida.

Swagger real2.0, duas rotas de saúde: teste do watcher mudou anotação, observou versão nova, restaurou e confirmou versão original antes de parar processo. Corrigidos packageName temporário e verificação de versão pelo buildinfo do Swaggo. CI Go/Swagger preparada; execução remota não realizada.

006–010 encerradas nos recortes documentados em etapa-02-fechamento.md; próxima011 Google real. Migração de dados legados é fora do recorte desta fundação: não sabemos suas contagens; inventário é gate de futura migração. Sem prática/Flutter/APK homologados.


##22/10 — encerramento para o próximo chat, a pedido do autor

Etapas01 e02/M1 concluídas no commitc23ace6;011 apenas investigada. Não foram criados handlersAuth, alteraçãofuncionalFlutter ou loginfictício. Investigada bibliotecaidtokenGooglev0.24.1 e identificados logs debody/response noAppDio e limpeza detokenemqualquerfalha noAuthRepository. Pendências detalhadas nohandoff; dependência exploratória não utilizada removida, manifestsGo restaurados ao commitvalidado.

Texto novo do autor recebido e comparativo consolidado emdocs/conteudo/opcoes-apis-exercicios.md, preservando evidências anteriores e um endereço histórico simples. Fontes primárias consultadas sem download demídia:free-exercise-db/Unlicense; GymRatREADMEdeclaraMITmasLICENSE404; hasaneyldrmNOTICEseparaGymvisual; APINinjasimagenspremium; MuscleWikigrátissóPlayground; MoveKitclipeavulso/APIemespera; ExerciseAnimaticinacessível/preçoaindanãoconfirmado.

Novo teto futuroatéR$400, gratuitasprimeiro, preferência porcompraúnica mantida; nenhuma compra, assinatura, cadastro, contato, scraping ou teste decarga deterceiros. Explorar opções gratuitas não autoriza ultrapassar quotas nem copiar biblioteca com direitos pendentes. Não reabrirNs porhábito.

API/watcher parados; clusterV1 parado comtools/db_local.py stop, dados/credenciais/backupretidos. ZIPGooficial instalado/verificado removido, toolchainmantida. Handoff comcomandos/estado/pontodecontinuação atualizado. Sempush/publicação.

## 22/10/2026 — retomada V1-011, segurança do cliente

Retomada autorizada no clone correto; HEAD inicial90e746e, working tree limpo. AppDio deixou de registrar URLs/query/headers/corpos/exceções e usa eventos fixos, status e categoria. Falha de secure storage interrompe a requisição. AuthRepository remove credencial somente diante de401 confirmado; timeout/offline/403/429/5xx propagam sem apagar sessão. AuthPage não exibe texto bruto de exceção.

Validação nova: Flutter3.41.4/Dart3.11.1 existentes; 7testes em test/auth_security_test.dart passaram e analyze dirigido sem achados. São regressões isoladas, não loginGoogle real. OAuth debug/release, implementaçãoGo e integração continuam pendentes. Nenhuma pesquisa de conteúdo, instalaçãoFlutter, reimportação ou restore repetidos. As execuções de binários no sandbox travaram sem output; leituraGit fora dele confirmou o estado.

## 22/10/2026 — auth Go/Flutter e checkpoint Android implementados, aceite pendente

Implementados Google oficialv0.24.1 (assinaturaRS256/issuer/audience/exp/iat/sub/e-mailverificado), identidade canônica por issuer+sub sem associação por e-mail, persistência transacional e sessão opaca256bits com hashesSHA256. Migration00004 aditiva aplicada ao clusterV1. Refresh singleuse com lock porfamília, reuso revoga inclusive access e vencedorconcorrente, logout idempotente por dispositivo e TTLmáximofixo.

Flutter migrou explicitamente auth para rotas/DTOsGo, com configuração por dartdefine, securestorage de parrotativo numa chave separada, refresh coordenado/retryúnico e limpeza condicional serializada. Offline/timeout/429/5xx preservam sessão; logoutoffline não declara revogação. Checkpoint da entrada mostra conta real e lacunas, sem chamar bootstrap/geradoresFastify. Produto continua Android+iOS; sem teste iOS.

Validações:12testesFlutter e analyze completo semissues; go test ./... e go vet ./...; testes criptográficosRSA/JWKS e negativosHTTP; concorrênciaPostgreSQL em DBtemporáriaexcluída e contagemV1inalterada;42testesPython; Swagger6operações conferido no processoAPI real. Testes negativos revelaram panic do parserSDK com payloadnull; implementada rejeição de formato/claims antes de validar assinatura e acrescentada regressão. Backend não devolve errosinternos nem credenciais. A revisão corrigiu corridas na limpeza local de sessão; testes passaram e APKfoirecompilado.

Autor confirmou por capturas o projetoCloud correto, OAuthdebug com pacote/fingerprint e clientWeb; públicoExternal com3contasteste. Existem avisosGoogledeinatividade. ClientOAuthrelease ainda não criado pelo autor. Certificado localRSA3072release dedicado criado em.local; Gradle não cai emdebug. ACLdoproperties restringida apósautorizaçãoexplícita, resolvendo rejeição inicial doauto-review. Nenhum segredo comitado.

EmuladorGooglePlayTrainForge_Benchmark existente iniciado, porta8082reversa; APKdebug gerado/instalado/aberto sem apagar dados. NovoAPK com últimos ajustes também gerado e assinatura verificada; não reinstalado para não interromper o loginmanual. Hashes/estado exatos emandroid-auth-checkpoint.json. Ainda0usuáriosV1naúltimaconferência; nenhuma fixture na base entregue. APIwatcher/cluster/emulador permanecemativos para intervenção doautor. Não houve loginGoogle real comprovado.

Backlog011permanece doing e completionEvidencevazio;012tem preparação implementada, sem fechamento. Handoff/guiaOAuth/contrato/Swagger/achados/diagramas atualizados. GrafoFlutter atualizado somente porAST (10alterados/33inalterados,499nós/640arestas); HTMLexportado, backupanterior guardado em.local. Semnova pesquisa deconteúdo, reimportação, restore, instalaçãoFlutter, push/deploy/compra/contatoexterno.

## 22/10/2026 — catálogo real, frontend e retomada preparados enquanto autor está fora

GitHub main consultado diretamente permaneceu90e746e;1765708/6d3f3a4 eram commits locais, sem push e sem confirmação pendente. Autor adiou login/OAuthrelease até voltar ao notebook. Nenhum consentimentoGoogle automatizado.

V1-014 concluída pelas dependências006/008: cinco leituras Go para catálogo/filtros/detalhe, movimentos separados de programas, filtros/cursor limitado, versão exata, rights/review/fidelity/withdrawal antes deETag. Projeção só de metadados, sem dose/instrução/mídia. LoteHTTP real exatamente73IDs revisados e créditos completos;0programas/prática, hash/contagens inalterados. FixturesSQL isoladas foram removidas, incluindo versões/retirada/ETag e ausência de privilégioeditorialruntime. Ver catalog-read-verification.json.

Flutter recebeu controllerauth injetado e restauração única, retry correto de logout/cancelamento/mensagens seguras; biblioteca pública/autenticada, busca/filtros/paginação/estados/detalhe revalidado e atribuição/licença/versões/requisitos sem inferência. url_launcher6.3.3 oficial adicionado para linksHTTPS voluntários. Não foram ligados os geradores legados. BackupAndroid desabilitado e regras excluem cloud/device/cross-platform-transfer para não copiar tokens.

APKdebug0.1.1+2 gerado/assinado, instalado sem apagar dados e inspecionado emAndroid35GooglePlay. Lista/detalhe públicos com autoria/licença conferidos, capturas ignoradas sem identidade.24testesFlutter e analyze passaram; go test/vet passaram;48testesPython passaram. Swagger atualizado para11operações. Não houve novo loginreal nem cadastro de usuário fictício.

Helper avaliar-android.ps1 validado de partida fria: iniciou somente DB/API/AVD existentes, conferiu certificado/fonte/config/APKhash, pulou reinstalação redundante e abriu app. Parada conferiu propriedade/bootID e encerrou os três recursos; APK/dados/credenciais/chave retidos. Recibo android-environment-verification.json. Roteiro para retorno em avaliacao-android.md.

V1-011 permanece doing,012/021/022parciais sem fechamento;016aguarda conteúdo realmente liberado. Demais módulos, HTTPSrelease e iOS não estão entregues. Backlog/contratos/achados/mapas/handoff atualizados e regenerados. Graphify incremental code-only:50Dart,615nós/786arestas,10alterados/40inalterados, backup em.local. Semnova pesquisa, importação/restore repetidos, contratação/pago, contatoexterno, push ou deploy.

## 22/10/2026 — V1-019 iniciada sem depender do autor/Google

Autor pediu avanço independente até retornar ao notebook. Git inicial limpo em5254ac9/ahead3; nenhuma publicação autorizada. Dependências004/010da019concluídas, enquanto016continua sem conteúdo liberado e031exige decisão comercial. Escolhido incremento técnico alimentar semlogin/infra/compra.

Implementados tools/alimentos_lote.py e preparar_alimentos_v1.py: hashes dos snapshots/planilhas/recibos, cobertura completa22famílias, identidade fonte+versão+código+nome, linhas/tabelas/células, decimais e estados exatos, denominadoresFA porcoluna inclusiveProximates, fatores separados, basealcoólica desconhecida preservada e colisõesquarentenadas. Temporários exclusivos e checagem criptográfica de cabeçalhos/staging; sem rede/banco.

Lote completo existente:3484identidadesCiqual/261300células e2887identidadesCoFID/808360células (41015linhas,1069660células no total). Não são6371alimentos semanticamente únicos. Ciqual:3484fatoresJones; CoFID:14435célulasdefatores,1código/2identidadesconflitantes e15marcadoresnãointerpretados preservados. Não foi refeito parserExcel nem pesquisa/coleta. Todos os candidatos continuam runtimeImportApproved=false/calculationsApproved=false;0alimentosimportados.

13testesnovos passaram, incluindo adulteração, bases/fatores/ausência/zero/limites, código e linha conflitantes, cobertura/paths, flags de autopromoção e reprodução em clone movido. Primeira regressão revelou traduçãoCRLF no hash do manifestoWindows; publicação passou a escreverLF explícito. Dados originais mantidos. Reciboagregado food-preflight-verification.json e alimentacao-preflight.md; dados/cabeçalhos completos somente emcontent/local ignorado.

V1-019doing/completionEvidencevazio; próximo trabalho autônomo: direitos/operação, base/grupoCoFID, identidade/métodos e importadorGo idempotente após manifesto específico aprovado. API/Swagger/APK0.1.1+2 não alterados; serviços seguem parados. Handoff/backlog/mapas atualizados; grafoFlutter não reindexado porque lib não mudou. Sem push/deploy/contratação/contatoexterno.

Verificação final deste incremento:61testesPython passaram (13novos+48existentes); geração/backlog/dependências/links passaram e --check conferiu hashes sem refazer planilhas. Não repetidos buildAPK, Go/Flutter ou restore/import históricos, pois seus códigos e contratos não mudaram.

## 22/10/2026 — lote alimentar autorizado importado, com idempotência e restore

Continuação autônoma solicitada pelo autor até o limite, preservando a intervençãoGoogle. Conferência direcionada de duas fontes já escolhidas: metadadosCiqual locais SHA/MD5/arquivo666260não restrito e Etalab2oficial; páginaCoFID/OGLindexadoprimário e guia de bases/grupos. Aberturasindisponíveis/403não contornadas; semnova pesquisaampla ou coleta de dataset. Distinguido arquivo principalCoFID2887da contagem histórica limitada2760e do arquivo oldfoods separado.

Revisão porfonte/operação emfood-review-decisions.json; sourceURL/licença/atribuição/versão/data/alterações/semgarantia preservados, sem imagens/guias/livros/dadospessoais nem prescrição. Projeção revisada6369registros (3484+2885),2identidadesconflitantes excluídas e3gruposBTMsem baseinferida.6335bases100g/31bases100ml/3desconhecidas;768461célulasdenutrientes+300639auxiliares+560excluídas conciliam1069660células. Denominadoresconflitantes têm valor/declaracão retidos, escala bloqueada.

ImportadorGo comos.OpenRoot/limites/validaçãoexata das colunas, decimais, estados e direitos; CLI restrita aoDBisolado. Migration00005aditiva de idioma/versão/operações/trilhalotes/retirada. Oprimeiroensaio descartável detectou duplicação da FKjáexistente na00002; corrigidoantesdeaplicar00005noDBentregue. Testesisolados passaram paraidempotência/rollback/imutabilidade/runtime readonly e basefoiremovida.

DBreal isolado:6369inseridos, reimport0/6369. Sem alteração nosdadosanteriores nem usuáriofictício. Checkpointanterior preservado e backupnovoefetivamente restaurado em outrabase, com contagem/hashdetodasastabelasiguais; base de restore removida. Fontes/datasets/backup/artefatos completos ficam ignorados. V1-019donecomcompletionEvidence;020continua dependendo de013/019/008. API/Flutteralimentar não integrados, Swagger11/APK0.1.1+2mantidos; sem rebuildFlutter nem reindexaçãoGraphify porque lib não mudou.

Go test/vet e sete testesPythonnovos deprojeçãopassaram; documentação/backlog/mapas/handoff atualizados. SemGoogle real, push, deploy, contratação, integração paga ou contatoexterno.

Verificação final do lote:68testesPython passaram; Go test/vet passaram e fixturesPostgreSQL executadas (não apenas skip). Diretórios de dados originais e artefatos/backup permanecem ignorados. A escrita de alimentos reais ocorreu apenas noDBisolado explicitamente verificado.

## 22/10/2026 — consulta alimentar públicaGo/Flutter (preparação020/025)

Após d4ea56c (V1-019), implementadas três rotas públicas reais:foods/lista,filters,detalhe; Go0.3.0/14operaçõesSwagger. Leitura somente de versões editoriais revisadas com vínculo de importação, grants e sem retirada. Titular privado não entra em lista/facetas/detalhe. Última versão selecionada antes de autorizar, retirada antes deETag304; cursor ligado aos filtros e limite, busca literal com normalização de espaços. Migration00006 só índices aplicada no cluster próprio; não altera migrations anteriores.

Flutterfeaturefood_reference: repository/controller injetáveis, entrada anônima/conta, busca com400ms, fonte, cursor, estadosvazios/erros/retry, detalhecomposição/créditos/base por célula, revalidação ao retornar. Decimais/zero/ausência/traço/N/limite preservados. Sem prescrição, cálculo de porção, cadastro/consumo/totais. Dados e nomes não traduzidos/inventados; quebras de linha só da apresentação normalizadas, raw permanece noDB/API.

Verificações: Go test/vet, PostgreSQL temporário descartado (titularidade/grants/retirada/latest/cursor/busca literal e multilinha),32testesFlutter/analyze0issues. HTTPreal percorreu128páginas/6369IDs sem repetição,3484Ciqual/2885CoFID/3bases desconhecidas; nutrientes/estados/bases comparados aoDB e ETag verificado,me401,0contas/refeições criadas. Nenhuma nova coleta/instalação/compra ou restauração de backup repetida. Backup validado na importação cobre00005; após restore aplicar00006.

Correções observadas: fixture nova usou inicialmente coluna legada de identidade; alinhada ao schema real e teste repetido com sucesso. Primeiro verificador de busca tentou nome integral/multilinha e caminhoauth/me; corrigido ao limite/rota reais, incluindo correção de buscaGo para espaços da planilha. Teste de logout precisava aguardar frame após ensureVisible quando o botão alimentar aumentou a página; mantido toque real. Inspeção do emulador revelou cabeçalhos de planilha com quebras de linha; apresentação ajustada sem alterar o original. AvisoGooglePlayServices keeps stopping observado/dispensado comVoltar, sem limpar cache/contas/configuração; recuperação de login não foi comprovada.

APKdebug0.1.2+3, certificado debug existente; instalação-r preserva dados e hashdoAPKinstalado confrontado com o arquivo/fontes/configuração. Somente telaspúblicas inspecionadas,0contas antes da captura; nenhuma senha/2FA/consentimento automatizados. Graphifycode-only55arquivos/705nós/901arestas,HTMLexportado e backups ignorados; sem extraçãosemântica. Guias,mapas,Swagger,backlog/handoff atualizados.020/025 continuamtodo e completionEvidence vazio porque cadastro/consumo/dependências pendem.011Google/OAuthrelease ainda aguardam autor; iOS/releaseHTTPS sem validação. Commitlocal apenas, sempush/deploy/contatoexterno.

Fechamento operacional: revisão também rejeita querystrings malformadas em vez de ignorar campos; Swagger declara ambas as partes da base como nullable.68testesPython/documentação passaram. Remoto main reconferido em90e746e sempush. API/emulador parados pelo helper e cluster15432 parado separadamente, pois havia sido iniciado pelo verificador alimentar; nenhum dado/credencial/chave apagado. APKfinalSHA256f15592f29e8e390eeffdd7090f5c8553e2409084fa11724aa9d07c6f9b1a1011.

## 23/10/2026 — publicação autorizada e início013

Autor autorizou expressamente commit/push dos incrementos validados antes da próxima implementação. Graphify atualizado/conferido com instalação existente:0alterações/55inalterados; saídas já correspondem ao código,705nós/901arestas. Sem extração semântica ou rebuild artificial. Git inicialmente limpo,6commits locais à frente. Publicação não inclui.local,dadosbaixados,credenciais/chaves/APKs. Próxima unidade V1-013 antes de iniciar outra história; Google real continua gate deaceite, nenhuma alegação de milhões simultâneos validada.

## 23/10/2026 — V1-013 implementada e APK de privacidade

Incremento Go0.4.0/18 operações e Flutter0.1.3+4. Autorização deriva a conta da sessão validada; exportação própria por oito seções, cursor vinculado ao titular/seção/limite, páginas até50 linhas/1MiB de itens e projeções explícitas sem credenciais. Revisão final acrescentou metadados de versão/origem/idioma/permissão antes omitidos e teste correspondente. Copiar no Flutter preserva o JSON original para evitar arredondamento de decimais; processamento grande fora da UI e prévia limitada.

Exclusão exige sessão TrainForge criada há até15min (não equivale a nova senha/MFA Google), intenção temporária de5min pelo relógio PostgreSQL e frase exata. Transação bloqueia titular/famílias, revalida acesso e nonce, apaga dados próprios/sessões e mantém registro mínimo UUID/data para restore. Função restrita apaga apenas alimentos privados; runtime segue sem DELETE/UPDATE editorial amplo. Inventário de tabelas/colunas/FKs privadas falha diante de ampliação não revisada. Controller/secure storage evitam resposta antiga apagar outra conta; falha local depois do commit informa exclusão confirmada e permite concluir limpeza sem repetir DELETE.

Limites reais por instância:1024 conexõesTCP,128 requisições admitidas, mapa rate limit particionado/limitado, cabeçalhos/corpos/páginas/timeouts/pool limitados. Proxy confiável exige CIDRs explícitos; cabeçalhos encaminhados de outro peer são ignorados. Sem alegação de milhões simultâneos: carga, limites distribuídos e infraestrutura não foram implantados/validados.

Migration00007 aplicada ao cluster isolado. Testes PostgreSQL descartáveis passaram para duas contas, titularidade/cursor, corpo grande, família/expiração/reentrada, rollback tardio, concorrência refresh/delete, privilégios editoriais/registro e manutenção/replay. Backup anterior à exclusão foi restaurado em alvo separado e sanitizado com registro atual:1 conta reaparecida→0, outra conta/editorial preservados, reaplicação idempotente. Nova repetição foi motivada pela correção das projeções da exportação. Alvos e dump de fixture removidos; base entregue continua sem contas/atividades/refeições fictícias.

Comandos administrativos de manutenção/restore com prévia por padrão e alvo local estrito. Restore recusa base real/ausente/conectada e nunca promove; corte exige pausar exclusões na origem e registro atualizado. Backups históricos preservados; expiração manual explicitada, sem prometer limpeza automática. Só prévia de manutenção foi executada na base entregue.

Validações:48 testes Flutter e analyze0issues; Go test/vet;71 testes Python/documentação. Swagger dos comentários/DTOs conferido. CI ampliada para a suíte Python padrão, sem executar banco/ADB/fixtures locais no runner. HTTP real: política200/no-store, três operações privadas anônimas401,73 metadados/6369 alimentos preservados,0 contas criadas/excluídas. Política pública inspecionada no APK final; nenhuma tela de senha/2FA/consentimento capturada.

APK debug final instalado com -r, hash/assinatura/fontes/configuração confrontados: aee2e72f49e82984357d3def33559083998b70405def21a6117f0700d788a585. Graphify incremental code-only:59 arquivos,783 nós/1001 arestas;HTML exportado,backup ignorado preservado. Diagramas/mapas/Swagger/backlog/handoff atualizados. Recursos de avaliação parados ao final; dados/credenciais/chaves/APK preservados.

V1-003 concluiu o gate remoto: push autorizado em3170c50 e CI39952064880 bem-sucedida, derivados já atuais. V1-013 continua doing/completionEvidence vazio:011 login Google real,OAuth release/HTTPS e aceite privado pessoal pendentes. Nenhuma próxima história funcional iniciada. V1-020/025 permanecem todo com preparação anterior; Android+iOS e todos os públicos/ambientes preservados. Sem deploy, compra, integração paga, pesquisa ampla ou contato externo.

Publicação013 confirmada: commit4b922abd32db6c8f7ec806438d1969f49086e44d enviado aoorigin/main, SHA remoto idêntico. CI39963554285 concluída comsucesso, incluindo71testesPython,Go test/vet/build,Swagger e sintaxeMermaid. Revisão documental posterior alinhou os pontos de entrada, camadas/segurança e achado deproxy ao código real; nenhuma nova funcionalidade/história iniciada.

## 23/10/2026 — autor retornou; Google e sessão Android reais

Autor autenticou pessoalmente no emulador e mostrou Conta conectada. IdentidadeGoogle canônica única noDB e GETme200; não registrar nome/e-mail/subject/tokens. Reabertura e falha temporária apenas noADB reverse8082 preservaram sessão, mapping restaurado emfinally, retomada200. Access aguardado até expirar naturalmente, sem UPDATE de validade:401→refresh→retry200, consumo0→1 e mesma identidade. Logout real204, tela deentrada,0famílias/acessos ativos, conta preservada.

Oito seções privadas consultadas: Conta/Sessões próprias semcredenciais, demais vazias/200, sem clipboard ou exportação bruta retidos. Titular autorizou explicitamente excluir esta contaTrainForge deavaliação; ação ainda pendente de reentrada manual solicitada após logout. ContaGoogle fica intacta. Novo recibo auth-real-android-verification.json; não sobrescrever negativos/fixtures históricos. Sem alteração de código/APK/Graphify ou repetição dos testes anteriores; recursos permanecem ativos para o ciclo consentido.011/013 ainda não concluídas; nenhuma outraV1 iniciada.

Fechamento do ciclo consentido: autor reentrou na mesma conta,1usuário/2famílias (só a nova ativa), sem duplicação. ExclusãoTrainForge explicitamente autorizada executada pelo fluxo normal daUI após conferir identidade original: leitura dos limites, intenção200, frase exata e DELETE200. App confirmou Conta TrainForge excluída. Banco:0contas/famílias/access/refresh/intenções/dados privados e1registro mínimo do titular.73metadados/6369alimentos e hashes das linhas editoriais preservados. Concluir/reabrir voltou àentrada sem requisição auth, sem ler securestorage. ContaGoogle não alterada; backups históricos preservados conforme política. Novos recibos distinguem inspeção de build anterior, conta criada pelo login consentido e exclusão autorizada. Gates restantes011/OAuthrelease/HTTPS/iOS explícitos; sem outraV1 iniciada. Recursos ativos para o autor.

## 23/10/2026 — OAuthAndroidrelease confirmado

Autor criou ocliente TrainForge avaliação release noGoogleCloud e enviou captura dosdetalhes. TipoAndroid, pacotecom.example.trainforge eSHA1 24:EF:27:3C:82:50:DC:FE:15:8A:E6:45:42:BA:8D:D4:0F:02:17:6D conferidos com metadados públicos do certificado dedicado local. Cadastro registrado em oauth-release-verification.json; nenhuma chave gerada/alterada e nenhum clientWeb substituído. Data deuso exibida não foi tratada como loginAPKrelease validado.

Esclarecida a separação entre contaadministradoraCloud e contaGoogle do testador. Fluxo atual só autentica identidade básica; documentação oficial prevê exceção àlista deTestusers paraopenid/email/profile. Nenhum e-mail pessoal acrescentado aoGit. HTTPS deavaliação/testeAPKrelease seguem pendentes, sem autorização de deploy/provisionamento/contratação. Pergunta sobre hospedagem existente ou avaliação gratuita encaminhada ao autor.011/013 não concluídas indevidamente;034 só com preparação parcial. Sem mudança de código/Swagger/APK; Graphify/testes funcionais anteriores não repetidos.

## 23/10/2026 — correção do bloqueio dehospedagem e aceite local

Autor esclareceu que não quer hospedagem e questionou por que aavaliação local estava bloqueada. O agente havia antecipado indevidamente os gates dedistribuição. Nenhuma dúvida ou informação adicional doautor falta para oteste local. APIpronta/APKatual/emulador conectado foram conferidos; biblioteca aberta pelaUI e confirmados73movimentos/0programas.

Critérios011/012/013 confrontados com as evidências reais já concluídas e cadastroOAuthrelease conferido. Encerradas essas histórias no checkpoint local, sem alterar acceptance: políticaHTTPS fora de desenvolvimento permanece noFlutter/manifest/API/testes; provisionar staging e testar a distribuiçãoAPKrelease continuam nas histórias031–036. iOSnativo continua futuro. Fechamento granular em auth-local-fechamento.md, completionEvidence atualizado e próxima implementação020pelas dependências;015/016 não podem fingirprogramas/prática permitidos que continuam0. Hospedagem adiada porvontade explícita doautor, sem nova pesquisa/provisionamento/contratação/deploy. Sem código/build/instalação/Graphify ou testes funcionais repetidos; somente manutenção documental.


## 23/10/2026 — frontend pontos01–06

Autor priorizou os seis primeiros pontos antes dos07–12. APKdebug0.2.0+11 implementa ícone/nome/splashTFnativos, bootstrap compreferência antes desessão e restauração limitada, Hoje real comsemana/calendário pordata e estados, loaders compartilhados, transições/redução de movimento e temas claro/escuro/sistema persistidos noaparelho.43PNGs nativos determinísticos/proveniência, códigoiOS noengineimplícito preparado, semalegar buildXcode. Sem novasAPIs/migrations/fontes ou dados.

85testesFlutter/analyze0issues;5testesrecursosnativos;15préviasfixtureinspecionadas. Android: temas/persistência/sistema restaurado, cold/warm/rede/retentativa semnovoGoogle, cincoáreas/calendário reais, hashinstaladoconferido e1consumorealpreservado. Agente não digitou quantidade nem criouregistro. Uma execução dohelper depersistência foiinterrompida ao concorrer com outra leituraUI; rechecagem sequencial posterior passou, semreset ou alteração dosdados.

ConectorFigma continua emquotaStarter. Pergunta de direção visual daabertura/dark permanece semresposta; proposta usa marcaTFvigente, semconsiderar silêncio comoaceite ou alegar fidelidade exata decontextos nãoobtidos. Pontos02/06 comfechamento visualpendente; demaisfamílias/aceite integral seguemabertos. Docs/backlog/diagramas/Graphify atualizados, pushautorizado semdeploy. Ver frontend-fidelidade-figma.md efrontend-stage01-verification.json.


Autor respondeu à pergunta e confirmou: usar marcaTF atual naabertura e criar dark derivado daidentidade. A implementação jávalidada corresponde àescolha. Pontos01–06 encerrados no checkpointAndroid, conforme frontend-fidelidade-figma.md;07–12 e execuçãoiOS permanecem abertos. A decisão substitui a pendência visual registrada acima, sem alegar leitura decomparação exata dosquadros nãoobtidos.76testesPython passaram, docsderivadas verificadas.


## 24/10/2026 — Grafite e lima e rolagem

Autor escolheu terceira proposta e pediu que o iOS acompanhe a plataforma. Aplicados fundo#111211, cartões#242823 (separação reforçada) e lima#D8EB90, com texto adequado e cores deconteúdo neutras no dark.70–20–10 é orientação, sem medição depixels. MaterialApp usa comportamento central: Android semStretchingOverscrollIndicator; física/notificações/atualizar e iOS padrão mantidos. Sem GSAP/Motion ou outra dependência/API/migration.

90testesFlutter/analyze0issues, cinco novos cenários de borda/refresh/iOS/composição. Seis préviasFlutter dasáreas/perfil inspecionadas comfixtures isoladas;320/texto2x e contraste passam. APK0.2.1+12 instalado, fonte/assinatura/hash conferidos; navegação nascincoáreas e reabertura comprovamtema/sessão. Conferência porcontagens preservou1consumo real; agente não digitou quantidade nem confirmouconsumo. HelperUI teve leitura do perfil antes daestabilização; recibo final passou comespera limitada e navegação pública observada, semreset deapp.

Recursos/código iOS preservados e física validada porwidget, sem alegar execuçãoiOS27 noWindows. Figma permanece emquota; semnovas chamadas ou pesquisa. Docs/backlog/fluxos/Graphify atualizados (80Dart/1185nós/1578arestas, ASTsomente). Ver frontend-fidelidade-figma.md efrontend-dark-scroll-verification.json.


## 24/10/2026 — frontend pontos07–12 nos fluxos disponíveis

Lista original recuperada da própria conversa e registrada emfrontend-fidelidade-figma.md. APKdebug0.3.0+13: biblioteca/filtros/detalhe, composição/cadastro/histórico/subtotais/confirmação/correções, privacidade eajuda refinados com componentes/tokens já conferidos. Formulários preservam/confirmam descarte de rascunho, bloqueiam saída durante envio e explicam resposta incerta; rolagem ao primeiro erro. Busca particular independente evita refazer diário/subtotais e descarta respostas antigas. Atividade/configuração têm limites e caminhos úteis; não foram simulados serviços.

101testesFlutter/analyze0issues;20prévias de fixtures claras/escuras inspecionadas;320/texto2x e alvos48px/rotulados. A nova validação encontrou loader sem espaço no texto2x e falta de validação de nutriente fora da tela; corrigidos com altura natural/rolagem e campos montados. Helpers de captura/semântica precisaram encerrar recursos corretamente; recibos finais passaram, sem alteração de dados reais.

Android real: atualização sem rascunho aberto, hash/assinatura/fingerprint conferidos, biblioteca com0programas, histórico/alimentos próprios/política/ajuda alcançáveis.1consumo antes/1depois; sem quantidade/consumo/cadastro/exclusão peloagente nem novoGoogle automatizado. Graphify83Dart/1235nós/1665arestas, ASTsomente. Sem novaAPI/migration/dependência/pesquisa/deploy/contratação.

Não declarar todos07–12 concluídos: configuração persistida, treino/atividade, capacidades sem contrato/conteúdo, contextosFigma faltantes e iOS nativo seguem emgates explícitos. Backlog021/022/025 mantido semdone indevido.

## 24/10/2026 — auditoria do produto antes de contratar mídia

- Pedido vigente:entender banco, segurança, estrutura Go, campos/UX Flutter, idiomas, testes e escala antes de comprar API de GIFs. [Relatório factual](auditoria-produto-2026-10-24.md), [recibo](auditoria-produto-verificacao.json). GIF não é o único impedimento; treino completo/cuidador/foto não entregues.
- Leitura real de schema/privilégios/contagens:PostgreSQL17.5,23tabelas;1conta/1consumo real preservados. Sem exportar valores privados.
- Nova medição usando runtimes existentes:Flutter101testes/78,46% das linhas instrumentadas; Go71resultados aprovados/zero falhas/10testes de integração pulados,40,73% das instruções. Não repetir ensaios SQL históricos, login, importação ou restore para obter essa medição.
- CI inspecionada:documentação/Python/Mermaid/Go/Swagger; sem Flutter, banco descartável automático, Sonar ou scanners completos. Carga ainda planejada, não medida. Nenhum nível de segurança/capacidade certificado.
- Corrigidos textos vigentes que ainda chamavam escrita alimentar de planejamento e OAuthdebug/release de pendência anterior. Backlog recebeu workEvidence, sem novos done ou alteração silenciosa do recorte de fotoPosterior.
- Somente documentação/recibos alterados; código/APK, conta, consumo, dados importados, serviços e sessão preservados. Validação documental:13 testes pertinentes aprovados; geração/backlog/dependências/links locais e diff sem erro, conforme recibo.

## 24/10/2026 — expectativas, trilha por área e limpeza documental

- Autor pediu registrar seus questionamentos e expectativas antes de comprarGIFs, separar banco/backend/segurança/frontend/testes/escala e encerrar cada recorte por critérios. Exigência desde já:código seguro, separado por responsabilidade e preparado para crescer.
- [Trilha detalhada](trilha-implementacao.md):decisões, tarefas identificadas, evidências/gates, dependências, próximos blocos de perguntas e limites. Q1 será perguntada após commit/push; treino/cuidador/foto ainda sem decisões de escopo dependentes. Nenhum item funcional marcado como concluído.
- Consolidados frontend-etapa-01-06.md, frontend-dark-scroll.md e frontend-etapa-07-12.md na [fonte frontend única](frontend-fidelidade-figma.md); removidos os três arquivos após transferência e revisão do conteúdo útil, corrigidos links e preservados recibos/licenças. Textos completos permanecem noGit; duplicações/instruções superadas não foram mantidas como ordens atuais. Handoff e AGENTS simplificados e plano macro sem prioridades históricas conflitantes.
- Figma:somente whoami executado, planoStarter/assentoFull confirmados; erro anterior era cota de leitura. Documentação oficial24/10 indica20leituras/mês paraStarter e whoami isento; saldo/renovação não foram medidos. Nenhuma leitura de design limitada, escritaFigma, contratação ou contorno. Arquivo aberto não muda cota; alternativas na trilha.
- Incremento somente documental; nenhum app/API/migration/registro do titular alterado. Validações:13testes documentais aprovados; geração reproduzível/backlog/dependências/links locais e gitdiff--check sem erros. Commit/push concluídos são informados no fechamento da rodada.

## 24/10/2026 — respostasQ1 e correção do foco do cuidador

- Autor escolheu os dois caminhos de treino:programas compatíveis e composição com regras humanas revisadas. NovaV1-044(todo), sem treino/dose inventados ou ampliação automática da040.
- Correção explícita:cuidador pratica durante pausas do próprio trabalho. Vínculo/delegação de pessoa assistida não é foco ou bloqueio daV1;043 continua posterior. Atualizados trilha, escopo, matriz e nota corretiva da auditoria.
- V1-042 antecipada dePosterior paraV1 e delimitada a alimento por foto:candidatos editáveis, corrigir/remover/adicionar, quantidade poritem digitada, cálculo da base/versão e confirmação idempotente. OCR/barcode/imagem deatividade permanecem separados e posteriores. Gate035 passa a exigir042/044, sem ciclo por037. Nenhum novo done.
- Histórico visual/agradável e continuidade entre aparelhos registrados como expectativa. Dados de consumo já noPostgreSQL; recuperar também fotos exige políticaQ2. Sugestão de cópia privada persistente+cache local é proposta, sem contratação/hospedagem.
- Ideias de variedade/fibra/ferro registradas como pendência de recorte/regras humanas, não diagnóstico de deficiência. Consulta delimitada aOMS/NCI/NIH sobre variedade/contexto e limites de diário alimentar; sem pesquisa de fornecedor, modelo ou envio de imagem.
- Rodada documental:sem código/API/migration, instalaçãoAPK, operação de consumo ou repetição de login/import/restore. Próxima conversaQ2. Validação documental:13testes aprovados, geração/backlog/dependências/links locais e diff sem erros. Commit/push informados no fechamento.

## 25/10/2026 — pesquisa de fotos e decisões Q2

- Pedido específico de comparação antes de escolher recuperação das fotos: [quatro produtos](pesquisa-fotos-historico.md), usando ajuda/políticas primárias. AteMate e GreaseFit documentam persistência pela conta; Cronometer separa scanner e nota com foto; recuperação da imagem de toda refeição escaneada não foi confirmada para Cronometer/MyFitnessPal. Sem instalação, conta, ensaio runtime ou seleção de API/provedor.
- Q2 confirmou agrupar por refeição e também visualizar por alimento. Clarificação explícita confirmou histórico visual, análise nutricional e dicas revisadas juntos na primeira versão. Fontes/regras/revisão/cobertura precisam ser elaboradas; não inferir deficiência, nutrientes zero ou meta clínica.
- Criadas V1-045/046 como todo;042 depende do agrupamento045 e aceite035 exige o conjunto. Nenhum status concluído alterado. Persistência privada das fotos pela conta+cache é recomendação, ainda não aprovação; política de imagens segue pendente e hospedagem continua adiada.
- Atualizadas decisões, trilha, backlog, escopo, matriz, frontend, índice e handoff. Próximo bloco após fechar fotos éQ3. Rodada documental, sem código/API/migration/APK, novo consumo ou repetição de Google/import/restore.
- Validação documental: geração reproduzível, backlog/dependências/requisitos/links locais conferidos; 13 testes de documentação passaram. Diff revisado antes do commit/push. Esses resultados não equivalem a validação funcional no aplicativo.
- Commit d2704a6 publicado em origin/main. Em seguida, autor aprovou recuperar fotos pela conta com cache no celular; Q2 respondido. Fontes atuais e critérios042 atualizados, sem escolher serviço ou liberar envio de fotos; próximos assuntos são configuração/ajustes/agenda/retomada noQ3.

## 25/10/2026 — respostas Q3, configuração e retomada

- Autor escolheu configuração completa antes de procurar treino; trocar exercícios compatíveis e ajustar dias/horários; oferecer retomar ou encerrar como parcial. Respostas registradas em decisoes-piloto.md e incorporadas na trilha/escopo/frontend/matriz/handoff.
- Consulta Graphify existente direcionou a inspeção do onboarding legado. Código antigo exige medidas físicas e chama geração de plano; continua fora do caminho ativo. Sua existência não valida contrato Go nem torna seus campos obrigatórios. Matriz de categorias/finalidades registrada para detalhamento.
- NovaV1-047(todo) explicita configuração privada Go/SQL/Flutter, com revisão/versão/concorrência;015 depende dela,044 herda o requisito via015 e035 exige o aceite integrado.017/023 incorporam retomada/parcial sem conclusão automática. Nenhum statusdone alterado.
- Próximo blocoQ4:destino da foto ao excluir refeição e funcionamento offline. Sem mudança de código/API/migration/APK, dado privado, fonte de conteúdo ou serviço externo; Swagger e GraphifyAST preservados. Não repetidos login/import/restore ou testes deapp.
- Validação documental: geração reproduzível, dependências/requisitos/entradas/links conferidos;13testes documentais passaram e diff sem erros. Commit/push seguem a autorização existente. Esses testes não comprovam funcionamento do novo fluxo noAPK.
