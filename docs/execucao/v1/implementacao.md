# Implementação: o que foi entregue e como foi comprovado

Atualizado em **18/11/2026**. Código alimentar em integração: API **0.11.0**, migrations até **16**, Flutter **0.5.0+30**, catálogo local amplo em geração. A base pessoal está no **schema16/38tabelas** após ativação protegida, com as30tabelas anteriores intactas, catálogo de treinos **0.2.0/schema 2/4 tabelas**; último APK anterior debug **0.4.7+29 gerado**. Os resultados abaixo pertencem aos seus checkpoints; esta reorganização não repetiu login, importação ou teste humano.

O [histórico](../../historico/README.md) explica a ordem das decisões. O [modelo técnico](../../arquitetura/modelo-e-contratos.md) e o [Swagger](../../../contracts/generated/swagger-v1.json) descrevem os contratos. O [backlog](backlog.json) conserva critérios e dependências: código detectado não encerra uma história.

<a id="curadoria"></a>
## Curadoria e primeiro lote

A pesquisa comparou fontes humanas, programas, movimentos, instruções, mídia e alimentos como objetos diferentes. A triagem técnica inventariou **512 ativos:73 metadados de consulta e439 excluídos**. Nenhum programa, instrução, dose ou mídia de treino foi aprovado para prática no lote entregue. Os critérios incluem identidade/versão, autoria, direitos por operação, fidelidade, instrução e segurança; uma fonte pesquisada não é automaticamente um fornecedor liberado.

O preparo trabalha offline sobre provas já obtidas. Importação e publicação são ações próprias, distintas de iniciar o ambiente. Não executar preparadores ou conferidores históricos só para abrir o app: podem gerar novas saídas ou alterar recibos.

Evidências: [manifesto](verificacao-manifesto.json), [preparação](verificacao-preparacao-local.json), [importação do catálogo](catalog-import-verification.json), [fontes e direitos](../../conteudo/README.md). Os documentos originais das etapas01/02 permanecem no acervo, com seus hashes.

<a id="fundacao"></a>
## Fundação e separação do catálogo

O backend foi estruturado em Go, `net/http`, pgx/v5 com SQL parametrizado e Goose. PostgreSQL local usa cluster e papéis próprios; não se confunde com o serviço instalado globalmente. Os contratos HTTP são derivados dos comentários e DTOs Go. Não há ORM no backend atual; Fastify/Prisma é referência histórica.

O catálogo foi a primeira extração delimitada: banco, papéis e cinco rotas de leitura próprios, com publicação, retirada, projeção, falha/recuperação e rollback ensaiados. Isso não significa que todos os domínios viraram microserviços. Alimentação e execução continuam no núcleo, mantendo suas transações locais.

Evidências: [banco](database-verification.json), [restore](restore-ci-verification.json), [leitura](catalog-read-verification.json), [rolloutM0–M4](catalog-rollout-verification.json). A decisão e os limites estão em [arquitetura](../../arquitetura/decisoes.md).

<a id="conta-e-privacidade"></a>
## Conta e privacidade

V1-011/012/013 foram encerradas no recorte local documentado: login Google Android debug, sessão com refresh/revogação e privacidade do titular. O cliente usa o contrato Go `/api/v1`, `accessToken` e armazenamento seguro; falha de rede não apaga uma sessão por suposição. Logs não imprimem tokens, corpos privados ou credenciais.

Exportação e exclusão verificam identidade e titularidade no servidor. A exclusão confirmada inclui dados particulares vinculados e possui regras de backup/restore. Conta master, publicação externa e certificação de produção têm critérios próprios; não existe privilégio por e-mail informado pelo app ou por ser dono do GitHub.

Evidências: [SQL/HTTP local](auth-local-verification.json), [Google Android](auth-real-android-verification.json), [checkpoint](android-auth-checkpoint.json), [privacidade](privacy-local-verification.json). Não repetir consentimento ou exclusão para reconfirmar um documento.

<a id="catalogo"></a>
## Biblioteca de consulta

O Flutter permite consulta pública de movimentos/programas, filtros e detalhe com versão. Consulta é separada de prática: ausência de programa, instrução suficiente ou direitos é exibida como indisponibilidade. A API faz a composição com o catálogo; o celular não acessa PostgreSQL nem importa automaticamente conteúdo de fornecedores.

Autoria, fonte, original, versão e limites permanecem acessíveis. Retirada editorial impede usos futuros conforme o contrato, sem transformar uma dose prevista em fato realizado.

Evidências: [SQL/leitura](catalog-read-verification.json), [composição Flutter](frontend-composition-verification.json), [conteúdo e lacunas](../../conteudo/evidencias-para-integracao.md).

<a id="configuracao"></a>
## Configuração antes do treino

V1-047 reúne contexto do praticante, ambientes, recursos e disponibilidade em etapas curtas com revisão final. O backend salva versões com revisão esperada e idempotência. Recursos desconhecidos continuam desconhecidos; a configuração não cria uma rotina nem confirma elegibilidade clínica.

O checkpoint humano recuperou a revisão 2 com o horário14:00 escolhido pelo autor. Não criar revisão3 para testar navegação. Esclarecimento de fuso/horário e aceite das etapas seguintes continuam separados.

Evidências: [fundação](training-configuration-foundation-verification.json), [SQL](training-configuration-sql-verification.json), [cliente](training-configuration-client-verification.json), [aceite humano](training-configuration-human-verification.json), [fechamento](training-configuration-047-fechamento.json).

<a id="alimentacao"></a>
## Alimentação offline, nomes e refeições

A consulta alimentar nova usa SQLite público assinado no aparelho, com TACO/USDA/OFF e legados. O pacote global ainda está em recuperação/conferência, conforme [handoff](handoff.md). FTS4, GTIN e leitura ML Kit estão integrados; a validação nativa permanece pendente. O cadastro particular permite marca/códigos e porções medidas, incluindo colher/unidade/lata quando seu peso ou volume forem conhecidos.

Primeiro login online, depois recursos e operações alimentares em SQLCipher por conta, com outbox durável e sync própria. O estado local pendente aparece como tal; confirmação exige igualdade do cálculo. Reenvio, conflitos, revogação conhecida e exclusão têm guardas persistentes. Contribuir é opcional, com convite dispensável, campos/fotos revisados e consentimento CC0; revisão pelo mantenedor precede export/publicação. Créditos/ODbL e downloads por versão ficam em Fontes e transparência.

O produto permite alimento particular e registra consumo com quantidade, base, unidade, data e fuso. Valores ausentes não viram zero, composição por100g não vira porção por inferência, métodos/fatores de energia são rastreáveis e identidades de alimentos não são mescladas pelo nome traduzido.

A base preparada/importada conserva fontes e direitos por lote, rejeições e lacunas. A UI apresenta pt-BR, pt-PT, inglês e espanhol; nomes editoriais são uma camada separada da composição. A infraestrutura multilíngue não significa cobertura editorial completa: o checkpoint registrou0/6369 nomes alimentares publicados como revisão profissional. As apresentações dos73 movimentos e31 variantes alimentares são vinculadas a ID/versão/original; faltas mantêm o original.

Refeição e alimento são visões dos mesmos registros. Agrupamento, correção de metadados e exclusão possuem revisão esperada, confirmação e proteção contra reenvio. O lançamento20g foi identificado pelo autor como teste de navegação; preservar esse registro, sem reclassificá-lo como ingestão real. V1-045 mantém aceite/correção/exclusão real e ligação com fotos pendentes. Nenhuma operação alimentar foi executada pela limpeza documental.

Verificação desta ampliação: [cliente Flutter](food-offline-client-verification-20261118.json) e [SQL descartável schema16](offline-nutrition-sql-verification.json). A implantação pessoal e o catálogo final não estão comprovados por esses testes.

Evidências históricas: [preflight](food-preflight-verification.json), [importação](food-import-verification.json), [consumo](nutrition-local-verification.json), [nomes](food-names-consumption-verification.json), [SQL refeições](meal-grouping-sql-verification.json), [integração](meal-grouping-client-verification.json). Quando um recibo distingue fixture e teste humano, essa distinção é vinculante.

<a id="atividade"></a>
## Execução de atividade: persistência e tela única

V1-017/023 estão **em andamento**. O agregado original Go e o Flutter preservam referências exatas de programa/versão/sessão/ocorrência, início original, revisão, alvos prescritos, séries efetivamente informadas e pausas. O contrato é `trainforge.activity-session/1`.

| Ação | Regra implementada |
|---|---|
| Iniciar | Exige ocorrência existente e prescrição explícita; nenhum realizado pré-preenchido |
| Registrar série | Somente iniciado, slot explícito e série prescrita; repetições ou duração; zero informado é diferente de ausência |
| Pausar/retomar | Abre/fecha intervalo, preservando o início original |
| Concluir | Confirmação explícita e todas as séries registradas; não exige falsificar o resultado para atingir o alvo |
| Encerrar parcial/cancelar | Confirmação explícita, preservando fatos já informados |
| Sair de tela/timer | Não grava medida, não pausa nem conclui automaticamente |

Persistência usa `activity_sessions`, `activity_events` e `idempotency_records`, sem migration/grant novo. O evento inicial congela prescrição e nomes por versão; comandos têm UUID, horário do servidor e hash da intenção. Reidratação confere journal, ocorrência e estado SQL. Uma ocorrência não ganha outra execução após encerrada. A mesma chave/corpo devolve a revisão originalmente aplicada e o snapshot atual; outro corpo conflita, inclusive depois de expirar o cache de resposta.

Cada transação revalida a credencial viva e ordena bloqueios de projeção/titular/ocorrência. Iniciar, retomar e registrar exigem versões exatas, `catalog_metadata` e `guided_practice` liberadas, instrução/segurança revisadas e ausência de retirada. Pausa e encerramento preservam fatos após retirada. `source_dose` só aceita o contrato próprio `trainforge.activity-prescription/1`, sem interpretar uma dose estrangeira por semelhança.

Quatro operações privadas: `GET me/activity`, `GET me/activity-sessions/{id}`, `POST me/activity-sessions` e `POST me/activity-sessions/{id}/commands`, todas sob `/api/v1`. O feed limita32 ocorrências e32 sessões, com `complete` explícito. O servidor atribui o horário e exige titularidade; JSON duplicado, campo inesperado, query indevida e corpo excessivo são recusados.

Na aba **Atividade**, lista e sessão ocupam a mesma superfície. O serviço é criado sob demanda por conta. Entradas começam vazias; duração em segundos e carga decimal em kg são convertidas sem ponto flutuante. Uma escrita incerta conserva intenção/chave/revisão **somente na memória do processo**, com retentativa por 24h e reconciliação explícita. Feed incompleto não prova ausência. Não há fila offline durável nem recuperação da intenção pendente após matar processo.

Evidências: [fundação](activity-session-foundation-verification.json), [SQL/HTTP descartável](activity-session-sql-verification.json), [integração/APK](activity-session-integration-verification.json). Resultado do incremento:337 Flutter, análise0, Go/vet,138 Python; SQL3 testes+23 subtestes, base entregue inalterada. Fixtures editoriais não aprovaram um treino real.

**Ainda falta:** primeiro programa próprio revisado, seleção/adesão e agenda (015/016), instrução/player/mídia, correção de série confirmada, modalidades adicionais, fila offline e aceite nativo do ciclo. A aba pode estar vazia porque nenhum programa foi liberado. O APK29 não foi instalado ou publicado por esse incremento.
