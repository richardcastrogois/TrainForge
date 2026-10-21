# Documentação técnica

Estado verificado em 21/10/2026: Flutter existente + API externa Fastify/Prisma/PostgreSQL. Nenhuma API Go ou migration nova foi implementada por esta entrega. O mapa detecta estrutura estática; execução real requer testes próprios.

| Assunto | Fonte vigente |
|---|---|
| Inventário, achados e código aproveitável | [Diagnóstico atual](docs/arquitetura/diagnostico-atual.md) e [inventário](docs/arquitetura/inventario-atual.json) |
| Organização Flutter/Go e escolha técnica | [Arquitetura proposta](docs/arquitetura/arquitetura-alvo.md) |
| Quem chama quem e dados trocados | [Mapa dinâmico no repositório](docs/arquitetura/README.md), [contratos propostos](docs/arquitetura/contratos-v1.md) e [fluxos](docs/arquitetura/fluxos.md) |
| Camadas do backend e documentação por comentários | [Camadas Go](docs/arquitetura/camadas-go.md) e [Swagger code-first](docs/arquitetura/swagger-go.md) |
| Entidades, unidades, versões e ocorrências | [Domínio/banco](docs/arquitetura/dominio-e-banco.md) |
| Autenticação, autorização, limites, escala e telemetria | [Segurança/operação](docs/arquitetura/seguranca-operacao.md) |
| Fonte, autoria e direitos | [Conteúdo](docs/conteudo/README.md) |
| Tarefas e retomada | [Backlog](docs/execucao/v1/backlog.md) e [handoff](docs/execucao/v1/handoff.md) |
| Infraestrutura, build e distribuição | [Implantação/APK](docs/execucao/v1/implantacao-e-apk.md) |

Contrato oficial gerado por comentários/DTOs Go, serviço Go e manifestos aprovados são entregas futuras. JSON/YAML Swagger serão derivados, não especificação manual concorrente. Não gerar cliente ou executar SQL a partir de tabelas propostas como se já tivessem sido aceitas/testadas. Snapshot técnico anterior: [arquivo](docs/arquivo/2026-10-21/documentacao-tecnica.md).
