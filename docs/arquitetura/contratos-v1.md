# Contratos da V1 — implementado e planejado

**22/10:11operações reais no Swagger Go0.2.0: saúde, auth/google, refresh, logout, me e cinco leituras de catálogo. Demais rotas da tabela são propostas.** [Catálogo entregue](../execucao/v1/catalogo-consulta.md). [Sessão e OAuth](../execucao/v1/oauth-android.md). LoginGoogle Android real permanece gate de aceite, separado de fixtures. A [referência HTTP gerada](gerado/chamadas-http.md) separa rotas Fastify capturadas e literais do Flutter atual, com arquivo/linha e tipos detectados. Esta tabela orienta a revisão dos DTOs/handlers/comentários na V1-008; não é contrato gerado de um serviço já executado.

Decisão vigente: [Swagger por comentários e tipos Go](swagger-go.md). Os `contracts/generated/swagger-v1.json` e `.yaml` são derivados do gerador fixado, não um YAML editado em paralelo. A versão inicial proposta usa Swagger2.0; não apresentá-la como OpenAPI3.

Base proposta `/api/v1`, HTTPS em staging/produção. JSON, datas ISO8601 UTC, fuso IANA quando necessário. Bearer access token nas rotas privadas. `X-Request-Id` para correlação; `Idempotency-Key` nas criações/eventos. Nenhum token ou dado físico em log. Erro padrão `application/problem+json` com type/title/status/code/requestId; erro de campo sem ecoar segredo.

| Quem chama / método e rota proposta | Envia | Recebe / acesso |
|---|---|---|
| Auth API: `POST /auth/google` | `{idToken}` real Google |200 `{accessToken,refreshToken,expiresIn,user:{id,name,email,image}}`; público com rate limit |
| Session API: `POST /auth/refresh` | `{refreshToken}` |200 rotação atômica;401 inválido/reuso; concorrência tem regra por família |
| Session API: `POST /auth/logout` | `{refreshToken}` |204 revogado idempotentemente |
| Bootstrap API: `GET /bootstrap` | Bearer, data/fuso se exigidos pelo resumo |200 usuário, configuração mínima, contexto e resumo permitido; sem todos os catálogos/históricos |
| Identity API: `GET /me` implementado; `PATCH /me` futuro | Bearer opaco |200 identidade própria `{id,name,email,image:null}`; perfil físico não implementado |
| Profile API: `GET /me/export` | Bearer |200 exportação privada versionada; fluxo assíncrono apenas se volume justificar |
| Profile API: `DELETE /me` | Confirmação autenticada conforme política |204/202 conforme operação definida; retenção/backup explicados |
| Catalog API: `GET /catalog/programs` | q, modality, environment, population, equipment, category, cursor, limit1..50, mode | Implementado:200 `{items,nextCursor,mode,notice}`, tipos program/collection;0programas no lote;304 revalidado |
| Catalog API: `GET /catalog/programs/{id}` | versionId SHA256 opcional e mode | Implementado:200 metadados/autoria/direitos/requisitos;304 após retirada/permissões;400/404/503; sem sessões/dose/instrução |
| Catalog API: `GET /catalog/movements` e `/{id}` | Mesmos filtros/versão do catálogo | Implementado:73movimentos de referência; não são programas nem instruções |
| Catalog API: `GET /catalog/filters` | Sem parâmetros | Implementado:facetas/contagens reais; ausências não viram elegibilidade |
| Catalog API: `GET /catalog/instructions/{id}` | versão e locale disponível |200 texto permitido, dose/unidades, atribuição, mídia autorizada ou ausência; sem completar texto faltante |
| Activity API: `POST /enrollments` | `{programVersionId, scheduleOptions, acknowledgements}` |201 adesão à versão e requisitos;409 conflito/422 opção incompatível; privado |
| Activity API: `GET /enrollments` | cursor e status |200 próprias adesões, incluindo arquivadas quando solicitado |
| Activity API: `POST /sessions` | `{enrollmentId,occurrenceId,startedAt}` + chave |201 sessão real iniciada; reenvio devolve resultado estável;409 conflito |
| Activity API: `POST /sessions/{id}/events` | `{type,occurredAt,payload}` + chave; unidade e estado tipados |200/201 evento e estado confirmado;403/404 recurso alheio conforme política consistente |
| Activity API: `GET /history` | from, to, cursor, limit |200 eventos/sessões reais com versão, autor, timestamps e próximos itens |
| Summary API: `GET /summary` | date, timezone |200 planejado/realizado separados, alimentação, métricas com origem; campos sem dado são null/ausentes conforme schema |
| Nutrition API: `GET /foods` | q, preparation, cursor, limit |200 alimento/versão/preparo/base/nutrientes/fonte; paginação limitada |
| Nutrition API: `POST /foods` (cadastro próprio; revisar na008/020) | Nome, preparo, base/unidade e valores efetivamente informados + chave |201 alimento próprio versionado, origem informada pelo usuário e titular; não publica no catálogo editorial nem completa nutrientes ausentes |
| Nutrition API: `POST /food-entries` | `{foodVersionId,quantity,unit,occurredAt,timezone}` + chave |201 consumo confirmado com cálculo rastreável;422 unidade não suportada |
| Nutrition API: `GET/PATCH/DELETE /food-entries/{id}` | alteração confirmada ou exclusão |200/204, somente titular; edição recalcula usando versão e fatores declarados |
| Operação: `GET /health/live` e `/health/ready` | Sem dados pessoais |200 processo; readiness503 se dependências necessárias não disponíveis, sem divulgar senha/host interno |

Os DTOs/comentários e o Swagger gerado definem os campos/limites implementados; x-nullable registra os campos desconhecidos. Na leitura de catálogo a versão mais recente é escolhida antes da autorização; retirada/grants/revisão são consultados antes de304. Filtros não inferem ambiente/público/apoio e a projeção não inclui dose/unidades/instrução/mídia. Rotas futuras da tabela ainda exigem revisão antes de integrar o cliente. Não gerar Dart a partir desta tabela. Exemplos de schema/teste nunca serão seed ou fallback do app entregue.

## Compatibilidade com o legado

As telas legadas ainda contêm chamadas a `/mobile-auth/google`, `/mobile-auth/me`, `/mobile/bootstrap`, `/mobile/home/{date}`, `/mobile/profile`, `/mobile/stats`, `/mobile/onboarding/*` e `/mobile/workout-plans/*`. A entrada atual usa contratoGo e não navega para esses fluxos legados. O retorno auth legado usa `token`, não `accessToken`; término de sessão usa `completedAt` no HTTP e `completeAt` internamente. A troca para `/api/v1` é explícita, por ambiente/release e com testes de contrato. Não trocar base URL e supor equivalência.

Preservar validação de proprietário, intervalo de tempo e concorrência; redesenhar plano/dia/exercício em catálogo/adesão/ocorrência. Manter Fastify isolado durante desenvolvimento da primeira fatia Go. Ele não deve gerar conteúdo para preencher a nova biblioteca.

## Uma jornada, sem mock no runtime

1. Google autentica pessoa real; backend verifica token e entrega sessão.
2. Flutter carrega o catálogo previamente importado de manifestos revisados; recebe fonte, versão e requisitos.
3. Pessoa escolhe conteúdo que permita aquele uso; API cria adesão ou explica bloqueio real.
4. Pessoa inicia/registra uma ação real; API persiste transacionalmente e devolve ID/estado.
5. Home/histórico consultam o banco; a UI não incrementa estatística fictícia por abrir a tela.

Testes unitários podem usar fixtures explícitas e isoladas; staging para carga pode usar usuários sintéticos. Nenhum desses registros integra a base/manifesto da V1 entregue. Teste de aceite usa o lote real autorizado e ações reais da conta de teste.
