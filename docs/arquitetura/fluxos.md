# Telas, chamadas e navegação

A [documentação dinâmica](README.md) tem mapas de telas, chamadas HTTP, banco e arquitetura proposta no próprio repositório, sem servidor de leitura. Referências de construtor/import são evidência estática; não demonstram clique bem-sucedido ou condição de navegação.

## Fluxo atual lido no Flutter

AuthGate consulta sessão/bootstrap e apresenta AuthPage, onboarding ou AppShell. AppShell alterna HomePage, WorkoutsPage, StatsPage e ProfilePage. A lista de planos abre WorkoutPlanPage; esta abre WorkoutDayPage; a Home também pode abrir o dia. OnboardingEntryPage oferece geração manual e IA. Falhas de autenticação podem navegar de volta ao login. São estruturas do código, não uma jornada reexecutada nesta entrega.

## Fluxo V1 a desenvolver

| Tela/estado | Faz / API proposta | Próximo destino |
|---|---|---|
| Entrada | Explica teste/privacidade, login Google real; `/auth/google` | Contexto mínimo ou Hoje conforme bootstrap |
| Contexto | Coleta somente campos necessários, ambiente/modalidade/interesse, sem diagnóstico automático | Biblioteca; perfil continua editável |
| Hoje | `/summary` e contexto do bootstrap; mostra planejado separado do registrado | Biblioteca, sessão atual, alimentação, histórico |
| Biblioteca | `/catalog/programs`; filtros reais e cursor | Detalhe; sem cobertura exibe falta e permite voltar/ajustar filtro |
| Detalhe | Versão, fonte, contribuições, instrução, uso permitido e requisitos | Adesão se permitido; consulta/referência ou voltar se bloqueado |
| Adesão | `/enrollments`; somente opções suportadas pelo conteúdo | Sessões/agenda e Hoje |
| Sessão/instrução | Carrega versão, inicia `/sessions`, envia eventos reais | Pausado, retomado, parcial/concluído; depois histórico/Hoje |
| Alimentação | `/foods`, detalhe e preparo, quantidade/unidade confirmadas | `/food-entries`, histórico alimentar e Hoje |
| Histórico | `/history`, eventos e registros antigos paginados; alimento pela rota própria | Detalhe do registro, correção permitida, volta preservando contexto |
| Perfil | `/me`, preferência/fuso, exportação/exclusão e logout | Resultado confirmado ou erro recuperável; login após logout |

Perda de conexão mostra o que está disponível localmente e o estado pendente do registro. Permissão negada oferece ação que funcione com capacidades disponíveis. Sem vídeo não há player simulado. Sem refeição registrada não há gráfico pré-preenchido. Sem apoio exigido não há início autônomo apenas porque existe um botão.

Os fluxos já observados no BeFit são benchmark em dossiês datados, sem atribuição de origem externa não comprovada. As telas propostas para TrainForge são decisões próprias baseadas em requisitos e contratos. O Figma será confrontado com a implementação numa história específica, sem reexecutar geradores antigos ou sobrescrever ajustes manuais.
