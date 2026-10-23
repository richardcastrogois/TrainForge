# Segurança, observabilidade e capacidade

Plano, não certificado de auditoria. Os números da imagem de referência de auditoria não são achados do TrainForge. A prioridade dos [achados locais](achados.json) é revisão estática; não houve scanner de dependências, pentest ou benchmark de produção nesta etapa.

## Checkpoint real de23/10

API Go0.4.0/18operações e APKdebug0.1.3+4. Auth e sessão implementados, logs por allowlist, exportação própria/exclusão confirmada, inventário privado, proxy explícito e limites por instância validados tecnicamente. A política pública está noAPK; testes de duas contas/rollback/refresh e restore usam banco descartável. Nenhuma conta fictícia na base entregue. [V1-013 e matriz de acesso](../execucao/v1/privacidade-013.md).

A exclusão remove dados correntes e revoga sessões após confirmação; o registro mínimo UUID/data impede retorno no restore separado. Manutenção temporária e expiração de backups continuam manuais; nenhum prazo automatizado é prometido. Antes de promoção, manter o alvo offline, aplicar migrations/registro atual e revalidar o corte com exclusões pausadas na origem. ContaGoogle e cópias feitas pelo usuário são independentes.

LoginGoogle consentido,OAuthrelease/HTTPS, iOS, carga e infraestrutura não foram validados. Não há certificação de segurança ou milhões simultâneos. A lista abaixo mantém os critérios para próxima exposição e versões posteriores, sem reclassificar planejamento como entrega.

## Critérios de segurança e exposição

- Identidade Google verificada com assinatura/issuer/audience/expiração, identidade estável e associação explícita. Preservar as verificações já existentes. Referência: [Google backend auth](https://developers.google.com/identity/sign-in/web/backend-auth).
- Access token de curta duração; refresh hash/rotação atômica/família/reuso; logout revoga no backend; secure storage no cliente. Não apagar sessão válida por erro de rede.
- Ownership em toda operação privada e teste de ID alheio; permissões do cuidador separadas. Limites de corpo/página/tempo, proxy confiável e rate limit coerentes com o deploy. Referência: [OWASP API Security 2023](https://api-security.owasp.org/editions/2023/en/0x11-t10/).
- Logging por allowlist e redação; não corpo de auth/perfil, token em query, e-mail como label de métrica ou log completo de exceção com segredo. Segredos em ambiente/gerenciador adequado, fora do Git e dos artefatos públicos.
- Análise Go/Flutter/Android, verificação de segredos e dependências com versões/data/resultado reais; `govulncheck` depois de existir Go. [Guia oficial de segurança Go](https://go.dev/doc/security/).
- Runtime com privilégio mínimo, SQL parametrizado, migrations separadas, TLS e banco protegido. Exportação/exclusão e retenção precisam cobrir também caches e backups. Ensaio de restore antes de confiar em backup.
- Release Android com assinatura própria, certificado verificado, segredo protegido, permissões necessárias e endpoint HTTPS. [Assinatura Android](https://developer.android.com/studio/publish/app-signing).

## Telemetria útil para o piloto

Começar com logs estruturados redigidos, requestId, duração/status por rota, erros, uso de pool e health/readiness. Uma falha real deve poder ser seguida de Flutter → HTTP → Go → SQL → resposta sem expor o usuário. Traces podem ser instrumentados conforme necessidade, com amostragem e retenção definidas. [OpenTelemetry](https://opentelemetry.io/docs/concepts/signals/) define sinais, não exige a pilha inteira das imagens de referência.

Não instalar Kubernetes, Spark, Cassandra, Elasticsearch ou toda uma stack de observabilidade para duas pessoas sem problema medido. Preferir recursos existentes do provedor e uma trilha reproduzível de diagnóstico. Alertas devem levar a ação: indisponibilidade, erro persistente, falha de backup, cota ou custo; não ruído por cada erro de formulário.

## Medição e escala progressiva

`V1-030` propõe inicialmente p95 de leituras abaixo de500ms e escritas abaixo de1s em staging aquecido. São **alvos a revisar**, não números medidos. Registrar hardware, região, versão, concorrência, volume, mistura de endpoints, duração, p50/p95/p99, erros e pool. Autenticação e cold start têm perfil diferente de catálogo cacheado.

Primeiro corrigir N+1, índices/planos de consulta, paginação, payload excessivo e limites de conexões. Medir compressão/cache/ETag em conteúdo público versionado. Escala horizontal exige estado de sessão e idempotência compartilhados corretamente, não memória local por usuário. Rate limit distribuído/fila/Redis/replica só entram se volume e comportamento justificarem.

Não fazer teste de carga em fornecedor de conteúdo externo. Importar o lote permitido e ensaiar nossa API em ambiente autorizado com dados sintéticos isolados; excluir essa carga do banco entregue. Um benchmark bem-sucedido não prova capacidade de milhões de usuários com qualquer padrão de uso.
