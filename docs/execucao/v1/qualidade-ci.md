# Qualidade automatizada — estado em29/10/2026

## O que já executou

O workflow documentacao.yml executa ferramentas documentais, diagramas Mermaid, testes/vet/build Go e deriva do Swagger. O [run40689113482](https://github.com/richardcastrogois/TrainForge/actions/runs/40689113482) concluiu com sucesso para297725f. As integrações SQL que exigem variáveis próprias são puladas na suíte comum Go; essa aprovação não comprova execução SQL em CI.

No Windows, o complemento de refeições passou248 testes Flutter completos antes do ajuste de descoberta e37 dirigidos depois, com análise sem issues. A execução local não é evidência de execução no runner Linux.

## Job Flutter acrescentado

[Workflow](../../../.github/workflows/flutter.yml) separado, com Ubuntu24.04 e o mesmo Flutter3.41.4 do checkpoint local. A tag oficial foi conferida contra a revisão ff37bef603469fb030f2b72995ab929ccfc227f0. O job baixa essa tag, confere a revisão imutável e mantém credenciais fora do checkout.

Etapas: resolver pubspec.lock com enforce-lockfile, gerar localização e recusar deriva, analisar, executar a suíte inteira de widgets/unidade e produzir lcov.info por sete dias. Fixtures são locais ao runner. Sem chamada de login Google, acesso ao banco de avaliação, assinatura Android ou deploy. Permissão contents:read; nenhum secret é fornecido e não há pull_request_target. Não exige instalar SDKs novamente no notebook.

A primeira execução remota foi conferida: [Flutter40690557153](https://github.com/richardcastrogois/TrainForge/actions/runs/40690557153), commit02e596b, concluiu com sucesso. SDK, lockfile, deriva l10n, análise, testes/cobertura e publicação do artefato foram aprovados no job122823943251. [Go/docs40690557360](https://github.com/richardcastrogois/TrainForge/actions/runs/40690557360) também passou para o mesmo commit. [Recibo](ci-flutter-verification.json). Isso não comprova as integrações SQL puladas na suíte comum Go.

## O que ainda falta

- Cobrir caminhos SQL ainda não ensaiados e completar os demais gates. Oito suítes/14testes principais e dump/restore com exclusões já passaram em serviço descartável; recibos abaixo.
- Completar artefatos/validação do APK e distribuição segura; a imagemAPI semroot identificada porcommit/digest já passou. Assinatura e deploy continuam fora dePRs semconfiança.
- Auditoria028 completa, Sonar/quality gate, observabilidade029 e baseline de carga030. Nenhuma conclusão sobre milhões de usuários é sustentada por esta automação.
- Aceite humano/nativo das jornadas, offline026, foto042 e release continuam com seus critérios. Não concluir032 por automatizar apenas Go/documentação/Flutter.


## CI SQL executado —29/10

[WorkflowSQL](../../../.github/workflows/sql.yml) usa serviço PostgreSQL17.5 por digest oficial, roles migrator/runtime separadas e base aleatória descartável. [Runner](../../../tools/sql_ci.py) exige GitHub-hosted Linux, checkout correto, ausência de configuração/estado de avaliação e cluster novo; não tem modo local. Aplica migrations duas vezes e executa SQL/HTTP de refeições e o ciclo SQL de exportação/exclusão/rollback de privacidade. Os grants são a mesma fonte do helper local, sem ampliar privilégios.3barreiras locais e equivalência de4variantes passaram. [Run40811811519](https://github.com/richardcastrogois/TrainForge/actions/runs/40811811519) aprovado em689f64b:13migrations/segundo passe0,3testesSQL/HTTP de refeições e1de privacidade, limpeza confirmada; job123243625797 teve logs conferidos. [Recibo](ci-sql-verification.json).

Novo incremento0.8.1 acrescenta teste SQL de readiness, aprovado no runner40813092631, com quatro negativos e recuperação; Go comum/vet/Swagger passaram sem iniciar API/banco locais. Não inclui todas as suítes SQL nem dump/restore noCI; PostgreSQL17.5 é paridade de fixture, não recomendação de produção ou conclusão da auditoria de dependências. Nenhum secret da conta, assinatura Android ou dados de negócio entra no runner. A credencial literal do serviço é descartável; senhas dos dois papéis são geradas e mascaradas durante o job.


## Auditoria Go028 em preparação —29/10

[Workflow de vulnerabilidades](../../../.github/workflows/security-go.yml) instala somente no runner o scanner oficial golang.org/x/vuln/cmd/govulncheck@v1.9.0, versão/hash publicados conferidos no proxy oficial. Scanner tem módulo compilado verificado. Inventário de módulos e análise de chamadas são executados paraGOOSLinux eWindows com dependências somente leitura. Pipeline preserva o código de erro do scanner e publica evidência porcommit/alvo durante sete dias, inclusive emfalha. [Recibo](go-vulnerability-verification.json).

[Run40813941007](https://github.com/richardcastrogois/TrainForge/actions/runs/40813941007), commit8331426, aprovado emLinux/Windows:0vulnerabilidades conhecidas alcançáveis detectadas, logs e módulo do scanner conferidos. Conforme o [projetoGo](https://go.dev/doc/security/vuln/), govulncheck relaciona advisories conhecidos às chamadas do código; aprovação não elimina falhas desconhecidas ou de autorização. Não cobre Flutter/Android, histórico de segredos, imagem/infraestrutura, cache offline ou administração master.028continua aberta.


## Primeira execução de segredos Git028 — histórico de29/10

Gitleaks8.30.1 por checksum, histórico completo e sem instalação no notebook. [Run40815286943](https://github.com/richardcastrogois/TrainForge/actions/runs/40815286943) falhou com87candidatos; fixture de redaction passou. Artefato contém somente regra/arquivo/linha/commit; saída bruta nunca é publicada. Revisão identificou79falsos positivos,2ocorrências de URL externa assinada já expirada e6ocorrências externas com token cuja validade não foi comprovada. Nenhuma credencial do projeto foi identificada nesses87; isso não comprova ausência geral de segredos. [Recibo](git-secret-verification.json).

As evidências atuais tiveram7campos de URL sanitizados em6arquivos, preservando localizador e documentos/hashes. A query removida não é mais uma URL de resposta assinada reproduzível; o status antigo continua sendo observação histórica. [Comparação semântica](research-url-sanitization.json). Naquele ponto o histórico antigo permanecia e o gate estava pendente. Não havia ocorrido replay, contato externo, rotação, reescrita Git ou exceção ampla; a aplicação autorizada posterior está no fechamento abaixo.

## Ampliação SQL por domínio aprovada —29/10

[Run40817964419](https://github.com/richardcastrogois/TrainForge/actions/runs/40817964419)/3169bea, job123263441423: oito suítes, 12 testes principais e 21 eventosPASS incluindo subtestes, sem skips aceitos. Schema13 em cada base; reexecução e limpeza passaram. Artefato sanitizado12873765255 e logs conferidos. Cada suíte usa base nova e ambienteTF isolado; o parser exige os testes esperados e recusa ausência, skip, falha ou resultado terminal duplicado. Só nomes e estados saem no relatório; em falha, apenas arquivo/linha, sem mensagem ou corpo. [Recibo](ci-sql-verification.json).

O primeiro ensaio40817472948 passou cinco suítes e falhou emconsumos por depender da referência copiada pelo wrapper local. O teste original foi preservado; o CI usa outro ponto de entrada, explicitamente sintético, que exercita os mesmos controles. Nenhum dado da avaliação foi copiado. Seis testes de barreiras/diagnóstico e a suíteGo comum passaram localmente antes da execução remota. Isso não valida consumo real ou Google real.

Go/docs e scannerGo também aprovaram3169bea; o gate de segredos continua pendente pelo histórico. Dump/restore, carga, imagem, Sonar e aceites humanos mantêm seus critérios próprios. O diagnósticoHTTP posterior tem [recibo separado](http-observability-verification.json), sem extrapolar o resultado desses commits.

O incremento HTTP0c0c531 passou Go/docs40818474388, SQL40818474391 (oito suítes, bases removidas) e scannerGo40818474380 emLinux/Windows (zero vulnerabilidades conhecidas alcançáveis detectadas). Jobs e logs conferidos; gate de histórico continua pendente.

## Imagem não root da API aprovada —29/10

[Run40819933235](https://github.com/richardcastrogois/TrainForge/actions/runs/40819933235)/83b799f, job123269780675, construiu e avaliou a imagem. BuilderGo1.27.3 por digest oficial; runtime scratch/65532 com binário, CA pública e tzdata embutido. Contexto do build por allowlist, sem dados/credenciais locais ou assinatura. Smoke confirmou filesystem somente leitura, capabilities removidas, sem elevação, rede interna sem porta publicada, produçãoHTTP426, modo de teste live200/ready503 sem banco, SIGTERM e limpeza. [Recibo](api-image-verification.json).

Artefato12874570734, cerca de10MB, contém arquivo da imagem e metadata por commit/versão/digest, retidos sete dias. Identidade e logs conferidos; não houve registry push, Docker local ou deploy. O ensaio inicial falhou por caminho de versão e o segundo por pressupor mapeamento de porta em rede interna; corrigidos e preservados no recibo. O acesso do host à bridge segue a [documentaçãoDocker](https://docs.docker.com/engine/network/port-publishing/), sem abrir porta nohost.

Não comprova TLS público, Google real, integração com banco, auditoria da imagem, multi-arquitetura, rebuild byte a byte ou capacidade de produção. LimitesCPU/RAM são do smoke, não recomendação de produção.032continua aberta, assim como028, Sonar/carga e aceites finais. O dump/restore emCI foi aprovado posteriormente, no recorte descrito abaixo.

## Prova isolada de catálogoM1 aprovada

[Run40860200717](https://github.com/richardcastrogois/TrainForge/actions/runs/40860200717)/ff8c8bb executou a prova em serviçoPostgreSQL próprio: bancos e papéis exclusivos, migration/reexecução, build doCLI e comparação do processo real com o handler anterior. Teste principal/cinco subtestes passaram, semskip. Credencial não escreve no catálogo nem conecta ao banco sentinela privado; retirada/ETag, versões, readiness com negativos, deadline/cancelamento eSIGTERM conferidos. Fixtures/papéis removidos. Somente metadados no artefato; [recibo](catalog-m1-verification.json). API/APK/avaliação preservados; não é conteúdo real ou migração editorial completa.

## Backup/restore com exclusões noCI aprovado

[Run40862745311](https://github.com/richardcastrogois/TrainForge/actions/runs/40862745311)/46fb1e2, job123409801747, passou com clientesPostgreSQL da própria imagem fixada e dump só emmemória. As30tabelas restauradas corresponderam ao estado anterior ao backup. O gateCLI removeu conta já excluída, configuração, alimentos/consumos e refeições; preservou outro titular, metadados públicos e fonte lógica após exclusão. Segunda aplicação idempotente. Runtime semCONNECT ao alvo; bancos/papéis removidos, nenhum dump emartefato. [Recibo](restore-ci-verification.json). Não restaura nem certifica o checkpoint real de avaliação ou backup de produção.

Dois testes SQL deprivacidade já existentes foram acrescentados à seleção do jobSQL: concorrência refresh/exclusão e manutenção de sessões expiradas sem quebrar revogação porreuso. [Run40863556767](https://github.com/richardcastrogois/TrainForge/actions/runs/40863556767)/d56cabf, job123412525297, aprovou8suítes/14testes principais/23PASS incluindo subtestes, semskip, schema13 e bases removidas. Os dois testes novos passaram individualmente noslogs. Artefato12892033753 conferido; [recibo](ci-sql-verification.json). Permissões/schema não mudaram.032/028continuam abertas.

## Correção dos falsos positivos e remediação histórica

Os90candidatos da execução40865025572 foram reconciliados contra os blobs dos commits originais. São82ocorrências não secretas:57hashes de arquivos,3identificadores públicos doFigma,1cursor de fixture,1nome de campo,1mapeamento editorial e19trechos de pesquisa. Os três adicionais foram comparados aos SHA256 reais dos arquivos. [Registro por contexto exato](git-secret-nonsecret-review.json).

O classificador conserva todos os achados no relatório e só retira da decisão de falha linhas cujo arquivo/regra/SHA256 do contexto inteiro correspondem à revisão. Hashes novos no inventário precisam coincidir com o conteúdo do arquivo no mesmo commit. Linha alterada, fonte ausente ou achado desconhecido bloqueiam. URLs com query não recebem exceção por esse registro, mesmo se uma entrada de revisão estiver errada. Testes cobrem essas recusas.

Antes da limpeza, oito ocorrências históricas de links com tokens continuavam bloqueadoras. Dois parâmetros curtos adicionais, não detectados pelo scanner, foram sanitizados em campos atuais; demais valores e hashes dos documentos preservados. A chave pública literalDEMO_KEY foi mantida. [Comparação semântica](research-url-sanitization-complement.json).

A primeira prévia sobre6d62673 revisou94commits/87IDs e passou com85não secretos e0bloqueadores. Após autorização expressa do autor e o incremento de isolamento do helper, a prova foi atualizada para o HEAD: **95commits/88IDs, sete blobs,11ocorrências em seis arquivos**. Comparação byte a byte preservou a árvore atual, autores, mensagens e datas. Bundle original mantido localmente com hash conferido; remoto da cópia de prévia desabilitado. A substituição da main foi aplicada com force-with-lease contra o HEAD exato; demais refs remotos comparados e preservados. Notebook alinhado, sem nova reescrita pendente. [Recibo final](git-history-remediation-preview.json).

O gate remoto [40888675534](https://github.com/richardcastrogois/TrainForge/actions/runs/40888675534), job123499303383, passou no commit6894858: **85candidatos não secretos verificados,0bloqueadores**, autorredação aprovada, sem valores brutos publicados. Artefato12903447721 contém somente metadados sanitizados. Os sete outros workflows do mesmo commit também passaram, incluindo [Go/documentação40888675485](https://github.com/richardcastrogois/TrainForge/actions/runs/40888675485), Flutter, SQL, restore, imagem, vulnerabilidades Go e catálogo.

O histórico anterior dos jobs continua registrando suas falhas; isso não significa falha na nova execução. Outros clones devem reconciliar ou clonar novamente antes de push. A prova não certifica remoção de caches/objetos inacessíveis do GitHub ou cópias externas nem validade dos tokens; nenhum replay, rotação ou contato externo foi feito.028/029/032 permanecem com seus critérios gerais abertos. Não repetir o force-push aplicado.
