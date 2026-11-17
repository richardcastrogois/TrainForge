# TrainForge

Aplicativo Flutter para Android e iOS, com conteúdo rastreável e dados reais. Primeiro ambiente de avaliação:Android local. Backend Go e PostgreSQL já implementados; catálogo separado em serviço/base próprios. Não há programa de treino liberado para prática.

## Comece aqui

- [Aprender cada peça](docs/aprendizado/README.md)
- [Iniciar, ver logs e parar](docs/aprendizado/operacao-local.md)
- [15 diagramas visuais e editáveis](docs/diagramas/README.md)
- [Backend, tabelas e contratos](documentacao-tecnica.md)
- [Estado atual e próxima história](docs/execucao/v1/handoff.md)
- [Requisitos e backlog](docs/execucao/v1/backlog.md)
- [Avaliação do MoveKit](docs/conteudo/avaliacao-movekit-2026-10-29.md)

## Estado

API 0.10.0/38 operações; catálogo 0.2.0; núcleo schema 13/30 tabelas e catálogo schema 2/4 tabelas. Execução ganhou persistência/API e uma tela na aba Atividade. Conteúdo próprio, adesão/agenda e aceite real de treino continuam pendentes; fotos, offline e demais jornadas mantêm seus critérios. [Entrega e limites](docs/execucao/v1/execucao-treino-017.md).

SomenteAndroid/iOS continuam como plataformasFlutter do produto. Dados, chaves e ferramentas locais ficam ignorados no Git. Push não é deploy. Sem contratação ou hospedagem autorizada nesta etapa.

## Anotações do projeto

- [/tolls]: Guarda scripts que automatizam tarefas do projeto, como iniciar o ambiente, preparar o aplicativo, executar testes e atualizar a documentação.

- [/test]: Guarda testes automatizados que verificam se as telas e as regras do aplicativo funcionam como esperado e continuam funcionando após mudanças no código. (apenas do frontend já que o backend fica dentro de suas pastas junta).

- [/services]: Guarda os serviços do backend que recebem pedidos do aplicativo, aplicam as regras do sistema e acessam o banco de dados.
- [/services/api/]: Reúne o código Go, os testes e a configuração do backend.
- [/services/api/cmd/]: Guarda os pontos de entrada dos programas: iniciar servidores, importar dados e executar manutenção.
- [/services/api/internal/]: Guarda a implementação das regras e dos recursos internos do backend.
- [/services/api/migrations/]: Guarda scripts SQL que criam e alteram a estrutura do banco principal de forma versionada.

- [/services/api/cmd/api/]: Inicia a API principal que atende o aplicativo.
- [/services/api/cmd/catalog/]: Inicia o servidor do catálogo separado.
- [/services/api/cmd/migrate/]: Executa as alterações versionadas do banco principal.
- [/services/api/cmd/catalog-migrate/]: Executa as alterações versionadas do banco do catálogo.
- [/services/api/cmd/catalog-release/]: Consulta, exporta e publica versões de conteúdo editorial do catálogo.
- [/services/api/cmd/catalog-transition/]: Prepara e verifica a cópia de leitura usada na transição do catálogo.
- [/services/api/cmd/import-content/]: Importa conteúdo para o sistema.
- [/services/api/cmd/import-food/]: Importa referências alimentares.
- [/services/api/cmd/food-names/]: Executa operações de revisão e publicação de nomes alimentares.
- [/services/api/cmd/privacy-maintenance/]: Executa tarefas de manutenção relacionadas à privacidade e exclusão de dados.
- [/services/api/cmd/privacy-restore/]: Aplica exclusões de privacidade em uma base restaurada de backup.

- [/services/api/internal/activity/]: Implementa regras de sessões e eventos de execução de atividades; não significa que o treino completo já esteja liberado.
- [/services/api/internal/auth/]: Cuida da autenticação, da identidade do usuário e das sessões de acesso.
- [/services/api/internal/catalog/]: Implementa consultas e importação de dados do catálogo.
- [/services/api/internal/catalogauthority/]: Controla versões e publicação do conteúdo editorial do catálogo.
- [/services/api/internal/catalogbridge/]: Faz a comunicação da API principal com o serviço de catálogo.
- [/services/api/internal/catalogruntime/]: Implementa o funcionamento e as verificações do servidor de catálogo.
- [/services/api/internal/catalogschema/]: Guarda a estrutura SQL e as migrations próprias do catálogo.
- [/services/api/internal/catalogtarget/]: Verifica se as operações do catálogo apontam para um banco permitido e isolado.
- [/services/api/internal/foodnamesops/]: Implementa operações administrativas dos nomes alimentares.
- [/services/api/internal/nutrition/]: Cuida de alimentos, refeições, consumo e informações nutricionais.
- [/services/api/internal/platform/]: Reúne recursos técnicos compartilhados, como configuração, servidor HTTP e conexão com o banco.
- [/services/api/internal/privacy/]: Implementa regras de privacidade, exportação e exclusão de dados.
- [/services/api/internal/swaggerdocs/]: Guarda a documentação gerada dos endpoints da API.
- [/services/api/internal/trainingconfig/]: Cuida das configurações de treino do usuário.

- [/services/api/internal/platform/config/]: Lê e valida as configurações do backend.
- [/services/api/internal/platform/httpapi/]: Organiza o servidor HTTP, as rotas e os controles comuns das requisições.
- [/services/api/internal/platform/postgres/]: Gerencia conexões e verificações de disponibilidade do PostgreSQL.

- [/lib/]: Guarda o código do aplicativo Flutter, incluindo telas, regras locais e comunicação com o backend.
- [/lib/main.dart]: É o ponto de entrada que inicia o aplicativo.
- [/lib/app.dart]: Monta o aplicativo e conecta configurações globais, como tema, idioma e dependências.

- [/lib/composition/]: Cria e conecta os componentes usados pelo aplicativo, como clientes da API e repositórios.
- [/lib/core/]: Reúne recursos técnicos comuns usados em diferentes partes do aplicativo.
- [/lib/features/]: Organiza o código por funcionalidade, como autenticação, alimentação e privacidade.
- [/lib/graphify-out/]: Guarda artefatos da análise de relações do código; não implementa funcionalidades do aplicativo.
- [/lib/l10n/]: Guarda os textos traduzidos e os recursos de idiomas do aplicativo.
- [/lib/l10n/generated/]: Guarda o código gerado automaticamente a partir dos arquivos de tradução.
- [/lib/shared/]: Reúne componentes de interface compartilhados entre funcionalidades.
- [/lib/shared/widgets/]: Guarda componentes e telas comuns, como navegação, carregamento e estrutura principal do aplicativo.
- [/lib/shared/theme/]: Está vazia atualmente; o tema implementado fica em lib/core/theme/.

- [/lib/core/config/]: Guarda configurações do aplicativo, como o endereço da API.
- [/lib/core/constants/]: Está vazia atualmente.
- [/lib/core/http/]: Configura a comunicação HTTP do aplicativo com o backend.
- [/lib/core/l10n/]: Controla o idioma escolhido e auxilia a apresentação de mensagens traduzidas.
- [/lib/core/log/]: Centraliza o registro de mensagens e erros para diagnóstico.
- [/lib/core/motion/]: Define comportamentos de animação e movimento do aplicativo.
- [/lib/core/preferences/]: Guarda recursos de diagnóstico da leitura de preferências.
- [/lib/core/scroll/]: Padroniza o comportamento de rolagem das telas.
- [/lib/core/theme/]: Define cores, tema e controle de aparência do aplicativo.
- [/lib/core/utils/]: Está vazia atualmente.

- [/lib/features/activity/]: Guarda telas, acesso a dados e regras relacionadas às atividades e sessões de treino em desenvolvimento.
- [/lib/features/auth/]: Cuida do login, dos dados de autenticação e da sessão do usuário.
- [/lib/features/bootstrap/]: Está vazia atualmente.
- [/lib/features/catalog/]: Implementa a consulta e a apresentação do catálogo de movimentos.
- [/lib/features/food_reference/]: Implementa a consulta e os detalhes das referências alimentares.
- [/lib/features/home/]: Guarda a tela Hoje, usada como visão inicial do aplicativo.
- [/lib/features/nutrition/]: Implementa telas e regras locais de alimentos, refeições, consumo e informações nutricionais.
- [/lib/features/onboarding/]: Está vazia atualmente.
- [/lib/features/privacy/]: Implementa a interface e a comunicação com os recursos de privacidade da conta.
- [/lib/features/profile/]: Está vazia atualmente; isso não significa que o aplicativo não tenha recursos de conta.
- [/lib/features/stats/]: Está vazia atualmente.
- [/lib/features/training_configuration/]: Implementa as telas, regras e comunicação das configurações de treino.
- [/lib/features/workouts/]: Está vazia atualmente.

- [/ios/]: Guarda o projeto nativo e as configurações necessárias para compilar e executar o aplicativo no iOS.
- [/ios/Flutter/]: Guarda configurações de integração e compilação do Flutter para iOS.
- [/ios/Runner/]: Guarda o código nativo, as configurações, os ícones e os recursos do aplicativo iOS.
- [/ios/Runner.xcodeproj/]: Guarda a definição do projeto no Xcode, incluindo arquivos, configurações e etapas de compilação.
- [/ios/Runner.xcworkspace/]: Organiza o projeto e suas integrações para abertura no Xcode.
- [/ios/RunnerTests/]: Guarda testes nativos da parte iOS do aplicativo.

- [/contracts/]: Guarda as especificações que descrevem como os clientes podem se comunicar com as APIs do backend.
- [/contracts/generated/]: Guarda os contratos das APIs gerados automaticamente a partir do código, nos formatos JSON e YAML.

- [/graphify-out/]: Guarda mapas e índices gerados das relações do código para facilitar consultas e orientar investigações no projeto.

- [/content/]: Guarda arquivos de preparação de conteúdo e registros de origem, revisão, aprovação e direitos de uso.
- [/content/local/]: Guarda conteúdo preparado e dados de importação locais, ignorados pelo Git; não representa aprovação automática para uso no aplicativo.
- [/content/manifests/]: Guarda inventários e decisões que identificam o conteúdo, sua origem e o que foi revisado ou aprovado.
- [/content/schemas/]: Guarda regras de estrutura usadas para validar os arquivos de conteúdo.

- [/build/]: Guarda arquivos gerados por compilações e testes, incluindo APKs e caches; pode ser apagada e recriada pelas ferramentas.

- [/assets/]: Guarda recursos visuais e fontes usados pelo aplicativo e por ferramentas de geração.
- [/assets/brand/]: Guarda a imagem de identidade usada pela ferramenta que gera os ícones nativos.
- [/assets/figma/]: Guarda ícones e ilustrações SVG usados nas telas do aplicativo.
- [/assets/fonts/]: Guarda as fontes Inter, sua licença e informações de origem.

- [/android/]: Guarda o código nativo e as configurações necessárias para compilar e executar o aplicativo no Android.
- [/android/app/]: Guarda o módulo Android do aplicativo, com configurações de compilação e código nativo.
- [/android/app/src/]: Organiza o código e os recursos por modo de execução.
- [/android/app/src/main/]: Guarda o código, as configurações e os recursos comuns do aplicativo Android.
- [/android/app/src/main/kotlin/]: Guarda o código Kotlin que conecta o Flutter aos recursos nativos do Android.
- [/android/app/src/main/java/]: Guarda código Java de integração, incluindo o registro gerado dos plugins Flutter.
- [/android/app/src/main/res/]: Guarda ícones, imagens de abertura, estilos e regras de backup do Android.
- [/android/app/src/debug/]: Guarda configurações específicas do modo de desenvolvimento.
- [/android/app/src/profile/]: Guarda configurações específicas do modo de análise de desempenho.
- [/android/gradle/]: Guarda arquivos que permitem executar a versão de Gradle definida pelo projeto.
- [/android/.gradle/]: Guarda caches locais do Gradle que podem ser recriados.
- [/android/.kotlin/]: Guarda arquivos temporários e de sessão das ferramentas Kotlin.
