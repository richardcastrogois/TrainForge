# Auditoria do produto antes de contratar mídia de exercícios

Data: **24/10/2026**. Base inspecionada: commit `953b1c04a042b2fb7b57a5e11f17260a2c54781f`, API Go **0.5.1 / 25 operações**, APK Android de avaliação **debug 0.3.0+13**. Repositório: `C:/dev/TrainForge/trainforge`.

## Correção de escopo após as respostas Q1

Em24/10 o autor esclareceu que **o cuidador é o praticante nas pausas do próprio trabalho**. A ausência de delegação para pessoa assistida não é um impedimento desse modo; a interpretação anterior foi corrigida. Ambos os caminhos de treino e alimento por foto com revisão/quantidade digitada entram na versão desejada, ainda não implementados. Histórico visual e recuperação das imagens estão em detalhamentoQ2. As medições técnicas abaixo mantêm o escopo do baseline. [Decisões](decisoes-piloto.md).

## Decisão principal

**A API de GIFs não é o único impedimento.** Há banco, autenticação e registro alimentar reais. Ainda não há o percurso completo configuração do usuário → seleção/composição permitida → agenda → execução do treino → histórico. A captura e identificação de refeições por foto também não foram implementadas.

A prioridade solicitada agora é entender e fechar essas lacunas, preservando a direção visual aprovada. Esta auditoria não compra ou integra API, não cria hospedagem, não altera regras do produto, não implementa treino e não encerra histórias por existência de tabelas ou telas. O valor futuro de até R$400 continua sujeito a decisão específica do autor; [opções já pesquisadas](../../conteudo/opcoes-apis-exercicios.md) permanecem o registro de fornecedores.

Veredito: **solicitar alterações antes de declarar o produto completo, seguro para exposição pública ou pronto para milhões de usuários**. A fundação pode ser mantida; não há justificativa nesta revisão para reescrever tudo ou dividir em microserviços.

## O que se pode avaliar no APK atual

| Jornada | Estado comprovado | Limite atual |
|---|---|---|
| Entrada, sessão e conta | Google real em Android debug, restauração, refresh, logout, exportação e exclusão já validados nos recibos históricos | Não é homologação de release distribuído, iOS ou segurança completa |
| Inicialização e visual | Marca TF, splash/ícone, claro/dark/sistema, loaders, transições e Android sem esticamento; checkpoint 07–12 nos fluxos disponíveis | Fidelidade integral ao Figma e famílias ainda sem referência continuam pendentes |
| Biblioteca de movimento | 73 metadados reais de consulta, fonte e versão | Zero programas, instruções, mídias ou práticas liberados; consulta não ensina nem prescreve execução |
| Configurar o usuário e escolher treino | Telas de orientação/disponibilidade | Sem configuração de treino persistida, adesão funcional ou composição executável |
| Executar treino e acompanhar evolução | Esqueleto de navegação com indisponibilidades explícitas | Sem contrato/serviço de execução, agenda e histórico de atividade; cartões vazios não são atividade implementada |
| Alimentação manual | 6.369 referências, busca, detalhe, cadastro particular, consumo, revisão, exclusão, histórico e subtotais pela API | Um consumo humano real confirmado; cadastro particular e demais variações ainda precisam de aceite humano; não há dieta prescrita |
| Alimentação por foto | Não implementada | Foto, identificação do alimento, preparo, porção, privacidade e confirmação exigem um fluxo próprio |
| Cuidador praticante | Usa os próprios dados; público preservado | Falta contexto de treino nas pausas com conteúdo permitido. Delegação de pessoa assistida é opção futura, não requisito deste modo |

Login real não foi repetido nesta auditoria. Fixtures de testes não contam como login Google ou aceite de uma refeição real. Nenhum consumo foi criado, editado ou excluído pelo agente nesta etapa.

## Banco: o que existe e onde

**Existe PostgreSQL local real, sem serviço de hospedagem contratado nesta etapa.** A consulta de metadados confirmou PostgreSQL **17.5**, banco `trainforge_v1_dev`, schema `trainforge_v1`, na porta local **15432**. O cluster de desenvolvimento fica em `.local/pgdata`, separado do backend legado. A API Go local usa a porta **8082**. Isso permite testar no notebook e no emulador sem hospedagem.

A API conecta por pool limitado e credencial de runtime separada da migração. O banco de desenvolvimento aceita até 30 conexões; o pool padrão da API é 10. São limites locais, não promessa de capacidade. Não incluir credenciais do PostgreSQL no APK.

Foram encontradas **23 tabelas de aplicação** no schema. A tabela de controle de migrations não é contada como entidade do produto.

| Tabela | O que guarda / para quê | Estado observado |
|---|---|---|
| `users` | Identidade Google canônica: provedor, emissor, subject e perfil | 1 conta; e-mail não é a chave canônica |
| `auth_families` | Família de sessão, revogação e ciclo do refresh | Implementada |
| `access_tokens` | Hashes e validade/revogação dos access tokens | Implementada; linha existente não significa token ativo |
| `refresh_tokens` | Hashes, rotação, consumo e detecção de reuso | Implementada |
| `account_deletion_intents` | Confirmação temporária para excluir a própria conta | Implementada |
| `account_erasures` | Registro mínimo UUID/data para impedir retorno de conta excluída no restore | 1 registro histórico; não é cópia do perfil |
| `sources` | Identidade e atribuição das fontes de conteúdo | 3 fontes |
| `content_versions` | Metadados imutáveis e operações permitidas por versão | 73 versões de consulta |
| `content_withdrawals` | Retirada de uma versão editorial | Estrutura e controles; nenhuma retirada atual |
| `import_batches` | Lote e rastreabilidade da importação de movimentos | 1 lote |
| `batch_content` | Relação entre lote e conteúdo importado | 73 vínculos |
| `program_items` | Componentes e dose de origem de um programa versionado | Vazia; não há treino montado |
| `program_sessions` | Sessões de programa | Vazia |
| `enrollments` | Adesão da pessoa a uma versão e agenda | Vazia; fluxo ainda não entregue |
| `schedule_occurrences` | Ocorrências agendadas da adesão | Vazia; fluxo ainda não entregue |
| `activity_sessions` | Execução observada da ocorrência | Vazia; fluxo ainda não entregue |
| `activity_events` | Eventos/transições de execução | Vazia; fluxo ainda não entregue |
| `food_versions` | Versão alimentar pública ou particular, base, nutrientes, origem e preparo | 6.369 versões públicas; zero particulares atuais |
| `food_entries` | Consumo do titular, quantidade/unidade, horário/fuso, evidência, cálculo e revisões | 1 consumo humano real ativo |
| `food_import_batches` | Rastreabilidade do lote alimentar | 1 lote |
| `food_batch_versions` | Vínculos do lote alimentar com versões | 6.369 vínculos |
| `food_withdrawals` | Retirada de referência alimentar | Estrutura implementada; nenhuma retirada atual |
| `idempotency_records` | Chave/payload resumidos, resultado e validade de uma operação reenviável | Implementada |

Contagens são um snapshot, não dados permanentes. Foram lidos schema, privilégios e contagens; não foi necessário exportar perfis, refeições ou tokens.

**Decisões corretas verificadas:** SQL parametrizado, constraints e chaves estrangeiras; vínculo de titularidade nas entidades; versões e proveniência preservadas; valores nutricionais desconhecidos distintos de zero; quantidade/base/unidade explícitas; cálculo racional autoritativo no Go; idempotência e revisões transacionais; separação de runtime, migrator e conteúdo editorial.

**O que ainda falta decidir ou comprovar:** modelo de configuração e contexto do usuário/cuidador praticante, política de montagem permitida, persistência de preferências entre aparelhos, durabilidade offline, retenção/expurgo automatizado, crescimento dos registros/revisões e índices sob carga. Não preencher essas lacunas com novas colunas escolhidas por suposição.

Não há RLS habilitada nas tabelas. Hoje a autorização depende da API, de filtros por titular, constraints, transações e privilégios. Isso não prova uma falha por si só; uma revisão deve decidir se RLS acrescenta defesa útil e testar também pool/contexto de conexão antes de adotá-la.

## Quem chama quem

Fluxo ativo do aplicativo: `main.dart → TrainForgeApp → AuthGate → ProductShell → página/controller → repository → AppDio → HTTP Go → handler/caso de uso → repository PostgreSQL → banco → DTO → estado da tela`.

O Google identifica a conta; o backend valida o ID token e emite sua própria sessão. O Flutter usa os tokens do TrainForge. O aplicativo não acessa tabelas diretamente. Swagger descreve a API; não é uma camada que executa chamadas.

Na autenticação e nas leituras há interfaces/services e composição explícita. Na escrita alimentar, o handler usa diretamente `NutritionStore`, que coordena SQL/transações; as regras de cálculo estão separadas em `entries.go`. A arquitetura-alvo não deve ser descrita como se todas as operações já passassem por um service/interface.

Fontes: [composição Go](../../../services/api/cmd/api/main.go), [camadas e limites reais](../../arquitetura/camadas-go.md), [contratos](../../arquitetura/contratos-v1.md) e [mapas gerados](../../arquitetura/README.md).

## O que fica no servidor e no celular

| Informação | Implementação atual | Avaliação / próximo critério |
|---|---|---|
| Identidade, autoria e registros alimentares | PostgreSQL | Servidor é a fonte de verdade; autorização por titular |
| Tokens de sessão do app | Valores no `FlutterSecureStorage`; apenas hashes na persistência de sessão do servidor | Adequado ao desenho atual; validar também artefato release e iOS |
| Senha Google | Não é solicitada nem armazenada pelo TrainForge | Consentimento ocorre com o Google |
| Credenciais do PostgreSQL e chaves de assinatura | Ambiente/arquivos locais fora do Git; não devem ir para o app | Proteção operacional e varredura de artefatos continuam critérios do release |
| Tema claro/dark/sistema | Preferência nativa no aparelho, separada da conta | Já decidido e implementado |
| Perfil carregado, resultados, abas e formulário | Memória do processo | Perde-se ao encerrar o processo; não é sincronização offline |
| Corpo pendente e chave de idempotência dos formulários | Memória enquanto a tela existe | Reenvio na mesma tela é protegido; encerramento abrupto ainda precisa de estratégia durável |
| Fonte, licença, versão e cálculo do consumo | PostgreSQL, enviados pela API conforme necessidade | Manter rastreabilidade; apresentar resumo humano antes dos detalhes técnicos |
| Fotos e localização | Não coletadas no fluxo atual | Sem armazenamento/serviço de reconhecimento ou rastreamento implementado |
| Ícone, marca e fontes visuais | Recursos empacotados no aplicativo | Não dependem de banco nem de serviço de mídia |

Risco de confiabilidade a ensaiar em banco descartável: servidor confirma uma escrita, a resposta se perde e o processo do app é encerrado. Sem chave pendente persistida, uma nova tentativa após reabrir pode virar uma nova operação. A proteção atual não deve ser apresentada como garantia de recuperação entre reinicializações.

Proposta ainda **não implementada**: se for requisito, fila local privada e protegida, ligada à conta e a um identificador de operação, com expiração, reconciliação e limpeza no logout/exclusão. Não copiar todo o banco para o aparelho. Se fotos forem aprovadas, decidir captura local/remota, retenção e acesso antes de escolher armazenamento; a imagem não precisa virar uma coluna binária do banco.

## Segurança: controles e limites

**Classificação atual: desenvolvimento local com controles implementados e validações específicas; sem homologação completa para exposição pública.** Não há fundamento para nota numérica, certificação OWASP ou garantia de ausência de vulnerabilidades.

| Controle observado | Evidência / limite |
|---|---|
| Identidade Google validada | Assinatura, issuer, audience, expiração, subject e e-mail verificado; login Android debug real em recibo histórico |
| Sessão própria | Tokens opacos de alta entropia; access de 15 min, refresh de 30 dias; hashes no banco; rotação/reuso/revogação |
| Titularidade | Consultas por usuário, checagem de sessão, transações e constraints; testes isolados históricos de duas contas e concorrência |
| Logs sem corpos sensíveis | Allowlist no cliente/servidor e regressão de tokens/dados pessoais; não logar uma requisição inteira para diagnosticar falha |
| Proteções HTTP | Corpo e cabeçalho limitados, timeouts, limites de conexões/concorrência e rate limit por instância; proxy confiável explícito |
| SQL e privilégios | Parametrização, runtime sem superusuário, escrita editorial negada e funções privadas restritas; credencial administrativa não é a do runtime |
| Privacidade | Exportação própria, confirmação de exclusão, revogação, ledger mínimo e gate de restore; expurgo/backup ainda com operação manual |
| Android | Secure storage e exclusão de backup/transferência dos dados do app; validação nativa completa de release continua pendente |
| Rede | HTTP limitado ao desenvolvimento local; HTTPS obrigatório fora desse recorte; não houve deploy nesta auditoria |

Pendências prioritárias: análise de dependências e segredos com ferramentas e versões registradas; revisão da configuração e artefatos Android/iOS; matriz de autorização completa incluindo cuidador; ensaios de abuso, recuperação e dispositivo; rotina de retenção e backups; comprovação de criptografia e proteção das cópias em repouso; observabilidade redigida. Não foi demonstrada criptografia dos dumps ou do volume PostgreSQL apenas por haver backup e ACL.

Os testes e a revisão estática cobrem comportamentos específicos; não substituem pentest nem auditoria independente. A [V1-028](backlog.md) permanece aberta. Usar [OWASP ASVS](https://asvs.owasp.org/) para requisitos da API e [OWASP MASVS](https://mas.owasp.org/MASVS/) para o aplicativo, registrando evidência por requisito. Não atribuir antigos níveis de MASVS como certificação atual.

## Backend: avaliação da estrutura

O `main` é uma raiz de composição: carrega configuração, conecta o pool, monta verificadores/repositories/services/handlers e inicia/encerra o servidor. **Não concentra as regras do produto.** Organização por domínio (`auth`, `catalog`, `nutrition`, `privacy`, `activity`) e monólito modular são escolhas proporcionais ao estágio.

Há separação útil entre HTTP, cálculo e SQL; dependências são explícitas e as consultas são parametrizadas. Go ajuda na implementação, mas não comprova arquitetura, capacidade ou segurança.

Ajustes concretos: explicitar fronteira de caso de uso/interface na escrita alimentar ao expandi-la; evitar ampliar o handler com mais regras; manter DTO HTTP separado do modelo persistido; testes de concorrência e transação como condição para novas escritas. `activity` tem apenas a declaração do módulo, não um serviço de treino entregue. Não extrair camadas vazias ou reescrever módulos já corretos só para simetria.

Existe código Flutter legado de `AppShell`/onboarding/geração fora da composição ativa. Backend Fastify e Next.js antigos são referências externas, não evidência de funcionalidades migradas. Identificar usos e depois isolar/remover caminhos obsoletos evita voltar a integrá-los por engano.

## Frontend: campos, simplicidade e acessibilidade

Nos fluxos alimentares ativos, os campos principais enviados pelo Flutter correspondem aos contratos Go:

| Operação | Informação do usuário | Informação técnica preenchida pelo app/API |
|---|---|---|
| Criar alimento particular | Nome, preparo opcional, base conhecida e nutrientes conhecidos/desconhecidos | ID, versão, dono, proveniência e chave de idempotência |
| Registrar consumo | Alimento/versionamento selecionado, quantidade positiva, g ou ml, medida/estimativa, preparo e data/hora | Identidade autenticada, chave de idempotência, revisão e formato de fuso/horário |
| Corrigir ou excluir consumo | Alteração e confirmação da intenção | Ownership, revisão/concorrência e resposta persistida |

Nem toda coluna do banco precisa de um campo na tela. O titular não deve digitar IDs, hashes ou identidade de autorização. Não foi identificado campo alimentar principal sem correspondente no contrato revisado. **Esse alinhamento não se estende a treino ou cuidador, cujos contratos funcionais ainda faltam.**

Achados verificáveis a corrigir:

1. O formulário aceita nomes de nutrientes repetidos e o Go rejeita duplicidade sem diferenciar maiúsculas/minúsculas; o erro exibido é genérico. Validar junto ao campo e mapear o motivo de negócio sem vazar detalhes internos.
2. O detalhe alimentar ainda pode mostrar códigos internos de ausência em inglês e rastreabilidade técnica. Apresentar explicação humana, manter fonte/licença acessíveis e recolher cálculo detalhado; não apagar a proveniência exigida.
3. `nutrition_forms.dart` concentra dois formulários, estado, validação e envio; `NutritionPage` também coordena operações. Há componentes reutilizáveis e repositories injetados, mas a separação controller/viewmodel/DTO tipado ainda é incompleta. Tamanho de arquivo sozinho não determina erro.
4. Cinco destinos principais com recursos indisponíveis aumentam a descoberta de becos sem saída. Rever prioridade e rotas para as tarefas reais, sem fingir que treino/atividade estão prontos e sem reduzir todo o produto a uma única jornada.

Não há refeição ou treino fictício preenchido automaticamente na composição atual. Há fixtures de testes e telas de indisponibilidade; elas não são prova de recurso concluído. Fonte estrangeira e cálculo cru podem ser dados reais e ainda assim uma apresentação inadequada para o público.

**Acessibilidade está parcial, não homologada.** Há semântica/estados, foco no primeiro erro, redução de movimento, temas e testes de escala em recortes. Falta aceite das jornadas completas com idosos e cuidadores, TalkBack/VoiceOver, tamanho de fonte/display grande, contraste nos estados, alvos de toque, teclado, foco, leitura e recuperação de erro em aparelho real. A documentação oficial do [Flutter](https://docs.flutter.dev/ui/accessibility) e sua [API de teste de acessibilidade](https://docs.flutter.dev/ui/accessibility/accessibility-testing) orientam critérios verificáveis; o sistema operacional não torna qualquer tela automaticamente acessível.

No foco confirmadoQ1, o cuidador pratica para si nas pausas e usa a mesma proteção de titularidade de qualquer praticante. Se houver acompanhamento de pessoa assistida futuramente, deverá ter vínculo/consentimento/permissões próprios; não é requisito desta entrega. Casa, praça, academia e idosos continuam no escopo; não há adequação clínica presumida.

## Idiomas e abrangência dos dados

**Não existem os quatro idiomas completos solicitados.** O app tem textos em português com mistura de variantes; não há configuração completa de `flutter_localizations`, delegates, ARB e `supportedLocales` para pt-BR, pt-PT, inglês e espanhol. A configuração de alimentos particulares ainda usa locale `pt` genérico. Componentes padrão de data também precisam entrar na localização.

Idioma da interface, nome do alimento e instrução de exercício são problemas distintos. Localizar botões não traduz uma base alimentar ou valida uma instrução. Planejar chaves/plurais, datas, números decimais, fuso e acessibilidade; manter nome original, fonte e versão e registrar traduções/sinônimos revisados sem inventar equivalência. Referência: [internacionalização oficial Flutter](https://docs.flutter.dev/ui/internationalization).

As 6.369 referências alimentares são de **Ciqual (França) e CoFID (Reino Unido)**. São uma base real utilizável, não cobertura global garantida nem catálogo brasileiro/português completo. Correspondência de alimento, preparo, unidade e base importa mais que traduzir o nome. As 73 referências de movimento não constituem uma biblioteca mundial de treinos executáveis.

## Testes, CI e Sonar

A execução desta auditoria acrescentou **medição de cobertura**, que não constava dos recibos anteriores. Não repetiu instalação, coleta de conteúdo, importação, restore ou login real.

| Verificação | Resultado e escopo |
|---|---|
| Flutter com cobertura | 101 testes aprovados; 2.797 / 3.565 linhas instrumentadas = **78,46%**, em 51 arquivos do perfil LCOV |
| Go com cobertura | 71 resultados de testes aprovados, zero falhas; **10 testes de integração pulados** por ausência de opt-in a banco descartável |
| Perfil Go | 989 / 2.428 instruções = **40,73%**; inclui comandos sem cobertura nesta execução; não mede os ensaios SQL históricos |
| Análise Flutter anterior, mesma base de código | Zero issues em 101 testes/analyze do checkpoint 07–12; não reexecutada sem mudança de código |
| Documentação desta auditoria | 13 testes pertinentes aprovados; geração/backlog/dependências/links locais e diff sem erro |
| Python/documentação anterior | 76 testes aprovados no checkpoint anterior; validação documental desta auditoria registrada separadamente |
| CI remota da base | Run 40113857308 bem-sucedido; não representa teste completo do APK |
| Sonar | Nenhuma configuração ou execução de SonarQube/SonarCloud encontrada no repositório/CI inspecionados |

Os percentuais usam denominadores diferentes: linhas Dart e instruções Go. Não são uma nota do aplicativo inteiro. A ausência de cobertura instrumentada não apaga um ensaio manual/SQL histórico, e um teste com mock não prova integração nativa. Não há 100% de testes unitários em tudo, nem isso seria garantia suficiente de qualidade.

Na CI atual entram geração/documentação, testes Python, Mermaid, Go test/vet/build e consistência Swagger. **Não entram Flutter analyze/test, cobertura com gate, build nativo completo, scanner de vulnerabilidades/segredos nem integração PostgreSQL automática com banco descartável.** Testes SQL podem ser pulados e ainda deixar a CI verde; isso precisa ficar explícito e ser corrigido no desenho da pipeline.

Prioridade de cobertura: sessão/secure storage e nativo, fluxos privados entre contas, envio com resposta perdida/reabertura, validação divergente, transações e concorrência, retirada de conteúdo, fuso/unidade/desconhecido, inicialização offline e jornadas acessíveis. Cobrir regra crítica e regressão útil; não perseguir percentual com testes que só repetem a implementação. Sonar, se adotado, é uma ferramenta de análise e quality gate, não certificado de segurança.

Recibo público sem dados do titular: [auditoria-produto-verificacao.json](auditoria-produto-verificacao.json). Logs/perfis e metadados brutos permanecem ignorados em `.local/product-*`.

## Escala, observabilidade e teste de estresse

**Não há evidência de capacidade para milhões simultâneos.** Paginação, índices, pool, timeouts, limites, cache/ETag público e transações são fundamentos úteis. Nenhum deles isoladamente garante vazão. Rate limit e admissão são locais por processo; multiplicar instâncias exige revisar comportamento conjunto, orçamento de conexões e isolamento.

O teste de carga **está planejado** em [segurança/operação](../../arquitetura/seguranca-operacao.md) e na **V1-030**, que continua `todo`. Alvos propostos de p95 leitura <500 ms e escrita <1 s não foram medidos. Não foi encontrado ensaio de estresse reproduzível executado nesta etapa.

Antes de alegar capacidade: cenário misto de leitura/escrita/refresh, volumes e concorrência progressivos, hardware/versão registrados, p50/p95/p99, taxa de erro, CPU, RAM, pool, banco e recuperação após saturação. Separar cache quente/frio, conflitos/reenvios e falha de rede; inspecionar planos de consulta e crescimento dos dados. Não estressar Google ou fornecedor externo.

É possível preparar e executar um baseline **local, em banco descartável**, sem escolher hospedagem. Capacidade local não equivale a capacidade de produção. V1-029 deve completar métricas e correlação; logs e requestId atuais não constituem painel, alertas e diagnóstico integral.

## Ordem recomendada antes de qualquer compra

| Ordem | Entrega que permite avaliar o produto | Dependência / critério de saída |
|---|---|---|
| 1 | Inventário de jornadas visíveis e contrato do contexto do usuário/cuidador | Entender o próprio praticante/cuidador nas pausas, objetivos/contexto necessários e limites de apoio; não coletar dados físicos sem finalidade |
| 2 | Percurso de treino com conteúdo e composição permitidos | V1-015/016 e revisão das evidências: fonte humana, direitos, público, instrução, dose e agenda aprovados; sem gerador de prescrição |
| 3 | Agenda e execução real com retomada | V1-017/018 e Flutter correspondente; estados, ocorrência única, parcial/pausa, histórico e testes de concorrência |
| 4 | Alimentação manual compreensível e durável | Fechar aceite V1-025, corrigir erros/terminologia, unidades/fuso e recuperação; preservar consumo real |
| 5 | Simplificação e localização da experiência | V1-021–027 conforme dependências; fluxos de idosos/cuidadores, quatro idiomas e validação em dispositivos; manter marca aprovada |
| 6 | Qualidade demonstrável | CI Flutter/SQL, revisão V1-028, observabilidade V1-029, carga V1-030 e release testável conforme escopo, sem exigir hospedagem agora |
| 7 | Reavaliar a lacuna de mídia | Só atribuir à API de GIFs aquilo que ela de fato fornece e licencia; comprar não aprova treino nem corrige as etapas acima |

**Foto é uma decisão de escopo separada.** Hoje V1-042 estava em `Posterior`, dependente deV1-037, no baseline. A respostaQ1 confirmou foto na versão desejada:história antecipada e delimitada a alimento por foto, com quantidade informada e confirmação. Recuperação das imagens e recorte das observações aguardamQ2; nada foi concluído só por replanejar. Separar rótulo/barcode, foto de prato e estimativa de porção; mostrar candidatos, incerteza e confirmação humana. Não afirmar que uma única fotografia mede com precisão o quanto foi consumido.

Também faltam critérios explícitos de suporte/recuperação, consentimento e privacidade das novas informações, compatibilidade Android/iOS e aparelhos modestos, bateria/memória/tempo de abertura, atualização do APK sem perda de dados, conflitos entre aparelhos, retirada de conteúdo e custo/licença de eventual mídia. Esses critérios devem acompanhar as histórias, não virar uma contratação antecipada.

## Evidências e preservação

Revisados: migrations 00001–00008, metadados/privilégios/contagens do schema real, composição/handlers/serviços/SQL Go, autenticação/HTTP/armazenamento Flutter, formulários e detalhe alimentar, localização/manifest/backup Android, workflow, backlog e recibos anteriores. Leitura de Graphify feita antes da inspeção; o grafo AST é Flutter e não comprova relações SQL/Go por si só.

Fontes de código: `services/api/internal/{auth,catalog,nutrition,privacy,platform}`, `lib/{app.dart,shared/widgets,features/auth,features/nutrition,core}`, `.github/workflows/documentacao.yml`. Achados de UX: `nutrition_forms.dart` (validação do nome do nutriente) e `entry_detail_page.dart` (motivo técnico). Não houve pentest, scanner completo, benchmark, teste humano adicional ou execução nativa iOS nesta auditoria.

Comandos de nova medição, usando ferramentas já existentes:

```powershell
C:/Users/richa/flutter/bin/flutter.bat test --no-pub --coverage --coverage-path=.local/product-flutter-lcov.info --reporter compact
./tools/go-api.ps1 test '-coverprofile=../../.local/product-go-coverage.out' -json ./...
```

O perfil Go usa caminho relativo ao módulo `services/api`. A primeira tentativa com caminho absoluto Windows não gerou cobertura e foi corrigida; não é falha funcional do app. A medição final completou sem falhas de teste. Os dez skips SQL são reportados, não contabilizados como aprovações.

**Estado preservado:** conta e consumo reais, fontes, cluster, sessão do emulador, código e APK. Só documentação/recibos são alterados por este incremento. As histórias abertas permanecem abertas. [Handoff](handoff.md) é o ponto de retomada.
