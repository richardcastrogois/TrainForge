# TrainForge

Aplicativo Flutter em desenvolvimento para integrar orientação por conteúdo humano, atividades, alimentação e acompanhamento pessoal. **Android e iOS** são o destino; desenvolvimento e primeiro teste serão em Android.

## Onde começar

- [Documentação atual](docs/README.md)
- [Plano até o APK da V1](docs/execucao/v1/plano-macro.md) e [43 histórias em 12 épicos](docs/execucao/v1/backlog.md)
- [Arquitetura proposta Go + Flutter + PostgreSQL](docs/arquitetura/arquitetura-alvo.md)
- [Arquitetura dinâmica: mapas, telas, HTTP, banco e progresso](docs/arquitetura/README.md)
- [Fontes, autoria, direitos e evidências](docs/conteudo/README.md)

## Estado em 21/10/2026

| Frente | Estado real |
|---|---|
| Flutter | Base existente de autenticação, onboarding, home, treino, stats e perfil; revisão necessária para catálogo humano |
| Backend | Fastify/TypeScript/Prisma/PostgreSQL no repositório separado `bootcamp-treinos-api`; Go é proposta para próxima etapa |
| Pesquisa | N01–N46 encerradas nos recortes:40 pesquisas e6 reusos;331 famílias catalogadas. Não significa conteúdo todo homologado |
| N15 |11 componentes modulares para cuidadores; separados de5 movimentos domésticos para idosos; direitos/apoio preservados |
| Planejamento |12 épicos/43 histórias documentadas; V1-003 documental em andamento e implementação do app pendente; próxima V1-001 |
| Entrega | Nenhum deploy ou APK V1 criado por este planejamento; assinatura, API real e teste ponta a ponta estão no backlog |

Sem treino prescrito por IA, dados de demonstração no runtime ou fonte atribuída sem prova. Não é produto pronto para uso público. Visão integral: [R01–R18](docs/planejamento/visao-produto.md).

## Entender o projeto sem iniciar ferramentas

Abra a [documentação de arquitetura](docs/arquitetura/README.md): diagramas Mermaid, mapas das telas, chamadas e dados trocados, banco, proposta Go e progresso. Tudo faz parte do clone e pode ser lido no GitHub/editor, sem servidor local.

A CI regenera os derivados em mudanças do código/planejamento e os versiona na branch principal quando as permissões/regras do remoto permitem. [Funcionamento e limites da atualização](docs/arquitetura/documentacao-dinamica.md). O backend Fastify externo é uma referência auditada/versionada, identificada como tal, sem dependência de caminhos deste computador.

[Swagger por comentários Go](docs/arquitetura/swagger-go.md): contrato gerado dos comentários e DTOs, com conferência de divergência. Serviço/Swagger Go real ainda a implementar.

O [guia](guia-do-projeto.md) diferencia ferramentas atuais e futuras. Snapshots antigos estão em [arquivo](docs/arquivo/README.md), mantendo evidências e autoria nos caminhos originais.
