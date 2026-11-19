# Decisões e evolução da arquitetura

Consolidação de **16/11/2026**. Esta página reúne o motivo das escolhas, o diagnóstico inicial e a primeira extração de serviço. Estado operacional atual e próxima ação ficam no [handoff](../execucao/v1/handoff.md); decisões de produto, em [Q1–Q6](../execucao/v1/escopo.md).

## Direção escolhida

Flutter continua compartilhado entre Android/iOS; Go e PostgreSQL compõem o backend. Em 21/10 o autor confirmou a migração de linguagem/domínio da V1. A recomendação inicial de um processo modular foi revista em 29/10: o autor escolheu **microserviços por etapas**. A primeira extração de catálogo M0–M4 foi concluída localmente. Demais domínios permanecem no núcleo; não houve decomposição integral.

| Caminho avaliado | Benefício | Custo/limite considerado |
|---|---|---|
| Evoluir Fastify | Reaproveitar autenticação/sessões e chegar mais rápido à primeira fatia | Modelo editorial e cliente ainda exigiam revisão; não atendia à direção Go escolhida |
| Go em processo modular | Composição, transações e operação inicial simples; módulos por negócio | Reimplementar contratos/auth/migrations/testes; publicação conjunta e privilégios compartilhados |
| Serviços por capacidade | Publicação/escala independentes e possível isolamento de falhas | Rede, contratos, identidade entre serviços, exclusão/restore e consistência distribuída |

A escolha não decorre de incapacidade de escalar Fastify nem certifica capacidade do Go. Microserviços não exigem Kubernetes, vários repositórios ou hospedagem. As referências usadas na avaliação foram as [recomendações Flutter](https://docs.flutter.dev/app-architecture/recommendations), [organização Go](https://go.dev/doc/modules/layout), [benefícios/desafios de microserviços](https://learn.microsoft.com/en-us/azure/architecture/guide/architecture-styles/microservices) e [extração gradual](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/strangler-fig.html). O [caso Nubank](https://flutter.dev/showcase/nubank) foi referência multiplataforma, sem provar capacidade ou stack do backend deste projeto.

## Diagnóstico que motivou a mudança

Em 21/10 foram lidos Flutter, backend externo Fastify e mapas estruturais, sem apresentar inspeção estática como teste runtime. O [recibo Graphify](graphify-2026-10-21.json) conserva a cobertura daquela data. As versões/fontes históricas podem ser recuperadas no Git; os fatos atuais estão nos guias consolidados.

| Achado original | Encaminhamento e estado consolidado |
|---|---|
| Modelo exigia séries/repetições/descanso para qualquer movimento | Novo conteúdo distingue gesto, instrução, mídia, programa, sessão, dose e ocorrência; conteúdo de prática continua condicionado a revisão |
| IA e builder chamado manual escolhiam rotinas/doses | Esses caminhos legados não integram a prática V1; não preencher lacuna com geração ou fixture |
| Logs de corpos, sessão apagada por rede e só access token no cliente | Cliente Go passou a refresh coordenado, logs restritos e recuperação; aceite local 011/012/013 registrado |
| Identidade por e-mail e refresh sem prova de concorrência | Go usa issuer/sub, rotação/família e revalidação transacional; Fastify preservado como referência histórica |
| Migration legada removia índices parciais | Invariantes foram revistas no schema novo, sem restaurar mecanicamente um plano ou refresh único por conta |
| Histórico confundia dia do plano com ocorrência | Ocorrências/eventos próprios e motor de execução foram implementados; seleção/agenda e conteúdo real mantêm seus gates |
| Pacote/assinatura/HTTP de desenvolvimento | OAuth local e armazenamento tiveram verificações próprias; HTTPS/distribuição release/iOS continuam separados |
| Forwarded headers, backup e capacidade sem prova | Proxy explícito/limites, ensaios de restore e readiness foram implementados; auditoria integral/carga seguem abertas |

[Registro dos achados e suas evidências](achados.json) · [Fechamento da fundação](../execucao/v1/implementacao.md) · [Aceite de autenticação](../execucao/v1/implementacao.md). Os achados sobre arquivos removidos são históricos, não uma alegação de que o código antigo ainda roda.

## Fronteiras que continuam relevantes

Uma transação alimentar confirma refeição, consumos, versões e replay juntos. Separar refeição de seus alimentos em serviços distintos perderia essa atomicidade sem protocolo adicional. Privacidade coordena inventário, exclusões e proteção de restore; extrair auth ou dados privados exige preservar revogação/sessão viva, confirmação e impedimento de recriação.

A decomposição candidata é por capacidade: alimentação; treinos (configuração/adesão/agenda/execução); catálogo editorial; futuro processamento de fotos; identidade/privacidade com protocolo transversal. Não é serviço por tabela ou endpoint. Vários executáveis com o mesmo usuário/banco manteriam acoplamento. Fotos ainda não têm provedor, storage ou serviço aprovado.

Uma nova extração precisa demonstrar propriedade de dados, contrato, indisponibilidade, autorização, idempotência, observabilidade, exclusão/restore e necessidade operacional. Múltiplas instâncias exigem orçamento de conexões e comportamento distribuído; nomes de arquitetura não provam milhões simultâneos. [Critérios e medição](seguranca-operacao.md).

## Catálogo: primeira extração concluída

| Marco de 29/10 | Resultado no recorte | Evidência |
|---|---|---|
| M0 | Direção gradual e levantamento de dependências Go/SQL | Esta decisão e backlog V1-002 |
| M1 | Executável catalog, reader/migrator próprios, fixtures/CI, equivalência/negativos de grants | CI 40860200717, commit ff8c8bb |
| M2 | Publicação/retirada por revisão/digest, CAS/replay e histórico append-only | CI 40874689251, commit c68b085 |
| M3 | Ensaio de transição/restore, comparação e falhas em descartável | [Recibo M0–M4](../execucao/v1/catalog-rollout-verification.json) |
| M4 | Banco/papéis próprios locais, encaminhamento, rollback verificado e recuperação | Mesmo recibo, com critérios/hashes por etapa |

O catálogo 0.2.0 usa schema 2 com quatro tabelas mais controle Goose, reader sem DML e sem acesso ao núcleo privado. Cinco GETs conservam o contrato Flutter: filtros, movimentos/lista/detalhe e programas/lista/detalhe. Mantêm identidade/versão, program/collection/movement, filtros/cursor, paginação, atribuição/direitos, consulta/prática, ausência e 400/404/503. Retirada/permissão é conferida antes de 304; selecionar a última versão antecede a filtragem de retirada para não reviver conteúdo.

A API encaminha somente esses GETs para origem loopback fixa, sem Authorization, cookies, identidade, proxy de ambiente ou redirects; usa prazo e tamanho limitados. Rede/frescor divergente retorna 503; não busca cópia antiga como fallback silencioso. Uma falha não apaga sessão nem altera configuração.

### Autoridade, espelho e recuperação

`catalog-release` publica pacote exato na autoridade, com CAS/replay e confirmação. `catalog-transition` faz bootstrap/espelho/verify. Fontes alimentares ficam no dono anterior. O espelho editorial do núcleo mantém referências/FKs históricas para configuração e execução; não é um segundo escritor autorizado. Importador antigo fica bloqueado após registro da autoridade.

Configuração revalida credencial em SQL e compara digest do espelho com revisão remota sob lock, sem cache. Divergência/rede retorna 503 antes da escrita. Isso valida identidade/frescor dos recursos declarados, sem prescrição ou autorização perpétua de prática; uma publicação concorrente pode se linearizar depois da leitura corrente.

`catalog_local.py activate` foi ferramenta específica da transição: criou banco editorial/papéis, checkpoint do núcleo e restore offline para comparar 30 tabelas antes de mudar o modo. Não é comando diário. Rollback explícito `local-verified` mantém autoridade remota, exige digest/revisão iguais antes/depois da resposta, inclusive 304, e falha fechado quando não consegue confirmar. Não existe retorno automático a estado antigo.

M4 conferiu cinco rotas equivalentes, 304, detalhe negativo de programa, biblioteca nativa 73/0, autoria/licença, indisponibilidade 503/recuperação 200 e retorno ao modo remoto; 30 tabelas privadas permaneceram iguais. Não existia programa real para detalhe positivo. O estado de processos ativos descrito no recibo é histórico, não observação atual. Não repetir ativação, restore, OAuth ou instalação por causa desta página.

## Preservações e próximos limites

Há um escritor por domínio, migrations isoladas e nenhuma dual write entre legado e Go. Dados legados não foram presumidos vazios ou migrados por inferência. Android/iOS, fontes/direitos e dados reais foram preservados; a limpeza retirou scaffolds e Dart inalcançável conforme [recibo](../execucao/v1/repository-cleanup-verification.json).

Execução de treino entrou depois, em 16/11, com tabelas/grants existentes, quatro rotas privadas e integração Flutter. Isso não fecha seleção/adesão, conteúdo, agenda, offline ou produto inteiro. [Escopo atual](../execucao/v1/implementacao.md#atividade). Hospedagem, compra de mídia e extração de todos os demais domínios continuam exigindo seus próprios requisitos/decisões.
