# O que cada peça faz e onde encontro o código

Meu mapa pessoal do TrainForge. As 100 entradas que anotei no README principal foram trazidas para cá e conferidas no checkout. `tolls` foi corrigido para `tools/`; as pastas antigas ausentes estão identificadas, sem recriá-las para combinar com a anotação. Os nomes descrevem responsabilidades, não garantem que uma funcionalidade inteira esteja pronta.

## A visão das peças

| Peça | Para que serve | O que não devo confundir |
|---|---|---|
| Flutter e Dart | Interface móvel, estado de tela, navegação e comunicação HTTP | A tela não acessa PostgreSQL diretamente |
| API Go | Receber requisições, autorizar, aplicar regras e responder JSON | Endpoint existente não libera conteúdo para prática |
| Catálogo Go separado | Servir versões editoriais rastreáveis por contrato próprio | Cada pasta do núcleo não é outro microserviço |
| PostgreSQL | Preservar dados, relações, revisões e transações | Tabela não chama outra tabela por HTTP |
| Python | Automatizar operação, geração e verificações locais | Helpers não atendem as rotas de negócio |
| Android/iOS | Integração nativa, permissões e compilação de cada plataforma | iOS preparado no código ainda exige macOS/Xcode e validação nativa |

O [fluxo de uma ação](fluxo-de-uma-acao.md) mostra quem chama quem usando três exemplos reais. Os [diagramas](../arquitetura/diagramas/README.md) complementam o texto.

## Ferramentas que uso

| Ferramenta | Papel no projeto |
|---|---|
| Android SDK e ADB | Compilar, instalar, conversar com o dispositivo e acompanhar logs |
| Emulador e AVD | Android virtual; o AVD define configuração e dados próprios |
| Go | Compilar API, catálogo e programas administrativos |
| pgx/pgxpool | Driver SQL e conjunto de conexões reutilizáveis para PostgreSQL |
| Goose | Aplicar migrations SQL versionadas; não é comando de iniciar o ambiente |
| Swagger/Swaggo | Gerar contrato e documentação HTTP de comentários/DTOs Go |
| Git/GitHub | Histórico, revisão e repositório remoto; push não é deploy |
| GitHub Actions | Executar checks em CI; não hospeda o app |
| Graphify | Navegar nas relações do corpus de código analisado; não comprova execução ou direitos de conteúdo |
| draw.io e SVG | Editar e ler os mapas visuais; não fazem parte do APK |
| Figma | Projetar e revisar telas/estados; protótipo não autentica nem grava dados |

## Banco e persistência

O backend atual usa **pgx/v5 e pgxpool com SQL parametrizado**. Valores entram em parâmetros como `$1` e `$2`; não por concatenação de dados da pessoa. Goose controla a sequência de migrations. Um exemplo para estudar é [`auth/postgres.go`](../../services/api/internal/auth/postgres.go), que agrupa identidade e sessão em transação. Outro é [`trainingconfig/postgres.go`](../../services/api/internal/trainingconfig/postgres.go), que preserva revisões da configuração.

Não há GORM, Ent ou sqlc no runtime Go atual. Goose é o único dono das migrations: um mesmo schema precisa de um dono claro.

A comparação abaixo conserva o estudo registrado em 29/10/2026; nenhuma alternativa foi instalada ou escolhida para substituir pgx nesta revisão documental.

| Caminho estudado | Benefício | Custo ou limite |
|---|---|---|
| pgx atual | SQL visível e controle de transações/privilégios | Mapeamento manual e testes necessários |
| sqlc + pgx | Gerar métodos e tipos Go a partir de SQL | Não é ORM; precisa de prova com as queries/funções reais |
| GORM | ORM Go com convenções de CRUD e associações | Novo mapeamento; `AutoMigrate` não deve alterar o schema crítico existente por inferência |
| Ent | Schema Go e código tipado gerado | Introduz outro modelo/geração e exige desenho de migrations/coexistência |

Referências já usadas no estudo: [sqlc/pgx](https://docs.sqlc.dev/en/latest/guides/using-go-and-pgx.html), [GORM](https://gorm.io/docs/) e [Ent](https://entgo.io/docs/getting-started/).

Para decidir uma troca, primeiro identifique uma dificuldade concreta em uma operação real. ORM ou ausência de ORM não garantem performance e segurança: continuam necessários parâmetros, titularidade, privilégios, transações, índices, testes e medição.

## Mapa detalhado das minhas anotações

Os caminhos abaixo preservam os assuntos do bloco original. Arquivos gerados, caches e diretórios privados aparecem para eu saber para que servem, não como sugestão de apagar ou publicar seu conteúdo.

### Ferramentas e testes

- `tools/`: Guarda scripts que automatizam tarefas do projeto, como iniciar o ambiente, preparar o aplicativo, executar testes e atualizar a documentação.
- `test/`: Guarda testes Dart do aplicativo, incluindo regras, controllers, contratos e widgets. Os testes Go ficam nos pacotes do backend (`*_test.go`); os testes das ferramentas Python ficam em `tools/test_*.py`.

### Backend Go

- `services`: Guarda os serviços do backend que recebem pedidos do aplicativo, aplicam as regras do sistema e acessam o banco de dados.
- `services/api/`: Reúne o código Go, os testes e a configuração do backend.
- `services/api/cmd/`: Guarda os pontos de entrada dos programas: iniciar servidores, importar dados e executar manutenção.
- `services/api/internal/`: Guarda a implementação das regras e dos recursos internos do backend.
- `services/api/migrations/`: Guarda scripts SQL que criam e alteram a estrutura do banco principal de forma versionada.
- `services/api/cmd/api/`: Inicia a API principal que atende o aplicativo.
- `services/api/cmd/catalog/`: Inicia o servidor do catálogo separado.
- `services/api/cmd/migrate/`: Executa as alterações versionadas do banco principal.
- `services/api/cmd/catalog-migrate/`: Executa as alterações versionadas do banco do catálogo.
- `services/api/cmd/catalog-release/`: Consulta, exporta e publica versões de conteúdo editorial do catálogo.
- `services/api/cmd/catalog-transition/`: Prepara e verifica a cópia de leitura usada na transição do catálogo.
- `services/api/cmd/import-content/`: Importa conteúdo para o sistema.
- `services/api/cmd/import-food/`: Importa referências alimentares.
- `services/api/cmd/food-names/`: Executa operações de revisão e publicação de nomes alimentares.
- `services/api/cmd/privacy-maintenance/`: Executa tarefas de manutenção relacionadas à privacidade e exclusão de dados.
- `services/api/cmd/privacy-restore/`: Aplica exclusões de privacidade em uma base restaurada de backup.
- `services/api/internal/activity/`: Implementa regras de sessões e eventos de execução de atividades; não significa que o treino completo já esteja liberado.
- `services/api/internal/auth/`: Cuida da autenticação, da identidade do usuário e das sessões de acesso.
- `services/api/internal/catalog/`: Implementa consultas e importação de dados do catálogo.
- `services/api/internal/catalogauthority/`: Controla versões e publicação do conteúdo editorial do catálogo.
- `services/api/internal/catalogbridge/`: Faz a comunicação da API principal com o serviço de catálogo.
- `services/api/internal/catalogruntime/`: Implementa o funcionamento e as verificações do servidor de catálogo.
- `services/api/internal/catalogschema/`: Guarda a estrutura SQL e as migrations próprias do catálogo.
- `services/api/internal/catalogtarget/`: Verifica se as operações do catálogo apontam para um banco permitido e isolado.
- `services/api/internal/foodnamesops/`: Implementa operações administrativas dos nomes alimentares.
- `services/api/internal/nutrition/`: Cuida de alimentos, refeições, consumo e informações nutricionais.
- `services/api/internal/platform/`: Reúne recursos técnicos compartilhados, como configuração, servidor HTTP e conexão com o banco.
- `services/api/internal/privacy/`: Implementa regras de privacidade, exportação e exclusão de dados.
- `services/api/internal/swaggerdocs/`: Guarda a documentação gerada dos endpoints da API.
- `services/api/internal/trainingconfig/`: Cuida das configurações de treino do usuário.
- `services/api/internal/platform/config/`: Lê e valida as configurações do backend.
- `services/api/internal/platform/httpapi/`: Organiza o servidor HTTP, as rotas e os controles comuns das requisições.
- `services/api/internal/platform/postgres/`: Gerencia conexões e verificações de disponibilidade do PostgreSQL.

### Aplicativo Flutter

- `lib/`: Guarda o código do aplicativo Flutter, incluindo telas, regras locais e comunicação com o backend.
- `lib/main.dart`: É o ponto de entrada que inicia o aplicativo.
- `lib/app.dart`: Monta o aplicativo e conecta configurações globais, como tema, idioma e dependências.
- `lib/composition/`: Cria e conecta os componentes usados pelo aplicativo, como clientes da API e repositórios.
- `lib/core/`: Reúne recursos técnicos comuns usados em diferentes partes do aplicativo.
- `lib/features/`: Organiza o código por funcionalidade, como autenticação, alimentação e privacidade.
- `lib/graphify-out/`: Guarda artefatos locais de análise do código quando presentes; não implementa funcionalidades do aplicativo. O mapa versionado de referência do checkout fica em `graphify-out/` na raiz.
- `lib/l10n/`: Guarda os textos traduzidos e os recursos de idiomas do aplicativo.
- `lib/l10n/generated/`: Guarda o código gerado automaticamente a partir dos arquivos de tradução.
- `lib/shared/`: Reúne componentes de interface compartilhados entre funcionalidades.
- `lib/shared/widgets/`: Guarda componentes e telas comuns, como navegação, carregamento e estrutura principal do aplicativo.
- `lib/shared/theme/`: Pasta citada nas primeiras anotações, ausente no checkout atual. O tema implementado fica em `lib/core/theme/`.
- `lib/core/config/`: Guarda configurações do aplicativo, como o endereço da API.
- `lib/core/constants/`: Pasta citada nas primeiras anotações, ausente no checkout atual; não é necessária apenas para manter o nome da estrutura antiga.
- `lib/core/http/`: Configura a comunicação HTTP do aplicativo com o backend.
- `lib/core/l10n/`: Controla o idioma escolhido e auxilia a apresentação de mensagens traduzidas.
- `lib/core/log/`: Centraliza o registro de mensagens e erros para diagnóstico.
- `lib/core/motion/`: Define comportamentos de animação e movimento do aplicativo.
- `lib/core/preferences/`: Guarda recursos de diagnóstico da leitura de preferências.
- `lib/core/scroll/`: Padroniza o comportamento de rolagem das telas.
- `lib/core/theme/`: Define cores, tema e controle de aparência do aplicativo.
- `lib/core/utils/`: Pasta citada nas primeiras anotações, ausente no checkout atual; utilitários devem permanecer próximos do uso quando não houver compartilhamento real.
- `lib/features/activity/`: Guarda telas, acesso a dados e regras relacionadas às atividades e sessões de treino em desenvolvimento.
- `lib/features/auth/`: Cuida do login, dos dados de autenticação e da sessão do usuário.
- `lib/features/bootstrap/`: Pasta citada nas primeiras anotações, ausente no checkout atual. A inicialização existente está em `main.dart`, `app.dart`, composição e widgets de abertura.
- `lib/features/catalog/`: Implementa a consulta e a apresentação do catálogo de movimentos.
- `lib/features/food_reference/`: Implementa a consulta e os detalhes das referências alimentares.
- `lib/features/home/`: Guarda a tela Hoje, usada como visão inicial do aplicativo.
- `lib/features/nutrition/`: Implementa telas e regras locais de alimentos, refeições, consumo e informações nutricionais.
- `lib/features/onboarding/`: Pasta citada nas primeiras anotações, ausente no checkout atual; o nome antigo não comprova uma jornada de primeiro uso pronta.
- `lib/features/privacy/`: Implementa a interface e a comunicação com os recursos de privacidade da conta.
- `lib/features/profile/`: Pasta citada nas primeiras anotações, ausente no checkout atual. Recursos de conta existem em autenticação, privacidade e no shell; ausência desta pasta não significa ausência de conta.
- `lib/features/stats/`: Pasta citada nas primeiras anotações, ausente no checkout atual; não representa um módulo estatístico entregue.
- `lib/features/training_configuration/`: Implementa as telas, regras e comunicação das configurações de treino.
- `lib/features/workouts/`: Pasta citada nas primeiras anotações, ausente no checkout atual. A execução existente está em `features/activity/`; configuração e catálogo têm módulos próprios.

### Projeto nativo iOS

- `ios/`: Guarda o projeto nativo e as configurações necessárias para compilar e executar o aplicativo no iOS.
- `ios/Flutter/`: Guarda configurações de integração e compilação do Flutter para iOS.
- `ios/Runner/`: Guarda o código nativo, as configurações, os ícones e os recursos do aplicativo iOS.
- `ios/Runner.xcodeproj/`: Guarda a definição do projeto no Xcode, incluindo arquivos, configurações e etapas de compilação.
- `ios/Runner.xcworkspace/`: Organiza o projeto e suas integrações para abertura no Xcode.
- `ios/RunnerTests/`: Guarda testes nativos da parte iOS do aplicativo.

### Contratos e mapas de código

- `contracts/`: Guarda as especificações que descrevem como os clientes podem se comunicar com as APIs do backend.
- `contracts/generated/`: Guarda os contratos das APIs gerados automaticamente a partir do código, nos formatos JSON e YAML.
- `graphify-out/`: Guarda mapas e índices gerados das relações do código para facilitar consultas e orientar investigações no projeto.

### Conteúdo rastreável

- `content/`: Guarda arquivos de preparação de conteúdo e registros de origem, revisão, aprovação e direitos de uso.
- `content/local/`: Guarda conteúdo preparado e dados de importação locais, ignorados pelo Git; não representa aprovação automática para uso no aplicativo.
- `content/manifests/`: Guarda inventários e decisões que identificam o conteúdo, sua origem e o que foi revisado ou aprovado.
- `content/schemas/`: Guarda regras de estrutura usadas para validar os arquivos de conteúdo.

### Arquivos de compilação

- `build/`: Guarda arquivos gerados por compilações e testes, incluindo APKs e caches. As ferramentas podem recriá-los; APKs usados como checkpoint precisam de versão, hash e assinatura antes de qualquer limpeza.

### Recursos do aplicativo

- `assets/`: Guarda recursos visuais e fontes usados pelo aplicativo e por ferramentas de geração.
- `assets/brand/`: Guarda a imagem de identidade usada pela ferramenta que gera os ícones nativos.
- `assets/figma/`: Guarda ícones e ilustrações SVG usados nas telas do aplicativo.
- `assets/fonts/`: Guarda as fontes Inter, sua licença e informações de origem.

### Projeto nativo Android

- `android/`: Guarda o código nativo e as configurações necessárias para compilar e executar o aplicativo no Android.
- `android/app/`: Guarda o módulo Android do aplicativo, com configurações de compilação e código nativo.
- `android/app/src/`: Organiza o código e os recursos por modo de execução.
- `android/app/src/main/`: Guarda o código, as configurações e os recursos comuns do aplicativo Android.
- `android/app/src/main/kotlin/`: Guarda o código Kotlin que conecta o Flutter aos recursos nativos do Android.
- `android/app/src/main/java/`: Guarda código Java de integração, incluindo o registro gerado dos plugins Flutter.
- `android/app/src/main/res/`: Guarda ícones, imagens de abertura, estilos e regras de backup do Android.
- `android/app/src/debug/`: Guarda configurações específicas do modo de desenvolvimento.
- `android/app/src/profile/`: Guarda configurações específicas do modo de análise de desempenho.
- `android/gradle/`: Guarda arquivos que permitem executar a versão de Gradle definida pelo projeto.
- `android/.gradle/`: Guarda caches locais do Gradle que podem ser recriados.
- `android/.kotlin/`: Guarda arquivos temporários e de sessão das ferramentas Kotlin.

## Pastas que não estavam na anotação original

| Caminho | O que encontro |
|---|---|
| `docs/aprendizado/` | Este percurso pessoal: peças, fluxo, operação e apresentação |
| `docs/arquitetura/` | Explicação técnica, contratos, decisões, manutenção e diagramas |
| `docs/execucao/v1/` | Handoff, backlog e evidências para retomar o trabalho |
| `docs/conteudo/` | Pesquisa, direitos, evidências, licenças e limites de adoção |
| `docs/design/` | Referências visuais históricas e os SVGs preservados para apresentação |
| `docs/apresentacao-senas/` | Material SeNAS preservado, com seus arquivos e dependências próprios |
| `docs/historico/` | Linha do tempo dos checkpoints anteriores |
| `.github/` | Workflows de validação remota |
| `.local/` | Bancos, credenciais, assinatura, logs, capturas e backups privados deste computador |
| `.tools/` | Ferramentas e caches já provisionados para o projeto |
| `.dart_tool/` | Metadados e cache das ferramentas Flutter/Dart |
| `.research-runtime/` | Ferramentas locais de pesquisa anterior; não é backend |
| `.idea/` e `*.iml` | Preferências locais da IDE |

Arquivos de configuração importantes: `pubspec.yaml` e `pubspec.lock` descrevem/resolvem dependências Flutter; `services/api/go.mod` e `go.sum` registram módulos Go; `l10n.yaml` controla geração de idiomas; `.metadata` registra as plataformas Flutter; `AGENTS.md` orienta agentes e não é executado pelo produto.

Linux/macOS/Windows/web eram destinos adicionais do scaffold Flutter removido; Android/iOS continuam como produto. Um Mac necessário para compilar iOS é diferente de configurar macOS como plataforma de destino. Dependências transitivas web/desktop nos lockfiles não recriam esses destinos e não devem ser removidas manualmente só para esconder seus nomes.

## Vocabulário para ler uma operação

| Termo | Como eu explico |
|---|---|
| API / endpoint | Contrato de comunicação / combinação de método e endereço |
| JSON / DTO | Formato da mensagem / descrição dos seus campos |
| Controller | Coordena o estado da interface e as ações assíncronas |
| Repository | Fronteira de acesso a dados ou integração |
| Handler | Recebe HTTP, valida o contrato e chama as regras adequadas |
| Migration / importador | Evolução de estrutura / entrada de conteúdo rastreável; são operações diferentes |
| Cluster / banco / schema | Instalação PostgreSQL / base lógica / agrupamento de objetos |
| PK / FK / JOIN | Identificador da linha / referência protegida / combinação de resultados |
| Transação / rollback | Operações que confirmam juntas / desfazer a transação |
| Revisão / idempotência | Detectar estado desatualizado / reconhecer o reenvio da mesma intenção |
| Cache / backup | Cópia temporária / cópia de recuperação que precisa de restauração validada |
| Token Google / sessão TrainForge | Comprovação externa de identidade / credenciais próprias de acesso ao nosso sistema |
| Microserviço | Processo com responsabilidade, contrato e operação próprios; o catálogo é o exemplo já separado |

Para iniciar, acompanhar logs e parar, use [Operação local](operacao-local.md). Não publique credenciais ou logs integrais ao pedir ajuda; descreva a ação, o horário, a mensagem curta e o `requestId`, quando houver.
