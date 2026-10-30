# TrainForge — instruções para agentes

Estado vigente: **30/10/2026**. Repositório **C:/dev/TrainForge/trainforge**; o diretório pai não é este checkout. A solicitação atual prevalece sobre snapshots históricos.

## Primeiro contexto

Antes de alterar, ler este arquivo, docs/execucao/v1/handoff.md, backlog.json, plano-macro.md e etapa-02-fechamento.md. Para requisitos, ler trilha-implementacao.md e a história/dependências. Para operar/aprender, docs/aprendizado/README.md e docs/diagramas/README.md. Conferir Git e arquivos reais; não repetir instalação/pesquisa/teste/restore/login sem motivo novo.

## Último incremento

- Pedido atual: explicar ORM, avaliar MoveKit, limpar o repositório e ensinar operação/fluxos. [Recibo](docs/execucao/v1/repository-cleanup-verification.json).
- Removidos31Dart inalcançáveis a partir de main.dart e todos os testes, mais63arquivos dos scaffoldsLinux/macOS/Windows/web. Android/iOS preservados; runtime ativo não ganhou dados fictícios. Não reintroduzir os endpoints legados removidos.
- APKdebug **0.4.6+28 instalado**, hash/assinatura conferidos, sessão existente restaurada; emulador emHoje. Reobservar antes de agir; não atualizar com formulário/envio incerto aberto por inferência.
-258testesFlutter/analyze0; quatro testes do helper e dois dos diagramas;14documentais.15mapasdraw.io/SVG validados pela skill e prévias locais conferidas. Graphify90Dart/4032nós/4628arestas,31removidos/90inalterados,zeroLLM. Backup exato em.local/graphify-backup-20261029-learning.
- Operação diária: tools/ambiente.py status/start/plan-stop/stop/start-catalog. Somente status/plan-stop executados para o novohelper; start/stop têm testes com mocks. Não chamar activate/init/restore para iniciar o ambiente já provisionado.
- Skill draw-io-diagram-generator em.local/skills, fixada na revisão5269f7ea2d6c3a9bfda5ed878b6726cf509121fd do repositório oficialgithub/awesome-copilot. Ler SKILL.md antes de novosdraw.io. Fontes públicas: docs/diagramas/mapas.json e schema-publico.json; gerar/verificar com tools/gerar_diagramas.py.
- MoveKit: pesquisa delimitada concluída; interesse do autor no pacoteR$779 NÃO é compra autorizada. MP4/metadata anunciados, licença perpétua e12meses de novidades; cache/offline/entrega e cobertura requerem conferência. [Avaliação](docs/conteudo/avaliacao-movekit-2026-10-29.md). Sem compra, contato ou integração.

## Estado funcional e próxima história

- API Go0.9.1/34operações; catálogo0.2.0, núcleo schema13/30tabelas, catálogo schema2/4tabelas. Go usa pgx/SQL eGoose, semORM. Prisma é referência antiga; não criar dois escritores/migradores nem adicionarNode para isso sem decisão.
- M0–M4 da primeira extração do catálogo concluídas localmente. Bancos/roles próprios, retirada/autoridade/rollback/falha/recuperação conferidos. API8082, catálogo18083, PostgreSQL15432 e emulador ativos; leitura emmodo remote. [Recibo](docs/execucao/v1/catalog-rollout-verification.json). Demais domínios não foram todos extraídos.
- **Próxima funcionalV1-015**: adesão/seleção depende de conteúdo humano aprovado.73metadados de consulta,439ativos excluídos, zero programas/instruções/doses/mídias liberados. Não inventar treino para fechar aceite. Continuar trabalho independente028/029/qualidade pelas dependências.
- V1-011/012/013 encerradas no recorte local real: loginGoogleAndroiddebug, sessão e privacidade. OAuthdebug/release conferidos. Não repetir consentimentoGoogle por hábito; fixtures não validam login real. HTTPS/distribuiçãorelease/iOS têm gates próprios.
- V1-047 encerrada funcionalmente: criação humana, edição autorizada para14:00 e recuperação da revisão2; sem terceira versão. Clareza fuso/hora segue refinamento; não reescrever rotina por inferência.
- V1-045doing: SQL/HTTP/cliente de refeições e edição de metadados integrados. Autor confirmou refeição20g como teste de navegação; preservar, não chamar consumo real nem excluir sem ação específica. Consumo real anterior e conta preservados.
- V1-048 entregue no recorte de capacidade;0/6369nomes editoriais reais publicados. UI atual tem apresentação73movimentos/31variantes alimentares nos quatro idiomas, ligada aID/versão/original, sem claim de revisão profissional. Demais alimentos usam original. Público:Perfil/Privacidade > Fontes e transparência conserva autoria/licença/cálculo; jornadas comuns limpas. Aviso de prática indisponível não é metadado dispensável.
- V1-028doing: resetOnErrorfalse, logsDio seguros, sessão não apagada por falha de rede, inventárioAndroid e gatesCI verificados; não é auditoria integral. Perda permanente de chave, dependências completas, release, offline/fotos/master/Sonar/carga continuam abertos. [Recibo](docs/execucao/v1/secure-storage-recovery-verification.json).

## Produto e limites

Dois caminhos de treino: programas compatíveis e composição com regras humanas revisadas. Configuração completa em etapas curtas/revisão antes de buscar; trocas compatíveis e agenda; retomar ou encerrar parcial. Cuidador pratica para si nas pausas. Preservar idosos, cuidadores, casa, praça/parque e academia; Android/iOS.

Foto propõe alimentos editáveis, pessoa informa quantidade e confirma. Refeição/alimento são visões dos mesmos registros. Histórico visual/análise/dicas revisadas juntos naV1. Fotos recuperáveis pela conta/cache; excluir refeição exclui foto. Offline requer fila durável privada, conflitos/idempotência e exclusão sem recriar dados. Master requer identidade/permissão revogável/auditoria; não inferir por e-mail, GitHub ouclaimdoapp.

Sem treino, dose, instrução, mídia, nutriente, tradução editorial ou histórico inventados. Fixtures só em testes descartáveis. Nenhum dado de exemploFigma vira dado real. Sem compra, conta comercial, assinatura, integração paga, hospedagem/deploy ou contato externo por inferência. Pesquisa ampla anterior consolidada; o pedidoMoveKit autorizou apenas pesquisa delimitada.

## Operação e verificação

- .local contém bancos, credenciais, assinatura, backups e capturas; nunca apagar/vazar/versionar. .tools e caches existentes preservados. Não parar processos globais nem mudar virtualização.
- SDKGo sem credenciais: tools.dev_api.environment(include_api_env=False). Defaultenvironment lê api.env; só fluxos que precisam disso.
- Não rodar analyze/gen-l10n/test em paralelo a avaliar_android.py prepare; fingerprint deve permanecer estável.
- Validação documental: python tools/gerar_documentacao.py --write --check e unittesttest_documentacao.py. Diagramas: python tools/gerar_diagramas.py --check. Swagger deriva de comentários/DTOs; regenerar só quando contrato muda.
- Graphify: consultar vizinhança primeiro; AST incremental lib/, code-only/no-cluster e HTML, sem reprocessar todos os dossiês/LLM. Go/SQL ficam nos mapas/Swagger.
- Figma: arquivo bX6YjBBLIJgoo2MtiFLntl;TF/Inter, darkGrafite/lima e rolagemAndroid sem esticar aprovados. Quatro contextos responderam em29/10; limiteStarter anterior não é bloqueio vigente comprovado. iOS não validado nativamente noWindows.

## Documentação e Git

Atualizar backlogJSON, contratos/mapas afetados e handoff conforme implementação. done exige completionEvidence; não encerrar história por preview ou regra planejada. Recibos/licenças/evidências referenciados foram preservados; histórico emGit não é instrução vigente.

Git por comando: git -c safe.directory=C:/dev/TrainForge/trainforge ...; não mudar confiança global. Commits e push de incrementos validados autorizados. Limpeza histórica anterior especificamente autorizada já foi aplicada e verificada: não repetir force-push. Outros clones precisam reconciliar o histórico; caches/cópias externas não certificados como apagados. Achado desconhecido de segredo bloqueia; não imprimir valor ou criar exceção ampla.

Validação complementar deste incremento: suíte completaPython doCI com127testes aprovada; inclui os helpers e a reprodutibilidade dos15diagramas. Não é teste real de parada/start nem validação de compra/licença do pacote adquirido.
