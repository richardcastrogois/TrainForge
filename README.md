# TrainForge

Aplicativo Flutter em desenvolvimento para integrar orientação por conteúdo humano, atividades, alimentação e acompanhamento pessoal. **Android e iOS** são o destino; desenvolvimento e primeiro teste serão em Android.

## Onde começar

- [Documentação atual](docs/README.md)
- [Plano até o APK da V1](docs/execucao/v1/plano-macro.md) e [43 histórias em 12 épicos](docs/execucao/v1/backlog.md)
- [Arquitetura proposta Go + Flutter + PostgreSQL](docs/arquitetura/arquitetura-alvo.md)
- [Painel interativo que acompanha código e planejamento](docs/painel/README.md)
- [Fontes, autoria, direitos e evidências](docs/conteudo/README.md)

## Estado em 21/10/2026

| Frente | Estado real |
|---|---|
| Flutter | Base existente de autenticação, onboarding, home, treino, stats e perfil; revisão necessária para catálogo humano |
| Backend | Fastify/TypeScript/Prisma/PostgreSQL no repositório separado `bootcamp-treinos-api`; Go é proposta para próxima etapa |
| Pesquisa | N01–N46 encerradas nos recortes:40 pesquisas e6 reusos;331 famílias catalogadas. Não significa conteúdo todo homologado |
| N15 |11 componentes modulares para cuidadores; separados de5 movimentos domésticos para idosos; direitos/apoio preservados |
| Planejamento |12 épicos/43 histórias documentadas, não iniciadas; próxima V1-001 |
| Entrega | Nenhum deploy ou APK V1 criado por este planejamento; assinatura, API real e teste ponta a ponta estão no backlog |

Sem treino prescrito por IA, dados de demonstração no runtime ou fonte atribuída sem prova. Não é produto pronto para uso público. Visão integral: [R01–R18](docs/planejamento/visao-produto.md).

## Painel local

```powershell
cd C:/dev/TrainForge/trainforge
./tools/abrir-painel.ps1
```

Abrir [http://127.0.0.1:8787](http://127.0.0.1:8787). O comando reutiliza Python existente; não instala pacotes. [Funcionamento, cobertura e como parar](docs/painel/README.md).

O [guia](guia-do-projeto.md) diferencia ferramentas atuais e futuras. Snapshots antigos estão em [arquivo](docs/arquivo/README.md), mantendo evidências e autoria nos caminhos originais.
