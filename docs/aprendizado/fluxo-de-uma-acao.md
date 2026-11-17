# Como uma ação atravessa o TrainForge

O caminho mais comum é: pessoa → tela Flutter → controller → repository → HTTP → handler Go → regras/persistência → PostgreSQL → JSON → estado da tela. Cada etapa tem uma responsabilidade. Uma tabela não recebe chamadas do aplicativo; o código Go consulta o banco e devolve somente o contrato HTTP permitido.

## Antes do primeiro toque: composição

[`lib/main.dart`](../../lib/main.dart) inicia o app. [`lib/app.dart`](../../lib/app.dart) monta tema, idioma e dependências. A pasta [`lib/composition/`](../../lib/composition/) descreve as dependências; `production_dependencies.dart` conecta suas interfaces às implementações Go. Isso permite substituir um repository por uma fixture em um teste sem trocar o código de produção.

O [`product_shell.dart`](../../lib/shared/widgets/product_shell.dart) organiza as áreas do produto. O [`app_dio.dart`](../../lib/core/http/app_dio.dart) centraliza o transporte HTTP. O endereço da API vem da configuração do cliente; em produção, a tela não escolhe livremente outro banco ou outra credencial.

## Exemplo 1: consultar a biblioteca de movimentos

É o primeiro fluxo para estudar porque uma consulta pública não cria registro pessoal.

| Etapa | Onde ler | O que observar |
|---|---|---|
| Tela | [`catalog_page.dart`](../../lib/features/catalog/presentation/catalog_page.dart) | Apresenta busca, filtros, lista, carregamento, erro e detalhe |
| Estado | [`catalog_controller.dart`](../../lib/features/catalog/presentation/catalog_controller.dart) | Coordena consulta e filtros; uma resposta antiga não substitui uma busca mais nova |
| Acesso HTTP | [`catalog_repository.dart`](../../lib/features/catalog/data/catalog_repository.dart) | `GoCatalogRepository` envia `GET /api/v1/catalog/movements` e filtros; usa `mode=consultation` |
| Contrato do cliente | [`catalog_entry.dart`](../../lib/features/catalog/domain/catalog_entry.dart) | Converte JSON em dados que o Flutter entende |
| Entrada Go | [`cmd/api/main.go`](../../services/api/cmd/api/main.go) | Conecta as rotas ao catálogo local ou ao serviço separado conforme a configuração |
| Fronteira separada | [`catalogbridge/client.go`](../../services/api/internal/catalogbridge/client.go) | No modo remoto, encaminha a consulta ao catálogo em `127.0.0.1:18083`, sem levar credenciais do usuário |
| Leitura do catálogo | [`catalog/handler.go`](../../services/api/internal/catalog/handler.go), [`read.go`](../../services/api/internal/catalog/read.go) e [`postgres_read.go`](../../services/api/internal/catalog/postgres_read.go) | Validam filtros, permissões editoriais e retirada antes de responder |

O catálogo tem processo e base próprios; o Flutter continua falando com a API principal. `mode=consultation` não autoriza prática: consultar nome, origem ou versão de um movimento não libera programa, dose, instrução ou mídia.

Para acompanhar sem executar: encontre `list()` no repository, copie o método e a rota, procure o registro da rota em Go e siga o leitor até o SQL. Compare os campos devolvidos com `CatalogEntry.fromJson`. Depois veja como o controller entrega a lista à tela.

## Exemplo 2: confirmar uma configuração de treino

Aqui existe uma escrita privada: a pessoa revisa o que informou e confirma. A configuração não é uma prescrição de treino.

| Etapa | Arquivo ou pasta | Responsabilidade |
|---|---|---|
| Campos e revisão | [`training_configuration_page.dart`](../../lib/features/training_configuration/presentation/training_configuration_page.dart) e [`training_configuration_sections.dart`](../../lib/features/training_configuration/presentation/training_configuration_sections.dart) | Apresentar etapas, dados, disponibilidade e revisão |
| Coordenação | [`training_configuration_controller.dart`](../../lib/features/training_configuration/presentation/training_configuration_controller.dart) | Gerenciar rascunho, envio, resposta incerta e contexto da conta |
| Comunicação | [`training_configuration_repository.dart`](../../lib/features/training_configuration/data/training_configuration_repository.dart) | Consultar com GET e salvar com `PUT /api/v1/me/training-configuration`; incluir chave de idempotência |
| Entrada e regras Go | [`trainingconfig/handler.go`](../../services/api/internal/trainingconfig/handler.go), [`service.go`](../../services/api/internal/trainingconfig/service.go) e [`model.go`](../../services/api/internal/trainingconfig/model.go) | Autorizar, validar campos/revisão e aplicar as regras da configuração |
| Persistência | [`trainingconfig/postgres.go`](../../services/api/internal/trainingconfig/postgres.go) | Revalidar a credencial viva e guardar/consultar versões em transação |

A revisão esperada evita salvar por cima de uma mudança que o cliente ainda não viu. A chave de idempotência identifica uma intenção de escrita: reenviar a mesma intenção não deve criar outra confirmação. Se a resposta se perder, não significa que o banco recusou a gravação. O cliente precisa reconciliar o resultado antes de inventar uma nova tentativa.

Os dados confirmados já existentes pertencem à pessoa. Ler o fluxo não exige criar outra revisão, mudar horários ou usar a conta real como massa de teste.

## Exemplo 3: acompanhar uma sessão na aba Atividade

A implementação de execução está presente, mas o lote entregue ainda não tem programa próprio, instruções e doses aprovados para prática. A lista real pode estar vazia. O exemplo abaixo explica o código; não é um roteiro para fabricar uma ocorrência.

1. [`ActivityPage`](../../lib/features/activity/presentation/activity_page.dart) usa o [`ActivityController`](../../lib/features/activity/presentation/activity_controller.dart) e apresenta lista, sessão, pausa e encerramento na mesma superfície.
2. [`GoActivityRepository`](../../lib/features/activity/data/activity_repository.dart) consulta `GET /api/v1/me/activity` ou o detalhe privado. Iniciar usa `POST /api/v1/me/activity-sessions`; comandos usam `POST /api/v1/me/activity-sessions/{id}/commands`.
3. [`activity/handler.go`](../../services/api/internal/activity/handler.go) valida o contrato e a identidade. [`service.go`](../../services/api/internal/activity/service.go) define a fronteira do serviço; [`session.go`](../../services/api/internal/activity/session.go) aplica as transições do agregado sem depender do HTTP.
4. [`activity/postgres.go`](../../services/api/internal/activity/postgres.go) revalida conta, credencial, ocorrência e disponibilidade editorial. Persiste sessão, eventos e idempotência nas tabelas existentes.
5. O servidor devolve snapshot e revisão. O Flutter confere titular, identidade e fatos confirmados antes de atualizar a tela; uma resposta atrasada não deve substituir estado mais recente.

Alvo prescrito e resultado informado são dados diferentes. Campos realizados começam vazios; zero informado não é ausência. Pausar, voltar à lista, trocar aba e fechar um timer não concluem a sessão. Conclusão, parcial e cancelamento exigem confirmação.

Uma escrita incerta conserva corpo, revisão e chave somente na memória do processo Flutter. Há persistência dos fatos confirmados no servidor, mas ainda não existe fila offline durável de intenções; matar o processo perde uma intenção não confirmada. As condições e verificações estão na [implementação da atividade](../execucao/v1/implementacao.md#atividade).

## Como escolher o lugar de uma mudança

| O que mudou? | Onde começar | O que precisa continuar coerente |
|---|---|---|
| Texto, alinhamento ou interação visual | Tela, widgets e recursos de idioma | Foco, teclado, texto ampliado, estados e acessibilidade |
| Carregamento, troca de conta ou resposta tardia | Controller e composição | Identidade, descarte de estado e ordens das respostas |
| Campos da mensagem HTTP | Repository, DTO e handler | Contrato cliente/servidor e Swagger derivado |
| Regra de negócio | Domínio/serviço Go | Invariantes e resultados observáveis |
| Consulta ou gravação | Repository/SQL Go | Titularidade, transação, índices e privilégios |
| Estrutura do banco | Migration adequada ao núcleo ou catálogo | Um dono do schema e atualização dos mapas afetados |

Não é necessário alterar todas as camadas em qualquer tarefa. Siga a ação afetada e confira as fronteiras que ela realmente atravessa. [Peças e vocabulário](pecas-do-projeto.md) explicam os nomes; [arquitetura](../arquitetura/camadas-e-fluxos.md) concentra o mapa técnico.
