# Documentação técnica

Estado em 29/10/2026:Flutter → APIGo0.9.1 → PostgreSQL. Catálogo Go0.2.0 separado, com cinco rotas preservadas e base/credenciais próprias. O núcleo ainda concentra autenticação, alimentação, privacidade e configuração; não apresentamos todos os domínios como microserviços concluídos.

| Pergunta | Fonte |
|---|---|
| Qual peça faz o quê? | [Aprendizado](docs/aprendizado/pecas-do-projeto.md) |
| Como iniciar/parar/ver logs? | [Operação local](docs/aprendizado/operacao-local.md) |
| Quem chama quem? | [15 mapas visuais](docs/diagramas/README.md) |
| Quais tabelas e campos? | [Schema real](docs/diagramas/banco.md) |
| Quais APIs existem? | [34 operações](docs/diagramas/apis.md), [Swagger](docs/arquitetura/swagger-go.md) |
| Usamos ORM? | [pgx, SQL, Goose e alternativas](docs/aprendizado/orm-e-persistencia.md) |
| Como estão os serviços separados? | [M0–M4 do catálogo](docs/arquitetura/reavaliacao-microservicos-2026-10-29.md) |
| Quais controles e lacunas? | [Segurança/operação](docs/arquitetura/seguranca-operacao.md) |
| Como preservar direitos? | [Conteúdo](docs/conteudo/README.md) e [MoveKit](docs/conteudo/avaliacao-movekit-2026-10-29.md) |
| O que falta? | [Handoff](docs/execucao/v1/handoff.md), [trilha](docs/execucao/v1/trilha-implementacao.md), [backlog](docs/execucao/v1/backlog.json) |

Código Go, migrations e Swagger gerado prevalecem sobre diagramas desatualizados. Os mapas visuais mostram fatos atuais e propostas com legenda; metadados de tabela não significam capacidade de negócio pronta. O[mapa estrutural gerado](docs/arquitetura/README.md) e[Graphify](docs/graphify.md) complementam a leitura.

Não executar Prisma sobre a baseGo. Migrations ficam com Goose e credenciais administrativas próprias. Nenhuma tabela recebe chamada direta do APK.
