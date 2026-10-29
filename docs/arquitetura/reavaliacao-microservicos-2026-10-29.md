# Reavaliar microserviços Go — 29/10/2026

**Direção escolhida pelo autor em29/10: microserviços por etapas.** O detalhamento foi aprovado; a primeira prova abaixo ainda requer delimitação/aceite antes de alterar processos, dados ou rotas da avaliação. O autor esclareceu que pretendia microserviços desde o início e continua propenso a esse rumo. A escolha Go permanece; a recomendação anterior de monólito modular deixa de representar uma decisão definitiva sobre a arquitetura de execução. O APK25, os contratos e os dados existentes são a referência de compatibilidade.

## O que existe e o que está acoplado

services/api/cmd/api/main.go compõe um processo com auth, catalog, nutrition, privacy e trainingconfig. Activity ainda não entrega execução. Há um pool e um schema PostgreSQL,13migrations/30tabelas; Go0.8.1/34operações. O Graphify existente cobre Dart; foi consultado para MealRepository, não é evidência das relações Go/SQL.

- Auth.Authorize entrega principal verificado. Escritas privadas revalidam sessão/família/token dentro de transações SQL. Não basta substituir essa fronteira por userId vindo de outro serviço ou do Flutter.
- MealStore confirma grupo, consumos, versões e replay juntos. Separar refeição e seus alimentos em serviços distintos quebraria essa atomicidade sem um protocolo adicional.
- Privacy.Postgres conhece dados privados dos módulos, coordena exportação, exclusão e proteção de restore. Em serviços com bancos próprios, precisará de coordenação com confirmação e impedimento de leitura/recriação após exclusão.
- O runtime atual tem privilégios compartilhados entre módulos. Criar vários executáveis usando o mesmo usuário e as mesmas tabelas manteria esse acoplamento.

## Comparação aplicada ao TrainForge

| Aspecto | Monólito modular atual | Microserviços com propriedade de dados |
|---|---|---|
| Execução/publicação | Um processo; módulos publicados juntos | Processos e versões publicáveis separadamente |
| Escala | Réplicas do conjunto; revisar estado local, limites e pool | Escalar cada domínio; coordenar limites, conexões e dependências |
| Refeição e consumos | Uma transação já testada | Continuam juntos no mesmo serviço alimentar; distribuição não exige separar cada tabela |
| Falhas | Menos chamadas de rede; uma falha pode afetar o processo | Isolamento potencial, condicionado a timeouts, filas e tratamento de indisponibilidade |
| Segurança | Menos fronteiras remotas; runtime compartilhado ainda deve melhorar | Identidade entre serviços, credenciais e privilégios por dono; mais fronteiras para auditar |
| Dados/privacidade | Exclusão/exportação coordenadas no banco atual | Contratos de exportação, exclusão, tombstones e restore por serviço |
| Desenvolvimento | Menor custo operacional inicial | Contratos e testes entre serviços, tracing e operação de versões coexistentes |

Publicação e escala independentes são benefícios possíveis; consistência, testes e operação distribuídos têm custo. Essa comparação segue os [benefícios e desafios descritos pela Microsoft](https://learn.microsoft.com/en-us/azure/architecture/guide/architecture-styles/microservices), sem escolher hospedagem ou Kubernetes.

## Uma proposta concreta de divisão

Dividir por capacidade de negócio, sem serviço para cada endpoint ou tabela. Candidatos, ainda sujeitos a validar fronteiras:

1. **Alimentação:** alimentos particulares, consumos, refeições, versões e cálculo. Um único dono preserva o commit atômico de grupo/itens. Nomes e versões externas usados no cálculo precisam de contrato/snapshot verificável, não joins no banco de outro serviço.
2. **Treinos:** configuração, adesão, composição permitida, agenda, execução e histórico; as partes ainda ausentes continuam ausentes. Conteúdo editorial aprovado é pré-requisito para prática.
3. **Catálogo editorial:** referências públicas e suas versões/direitos. Separar leitura de catálogo não autoriza prática ou mídia sem licença. Examinar consultas e dependências antes de mover tabelas.
4. **Fotos/processamento:** candidato com perfil de carga próprio. A042 ainda não existe; armazenamento, reconhecimento, consentimento e exclusão precisam ser desenhados. Não há modelo/provedor contratado ou aprovado por esta proposta.
5. **Identidade/privacidade:** contratos transversais a desenhar antes de extrair auth. A dependência atual de sessão viva nas funções SQL torna essa extração sensível. Revogação e exclusão não podem aceitar falha de rede como autorização nem prometer consistência imediata sem protocolo comprovado.

Um monorepositório pode conter esses serviços. Microserviços não exigem vários repositórios ou cloud. O ambiente de prova pode ser local, com processos Go e bancos/roles isolados. Não foi medido esforço em dias nem custo de operação; não há previsão de milhões simultâneos sustentada por carga.

## Sequência se o autor escolher migrar

Preferência técnica inicial: migração progressiva, mantendo avaliação do APK. A [AWS descreve extração gradual e seus riscos](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/strangler-fig.html); isso não obriga usar serviços AWS.

1. Aprovar limites, propriedade das tabelas, contratos e ordem. Definir autenticação interna, versões, prazo/retry, idempotência, observabilidade e ciclo de exclusão/restore.
2. Escolher uma fatia e comparar o mesmo comportamento antes/depois em dados descartáveis. Levantar queries, transações e dependências; não fazer uma reescrita geral baseada apenas no nome dos pacotes.
3. Manter a API pública consumida pelo Flutter compatível. Um componente de entrada pode encaminhar para o dono da capacidade; testar indisponibilidade sem gravar em dois lugares.
4. Fazer checkpoint, ensaio de migração/restore e troca explícita de dono. Um escritor por dado. Rollback exige compatibilidade verificada; não consultar/gravar indiscriminadamente no sistema antigo se o novo estiver indisponível, pois isso pode recriar dados excluídos.
5. Comprovar isolamento entre contas/serviços, expiração/revogação, exclusão concorrente, replay, timeout, recuperação e observabilidade. Medir carga por domínio antes de prometer capacidade.

## Decisão recebida e limites

O autor escolheu **microserviços por etapas** ao responder à pergunta de qual caminho detalhar antes de mudar a arquitetura. Essa direção substitui a indecisão entre manter o processo atual e uma reescrita ampla. Não autoriza implicitamente migrar o banco real, mover sessões ou trocar o APK. CI/segurança continuam independentemente; práticas015/016 permanecem bloqueadas por falta de conteúdo aprovado.

## Dependências Go conferidas por go list

Imports de produção internos: auth→httpapi;catalog→httpapi;nutrition→auth/httpapi;privacy→auth/httpapi;trainingconfig→auth/httpapi;foodnamesops→nutrition/postgres. Platform não importa domínios. Testes não entraram nessa contagem. Isso mostra dependências de pacotes; não prova isolamento dos dados: as referências SQL entre sessões, alimentação e privacidade continuam existindo. A prontidão0.8.1 é um adaptador daAPI atual e deverá receber requisitos por serviço se a extração for aprovada.

## Primeiro incremento proposto: leitura do catálogo público

**Escopo para revisão, ainda sem implementação/cutover.** Usar o catálogo de movimentos/programas como primeira prova de processo separado. Seu pacote só importa a camadaHTTP interna; leitura depende de `sources`, `content_versions` e `content_withdrawals`. A propriedade editorial completa não estará extraída apenas por abrir outro processo.

| Parte | Prova isolada proposta | Condição para a troca real |
|---|---|---|
| Processo | Novo executável Go no monorepositório, reutilizando domínio/DTOs do catálogo e composição própria | Build e publicação independentes, configuração/dependências mínimas verificadas |
| Banco | Base descartável própria noCI, migrator e reader exclusivos; reader sóSELECT nas3tabelas editoriais necessárias | Banco e migrations sob um único dono editorial; nenhuma credencial do banco privado |
| Conteúdo | Fixtures explicitamente sintéticas, incluindo retiradas; nada importado na avaliação | Conteúdo real já permitido, versões/direitos/retiradas reconciliados antes da troca |
| Entrada |HTTP da prova emloopback/httptest, sem redirecionar Flutter ouAPI atual | Encaminhamento só das5rotas aprovadas; sem repassar Authorization/cookies para o catálogo público |
| Escrita | Nenhuma rota pública de escrita; publicação real continua com o dono atual | Transferência editorial explícita, com um escritor, revisor e trilha de retirada |
| Treinos | Configuração047 continua no processo/banco atual | Substituir a consulta editorial compartilhada por contrato que preserve validação e versões |
| Saúde | live do processo e ready verificando apenas seus objetos/reader; falha genérica | Limites de conexão, cancelamento, shutdown e indisponibilidade exercitados |

Não clonar migrations privadas para o serviço de catálogo. Compartilhar código dentro do monorepositório é transitório e não equivale a isolamento de dados. Criar executáveis com a mesma senha/runtime e o mesmo schema não satisfaz o objetivo.

### Contrato que deve permanecer compatível

Manter os caminhos atuais, sem login novo ou alteração noFlutter:

- GET `/api/v1/catalog/filters`;
- GET `/api/v1/catalog/programs`;
- GET `/api/v1/catalog/programs/{id}`;
- GET `/api/v1/catalog/movements`;
- GET `/api/v1/catalog/movements/{id}`.

PreservarIDs/versões, tiposprogram/collection/movement, filtros literais, cursores vinculados aos filtros, paginação, ausência explícita, autoria/fonte/direitos, consulta/prática e os códigos400/404/503. ConfirmarETag/If-None-Match e Cache-Control existentes. A checagem de retirada/permissão deve acontecer antes de responder304. Listagem escolhe a última versão antes de verificar direito/retirada; detalhe com versão explícita conserva o contrato atual, sem ressuscitar item retirado.

Proposta de teste contratual: mesma requisição e fixture para o handler atual e o processo isolado, comparando status, cabeçalhos relevantes e JSON canônico. Ignorar somente identificadores efêmeros de requisição devidamente identificados; não ignorar campos de negócio.

### Acoplamento que impede uma troca ingênua

A configuração047 usa funçãoSQL `save_training_configuration` e consultas de recursos sobre o conteúdo editorial. Nutrição/refeições e privacidade têm suas próprias transações privadas e ficam juntas por enquanto. Não remover tabelas/FKs ou aceitar recurso só porque um serviço remoto respondeu anteriormente.

Antes do cutover, levantar exatamente os consumidores de catálogo e funçõesSQL, definir snapshots históricos porID/versão e a regra de revalidação. Definir como publicação/retirada chega ao dono e como o consumidor comprova frescor. Enquanto isso não existir, a prova será uma **projeção de leitura em ambiente descartável**, sem promessa de serviço editorial completo.

Retirada tem precedência sobre cache. Sem prova atual de permissão, devolver indisponibilidade; nunca consultar uma cópia antiga como fallback silencioso. Uma indisponibilidade do catálogo não deve apagar sessão, gravar configuração ou trocar conteúdo por fixture. Nenhuma fila, produto cloud ou fornecedor é escolhido por esta proposta.

### Sequência e critérios de saída

| Passo | Entrega verificável | Estado |
|---|---|---|
| M0 | Direção gradual escolhida e acoplamentos Go/SQL documentados | Direção aceita; limites da primeira prova em revisão |
| M1 | Processo de catálogo e reader próprio em fixtures/CI; contratos equivalentes e negativos de grants | Proposto; ainda não implementado |
| M2 | Protocolo editorial de publicação/retirada, versões, frescor e treino047; um dono por dado | Proposto; impede cutover |
| M3 | Ensaio de migração/restore com dados descartáveis e comparação de hashes/visibilidade; falhas de rede | Proposto; sem acesso a dados reais |
| M4 | Checkpoint real, troca controlada das5rotas, aceite doAPK e rollback ensaiado | Requer escopo/autorização concreta; não iniciado |

Aceite deM1 exige: processo sem auth/nutrition/privacy/trainingconfig; credencial incapaz de ler usuários/sessões/consumos ou gravar catálogo; migração idempotente somente editorial; testes de contrato, retirada, cache304, erro deDB, timeout/cancelamento e encerramento. Nenhum segredo ou corpo pessoal nos logs. Fixtures não validam loginGoogle nem prática real. Nenhuma nova prática será liberada.

M4 só ocorre depois deM2/M3. Rollback do caminhoHTTP só é permitido enquanto a autoridade editorial anterior continuar atualizada e válida; caso contrário,503 é preferível a publicar conteúdo retirado. Não fazer dual write. Não iniciar nova hospedagem, serviçoWindows, Docker local ou mudanças emDNS/HTTPS nesta prova.

### Próximas extrações, depois da prova

1. Consolidar catálogo editorial como dono e consumidor047 por contrato revisado.
2. Isolar alimentação como um domínio: refeições, itens, versões e cálculo preservam atomicidade. Foto/reconhecimento pode ser trabalho assíncrono com ciclo privado próprio, sem confirmar consumo automaticamente.
3. Isolar treinos quando configuração, conteúdo e jornadas tiverem contratos comprovados; manter histórico/parcial e regras humanas.
4. Extrair identidade e coordenação de privacidade somente com protocolo de revogação/exclusão/restore testado entre serviços. Nunca substituir principal verificado por userId do cliente ou aceitar timeout como autorização.

Essa ordem é candidata e poderá mudar por evidência de carga/acoplamento. Não é estimativa de prazo nem capacidade garantida. No momento, oAPK continua na arquitetura atual e continua faltando conteúdo humano, foto/análise, offline e os demais critérios do backlog.
