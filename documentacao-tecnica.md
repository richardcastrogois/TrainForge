# Documentação técnica

Estado verificado em 21/10/2026: Flutter existente + API externa Fastify/Prisma/PostgreSQL. Nenhuma API Go ou migration nova foi implementada por esta entrega. O mapa detecta estrutura estática; execução real requer testes próprios.

| Assunto | Fonte vigente |
|---|---|
| Inventário, achados e código aproveitável | [Diagnóstico atual](docs/arquitetura/diagnostico-atual.md) e [inventário](docs/arquitetura/inventario-atual.json) |
| Organização Flutter/Go e escolha técnica | [Arquitetura proposta](docs/arquitetura/arquitetura-alvo.md) |
| Quem chama quem e dados trocados | [Contratos propostos](docs/arquitetura/contratos-v1.md), [fluxos](docs/arquitetura/fluxos.md) e [painel](docs/painel/README.md) |
| Entidades, unidades, versões e ocorrências | [Domínio/banco](docs/arquitetura/dominio-e-banco.md) |
| Autenticação, autorização, limites, escala e telemetria | [Segurança/operação](docs/arquitetura/seguranca-operacao.md) |
| Fonte, autoria e direitos | [Conteúdo](docs/conteudo/README.md) |
| Tarefas e retomada | [Backlog](docs/execucao/v1/backlog.md) e [handoff](docs/execucao/v1/handoff.md) |
| Infraestrutura, build e distribuição | [Implantação/APK](docs/execucao/v1/implantacao-e-apk.md) |

Contrato oficial OpenAPI, serviço Go e manifestos aprovados são entregas futuras. Não gerar cliente ou executar SQL a partir de tabelas propostas como se já tivessem sido aceitas/testadas. Snapshot técnico anterior: [arquivo](docs/arquivo/2026-10-21/documentacao-tecnica.md).
