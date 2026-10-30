# Documentação do TrainForge

## Para aprender e operar

- [Começar pelo aprendizado](aprendizado/README.md)
- [Iniciar, acompanhar logs e parar](aprendizado/operacao-local.md)
- [O que cada pasta/ferramenta faz](aprendizado/pecas-do-projeto.md)
- [Banco sem ORM e a dúvida sobre Prisma](aprendizado/orm-e-persistencia.md)
- [Diagramas visuais/editáveis](diagramas/README.md), [tabelas](diagramas/banco.md) e [APIs](diagramas/apis.md)

## Para implementar e retomar

- [Handoff vigente](execucao/v1/handoff.md)
- [Trilha por área](execucao/v1/trilha-implementacao.md) e [backlog](execucao/v1/backlog.json)
- [Mapa estrutural gerado](arquitetura/README.md) e [Graphify](graphify.md)
- [Fonte visual](execucao/v1/frontend-fidelidade-figma.md)
- [Conteúdo e direitos](conteudo/README.md)
- [Avaliação MoveKit](conteudo/avaliacao-movekit-2026-10-29.md)

Estado atual é documentado no handoff; snapshots de2026 anteriores não são instrução para instalar ou recomeçar. Docs de entrada foram atualizados paraGo; Fastify/Prisma continuam referências históricas.

## O que foi preservado e por quê

execucao/v1 guarda decisões e recibos; conteudo guarda evidências/licenças; arquitetura contém contratos e mapas; design e arquivo preservam referências históricas que ainda são citadas. Geradores/protótipos antigos não são funcionalidades do APK. Não apagar essas provas por parecerem antigas.

A limpeza de 29/10 removeu31 arquivos Dart sem referências e63 arquivos dos quatro scaffolds Flutter fora deAndroid/iOS. [Recibo](execucao/v1/repository-cleanup-verification.json). Não limpou bancos, chaves, backups, caches necessários nem provas de origem.
