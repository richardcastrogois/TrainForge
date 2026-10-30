# O que cada peça faz

## O caminho de uma ação

Pessoa toca na tela → controller coordena o estado → repository chama a API → handlerGo valida a entrada → caso de uso aplica regras → PostgreSQL guarda/consulta → JSON volta → tela atualiza. A tela não conecta diretamente ao banco. Tabelas não fazem chamadasHTTP: chaves estrangeiras protegem relações; queries e funções executam as operações.

## Ferramentas

| Nome | O que é / por que está aqui | Necessário para quê? |
|---|---|---|
| Flutter/Dart | Interface e código do aplicativo | Compilar/executarAndroid e futuramente iOS |
| AndroidSDK/ADB | Compila, instala e conversa comAndroid | Emulador/celular, autorizaçãoUSB, logs |
| Emulador/AVD | UmAndroid virtual; AVD é sua configuração/dados | Testar sem celular físico |
| Go | Compila os executáveis do backend | API, catálogo e ferramentas administrativas |
| PostgreSQL | Servidor relacional de dados persistentes | Conta, alimentos, registros e versões |
| pgx/pgxpool | DriverGo e conjunto de conexões reutilizáveis | ExecutarSQL; não é ORM |
| Goose | Controla sequência de migrationsSQL | Evoluir schema; não inicia treino nem cria dados reais automaticamente |
| Swagger/swag | Gera contrato e página de consulta a partir de comentários/DTOs | Entender/testarHTTP; não é um segundo backend |
| Python | Automatiza tarefas locais e documentação | Helpers; não atende as rotas de negócio |
| Git/GitHub | Histórico local/remoto e revisão | Recuperar versões; push não é deploy |
| GitHubActions | Executa verificações em máquinas deCI | Testes isolados; não é hospedagem do app |
| Graphify | Grafo estrutural do código | Navegação técnica; não prova execução/direitos |
| draw.io/SVG | Diagramas editáveis e imagens vetoriais | Aprender os fluxos; não fazem parte do APK |
| Prisma | ORM do backend antigoNode/TypeScript | Não é dependência do Go atual |

## Pastas e arquivos

| Caminho | Função | Tratamento |
|---|---|---|
| lib/ | CódigoFlutter ativo, por funcionalidade e camadas comuns | Fonte do APK |
| lib/composition/ | Conecta implementações reais às interfaces | Evita a tela construir acesso ao banco |
| lib/core/ | HTTP, idioma, tema, motion e infraestrutura do cliente | Compartilhado |
| assets/ | ÍconesTF/Figma e fontesInter com licenças | Não apagar por parecer imagem decorativa |
| android/, ios/ | Integração nativa, permissões e build por plataforma | Ambos preservados |
| services/api/cmd/ | Pontos de entradaGo | api/catalog/migrations/importadores têm efeitos diferentes |
| services/api/internal/ | Regras, HTTP, persistência e integração entre serviços | Código do backend |
| services/api/migrations/ | Evolução numerada do schema do núcleo | Histórico necessário; não remover migrations antigas |
| contracts/generated/ | SwaggerJSON/YAML gerado | Regenerar da fonte, não editar manualmente |
| content/ | Manifestos/campos editoriais e lotes rastreáveis | Não equivale a conteúdo liberado |
| docs/conteudo/ | Direitos, evidências e limites de fornecedores | Necessário para justificar uso |
| docs/execucao/v1/ | Backlog, decisões e recibos/handoff | Necessário para retomar sem repetir |
| docs/diagramas/ | Mapas visuais públicos do sistema | Novo ponto de aprendizado |
| docs/aprendizado/ | Este percurso e operação local | Começar aqui |
| docs/design/, docs/arquivo/ | Histórico de desenho/documentação, identificado como tal | Preservar provas/referências; não usar como runtime atual |
| test/ | TestesDart; fixtures só de ensaio | Não são dados do cliente |
| tools/ | HelpersPython e verificadores | Nem todos devem ser executados todo dia |
| .github/ | PipelinesCI | Validação remota |
| graphify-out/ | Saídas estruturais versionadas e caches locais | Não é código do APK |
| .local/ | Bancos, credenciais, logs, capturas e backups deste computador | Privado e ignorado; NÃO apagar |
| .tools/ | Go/ferramentas e caches já instalados para o projeto | Não entram no APK; apagar exige baixar/recompilar |
| .dart_tool/, build/ | CacheFlutter e artefatos comoAPK | Gerados, mas preservados agora para evitar rebuild desnecessário |
| .research-runtime/ | Ferramentas locais da pesquisa anterior | Ignorado; não é backend |
| .idea/, *.iml | Preferências/arquivos daIDE | Ignorados; não são serviços |
| pubspec.yaml/lock | DependênciasFlutter e versões resolvidas | Preservarlockfile |
| go.mod/go.sum | DependênciasGo e integridade | Não são tabelas |
| .metadata | Metadados das plataformasFlutter | Alinhados aAndroid/iOS |
| AGENTS.md | Instruções de trabalho para agentes | Não é executado pelo app |
| l10n.yaml | Geração dos recursos deidioma | Idioma do aparelho é o padrão; escolha opcional |

Linux/macOS/Windows/web eram scaffolds de outras plataformasFlutter e foram removidos porque o produto definido éAndroid/iOS. macOS como plataforma de destinoFlutter é diferente do computadorMac necessário para compilar/testariOS no futuro.

## Vocabulário para aprender lendo o código

- API é o contrato de comunicação; endpoint é um endereço+método.
- JSON é o formato da mensagem; DTO descreve seus campos.
- Handler recebeHTTP; repository encapsula persistência/integração.
- Migration altera estrutura; importador adiciona conteúdo revisado.
- Schema agrupa objetos; banco é uma base lógica; cluster é a instalaçãoPostgreSQL que pode conter vários bancos.
- PK identifica a linha; FK referencia outra; JOIN combina resultados. UmaFK não chama outra tabela.
- Transação faz operações confirmarem juntas; rollback desfaz a transação.
- Idempotência impede que o mesmo reenvio confirme duas vezes.
- Cache é cópia temporária; backup é cópia de recuperação validada porrestore.
- JWT/IDtokenGoogle comprova identidade; tokens TrainForge autorizam nossa sessão. Não publicar nenhum deles.
- Microserviço é um processo com responsabilidade/contrato próprios. Hoje o catálogo foi separado; não é correto chamar todos os módulos restantes de microserviços já entregues.

Os lockfiles podem incluir implementações web/desktop transitivas de plugins multiplataforma. Isso não significa que essas plataformas de produto continuem configuradas; não remova dependências resolvidas manualmente para esconder nomes.
