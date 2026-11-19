# Segurança, observabilidade e capacidade

Atualizado em **18/11/2026**; implantação e catálogo final estão em integração no [handoff](../execucao/v1/handoff.md). Existem controles e verificações locais; V1-028/029/030 mantêm critérios abertos. Não há certificação integral, pentest completo ou capacidade de milhões comprovada. [Modelo e contratos](modelo-e-contratos.md) · [Operação diária](../aprendizado/operacao-local.md).

## Controles implementados e evidência

| Fronteira | Controle e limite | Evidência |
|---|---|---|
| Identidade/sessão | Google verificado, identidade issuer/sub, hashes, rotação/família/reuso e logout; aceite Android debug local, sem comprovar distribuição release/iOS | [Aceite local](../execucao/v1/implementacao.md) |
| HTTP privado | Principal autenticado, titular em query e credencial viva revalidada na transação; conta alheia sem acesso; revisão/idempotência e limites por operação | [Privacidade](../execucao/v1/implementacao.md), [configuração SQL](../execucao/v1/training-configuration-sql-verification.json), [atividade SQL](../execucao/v1/activity-session-sql-verification.json) |
| Persistência | SQL parametrizado, papéis runtime/migrator separados, funções restritas e versões imutáveis; SECURITY DEFINER com search_path fixo/execução explícita | [Schema/privilégios](../execucao/v1/database-verification.json) |
| Readiness | Live separado; ready confere conexão, objetos/grants, funções e runtime não elevado; falha genérica 503 sem consultar dados privados | [CI SQL](../execucao/v1/ci-sql-verification.json) |
| Catálogo separado | Reader sem DML/acesso privado; encaminhamento sem credenciais; digest/revisão e retirada precedem cache/304; indisponível falha fechado | [Transição](../execucao/v1/catalog-rollout-verification.json), [decisões](decisoes.md) |
| Cliente | Logs restritos, troca de conta/geração invalida respostas, rede não apaga sessão; intenção incerta conserva corpo/chave em memória | [Integração](../execucao/v1/activity-session-integration-verification.json) |
| Armazenamento seguro | AndroidOptions(resetOnError:false) preserva falha para retentativa; algoritmos/formato/logout explícito mantidos | [Recibo](../execucao/v1/secure-storage-recovery-verification.json) |

Prontidão não audita todo DDL, dependências, backups ou capacidade. Testes do secure storage conferem a opção enviada ao canal nativo e leitura posterior sem exclusão; não simulam perda física da chave. Rascunho em memória não entrega a fila durável V1-026.

O [inventário Android histórico](../execucao/v1/android-security-inventory.json) registra minSDK24/target36, allowBackup false, exclusões de backup/cloud/transferência, permissões e componentes exportados daquele APK. Biometria transitiva no manifesto não significa fluxo biométrico habilitado. Após preparar novo artefato pertinente, `python tools/android_security_inventory.py --write` reavalia o manifesto compilado, sem ler credenciais/dados do aparelho ou instalar ferramentas. Hash/assinatura divergentes, permissão/export novo ou exclusão ausente exigem revisão do recibo. Manifesto não certifica comportamento de todos os fabricantes ou resistência do keystore.

## Exclusão e recuperação

Exclusão própria exige sessão/intenções válidas e confirmação, remove o inventário privado e revoga sessões. O ledger mínimo UUID/data impede retorno no restore separado, sem nome/e-mail/token. Configuração, refeições, consumos e execução integram suas verificações privadas. Conta Google e cópias feitas pelo usuário são independentes.

Restore permanece separado/offline: aplicar migrations/registro atual, conferir exclusões e revalidar o corte antes de promover. O CLI não promove automaticamente. Manutenção/expiração de backups são manuais e limitadas; não se promete apagamento físico instantâneo ou prazo automatizado inexistente. [Procedimento e limites](../execucao/v1/implementacao.md), [restore de configuração](../execucao/v1/training-configuration-privacy-verification.json).

## Offline, fotos e master: requisitos ainda abertos

| Cenário | Critério antes de liberar |
|---|---|
| Processo morre após salvar localmente | Operação privada durável/protegida é recuperada, ou falha local é informada sem falso aceite |
| API confirma e resposta se perde | Reconciliar mesma identidade/chave sem duplicar consumo/sessão |
| Conta troca, é revogada ou excluída | Fila inacessível a outro titular e sem reaplicação na conta recriada |
| Refeição é excluída durante upload/reenvio | Cancelar/reconciliar; foto/miniatura não reaparecem nem permanecem acessíveis como revisão |
| Banco e arquivo falham em etapas diferentes | Revogar acesso e retentar limpeza, sem declarar remoção física não comprovada |
| Outro aparelho/backup tem cópia antiga | Aplicar exclusões em reconciliação/restore e explicar os limites externos |
| Exclusão por master | Permissão explícita/revogável no servidor, identidade estável, titular/recurso exatos, confirmação e auditoria mínima |

A fila alimentar e as fotos opcionais de rótulo usam SQLCipher por conta/chave segura, lock persistente após 401 e erasure local; o servidor revalida sessão e mantém ledger/tombstones duráveis. Mídia enviada é sanitizada e limitada. Esses controles passaram em unidade/SQL; execução nativa, morte do processo e demais cenários acima conservam seus aceites. Fotos de refeição e offline de atividade têm escopo próprio. Tokens não ficam no payload da fila/log; sincronização exige autenticação válida. Master não é inferido por e-mail, GitHub ou campo do aplicativo e não implica leitura/edição irrestritas. Ensaiar papel forjado/revogado, conta alheia, confirmação inválida, repetição e concorrência em ambiente isolado. [Decisões Q4/Q6](../execucao/v1/escopo.md).

## Instrumentação e dados que podem aparecer em log

O evento `http_request` contém requestId gerado, método categorizado, padrão de rota, status, duração e bytes. Não contém URL/query/IDs fornecidos, corpo, Authorization, cookies, IP ou identidade. Rejeição antes do router usa unmatched; método desconhecido usa OTHER. Panic gera código fixo correlacionado, sem texto bruto da exceção. Testes cobriram sucesso/404/503/panic e sentinelas privadas. [Recibo HTTP](../execucao/v1/http-observability-verification.json).

Faltam correlação Flutter→Go→SQL, métricas/pool, traces, retenção e alertas operacionais. Um evento por requisição exige medir volume/custo antes de exposição. Nenhum coletor ou storage foi contratado. [Sinais OpenTelemetry](https://opentelemetry.io/docs/concepts/signals/) foram referência conceitual, sem exigir uma pilha inteira.

## Exposição e capacidade

Preservar verificação de assinatura/issuer/audience/expiração, autorização em todo recurso, paginação/corpo/tempo limitados, proxy explicitamente confiável e rate limit coerente com a topologia. Não incluir corpo privado, token, e-mail ou exceção bruta em logs/métricas. Runtime sem superuser, TLS/banco protegido e assinatura própria/HTTPS no release continuam critérios de distribuição.

Análise de dependências/segredos/Go/Flutter/Android precisa registrar versão, data e resultado reais. Referências utilizadas: [Google backend auth](https://developers.google.com/identity/sign-in/web/backend-auth), [OWASP API Security](https://api-security.owasp.org/editions/2023/en/0x11-t10/), [segurança Go](https://go.dev/doc/security/) e [assinatura Android](https://developer.android.com/studio/publish/app-signing). CI aprovado em um recorte não encerra auditoria completa, Sonar, release, offline/fotos/master ou carga.

V1-030 conserva alvos iniciais a revisar: p95 de leituras abaixo de 500ms e escritas abaixo de 1s em staging aquecido. São metas, não medidas. Um ensaio deve declarar hardware/região/versão, concorrência, volume, mistura de endpoints, duração, p50/p95/p99, erros e saturação do pool/CPU/memória. Login/cold start e catálogo cacheado têm perfis diferentes.

Primeiro observar consultas/índices/N+1, paginação/payload, cache público versionado, conexões/timeouts e transações. Réplicas precisam compartilhar corretamente sessão/idempotência; rate limit atual é por instância. Fila, cache distribuído, réplica ou nova extração entram por necessidade medida. Não fazer carga em fornecedor externo nem no banco real entregue: ensaiar a própria API com dados sintéticos isolados. Nenhuma hospedagem está autorizada por estes critérios.
