# Qualidade automatizada — estado em28/10/2026

## O que já executou

O workflow documentacao.yml executa ferramentas documentais, diagramas Mermaid, testes/vet/build Go e deriva do Swagger. O [run40689113482](https://github.com/richardcastrogois/TrainForge/actions/runs/40689113482) concluiu com sucesso para297725f. As integrações SQL que exigem variáveis próprias são puladas na suíte comum Go; essa aprovação não comprova execução SQL em CI.

No Windows, o complemento de refeições passou248 testes Flutter completos antes do ajuste de descoberta e37 dirigidos depois, com análise sem issues. A execução local não é evidência de execução no runner Linux.

## Job Flutter acrescentado

[Workflow](../../../.github/workflows/flutter.yml) separado, com Ubuntu24.04 e o mesmo Flutter3.41.4 do checkpoint local. A tag oficial foi conferida contra a revisão ff37bef603469fb030f2b72995ab929ccfc227f0. O job baixa essa tag, confere a revisão imutável e mantém credenciais fora do checkout.

Etapas: resolver pubspec.lock com enforce-lockfile, gerar localização e recusar deriva, analisar, executar a suíte inteira de widgets/unidade e produzir lcov.info por sete dias. Fixtures são locais ao runner. Sem chamada de login Google, acesso ao banco de avaliação, assinatura Android ou deploy. Permissão contents:read; nenhum secret é fornecido e não há pull_request_target. Não exige instalar SDKs novamente no notebook.

A primeira execução remota foi conferida: [Flutter40690557153](https://github.com/richardcastrogois/TrainForge/actions/runs/40690557153), commit02e596b, concluiu com sucesso. SDK, lockfile, deriva l10n, análise, testes/cobertura e publicação do artefato foram aprovados no job122823943251. [Go/docs40690557360](https://github.com/richardcastrogois/TrainForge/actions/runs/40690557360) também passou para o mesmo commit. [Recibo](ci-flutter-verification.json). Isso não comprova as integrações SQL puladas na suíte comum Go.

## O que ainda falta

- CI de migrations e integrações SQL em PostgreSQL descartável, com roles/grants reais e rejeição de alvos de avaliação/produção.
- Imagem sem root, artefatos identificados por commit/digest e distribuição segura; assinatura e deploy continuam fora de PRs sem confiança.
- Auditoria028 completa, Sonar/quality gate, observabilidade029 e baseline de carga030. Nenhuma conclusão sobre milhões de usuários é sustentada por esta automação.
- Aceite humano/nativo das jornadas, offline026, foto042 e release continuam com seus critérios. Não concluir032 por automatizar apenas Go/documentação/Flutter.
