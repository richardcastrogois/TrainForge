# Banco sem ORM? E o Prisma?

## Estado atual

O backend Go usa pgx/v5 e pgxpool com SQL parametrizado. Goose executa migrations. Não usamosGORM, Ent, Prisma nemsqlc no runtime atual. Exemplo real emservices/api/internal/auth/postgres.go: uma transação insere/atualiza usuário e cria a sessão. Valores entram por$1,$2...; não por concatenação de entrada do usuário.

O Prisma era do backend externoFastify/TypeScript, mantido apenas como referência. Não se deve executar migrationsPrisma eGoose sobre a mesma base por conveniência: dois donos do schema criariam divergências.

## Posso ter algo parecido?

Sim, há alternativas, com custos diferentes:

| Caminho | Benefício | Custo/limite |
|---|---|---|
| pgx atual | SQL visível, controle de transação/privilégios | Escrita/mapeamento manual e testes necessários |
| sqlc + pgx | Gera métodos/tiposGo a partir deSQL | Não éORM; exige prova com queries/funções reais |
| GORM | ORMGo com associações/CRUD | Novo mapeamento/convenções; não usarAutoMigrate contra schema crítico existente |
| Ent | SchemasGo e código tipado gerado | Introduz outro modelo/geração; coexistência/migrations precisam desenho |
| Prisma atual | Familiaridade emTypeScript | Não substitui diretamentepgx em Go; adicionar serviçoNode só para isso aumenta operação |

O antigo[prisma-client-go](https://github.com/steebchen/prisma-client-go) comunitário foi arquivado em28/07/2025. Isso é diferente dos exemplos históricosPrisma1 que ainda aparecem nas buscas. A[documentação atualPrisma](https://www.prisma.io/docs/orm) descreve o runtimeTypeScript.

Minha proposta é manter o acesso existente e, se você quiser geração tipada semelhante ao conforto doPrisma, avaliar uma fatia pequena com[sqlc/pgx](https://docs.sqlc.dev/en/latest/guides/using-go-and-pgx.html). [GORM](https://gorm.io/docs/) e[Ent](https://entgo.io/docs/getting-started/) são alternativas reais deORM. Nenhum foi instalado ou escolhido nesta tarefa.

Ausência deORM não garante performance/segurança; presença deORM também não. Os critérios continuam:SQL parametrizado, titularidade, privilégios mínimos, transações, índices, testes e medição. Primeiro aprenda uma operação real e suas tabelas em[diagramas](../diagramas/README.md); depois decida se a troca resolve uma dificuldade concreta.
