# Reavaliar microserviços Go — 29/10/2026

**Estado: proposta para decisão do autor; nenhuma decomposição aprovada ou executada.** O autor esclareceu que pretendia microserviços desde o início e continua propenso a esse rumo. A escolha Go permanece; a recomendação anterior de monólito modular deixa de representar uma decisão definitiva sobre a arquitetura de execução. O APK25, os contratos e os dados existentes são a referência de compatibilidade.

## O que existe e o que está acoplado

services/api/cmd/api/main.go compõe um processo com auth, catalog, nutrition, privacy e trainingconfig. Activity ainda não entrega execução. Há um pool e um schema PostgreSQL,13migrations/30tabelas; Go0.8.0/34operações. O Graphify existente cobre Dart; foi consultado para MealRepository, não é evidência das relações Go/SQL.

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

## Decisão pendente

O autor pode manter o atual enquanto avalia, aprovar extração progressiva ou priorizar uma migração completa antes de novas jornadas. A implementação atual não será apresentada como arquitetura final aprovada. CI SQL, contratos, regras e segurança necessários aos dois caminhos podem avançar enquanto essa decisão é discutida. A migração ampla só começa após escopo e critérios concretos aprovados.
