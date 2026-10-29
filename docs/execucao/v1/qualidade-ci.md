# Qualidade automatizada — estado em29/10/2026

## O que já executou

O workflow documentacao.yml executa ferramentas documentais, diagramas Mermaid, testes/vet/build Go e deriva do Swagger. O [run40689113482](https://github.com/richardcastrogois/TrainForge/actions/runs/40689113482) concluiu com sucesso para297725f. As integrações SQL que exigem variáveis próprias são puladas na suíte comum Go; essa aprovação não comprova execução SQL em CI.

No Windows, o complemento de refeições passou248 testes Flutter completos antes do ajuste de descoberta e37 dirigidos depois, com análise sem issues. A execução local não é evidência de execução no runner Linux.

## Job Flutter acrescentado

[Workflow](../../../.github/workflows/flutter.yml) separado, com Ubuntu24.04 e o mesmo Flutter3.41.4 do checkpoint local. A tag oficial foi conferida contra a revisão ff37bef603469fb030f2b72995ab929ccfc227f0. O job baixa essa tag, confere a revisão imutável e mantém credenciais fora do checkout.

Etapas: resolver pubspec.lock com enforce-lockfile, gerar localização e recusar deriva, analisar, executar a suíte inteira de widgets/unidade e produzir lcov.info por sete dias. Fixtures são locais ao runner. Sem chamada de login Google, acesso ao banco de avaliação, assinatura Android ou deploy. Permissão contents:read; nenhum secret é fornecido e não há pull_request_target. Não exige instalar SDKs novamente no notebook.

A primeira execução remota foi conferida: [Flutter40690557153](https://github.com/richardcastrogois/TrainForge/actions/runs/40690557153), commit02e596b, concluiu com sucesso. SDK, lockfile, deriva l10n, análise, testes/cobertura e publicação do artefato foram aprovados no job122823943251. [Go/docs40690557360](https://github.com/richardcastrogois/TrainForge/actions/runs/40690557360) também passou para o mesmo commit. [Recibo](ci-flutter-verification.json). Isso não comprova as integrações SQL puladas na suíte comum Go.

## O que ainda falta

- Ampliar CI SQL às demais suítes e dump/restore; migrations/refeições/privacidade já executaram em serviço descartável.
- Imagem sem root, artefatos identificados por commit/digest e distribuição segura; assinatura e deploy continuam fora de PRs sem confiança.
- Auditoria028 completa, Sonar/quality gate, observabilidade029 e baseline de carga030. Nenhuma conclusão sobre milhões de usuários é sustentada por esta automação.
- Aceite humano/nativo das jornadas, offline026, foto042 e release continuam com seus critérios. Não concluir032 por automatizar apenas Go/documentação/Flutter.


## CI SQL executado —29/10

[WorkflowSQL](../../../.github/workflows/sql.yml) usa serviço PostgreSQL17.5 por digest oficial, roles migrator/runtime separadas e base aleatória descartável. [Runner](../../../tools/sql_ci.py) exige GitHub-hosted Linux, checkout correto, ausência de configuração/estado de avaliação e cluster novo; não tem modo local. Aplica migrations duas vezes e executa SQL/HTTP de refeições e o ciclo SQL de exportação/exclusão/rollback de privacidade. Os grants são a mesma fonte do helper local, sem ampliar privilégios.3barreiras locais e equivalência de4variantes passaram. [Run40811811519](https://github.com/richardcastrogois/TrainForge/actions/runs/40811811519) aprovado em689f64b:13migrations/segundo passe0,3testesSQL/HTTP de refeições e1de privacidade, limpeza confirmada; job123243625797 teve logs conferidos. [Recibo](ci-sql-verification.json).

Novo incremento0.8.1 acrescenta teste SQL de readiness, aprovado no runner40813092631, com quatro negativos e recuperação; Go comum/vet/Swagger passaram sem iniciar API/banco locais. Não inclui todas as suítes SQL nem dump/restore noCI; PostgreSQL17.5 é paridade de fixture, não recomendação de produção ou conclusão da auditoria de dependências. Nenhum secret da conta, assinatura Android ou dados de negócio entra no runner. A credencial literal do serviço é descartável; senhas dos dois papéis são geradas e mascaradas durante o job.


## Auditoria Go028 em preparação —29/10

[Workflow de vulnerabilidades](../../../.github/workflows/security-go.yml) instala somente no runner o scanner oficial golang.org/x/vuln/cmd/govulncheck@v1.9.0, versão/hash publicados conferidos no proxy oficial. Scanner tem módulo compilado verificado. Inventário de módulos e análise de chamadas são executados paraGOOSLinux eWindows com dependências somente leitura. Pipeline preserva o código de erro do scanner e publica evidência porcommit/alvo durante sete dias, inclusive emfalha. [Recibo](go-vulnerability-verification.json).

[Run40813941007](https://github.com/richardcastrogois/TrainForge/actions/runs/40813941007), commit8331426, aprovado emLinux/Windows:0vulnerabilidades conhecidas alcançáveis detectadas, logs e módulo do scanner conferidos. Conforme o [projetoGo](https://go.dev/doc/security/vuln/), govulncheck relaciona advisories conhecidos às chamadas do código; aprovação não elimina falhas desconhecidas ou de autorização. Não cobre Flutter/Android, histórico de segredos, imagem/infraestrutura, cache offline ou administração master.028continua aberta.


## Segredos Git028 executado —29/10

Gitleaks8.30.1 por checksum, histórico completo e sem instalação no notebook. [Run40815286943](https://github.com/richardcastrogois/TrainForge/actions/runs/40815286943) falhou com87candidatos; fixture de redaction passou. Artefato contém somente regra/arquivo/linha/commit; saída bruta nunca é publicada. Revisão identificou79falsos positivos,2ocorrências de URL externa assinada já expirada e6ocorrências externas com token cuja validade não foi comprovada. Nenhuma credencial do projeto foi identificada nesses87; isso não comprova ausência geral de segredos. [Recibo](git-secret-verification.json).

As evidências atuais tiveram7campos de URL sanitizados em6arquivos, preservando localizador e documentos/hashes. A query removida não é mais uma URL de resposta assinada reproduzível; o status antigo continua sendo observação histórica. [Comparação semântica](research-url-sanitization.json). O histórico antigo permanece e o gate continua pendente. Não houve replay, contato externo, rotação, reescrita Git ou exceção ampla para obter aprovação artificial.
