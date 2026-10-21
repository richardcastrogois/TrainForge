# Estado técnico verificado em 21/10/2026

Inspeção estática do código local. Não foram executados API, migrations, testes de carga ou nova jornada de login do aplicativo nesta entrega. O [inventário portátil](inventario-atual.json) e o [mapa no repositório](README.md) mostram caminhos relativos e cobertura; o Fastify é referência versionada, não dependência local implícita. Os achados são [registros revisáveis](achados.json), não uma auditoria de vulnerabilidades executada.

## Base existente

| Área | Existe | Implicação |
|---|---|---|
| Flutter | `lib/` com 42 arquivos Dart; features auth/bootstrap/home/onboarding/workouts/stats/profile, separadas em data/domain/presentation | Evoluir a base, retirar lógica de tela e injetar dependências; evitar recomeçar o frontend |
| HTTP | Dio central, secure storage, Google Sign-In | Aproveitar infraestrutura, corrigir logging/configuração/ciclo de sessão |
| Backend externo | `C:/dev/bootcamp-treinos-api`, Fastify 5, TypeScript, Prisma 7 e PostgreSQL; 33 fontes TS fora do cliente gerado | Referência de contratos e invariantes, não um backend Go já migrado |
| Identidade | Validação Google e JWT mobile; refresh aleatório com hash armazenado | Preservar as validações existentes e revisar associação de identidade e rotação concorrente |
| Casos de uso | Verificações de proprietário e transações serializáveis nos fluxos de sessão | Não afirmar que autorização está ausente; portar e testar as regras úteis |
| Banco | Nove modelos Prisma: usuário, plano, dia, exercício, sessão, refresh e três modelos de autenticação | Modelo centrado em musculação/plano mutável; não representa catálogo editorial versionado |
| Graphify | Grafos separados de Flutter, backend e web antigo | Relações estruturais não provam que uma chamada HTTP funcionou |
| Android/iOS | Pastas nativas presentes | Presença de pasta não demonstra release, assinatura nem paridade testados |

Versões são o snapshot dos manifests, não recomendação de congelá-las para sempre. Revalidar suporte e segurança ao implementar.

## Bloqueadores da primeira entrega

1. **Conteúdo:** `WorkoutDayExerciseDetail` e Prisma exigem séries/repetições/descanso; não há autoria, licença por ativo, versão editorial, requisito de apoio nem unidades suficientes. Instrução de respiração ou caminhada não pode receber `reps: 0` para caber no modelo.
2. **Origem dos planos:** `src/routes/mobile-onboarding.ts` usa geração IA e `manual-plan-builder.ts` escolhe rotinas e doses por templates. O caminho chamado “manual” também não é a seleção de programas humanos desejada.
3. **Sessão e privacidade:** Flutter armazena somente o access token, encerra sessão localmente e limpa o acesso após qualquer erro de `/me`. Logging do Dio inclui corpo de requisição e resposta. Corrigir antes de distribuir.
4. **Identidade e concorrência:** API vincula login por e-mail; revisar `issuer + sub`. Refresh é lido antes da transação e revogado por atualização sem condição de uso único; testar e corrigir atomicidade. Não houve prova de exploração.
5. **Integridade:** a migration `20260321144259_partialunique` remove os três índices parciais da anterior. Revisar intenção/invariantes no novo modelo. Um único refresh ativo por usuário pode contrariar múltiplos dispositivos; não restaurar mecanicamente.
6. **Ocorrências:** UI considera sessão concluída no histórico do dia de treino; recorrência em outra semana e histórico independente do plano ativo precisam de novo contrato e testes.
7. **Entrega Android:** `com.example.trainforge`, assinatura debug em release e `http://127.0.0.1:8081` são configuração de desenvolvimento. Conferir INTERNET no manifest release, HTTPS, OAuth/certificado e chave própria. Backend tem porta padrão8080; loopback do notebook não é o do emulador.
8. **Operação:** rate limit usa `x-forwarded-for`; configurar fronteira de proxy e testar spoof. Métricas, backup/restauração, limites e desempenho precisam de evidência de execução.

Localização dos achados e histórias correspondentes: [achados.json](achados.json). O gerador não decide se uma correção resolveu um achado. A conclusão requer revisão e teste registrados; fontes externas se referem ao snapshot identificado.

## O que aproveitar

Manter organização por feature, modelos tipados, Dio, armazenamento seguro e componentes reutilizáveis quando adequados. Portar as verificações de propriedade, validação temporal e proteção transacional do legado, ajustadas para ocorrências. Separar `completeAt` do banco antigo de `completedAt` do contrato, sem renomear silenciosamente. Aproveitar os dossiês e importações já estudados, sem repetir pesquisas na ausência de nova pista.

O Figma é referência de experiência, com telas e dados demonstrativos. A V1 vai confrontar os fluxos com campos e estados reais. Nenhum Figma foi alterado nesta entrega.
