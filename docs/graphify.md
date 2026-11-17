# Graphify: mapa do código e seus limites

Verificação de **17/11/2026**: **95 arquivos Dart,4.430 nós e5.046 arestas**. A atualização atual conferiu zero arquivos alterados: a reorganização de documentos não modificou o Flutter. O grafo e o HTML foram conferidos/exportados; o recibo distingue essa verificação de uma nova extração de código.

## Consultar

Abrir [graph.html](../graphify-out/graph.html), [relatório atual](../graphify-out/GRAPH_REPORT.md) ou [JSON](../graphify-out/graph.json). Não precisa iniciar API, banco ou servidor. O HTML é uma ferramenta de documentação; o produto continua Android/iOS.

O grafo atual vem do AST de `lib/`: classes, funções, imports e relações estáticas. Ele ajuda a localizar o caminho entre shell, controller, repository e modelos. Não cobre semanticamente estes guias, a pesquisa, Go ou SQL. Para esses assuntos use [arquitetura](arquitetura/README.md), [Swagger](../contracts/generated/swagger-v1.json), [banco](arquitetura/diagramas/banco.md) e [histórico](historico/README.md).

Uma aresta não comprova que houve clique, autenticação, persistência, validação de segurança ou aceite humano. Não usar contagens para alegar que o produto está pronto. ARB e cobertura editorial também não são deduzidos do grafo.

## Conferir e atualizar sem varrer toda a pesquisa

```powershell
python tools/atualizar_graphify.py
python tools/atualizar_graphify.py --write
```

O primeiro comando confere mudanças sem escrever; retorna status não zero se encontrar atualização pendente. O segundo faz backup privado, extrai somente Dart novo/alterado, remove referências a arquivos apagados, conserva o restante e exporta HTML. Não executa extração semântica/LLM nem clustering. Os derivados ficam em `graphify-out/`; backups em`.local`.

O interpretador existente é indicado em `graphify-out/.graphify_python`. Se o caminho não existir em outro computador, configurar uma instalação local apropriada; o helper não baixa ou instala ferramentas. Não executar um rebuild da raiz incluindo bancos, corpos de fontes, dependências ou milhares de arquivos históricos.

Os numerosos checkpoints anteriores foram reunidos no [acervo histórico](historico/README.md). Grafos das antigas bases Fastify/web ficaram na memória documental; não representam o backend atual nem precisam continuar como duas árvores de arquivos ativos.
