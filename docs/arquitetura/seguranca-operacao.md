# Segurança, observabilidade e capacidade

Plano, não certificado de auditoria. Os números da imagem de referência de auditoria não são achados do TrainForge. A prioridade dos [achados locais](achados.json) é revisão estática; não houve scanner de dependências, pentest ou benchmark de produção nesta etapa.

## Incremento047 verificado em27/10

Configuração privada tem validação em Go e SQL, credencial viva, lock do titular, revisão otimista, idempotência atômica e versões imutáveis. Negativos em SQL direto recusaram review:false, campo de titular forjado, medida física não prevista e fusoLocal. Runtime não insere/atualiza/apaga a tabela diretamente; funções SECURITYDEFINER usam search_path fixo e execução explicitamente concedida. Não há privilégio master inferido.

HTTP exige Bearer e titular da sessão, aplica no-store, JSONestrito16KiB e limite por conta. Client congela intenção incerta e invalida respostas por conta/geração; rascunho em memória não é fila offline durável. Exportação, exclusão confirmada e restauração/ledger incluem a configuração; testes em descartável provaram preservação de outra conta e editorial. [SQL](../execucao/v1/training-configuration-sql-verification.json), [restore](../execucao/v1/training-configuration-privacy-verification.json).

Schema12 foi ativado somente na base local, com checkpoint de schema e comparação das linhas reais; não é alegação de backup completo restaurado desta ativação. Testes não certificam segurança total nem escala: rate limit é por instância, busca de recursos usa view JSON do catálogo atual e precisa de benchmark/indexação conforme carga. Sonar/CIFlutterSQL/carga e operação pública continuam com seus gates. Nenhuma hospedagem foi criada.

## Estado conferido em24/10/2026

A [auditoria do produto](../execucao/v1/auditoria-produto-2026-10-24.md) inspecionou a API Go0.5.1/25operações, APKdebug0.3.0+13, schema/privilégios reais e cobertura. Há controles concretos de autenticação, titularidade, sessão, logs, rede e persistência; não há homologação completa de segurança, Sonar configurado ou capacidade medida. V1-028/029/030 continuam abertas. CI verde atual não inclui Flutter nem integraçãoSQL descartável automática.

GoogleAndroiddebug consentido e clientesOAuthdebug/release já conferidos no [aceite local](../execucao/v1/auth-local-fechamento.md). Isso não valida distribuiçãoAPKrelease porHTTPS, iOS ou ambiente público. O autor não quer hospedagem neste momento. Não pedir nova infraestrutura como condição para teste noemulador.

## Checkpoint histórico de23/10 — API0.4.0

API Go0.4.0/18operações e APKdebug0.1.3+4. Auth e sessão implementados, logs por allowlist, exportação própria/exclusão confirmada, inventário privado, proxy explícito e limites por instância validados tecnicamente. A política pública está noAPK; testes de duas contas/rollback/refresh e restore usam banco descartável. Nenhuma conta fictícia na base entregue. [V1-013 e matriz de acesso](../execucao/v1/privacidade-013.md).

A exclusão remove dados correntes e revoga sessões após confirmação; o registro mínimo UUID/data impede retorno no restore separado. Manutenção temporária e expiração de backups continuam manuais; nenhum prazo automatizado é prometido. Antes de promoção, manter o alvo offline, aplicar migrations/registro atual e revalidar o corte com exclusões pausadas na origem. ContaGoogle e cópias feitas pelo usuário são independentes.

Naquele snapshot anterior ao aceite local, loginGoogle e configuraçãoOAuthrelease ainda estavam pendentes; foram posteriormente conferidos conforme a seção vigente acima. HTTPS/distribuiçãorelease, iOS, carga e infraestrutura continuam sem validação completa. Não há certificação de segurança ou milhões simultâneos. A lista abaixo mantém os critérios para próxima exposição e versões posteriores, sem reclassificar planejamento como entrega.

## Q4 — controles a implementar para offline e fotos

Em25/10, o autor aprovou excluir foto com a refeição e registrar alimentação/andamento offline para sincronizar depois.026/042/045 continuam pendentes; esta matriz não comprova implementação nem proteção já verificada.

| Risco/cenário | Critério do novo recorte |
|---|---|
| Processo encerra após salvar localmente | Operação durável/protegida recuperada, ou falha local informada sem falso aceite |
| API confirma e resposta se perde | Reconciliar a mesma identidade/chave, sem segundo consumo/sessão |
| Conta muda, é revogada ou excluída | Fila inacessível a outro titular e sem envio indevido; não reaplicar na conta recriada |
| Refeição excluída durante upload/reenvio | Cancelar/reconciliar; foto/miniatura não reaparecem nem ficam acessíveis como revisão |
| Falha entre remoção no banco e no arquivo | Acesso revogado e limpeza retentável; não declarar limpeza física antes de comprová-la |
| Outro aparelho ou backup contém cópia antiga | Aplicar exclusões na reconciliação/restore; explicar limites sem promessa de limpeza instantânea externa |

Usar dados/arquivos isolados. Definir limites, proteção em repouso, recuperação, ciclo de chaves, backup e expurgo antes de liberar filas/imagens privadas. Autenticação válida condiciona sincronização; tokens não ficam no payload da fila/log. Nenhum dado real foi apagado nesta rodada. [Decisões Q4](../execucao/v1/decisoes-piloto.md).

## Q6 — autorização de exclusão e master planejado

O autor determinou exclusão de dados particulares pelo usuário que os incluiu ou pelo master do projeto. Hoje a exclusão de consumo usa o titular da sessão na query; não há papel master no runtime. V1-049 implementará a exceção, sem bypass genérico de ownership.

Requerer permissão explícita e revogável no servidor, identidade autenticada estável verificada, confirmação reforçada, recurso/titular exatos e trilha mínima de ator/motivo/resultado sem corpo privado. Não derivar poder de e-mail, campo enviado pelo app ou propriedade do GitHub; não conceder leitura/edição irrestritas por inferência. Provar casos de usuário alheio, papel forjado/revogado, confirmação inválida, repetição e exclusão concorrente com fila/upload em ambiente isolado.

O vínculo da conta master real permanece pendente de verificação antes da ativação. Todos os cenários devem constar do aceite; isso não significa que participantes humanos ou práticas/conteúdo já estejam disponíveis. [Decisões Q6](../execucao/v1/decisoes-piloto.md).

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

## Leitura individual de consumo — 27/10/2026

GET /me/food-entries/{id} exige o mesmo Bearer/guarda de conta das operações privadas; a sessão é revalidada no banco e a consulta usa user_id autenticado. Registro alheio ou excluído retorna404, credencial revogada401, sem divulgar nome/quantidade. Respostas privadas no-store. Nome revisado é metadado público anexado fora do snapshot; nenhum ID particular/titular vai para a consulta editorial. Pool de uma conexão e negativos passaram no ensaio isolado; não é teste de carga. [Evidência](../execucao/v1/food-names-consumption-verification.json).
