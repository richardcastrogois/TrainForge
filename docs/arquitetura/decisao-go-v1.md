# Decisão executiva do backend V1

Decisão em21/10/2026, V1-002. O autor solicitou implementar as etapas planejadas em sequência, após sua direção de refatoração paraGo. Adotar **Go como monólito modular**, mantendo o Fastify como referência isolada. A mudança serve à arquitetura/direção técnica do projeto; não se alega que Fastify não escala nem que trocar linguagem garante latência.

## Fronteira

- Serviço novo em `services/api`, com `net/http`, aplicação/domínio por módulo e persistência PostgreSQL explícita compgx.
- Banco novo `trainforge_v1_dev`, porta local proposta15432; schema `trainforge_v1`. Legado não recebe migrations, importações ou dualwrite. Nenhum dado legado é presumido existente ou copiado.
- API nova usa `/api/v1`; Flutter não muda debaseURLsem adaptação/teste. Legado usa rotasmobile e tokencomformato diferente. Não manter dois escritores no mesmo domínio/schema.
- Go é único dono das migrations novas: **Goose3.29.0**, SQL versionado. Conexão de migration separada do runtime e sem down/reset automático.
- Primeira fatia: processo/saúde/configuração/Swagger → modelo/migrations → importação idempotente do lote de consulta. Auth e Flutter seguem suas dependências.

## Versões verificadas

Go instalado globalmente1.24.5; a [política oficial](https://go.dev/doc/devel/release) mantém duas linhas recentes, e a versão corrente estável recebida foi1.27.3. Usar cópia portátil1.27.3 em `.tools/go`, com ZIP eSHA256 [oficiais](https://go.dev/dl/?mode=json); nenhum instalador ou PATHglobal alterado. SHA256Windowsamd64: `f26081f438319757f8a1b46d7d0b2c5ec7583d4038e485e0aa725cfde7885fff`.

Dependências fixadas após consulta primária: [pgx5.11.0](https://github.com/jackc/pgx/releases/tag/v5.11.0), [Goose3.29.0](https://github.com/pressly/goose/releases/tag/v3.29.0), [http-swagger2.0.2](https://github.com/swaggo/http-swagger/releases/tag/v2.0.2). Swaggo permanece1.16.6 pelo contrato documental existente: comentários/DTOs → Swagger2.0 gerado, sem YAMLmanual. Compatibilidade só será afirmada após build/execução.

PostgreSQL17.5 nativo já instalado foi reutilizado somente como binário: cluster próprio `.local/pgdata`, porta15432, banco `trainforge_v1_dev`. Três migrations forward foram aplicadas e o backup restaurado em base temporária com contagens e conteúdo conferidos. A linha17 é suportada, mas o patch17.5 está defasado: atualizar para patch suportado atual (17.11 na consulta de21/10) antes de ambiente externo; [política oficial](https://www.postgresql.org/support/versioning/). Não acessar o serviço/bancos legados para fechar esta preparação isolada.

## Reversibilidade e custo

Ferramentas gratuitas, sem conta/assinatura ou cobrança. RuntimeGo portátil e caches ficam locais/ignorados, módulos com versão/checksum versionados. Docker falhou no socket local `dockerInference`; foi substituído nesta etapa pelo cluster PostgreSQL nativo isolado. Sem reset de volumes, extensão deVSCodeou mudança de virtualização. Criação do banco local usa recurso isolado identificado e credenciais locais ignoradas. Recursos do legado e outros projetos não serão reiniciados ou removidos.

Pode-se continuar estudando/adaptando o Fastify, mas apenas um backend será selecionado para cada fatia do cliente. Se a migração não produzir a fatia verificável, comparar a adaptação do legado com o objetivo do teste; não apresentar um segundo serviço vazio como benefício entregue.
