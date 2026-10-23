# Graphify — cobertura e atualização

## Atualização23/10: privacidade

59arquivosDart,783nós/1001arestas. Atualização incremental porAST dos7arquivos novos/alterados deprivacidade/auth e HTML exportado; sem clusterização, leitura semântica de dossiês ou custoLLM. Backup anterior preservado em.local/graphify-backup-20261023-privacy. A conferência inicial desta retomada encontrou0alterações/55inalterados antes da implementação. Contagens abaixo são históricas.

## Atualização22/10: consulta alimentar

55arquivosDart,705nós/901arestas. Novos modelos/repository/controller/telas de referência alimentar e navegação foram atualizados apenas por AST;7arquivos alterados na primeira passagem, depois somente1/3arquivos dos ajustes concretos de busca/exibição. HTML exportado. Sem clusterização, extração documental ou custoLLM. Backups inicial/final desta fatia retidos em.local/graphify-backup-20261022-food-reference e.local/graphify-backup-20261022-food-reference-final. Contagens de rodadas anteriores abaixo são históricas.

## Atualização22/10: catálogo e controllers

50arquivosDart;10alterados/40inalterados/0removidos,615nós/786arestas. Update incremental code-only e HTML exportado, sem clusterização/custoLLM. Backup desta rodada retido em.local/graphify-backup-20261022-catalog. Contagens anteriores abaixo são históricas.

## Atualização22/10: autenticação Flutter

Atualização incremental somente de código:10arquivos alterados,33inalterados,0removidos;43arquivosDart,499nós/640arestas. graph.json/manifest.json e graph.html atualizados. Sem clusterização/extracão semântica ou custo de LLM; rótulos de comunidades anteriores preservados. Backup automático anterior retido em .local/graphify-backup-20261022, fora do Git. O relatório abaixo preserva a conferência histórica de21/10; não foi refeito para fingir nova análise semântica.

## Conferência histórica21/10

Conferência incremental executada em **21/10/2026**, com a instalação existente. Não houve instalação/upgrade de pacote nem extração semântica dos dossiês.

| Corpus | Arquivos de código | Nós | Arestas | Resultado desta rodada |
|---|---:|---:|---:|---|
| Flutter `lib/` |42|470|607|0 alterados,42 inalterados,0 removidos |
| Fastify `src/`, excluindo generated |33|193|495|0 alterados,33 inalterados,0 removidos |
| Web histórico |53|295|422|Grafo preservado; corpus não mudou e não foi reindexado |

Os dois comandos retornaram exit0 e `no incremental changes detected (--no-cluster); outputs left untouched`. Portanto os grafos já correspondem aos corpora atuais; não inventar novos nós por causa de documentação nova. [Registro desta execução](arquitetura/graphify-2026-10-21.json).

- Flutter: [relatório](../graphify-out/GRAPH_REPORT.md), [visualização](../graphify-out/graph.html), [JSON](../graphify-out/graph.json).
- API: [relatório](referencias/api/graphify-out/GRAPH_REPORT.md), [visualização](referencias/api/graphify-out/graph.html).
- Web antigo: [relatório](referencias/frontend/graphify-out/GRAPH_REPORT.md), [visualização](referencias/frontend/graphify-out/graph.html).

## Atualizar sem repetir trabalho

Python já instalado neste computador:
`C:/Users/richa/AppData/Roaming/uv/tools/graphifyy/Scripts/python.exe`.

```powershell
& 'C:/Users/richa/AppData/Roaming/uv/tools/graphifyy/Scripts/python.exe' -m graphify extract C:/dev/TrainForge/trainforge/lib --update --code-only --no-cluster --out C:/dev/TrainForge/trainforge
& 'C:/Users/richa/AppData/Roaming/uv/tools/graphifyy/Scripts/python.exe' -m graphify extract C:/dev/bootcamp-treinos-api/src --update --code-only --exclude generated --no-cluster --out C:/dev/TrainForge/trainforge/docs/referencias/api
```

Em perguntas sobre arquitetura, consultar primeiro a vizinhança pertinente no grafo, depois conferir arquivos/linhas. Exemplo:

```powershell
& 'C:/Users/richa/AppData/Roaming/uv/tools/graphifyy/Scripts/python.exe' -m graphify query 'workout plans workout detail exercise repository app shell routing' --budget 1200
```

Usar a raiz do corpus/grafo correto. Não enviar todo graph.json como contexto. Atualização estrutural code-only não confirma comportamento de rede nem analisa semanticamente todo o conteúdo pesquisado; arestas INFERRED continuam inferências.

## Documentação dinâmica e Graphify

O [mapa versionado do repositório](arquitetura/README.md) conecta HTTP, telas, schema de referência e backlog em Markdown/Mermaid. Não exige serviço para leitura; a [CI documental](arquitetura/documentacao-dinamica.md) gera/verifica seus derivados. Graphify permanece um mapa estrutural separado. Intenção Go, direitos, aceite e execução real não são inferidos por nenhum dos dois. Código novo em tools/ não foi acrescentado ao corpus Flutter `lib/`; ampliar cobertura deve ser decisão explícita.

Histórico anterior em [arquivo](arquivo/2026-10-21/docs/graphify.md).
