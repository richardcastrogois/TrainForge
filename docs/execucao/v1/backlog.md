# Backlog V1

> Gerado de `backlog.json` por `tools/painel_projeto.py --snapshot`. Edite o JSON.

Status: todo = não iniciado; done exige evidência. Não confundir planejamento com implementação.

## EP01 — Recorte verificável e governança

Transformar a pesquisa concluída em um lote candidato real e uma execução rastreável, sem presumir liberação dos materiais.

### V1-001 — Fixar o lote candidato e a jornada do primeiro teste

**todo · V1 · S**

Como responsável pelo produto, quero escolher conteúdo pesquisado e uma jornada pequena para ver o app com dados reais.

Dependências: nenhuma

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md

Critérios de aceite:

- Manifesto enumera IDs PR/N/componentes, versões e público para casa, praça, academia, idosos e cuidadores, mantendo os recortes distintos
- Esposa testa usabilidade; idade, elegibilidade e eventual apoio não são inferidos
- Cada material tem estado consulta/prática/bloqueado e motivo; zero conteúdo inventado

Tarefas e subtarefas:

- V1-001-T01 — Selecionar candidatos existentes
  - Ler consolidacao-n01-n46 e seleção N15 de 21/10
  - Listar autoria, dose, idioma, mídia disponível e lacunas sem nova coleta sem pista
- V1-001-T02 — Delimitar o piloto
  - Descrever login → biblioteca → detalhe → registro → histórico e alimentação
  - Separar teste de interface de prática e registrar campos realmente necessários

Validação: Revisão do manifesto contra evidências locais; Conferir que componentes isolados não aparecem como programa integral

Entregas: content/manifests/pilot-candidates.json (futuro); Critérios de elegibilidade e estados de conteúdo

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-002 — Aceitar a decisão Go e definir a fronteira de migração

**todo · V1 · S**

Como mantenedor, quero um serviço com responsabilidade clara para evitar duas APIs escrevendo nos mesmos domínios.

Dependências: V1-001

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md

Critérios de aceite:

- Registrar decisão de implementar Go ou manter Fastify com custos, compatibilidade e motivação
- Novo serviço proposto em services/api; legado preservado e um único escritor por domínio
- Nenhuma migration de produção é executada nesta história

Tarefas e subtarefas:

- V1-002-T01 — Fechar ADR
  - Comparar prazo do Fastify com migração Go e objetivo de aprendizagem
  - Escolher versão Go suportada e gerenciador de migrations na data da execução
- V1-002-T02 — Congelar fronteira
  - Inventariar rotas e invariantes úteis do legado
  - Definir banco de teste isolado, estratégia de importação e rollback

Validação: Revisão do inventário de contratos; Checar ausência de dual write e de dependência obrigatória de Gemini

Entregas: ADR final; Mapa de compatibilidade e fronteiras

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-003 — Manter mapa, backlog e evidências na rotina de entrega

**todo · V1 · S**

Como autor, quero acompanhar o projeto num lugar único e distinguir plano, código e runtime.

Dependências: nenhuma

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md

Critérios de aceite:

- Painel abre localmente, distingue detectado/planejado e mostra ausência do backend externo
- CI/local valida IDs, dependências, backlog gerado e contratos que passarem a ser oficiais
- Tarefa só é marcada done com evidência; mudança de código não inventa conclusão

Tarefas e subtarefas:

- V1-003-T01 — Formalizar atualização
  - Usar tools/painel_projeto.py --snapshot --check
  - Ligar a validação ao futuro pipeline sem exigir Graphify com IA
- V1-003-T02 — Acrescentar cobertura conforme a implementação
  - Ensinar scanner a ler rotas Go e contrato OpenAPI quando existirem
  - Registrar lacunas e validar mudança real no mapa com teste de regressão

Validação: Teste do watcher sem reiniciar a página; Teste de API ausente e dependência cíclica

Entregas: Painel e inventário mantidos; Job documental da CI

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

## EP02 — Conteúdo, autoria e direitos

Um catálogo importável com proveniência, versões e uso permitido por ativo; pesquisa fechada não vira publicação automaticamente.

### V1-004 — Criar contrato editorial dos quatro tipos de conteúdo

**todo · V1 · M**

Como curador, quero separar movimentos, instruções, mídia e programas completos para não atribuir ao conjunto direitos de uma única peça.

Dependências: V1-001

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/conteudo/README.md; docs/arquitetura/dominio-e-banco.md

Critérios de aceite:

- Source, autoria/contribuição, licença por ativo, evidência, versão, idioma, população, ambiente e apoio definidos
- Dosagem suporta tempo, repetições, distância, lado e pausas sem zeros fictícios
- Composição preserva origem de cada peça e não herda eficácia do programa original

Tarefas e subtarefas:

- V1-004-T01 — Especificar manifesto
  - Definir schemas versionados para movement/instruction/media/program
  - Representar ausência, incompatibilidade de variante e revisão pendente
- V1-004-T02 — Criar regras de publicação
  - Definir allowlist e motivos de bloqueio por operação
  - Distinguir referência externa, incorporação e redistribuição comercial

Validação: Validar manifesto com 11 componentes N15 e pacote ES2019 separados; Rejeitar componente sem proveniência ou unidade válida

Entregas: Schema JSON editorial; Matriz de direitos por ativo

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-005 — Revisar o lote real para o uso do piloto

**todo · V1 · L**

Como usuário, quero ver apenas o uso que o material realmente permite.

Dependências: V1-004

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/conteudo/README.md; docs/arquitetura/dominio-e-banco.md

Critérios de aceite:

- Cada item tem evidência de direitos e fidelidade do que será exibido, sem copiar PDF/foto indevidamente
- Revisão editorial e de segurança tem responsável real e resultado, ou item continua bloqueado
- Apoio profissional exigido só habilita execução se de fato existir; sem parceiro presumido

Tarefas e subtarefas:

- V1-005-T01 — Conferir o lote
  - Reutilizar fonte, autoria e recibo guardado; consultar rede só com pista nova
  - Verificar localização e material específico, não só licença do site
- V1-005-T02 — Classificar uso
  - Registrar consulta ou prática permitida e revisor
  - Retirar do manifesto de publicação itens sem cobertura; manter lacuna visível

Validação: Revisão linha a linha da allowlist; Tentar publicar item bloqueado e comprovar rejeição

Entregas: content/manifests/pilot-approved.json (futuro); Registro de revisão e pendências reais

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-006 — Importar conteúdo de forma idempotente e auditável

**todo · V1 · M**

Como operador, quero carregar o lote aprovado no PostgreSQL sem pesquisa em runtime nem duplicações.

Dependências: V1-005, V1-010

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/conteudo/README.md; docs/arquitetura/dominio-e-banco.md

Critérios de aceite:

- Dry run informa contagens/erros e não escreve; importação usa versão/hash e transação
- Reimportação não duplica, versão publicada permanece imutável e retirada deixa motivo
- Zero seed de usuários, progresso, plano IA ou instrução completada artificialmente

Tarefas e subtarefas:

- V1-006-T01 — Construir importador Go
  - Ler apenas manifesto revisado e arquivos autorizados
  - Validar referências, hash, versão, unidade e direitos antes da transação
- V1-006-T02 — Ensaiar atualização
  - Carregar lote real em DB isolado e comparar IDs/contagens
  - Reimportar, criar versão e retirar item preservando referências históricas

Validação: Integração PostgreSQL com manifesto real permitido; Dry run inválido não escreve e reimportação é estável

Entregas: cmd/import-content; Relatório de importação e rollback editorial

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

## EP03 — Fundação Go, contratos e banco

Uma API pequena com configurações, migrations e domínio próprios; preservar as boas invariantes do legado.

### V1-007 — Criar o esqueleto do monólito modular Go

**todo · V1 · M**

Como desenvolvedor, quero iniciar API e testes de forma previsível com módulos explícitos.

Dependências: V1-002

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/arquitetura-alvo.md; docs/arquitetura/contratos-v1.md; docs/arquitetura/dominio-e-banco.md

Critérios de aceite:

- services/api contém cmd/api e internal/{auth,catalog,activity,nutrition,platform}
- Configuração por ambiente validada sem segredo em logs; sem chave IA obrigatória
- Servidor tem timeout, limite de corpo, request ID, shutdown e health/readiness com semântica diferente

Tarefas e subtarefas:

- V1-007-T01 — Inicializar módulo
  - Usar net/http e escolher somente dependências justificadas (pgx e biblioteca de migrations)
  - Criar config tipada, roteador versionado e erros comuns
- V1-007-T02 — Operar localmente
  - Criar .env.example sem valores reais e comando único de desenvolvimento
  - Adicionar health live e ready dependente de banco com timeout

Validação: go test ./...; go vet ./... e processo inicia/finaliza sem conexão vazada

Entregas: services/api/go.mod; Servidor local e instruções reproduzíveis

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-008 — Publicar contrato OpenAPI v1 antes do cliente

**todo · V1 · M**

Como integrador, quero contratos verificáveis para Flutter e Go evoluírem sem adivinhação.

Dependências: V1-004, V1-007

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/arquitetura-alvo.md; docs/arquitetura/contratos-v1.md; docs/arquitetura/dominio-e-banco.md

Critérios de aceite:

- Rotas planejadas de contratos-v1.md tornam-se OpenAPI revisado com schemas, erros e autorização
- null é diferente de zero; cursor, datas UTC, fuso IANA e Idempotency-Key definidos
- Rotas legado não mudam silenciosamente; compatibilidade e descontinuação explícitas

Tarefas e subtarefas:

- V1-008-T01 — Definir contrato
  - Especificar requests, responses e exemplos somente identificados como contrato/teste
  - Fixar enum, paginação, validação e formato problem+json com requestId
- V1-008-T02 — Conectar geração
  - Escolher ferramenta de cliente Dart depois de teste mínimo
  - Conferir diffs do contrato gerado na CI

Validação: Lint de OpenAPI; Testes de contrato handler/DTO/cliente contra schemas

Entregas: contracts/openapi-v1.yaml; Política de compatibilidade

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-009 — Modelar conteúdo versionado, adesão e ocorrências

**todo · V1 · M**

Como usuário, quero repetir uma atividade em outra data sem perder histórico ou mudar a fonte original.

Dependências: V1-004, V1-007

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/arquitetura-alvo.md; docs/arquitetura/contratos-v1.md; docs/arquitetura/dominio-e-banco.md

Critérios de aceite:

- Programa/versão/sessão prescrita separados de enrollment/ocorrência/registro real
- Movimentos e instruções têm proveniência própria; cuidador praticante separado de pessoa assistida
- Sessão usa ocorrência e estado explícito; fonte alterada não reescreve histórico

Tarefas e subtarefas:

- V1-009-T01 — Desenhar modelo
  - Revisar entidades e relações de dominio-e-banco.md
  - Definir timezone, unidades, estados, exclusão e retenção
- V1-009-T02 — Definir invariantes
  - Unicidade de idempotência por usuário/operação e sessão aberta por ocorrência
  - Planejar índices por consulta; não restaurar índice de um refresh por usuário indiscriminadamente

Validação: Revisão ER/contratos com N15 e prática por tempo; Casos semana repetida, plano inativo e autoria preservada

Entregas: Modelo lógico revisado; Decisão de invariantes e consultas

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-010 — Criar migrations e testar backup/restauração

**todo · V1 · L**

Como operador, quero evoluir o banco sem perder pesquisa ou registros pessoais.

Dependências: V1-009

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/arquitetura-alvo.md; docs/arquitetura/contratos-v1.md; docs/arquitetura/dominio-e-banco.md

Critérios de aceite:

- Banco isolado sobe do zero por migrations Go; Prisma não migra o mesmo schema simultaneamente
- Backup restaurado em outra base é conferido por contagens e referências
- Banco real existente é inventariado com acesso autorizado; se não existe dado, registrar sem inventar migração

Tarefas e subtarefas:

- V1-010-T01 — Preparar base isolada
  - Escolher versão Postgres suportada na execução e porta sem conflito
  - Aplicar constraints, índices e usuário runtime de menor privilégio
- V1-010-T02 — Ensaiar restauração e evolução
  - Criar backup antes de mudança e restaurar em base separada
  - Testar migration forward e estratégia de recuperação sem down destrutivo automático

Validação: Migrations do zero e upgrade em DB de teste; Restore conferido; nunca docker compose down -v como rotina

Entregas: services/api/migrations; Runbook de backup/restore com resultado

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

## EP04 — Identidade, privacidade e acesso

Autenticação real, sessões revogáveis e isolamento de dados por usuário, inclusive sob concorrência.

### V1-011 — Autenticar Google no novo serviço

**todo · V1 · M**

Como testador, quero entrar com minha conta real e usar a mesma identidade nas duas plataformas.

Dependências: V1-008, V1-010

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/seguranca-operacao.md; docs/arquitetura/contratos-v1.md

Critérios de aceite:

- ID token validado por assinatura/iss/aud/exp e identidade vinculada a issuer+sub
- E-mail não é chave única de associação automática entre provedores
- Android debug/release têm OAuth correto; IDs públicos separados de segredos; HTTPS fora do desenvolvimento

Tarefas e subtarefas:

- V1-011-T01 — Implementar troca
  - Preservar validações úteis do legado e testar audience incorreta
  - Criar usuário apenas a partir de autenticação real consentida
- V1-011-T02 — Configurar ambientes
  - Documentar fingerprint do certificado debug/release e client ID de servidor
  - Preparar configuração iOS futura sem declarar teste feito

Validação: Integração com login real no Android; Testes de token inválido/expirado e identidade duplicada

Entregas: Auth Go e contrato de sessão; Guia OAuth por ambiente

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-012 — Rotacionar e revogar refresh tokens

**todo · V1 · L**

Como usuário, quero continuar conectado e encerrar acesso de forma confiável.

Dependências: V1-011

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/seguranca-operacao.md; docs/arquitetura/contratos-v1.md

Critérios de aceite:

- Refresh hash armazenado, rotação atômica single use e detecção de reuso por família
- Logout revoga sessão no servidor; outro dispositivo não é revogado sem intenção
- Flutter serializa refresh concorrente; rede indisponível não apaga sessão válida

Tarefas e subtarefas:

- V1-012-T01 — Implementar ciclo servidor
  - Definir família de sessão, expiração, revogação e transação concorrente
  - Testar dois refresh simultâneos e resposta sem token nos logs
- V1-012-T02 — Integrar cliente
  - Guardar tokens em secure storage; retry único após 401 e refresh coordenado
  - Separar 401 confirmado de timeout/offline e revogar no logout

Validação: Teste PostgreSQL concorrente; Login, expiração, refresh e logout reais em emulador

Entregas: Ciclo de sessão Go/Flutter; Política de reuso e dispositivos

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-013 — Aplicar autorização, limites e ciclo dos dados

**todo · V1 · L**

Como titular, quero que só eu acesse meus registros e que exclusão seja verificável.

Dependências: V1-011, V1-009

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/seguranca-operacao.md; docs/arquitetura/contratos-v1.md

Critérios de aceite:

- Todas as consultas/mutações privadas filtram ownership, inclusive IDs trocados
- Proxy confiável explicitamente configurado; rate limit não confia em X-Forwarded-For arbitrário
- Exportação/exclusão e retenção cobrem DB, fotos futuras, caches e backups com limites explicados

Tarefas e subtarefas:

- V1-013-T01 — Cobrir autorização
  - Criar matriz rota × usuário/terceiro/anônimo
  - Manter uso próprio e acompanhamento de terceiro como permissões distintas
- V1-013-T02 — Controlar dados e recursos
  - Definir limites de corpo/paginação/tempo e regras proxy
  - Implementar minimização, exportação e exclusão confirmada; registrar política de backups

Validação: Testes BOLA em todos os recursos privados; Teste de spoof de forwarded header, corpo grande e exclusão de conta de teste

Entregas: Matriz de acesso; Política de privacidade do piloto e operações de dados

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

## EP05 — Biblioteca humana e API de catálogo

Consumir conteúdo pesquisado com origem e disponibilidade reais, sem gerar programas de fallback.

### V1-014 — Servir catálogo, versão e requisitos de uso

**todo · V1 · M**

Como praticante, quero comparar opções reais por público, local e apoio.

Dependências: V1-006, V1-008

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/conteudo/README.md; docs/arquitetura/dominio-e-banco.md

Critérios de aceite:

- GET catalog/programs e detalhe retornam somente conteúdo permitido ao modo de consulta/prática
- Filtros representam ambiente, modalidade, público e equipamento reais; cursor estável
- Fonte, contribuição, versão, direitos, unidades e razões de bloqueio chegam ao Flutter

Tarefas e subtarefas:

- V1-014-T01 — Implementar leitura
  - Consultar tabelas versionadas com projeção explícita
  - Expor paginação e ETag por versão sem baixar vídeo nem consultar fornecedor a cada toque
- V1-014-T02 — Cobrir falta de conteúdo
  - Retornar indisponibilidade e alternativas pesquisadas sem completar texto/dose
  - Distinguir peça modular de programa completo no contrato

Validação: Contrato e DB com lote real; Filtro e item retirado não vazam conteúdo não autorizado

Entregas: Handlers e queries de catálogo; Respostas verificadas do lote

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-015 — Criar adesão sem geração de treino

**todo · V1 · M**

Como usuário, quero selecionar uma versão existente e uma agenda permitida pelo autor.

Dependências: V1-014, V1-013

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/conteudo/README.md; docs/arquitetura/dominio-e-banco.md

Critérios de aceite:

- Adesão aponta para versão imutável e valida os requisitos necessários
- Composição personalizada mantém autoria de componentes e perde rótulo de programa original se alterado
- Rotas IA/manual-generator não participam da V1 e Gemini deixa de ser requisito

Tarefas e subtarefas:

- V1-015-T01 — Implementar adesão
  - Validar versão publicada, consentimentos e apoio exigido
  - Aceitar apenas opções de agenda previstas pela fonte, sem inventar progressão
- V1-015-T02 — Tratar troca e arquivamento
  - Preservar adesão e sessões antigas ao escolher outra versão
  - Retornar motivo concreto de incompatibilidade sem prescrição automática

Validação: Selecionar lote real no banco e consultar adesão; Rejeitar variante, público ou modo incompatível

Entregas: API de enrollments; Fluxo de seleção humano

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-016 — Expor instrução acessível e mídia com direitos

**todo · V1 · M**

Como usuário, quero aprender o material disponível e saber quem o escreveu.

Dependências: V1-014

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/conteudo/README.md; docs/arquitetura/dominio-e-banco.md

Critérios de aceite:

- Texto fiel revisado, idioma, atribuição e versão aparecem juntos
- Mídia ausente fica indisponível; nenhuma foto/vídeo de placeholder ou extração BeFit
- Se existir mídia autorizada, entrega não expõe bucket nem exige download irrestrito

Tarefas e subtarefas:

- V1-016-T01 — Servir material permitido
  - Separar referência externa de ativo redistribuível
  - Expor autoria, legenda/transcrição quando autorizada e texto alternativo
- V1-016-T02 — Controlar retirada
  - Revogar entrega de ativo sem apagar proveniência de sessões passadas
  - Aplicar cache versionado e custo/quota de mídia se necessária

Validação: Inspeção visual e acessibilidade do material real; Link indisponível, versão retirada e ausência de vídeo sem fallback fictício

Entregas: Contrato de instruction/media; Lista de ativos efetivamente liberados

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

## EP06 — Atividade e alimentação registradas de verdade

Persistir ações reais, unidades corretas e histórico sem criar desempenho, dieta ou medição fictícios.

### V1-017 — Executar ocorrências idempotentes de atividade

**todo · V1 · L**

Como usuário, quero iniciar e terminar uma sessão uma vez, mesmo com reenvio da rede.

Dependências: V1-015, V1-012

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/contratos-v1.md; docs/arquitetura/fluxos.md

Critérios de aceite:

- Planejado, iniciado, pausado, parcial, concluído, não feito e descanso têm semântica explícita
- Idempotency-Key e constraints evitam duas sessões para a mesma ocorrência
- Conclusão de uma semana não bloqueia outra; duração observada separada da dose prescrita

Tarefas e subtarefas:

- V1-017-T01 — Implementar máquina de estados
  - Validar transições, timestamps UTC e data no fuso escolhido
  - Registrar exercício/tempo/repetições reais sem tratar prescrição como realizado
- V1-017-T02 — Testar concorrência
  - Repetir POST com mesma chave e payload diferente
  - Testar corrida, pausa, falha de rede e retomada

Validação: Integração PostgreSQL concorrente; Sessões reais em duas datas e estado parcial preservado

Entregas: API sessions e session-events; Invariantes documentadas e testes

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-018 — Consultar histórico e resumo com origem das métricas

**todo · V1 · M**

Como usuário, quero saber o que registrei, sem números de demonstração.

Dependências: V1-017

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/contratos-v1.md; docs/arquitetura/fluxos.md

Critérios de aceite:

- Home, histórico e estatísticas vêm de registros persistidos e respeitam fuso e autoria
- Sem dado mostra ausência, não valor medido zero; estimativas identificam fórmula/fonte
- Histórico não depende apenas do plano ativo e usa cursor/intervalo limitado

Tarefas e subtarefas:

- V1-018-T01 — Criar consultas
  - Definir resumo diário e tendência com datas/fusos
  - Projetar índices e paginação para não carregar todas as sessões
- V1-018-T02 — Garantir semântica
  - Separar estimado/medido/planejado e evitar dupla contagem
  - Testar atividade sem calorias e novo usuário sem histórico

Validação: Conferir resumo contra linhas reais do DB; Casos fronteira de dia, troca de plano e registro editado

Entregas: API summary/history; Dicionário de métricas

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-019 — Validar e importar o lote alimentar

**todo · V1 · L**

Como usuário, quero procurar alimentos pesquisados com preparo e unidades corretos.

Dependências: V1-004, V1-010

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/contratos-v1.md; docs/arquitetura/fluxos.md

Critérios de aceite:

- Selecionar lote real das fontes alimentares pesquisadas com direitos de uso e cobertura PT conferidos
- Alimento/preparo, base 100g/100ml, porção e nutrientes ausentes mantidos distintos
- Não gerar receita, alergênico seguro, dieta ou medida caseira sem origem

Tarefas e subtarefas:

- V1-019-T01 — Selecionar e revisar fonte
  - Conferir catálogos N de alimentação e termos por dataset
  - Escolher itens úteis ao piloto sem presumir que todos têm direitos iguais
- V1-019-T02 — Importar versão
  - Validar nutrientes/unidades e identificador de origem
  - Criar importador idempotente e relatório sem payload de terceiro no Git sem licença

Validação: Comparar amostra importada à fonte autorizada; Rejeitar mistura entre alimento cru/cozido e null=0

Entregas: Manifesto alimentar aprovado; Lote alimentar versionado no DB

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-020 — Pesquisar alimento e registrar consumo

**todo · V1 · L**

Como usuário, quero registrar uma quantidade real e consultar o que consumi.

Dependências: V1-019, V1-013, V1-008

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/contratos-v1.md; docs/arquitetura/fluxos.md

Critérios de aceite:

- Busca paginada de alimentos reais e POST de registro com quantidade, unidade, preparo e versão
- Nutrientes derivados usam base/fator declarado; quantidade não confirmada não vira medida
- Sem dietas prescritas, história pré-populada ou compensação automática de calorias do treino

Tarefas e subtarefas:

- V1-020-T01 — Criar contratos e handlers
  - Implementar foods e food-entries com ownership e idempotência
  - Definir edição/exclusão sem perder rastreio da origem do cálculo
- V1-020-T02 — Integrar totais
  - Somar apenas registros confirmados com regras de null
  - Testar divergência de porção e registro em outro fuso

Validação: Integração DB/API com alimento pesquisado; Conferir cálculo contra base conhecida e histórico vazio

Entregas: API nutrition v1; Registro de consumo real

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

## EP07 — Flutter e experiência da V1

Evoluir a lib existente por feature, com contratos reais, estado consistente e suporte às duas plataformas.

### V1-021 — Organizar configuração, composição e estado

**todo · V1 · L**

Como desenvolvedor, quero telas pequenas e dependências substituíveis sem reescrever a lib inteira.

Dependências: V1-008, V1-012

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/contratos-v1.md; docs/arquitetura/fluxos.md

Critérios de aceite:

- Feature-first preservado; UI usa controller/viewmodel e repository injetado
- Dio central com base URL por flavor/dart-define, timeouts e sessão coordenada
- Logging por allowlist remove tokens/dados físicos; domínio não importa widgets ou Dio

Tarefas e subtarefas:

- V1-021-T01 — Preparar núcleo
  - Separar config dev/staging e futura produção
  - Definir composition root simples e ViewModels com APIs Flutter existentes antes de nova lib
- V1-021-T02 — Migrar uma fatia
  - Converter auth/bootstrap e uma tela com loading/error/empty/data
  - Reutilizar bootstrap e preservar abas/rascunhos sem cache eterno

Validação: flutter analyze e testes de estados relevantes; Inspecionar logs de login real sem segredos e sem logout por timeout

Entregas: lib/core revisada; Padrão de feature exemplificado

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-022 — Implementar entrada e biblioteca com conteúdo real

**todo · V1 · L**

Como iniciante, quero escolher uma opção humana e entender por que ela está disponível.

Dependências: V1-014, V1-015, V1-021

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/contratos-v1.md; docs/arquitetura/fluxos.md

Critérios de aceite:

- Login → contexto mínimo → biblioteca → detalhe → adesão sem AI/manual generator
- Filtros casa/praça/academia e públicos preservam restrições; origem e versão legíveis
- Ausência, incompatibilidade, carregamento e erro usam dados reais e ação útil

Tarefas e subtarefas:

- V1-022-T01 — Desenhar a fatia com o material
  - Comparar Figma vigente com campos reais do contrato
  - Reutilizar componentes/tokens e justificar novos fluxos sem copiar BeFit
- V1-022-T02 — Implementar telas e navegação
  - Criar catálogo/detalhe/requisitos e vínculo real
  - Persistir seleção e tratar botão voltar, leitor de tela e texto ampliado

Validação: Teste widget de erro/vazio/seleção; Emulador com API/DB e manifesto real aprovado

Entregas: Telas library/detail/enrollment; Mapa de fluxo atualizado

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-023 — Implementar sessão e recuperação de interrupção

**todo · V1 · L**

Como praticante, quero acompanhar o material e registrar o que fiz sem perder a sessão ao trocar de aba.

Dependências: V1-016, V1-017, V1-022

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/contratos-v1.md; docs/arquitetura/fluxos.md

Critérios de aceite:

- Player/instrução usa modalidade/unidade real; prática bloqueada quando requisito não atendido
- Pausar/retomar/encerrar/parcial funcionam com estado persistido e idempotência
- Matar processo e reabrir recupera registro real; sem duração/reps fictícias

Tarefas e subtarefas:

- V1-023-T01 — Criar controller de sessão
  - Carregar prescrição e execução separadas
  - Persistir ocorrência e chave de reenvio, sincronizar confirmação servidor
- V1-023-T02 — Construir experiência
  - Mostrar instrução, fonte, dose disponível e entrada do realizado
  - Implementar pausa, saída segura e retomada sem simular vídeo

Validação: Integração Android com reinício e duplo toque; Repetir em data futura sem bloqueio da sessão passada

Entregas: Fluxo de sessão real; Evidência de recuperação

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-024 — Implementar Hoje, histórico e perfil

**todo · V1 · L**

Como usuário, quero enxergar meus próprios registros e gerenciar minha conta.

Dependências: V1-018, V1-021, V1-013

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/contratos-v1.md; docs/arquitetura/fluxos.md

Critérios de aceite:

- Abas mantêm estado e exibem resumo real sem nova busca redundante a cada toque
- Histórico lista versões/ocorrências antigas e ausência honesta; perfil permite campos opcionais
- Exportação, logout/revogação e exclusão têm confirmação e resultado verificável

Tarefas e subtarefas:

- V1-024-T01 — Migrar as abas existentes
  - Ligar ViewModels às APIs e paginação com cache limitado
  - Separar tendência calculada de medição e limpar cache ao trocar conta
- V1-024-T02 — Concluir perfil
  - Minimizar dados físicos e explicar finalidade
  - Implementar operações privadas e estados de erro sem mostrar dados de outro usuário

Validação: Emulador com duas contas reais de teste autorizadas ou contas isoladas de integração; Conferir resumo com DB e logout/exclusão

Entregas: Hoje/history/profile; Estado de conta e privacidade

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-025 — Implementar busca e registro alimentar no Flutter

**todo · V1 · L**

Como usuário, quero consumir o lote alimentar real em uma refeição registrada por mim.

Dependências: V1-020, V1-021

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/contratos-v1.md; docs/arquitetura/fluxos.md

Critérios de aceite:

- Tela procura alimento/preparo, confirma quantidade e registra por API
- Total, base por100 e campos desconhecidos são claros; sem dieta ou foto reconhecida fictícia
- Integração visual com Hoje mantém alimentação distinta de gasto da atividade

Tarefas e subtarefas:

- V1-025-T01 — Criar feature nutrition
  - Reusar cliente e estado, adicionar busca com debounce/cancelamento
  - Construir detalhe, unidade e confirmação sem inferir peso por fotografia
- V1-025-T02 — Ligar histórico
  - Editar/excluir registro próprio e atualizar resumo
  - Oferecer vazio real quando lote/quantidade não disponível

Validação: Flutter analyze e widgets de unidades/ausência; Registro ponta a ponta com fonte alimentar real

Entregas: Feature nutrition; Refeição persistida e exibida

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-026 — Tratar offline e sincronização sem fingir sucesso

**todo · V1 · L**

Como usuário, quero ler material já autorizado e saber quando um registro ainda não foi enviado.

Dependências: V1-023, V1-025

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/contratos-v1.md; docs/arquitetura/fluxos.md

Critérios de aceite:

- Cache tem versão, validade, direitos e isolamento por conta; sem cache de conteúdo bloqueado
- Fila guarda somente ações reais do usuário, idempotentes, com pendente/enviado/conflito
- Retirada de conteúdo e logout invalidam acesso; UI não mostra sucesso antes da confirmação adequada

Tarefas e subtarefas:

- V1-026-T01 — Definir limites offline
  - Escolher armazenamento local mínimo e política de validade
  - Definir material consultável offline e prática que exige apoio/rede
- V1-026-T02 — Implementar sincronização
  - Enfileirar registros reais e reenviar com chaves estáveis
  - Resolver conflito explicitamente e testar troca de conta

Validação: Modo avião, interrupção, expiração e reconexão; Nenhum registro duplicado nem vazamento entre contas

Entregas: Política de cache e fila; Recuperação verificada

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-027 — Validar acessibilidade e paridade de contratos Android/iOS

**todo · V1 · M**

Como usuário de qualquer plataforma, quero uma experiência compreensível e compatível com minhas necessidades.

Dependências: V1-022, V1-024, V1-025

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/contratos-v1.md; docs/arquitetura/fluxos.md

Critérios de aceite:

- Texto ampliado, semântica, contraste, alvos de toque e movimento reduzido conferidos
- Pessoas idosas e cuidadores mantêm requisitos específicos sem seleção automática por idade
- Abstrações isolam permissões, OAuth e armazenamento; iOS não declarado testado no Windows

Tarefas e subtarefas:

- V1-027-T01 — Verificar Android
  - Testar TalkBack, tamanhos de fonte e fluxo com pouco conhecimento digital
  - Conferir casa/praça e cuidador praticante versus pessoa assistida
- V1-027-T02 — Preparar matriz de plataformas
  - Listar comportamento comum e diferenças nativas de cada integração
  - Manter ios/ e contrato neutro sem exigir o mesmo visual de sistema

Validação: Roteiro de acessibilidade em Android; Checklist iOS pendente até macOS/dispositivo real

Entregas: Relatório de acessibilidade; Matriz Android/iOS por funcionalidade

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

## EP08 — Segurança, desempenho e observabilidade

Medir e verificar o caminho real antes da distribuição, com dados sensíveis protegidos e custos controlados.

### V1-028 — Auditar dependências, segredos e superfície de ataque

**todo · V1 · L**

Como mantenedor, quero um release com riscos conhecidos em vez de um gráfico de auditoria inventado.

Dependências: V1-013, V1-021

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/seguranca-operacao.md; docs/arquitetura/contratos-v1.md

Critérios de aceite:

- Inventário e análise de Go/Flutter/Android com resultados e versões reais
- govulncheck, análise estática e busca de segredos registram escopo/data e exceções
- Nenhum token, dados físicos ou mídia privada em log/artefato de build; nenhuma contagem fictícia de falhas

Tarefas e subtarefas:

- V1-028-T01 — Executar verificação
  - Rodar ferramentas suportadas e revisar reachability/impacto de achados
  - Conferir dependências nativas Android e configuração release
- V1-028-T02 — Corrigir e registrar
  - Priorizar falhas que expõem dados/autenticação e validar regressão
  - Tratar permissões mínimas, backup Android e armazenamento seguro

Validação: Relatórios reais de scanners e testes de autorização; Revisão dos logs e artefato Android

Entregas: Relatório de segurança versionado sem segredos; Riscos residuais e correções

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-029 — Instrumentar requisições, consultas e falhas

**todo · V1 · M**

Como operador, quero descobrir onde uma jornada falhou sem registrar conteúdo pessoal.

Dependências: V1-007, V1-018

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/seguranca-operacao.md; docs/arquitetura/contratos-v1.md

Critérios de aceite:

- RequestId correlaciona Flutter/API; logs estruturados com redação e cardinalidade limitada
- Métricas de latência/erro/pool e traces opcionais mostram chamadas reais; health não vaza detalhes
- Alertas/retention/custo definidos; OpenTelemetry não exige Kubernetes ou Elastic para o piloto

Tarefas e subtarefas:

- V1-029-T01 — Implementar instrumentação mínima
  - Medir duração, status, tamanho e pool sem corpo/token
  - Definir propagação e amostragem; redigir identificadores e nunca nome como label
- V1-029-T02 — Preparar diagnóstico
  - Criar roteiro usuário→HTTP→caso de uso→DB→resposta com requestId
  - Definir alertas acionáveis de erro, indisponibilidade e falha de backup

Validação: Provocar erro controlado em staging e seguir correlação; Conferir ausência de PII e excesso de cardinalidade

Entregas: Runbook e painel de métricas reais; Evidência de uma jornada rastreada

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-030 — Medir consultas e carga representativa

**todo · V1 · L**

Como responsável técnico, quero limites medidos e um plano de escala gradual.

Dependências: V1-014, V1-018, V1-020, V1-029

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/arquitetura/seguranca-operacao.md; docs/arquitetura/contratos-v1.md

Critérios de aceite:

- Baseline registra hardware, versão, volume, cenário, p50/p95/p99, erros e saturação
- Meta inicial proposta p95 leitura abaixo de500ms e escrita abaixo de1s em staging aquecido é revista com medição
- Nenhuma alegação de milhões sem teste; otimizar paginação/índices/pool antes de dividir serviços

Tarefas e subtarefas:

- V1-030-T01 — Ensaiar carga
  - Definir mistura de catálogo, resumo, login e registros com dados de teste isolados
  - Separar carga sintética de usuários reais e não gravá-la na V1 entregue
- V1-030-T02 — Corrigir gargalos
  - Inspecionar planos de consulta e N+1 com EXPLAIN apropriado em teste
  - Medir cache/ETag e limites por instância; repetir apenas após mudança relevante

Validação: Relatório reproduzível de carga em ambiente autorizado; Teste de limite e recuperação após saturação

Entregas: Baseline e orçamento de capacidade; Plano de escala condicionado a métricas

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

## EP09 — Infraestrutura, CI e implantação

Subir API e banco com HTTPS, backup e rollback, após decisão concreta de fornecedor e custos.

### V1-031 — Escolher hospedagem e orçamento do piloto

**todo · V1 · S**

Como dono, quero aprovar uma opção concreta antes de criar recursos ou fornecer cartão.

Dependências: V1-007, V1-010

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/execucao/v1/implantacao-e-apk.md

Critérios de aceite:

- Comparar container Go + Postgres gerenciado com VPS, região/latência, backup, sleep, quotas e custo atual oficial
- Reutilizar conta/recurso existente se funcionar, sem prometer gratuidade permanente
- Registrar fornecedor, teto mensal, forma de cobrança, domínio e aprovação antes de provisionar

Tarefas e subtarefas:

- V1-031-T01 — Levantar o que existe
  - Listar recursos autorizados sem imprimir credenciais
  - Medir necessidades e consultar preços/limites nas páginas oficiais na data
- V1-031-T02 — Apresentar proposta concreta
  - Definir API, DB, TLS/DNS e logs com caminhos e efeitos
  - Fixar orçamento e plano de parada/exportação; aguardar aprovação para gasto/criação

Validação: Conferir preços e limites atuais com fontes oficiais; Revisar plano de desligamento e restauração

Entregas: Decisão de provedor e custos aprovada; Mapa de ambientes e região

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-032 — Construir pipeline e artefatos reproduzíveis

**todo · V1 · L**

Como mantenedor, quero testar a mesma versão de API, contrato e app que será distribuída.

Dependências: V1-008, V1-028

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/execucao/v1/implantacao-e-apk.md

Critérios de aceite:

- CI roda análise/testes de Go e Flutter, migrations em DB isolado e validação documental
- Imagem não root e artefatos identificados por commit, versão e digest
- Segredos de assinatura/deploy fora do Git e não disponíveis em PR não confiável

Tarefas e subtarefas:

- V1-032-T01 — Criar jobs
  - Separar testes, contrato, import dry run e build
  - Fixar versões suportadas e cache sem credenciais
- V1-032-T02 — Versionar entrega
  - Associar commit, manifestos e schema à imagem e APK
  - Definir aprovação de deploy e retenção de artefatos

Validação: Pipeline completo no repositório autorizado; Rebuild e conferência de versão/digest

Entregas: Workflow CI; Imagem da API e metadados de release

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-033 — Implantar staging e conferir restauração

**todo · V1 · L**

Como testador, quero acessar a API do celular fora da rede do notebook.

Dependências: V1-031, V1-032, V1-006, V1-020, V1-029

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/execucao/v1/implantacao-e-apk.md

Critérios de aceite:

- API pública por HTTPS com DB privado, segredo gerenciado, CORS/proxy corretos e readiness
- Migrations e importação revisadas executadas uma vez com backup; smoke testa leitura e escrita reais
- Rollback de imagem e restauração ensaiados; apagar recursos somente após deixar de usar e preservar dados necessários

Tarefas e subtarefas:

- V1-033-T01 — Provisionar após aprovação
  - Criar ambiente com orçamento, região e acesso mínimo definidos
  - Aplicar migrations por job controlado e importar lote revisado
- V1-033-T02 — Validar fora do notebook
  - Conferir login/refresh/catálogo/registro/consulta com conta real autorizada
  - Ensaiar restore e registrar endpoint, versão, custos e desligamento

Validação: Smoke HTTPS de ponta a ponta; Restore em base separada e rollback de imagem

Entregas: URL staging e runbook; Evidência de implantação e recuperação

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

## EP10 — APK e primeiro teste acompanhado

Entregar um arquivo instalável legítimo, rastreável e útil para feedback real da esposa.

### V1-034 — Preparar identidade e assinatura Android

**todo · V1 · M**

Como desenvolvedor, quero que o APK de teste possa ser atualizado sem perder a instalação.

Dependências: V1-021, V1-032

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/execucao/v1/implantacao-e-apk.md

Critérios de aceite:

- ApplicationId próprio, versionName/code e keystore release protegido e com backup seguro
- Manifest INTERNET e network config conferidos; release usa HTTPS e assinatura própria, sem debug key
- OAuth release fingerprint configurado; segredo não entra no repo/log

Tarefas e subtarefas:

- V1-034-T01 — Definir identidade
  - Escolher applicationId estável e política de versão
  - Gerar chave fora do Git com senha segura e backup recuperável
- V1-034-T02 — Validar release
  - Configurar Gradle sem segredo hardcoded e revisar permissões
  - Conferir certificado do APK, endpoint e flags debug

Validação: Verificar APK com ferramenta de assinatura do SDK; Instalar e atualizar build assinada mantendo dados

Entregas: Configuração de release; Procedimento de guarda/recuperação de chave

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-035 — Validar a jornada completa da V1

**todo · V1 · L**

Como responsável pelo teste, quero evidência de que o arquivo usa API, DB e conteúdo reais.

Dependências: V1-023, V1-024, V1-025, V1-026, V1-027, V1-030, V1-033, V1-034

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/execucao/v1/implantacao-e-apk.md

Critérios de aceite:

- Login real → lote aprovado → fonte/versão → registro real → resumo → relançamento → logout verificados
- Erro/offline/duplo toque/ausência de conteúdo e troca de data cobertos sem mocks no runtime
- Lote bloqueado não executa; feedback não é apresentado como comprovação clínica

Tarefas e subtarefas:

- V1-035-T01 — Executar roteiro release
  - Usar o APK assinado e API staging, não apenas flutter run
  - Conferir respostas e linhas do DB sem publicar dados pessoais
- V1-035-T02 — Fechar critérios
  - Registrar resultados por passo, versão, dispositivo e limitações
  - Corrigir bloqueadores e repetir somente trechos afetados

Validação: E2E real em Android/emulador e aparelho quando disponível; Verificação de contrato, assinatura e ausência de fixtures na distribuição

Entregas: Relatório de aceite V1; Lista de problemas e limitações

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-036 — Gerar e disponibilizar APK à esposa

**todo · V1 · S**

Como testadora, quero receber o arquivo e instruções claras para instalar, testar e reportar problemas.

Dependências: V1-035

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/execucao/v1/implantacao-e-apk.md

Critérios de aceite:

- APK release versionado, checksum, notas e link privado autorizado; sem envio de mensagem sem pedido explícito
- Guia explica instalação da origem usada, permissão temporária, atualização, login e roteiro
- Testadora concorda com uso dos dados; conta/log/arquivo temporários têm regra de limpeza após uso

Tarefas e subtarefas:

- V1-036-T01 — Empacotar
  - Build release com URL staging e manifesto aprovados
  - Gerar SHA256, verificar certificado e escrever release notes com limites
- V1-036-T02 — Preparar entrega e feedback
  - Disponibilizar arquivo/link no local aprovado e roteiro simples
  - Separar feedback de usabilidade de sintoma/prática; registrar erro/requestId sem PII

Validação: Download e hash coincidem; instalação real confirmada pela testadora; Registrar feedback real, sem inventar aceitação

Entregas: APK instalável e checksum; Guia para esposa e registro de feedback

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-037 — Encerrar piloto e priorizar correções

**todo · V1 · S**

Como dono, quero aprender com o uso e retirar o que não for mais necessário.

Dependências: V1-036

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/execucao/v1/implantacao-e-apk.md

Critérios de aceite:

- Consolidar problemas realmente observados por impacto e reprodução
- Excluir temporários/contas de teste e recursos dispensados somente após confirmar que não são mais usados
- Conteúdo e evidências de autoria preservados; histórico pessoal tratado conforme consentimento

Tarefas e subtarefas:

- V1-037-T01 — Avaliar feedback
  - Comparar roteiro com uso real sem gerar métricas de adesão falsas
  - Criar bugs com evidência e próximo incremento revisável
- V1-037-T02 — Fazer limpeza
  - Inventariar APKs/logs/recursos/contas ainda necessários
  - Apagar apenas alvos definidos, conferir ausência e guardar recibo sem segredos

Validação: Conferir correções com reexecução afetada; Recibo de limpeza e custo final

Entregas: Balanço do piloto; Backlog repriorizado e limpeza documentada

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

## EP11 — iOS e distribuição nas lojas

O mesmo produto terá iOS; execução e publicação nativa ficam depois da primeira validação Android.

### V1-038 — Compilar e testar no ecossistema iOS

**todo · V1.1 · L**

Como usuário de iPhone, quero acesso aos mesmos contratos e conteúdo permitido.

Dependências: V1-027, V1-035

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/execucao/v1/implantacao-e-apk.md

Critérios de aceite:

- Ambiente macOS/Xcode e dispositivo/simulador reais disponíveis e documentados
- Bundle ID, OAuth, keychain, rede, permissões e lifecycle testados separadamente
- Nenhum APK convertido em IPA; mesma API/dados, adaptações nativas explícitas

Tarefas e subtarefas:

- V1-038-T01 — Preparar ambiente
  - Verificar acesso existente a Mac e compatibilidade Flutter/Xcode antes de instalação
  - Configurar assinatura/BundleID/OAuth sem expor certificados
- V1-038-T02 — Validar paridade
  - Rodar jornada real, interrupção, secure storage e acessibilidade
  - Registrar diferenças e corrigir sem forçar aparência Android

Validação: Build iOS e testes em ambiente Apple; E2E na API staging e relatório de diferenças

Entregas: Build iOS validada; Matriz de paridade atualizada

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-039 — Preparar TestFlight, Play e políticas de publicação

**todo · V1.1 · L**

Como responsável, quero distribuir nas lojas quando houver aceite, privacidade e custos definidos.

Dependências: V1-038, V1-037

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md; docs/execucao/v1/implantacao-e-apk.md

Critérios de aceite:

- Contas de desenvolvedor, taxas atuais, regras de saúde/dados e revisão verificadas em fontes oficiais
- Assinatura, formulários de privacidade, screenshots reais e política de suporte coerentes
- Publicação somente após autorização; teste interno Android não exige loja agora

Tarefas e subtarefas:

- V1-039-T01 — Revisar requisitos atuais
  - Conferir Apple/Google no momento da publicação
  - Aprovar custos, identidade legal e política de dados
- V1-039-T02 — Distribuir por fases
  - Configurar testes internos/TestFlight e coletar feedback
  - Preparar rollback/retirada e submissão com versão rastreável

Validação: Checklist oficial preenchido e testes de loja reais; Sem afirmação de aprovação antes do retorno da plataforma

Entregas: Pacotes/metadata de loja; Relatório de submissão e decisões

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

## EP12 — Visão integral após o primeiro piloto

Preservar os requisitos ainda não implementados, sem enchê-los de simulações na V1.

### V1-040 — Ampliar modalidades, programas e personalização humana

**todo · Posterior · L**

Como usuário experiente ou iniciante, quero ampliar a biblioteca sem perder autoria nem chamar composição de programa original.

Dependências: V1-037

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md

Critérios de aceite:

- Expandir pelos lotes N pesquisados, mantendo direitos/apoio/variante e ambiente
- Montar/importar treino próprio é complementar e registra quem alterou e a origem das peças
- Cada modalidade usa unidades e progressão reais; sem dose criada pela IA

Tarefas e subtarefas:

- V1-040-T01 — Priorizar lotes
  - Usar lacunas observadas no piloto e mapa N01–N46
  - Selecionar programas/componentes de casa, praça e academia com cobertura real
- V1-040-T02 — Implementar composição
  - Modelar alterações e atribuição por componente
  - Revisar material/instruções e liberar somente uso sustentado

Validação: Revisão dos lotes e testes de unidade/ordem; Fluxo de composição com atribuição preservada

Entregas: Lotes adicionais; Editor/importador com limites

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-041 — Adicionar sensores, GPS e integrações

**todo · Posterior · L**

Como usuário, quero importar medidas reais com permissão e origem, evitando registros duplicados.

Dependências: V1-037, V1-038

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md

Critérios de aceite:

- Plataformas/provedores são escolhidos por pesquisa e capacidade real do aparelho
- Permissões graduais, revogação, identificação da origem e deduplicação testadas
- Sem frequência cardíaca/distância/calorias inventadas quando sensor não existir

Tarefas e subtarefas:

- V1-041-T01 — Definir integração prioritária
  - Comparar capacidades Android/iOS, termos e custo atuais
  - Desenhar permissionamento, consentimento e regra de conflitos
- V1-041-T02 — Implementar captura real
  - Iniciar/pausar/retomar e tratar perda de sinal/background
  - Validar unidade, precisão declarada e duplicidade com registro manual

Validação: Testes em dispositivos reais compatíveis; Negação/revogação de permissão e ausência de sensor

Entregas: Integração real documentada; Matriz de disponibilidade

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-042 — Investigar imagem, OCR e confirmação humana

**todo · Posterior · L**

Como usuário, quero apoio para registrar uma foto sem tratar estimativa visual como medição confirmada.

Dependências: V1-037

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md

Critérios de aceite:

- Foto de prato, rótulo/barcode, painel de treino e gesto são problemas separados
- Modelo/API, licença, custo, privacidade e precisão medidos antes de adoção
- Candidatos exigem confirmação de alimento/preparo/quantidade/atividade; nenhum treino prescrito por IA

Tarefas e subtarefas:

- V1-042-T01 — Executar prova delimitada
  - Reutilizar evidências N correspondentes antes de nova pesquisa
  - Definir dataset autorizado e métricas de erro sem dados pessoais por padrão
- V1-042-T02 — Decidir produto
  - Comparar captura local/remota e fallback manual
  - Implementar somente resultado aprovado, com edição e exclusão da foto

Validação: Ensaio com material autorizado e resultados reais; Testes de erro, baixa confiança e privacidade

Entregas: Decisão por tipo de captura; Fluxo confirmado pelo usuário

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.

### V1-043 — Desenvolver acompanhamento e alimentação avançados

**todo · Posterior · L**

Como cuidador ou usuário, quero ferramentas próprias com consentimento e limites claros.

Dependências: V1-037, V1-013

Entradas: docs/execucao/v1/escopo.md; docs/arquitetura/diagnostico-atual.md; docs/conteudo/evidencias-para-integracao.md; docs/execucao/v1/handoff.md

Critérios de aceite:

- Pessoa assistida tem vínculo e permissões explícitos; registros distinguem autor e titular
- Modelos humanos de alimentação dependem de conteúdo/direitos e responsabilidade real, não cardápio gerado
- Reconhecimento, recomendações e contextos clínicos continuam condicionados à evidência apropriada

Tarefas e subtarefas:

- V1-043-T01 — Especificar jornadas
  - Separar saúde do cuidador de acompanhamento de outra pessoa
  - Investigar consentimento, acesso, acessibilidade e revogação em cenários reais
- V1-043-T02 — Implementar por fatia
  - Priorizar registro compartilhado e organizador alimentar conforme feedback
  - Adicionar modelo humano somente após cumprir os mesmos gates do catálogo

Validação: Teste de permissões entre titulares e cuidadores; Revisão da origem dos modelos e ausência de prescrição automática

Entregas: Jornadas de acompanhamento; Expansão alimentar com origem

Handoff: Registrar arquivos/contratos alterados, comandos e resultados reais, pendências e próxima história desbloqueada em docs/execucao/v1/diario.md; atualizar este JSON, regenerar backlog e conferir painel. Concluir somente com os critérios e evidências desta história.
