# Graphify — cobertura e atualização

## Limpeza de 29–30/10

90Dart/4032nós/4628arestas;31arquivos removidos/90inalterados. ASTincremental code-only eHTML, semLLM/semântica/clusterização. Backup exato em.local/graphify-backup-20261029-learning. Código legado removido não deve orientar diagramas ativos; [mapas didáticos](diagramas/README.md) usam fontes e schema conferidos. [Recibo](execucao/v1/repository-cleanup-verification.json).

## Atualização29/10 — conteúdo limpo e armazenamento

121arquivosDart/4370nós/5129arestas. Ajuste visual e hub de fontes incluídos; depois1arquivoAuthStorage alterado/120inalterados/0removidos. ASTincremental code-only/HTML, semLLM/semântica/clusterização. Backups em.local/graphify-backup-20261029-clean-content e.local/graphify-backup-20261029-storage-policy. CincoARBnão interpretados; Go/SQL seguem nos contratos/Swagger. [UI](execucao/v1/frontend-content-cleanup-verification.json), [armazenamento](execucao/v1/secure-storage-recovery-verification.json).

Conferência final28/10 solicitada pelo autor:0Dart alterados/116inalterados;4254nós/4998arestas mantidos e HTML exportado. AST somente, semLLM. Trabalho parado após o checkpoint.

## Atualização28/10 — seleção privada, metadados e clareza045

116Dart/4254nós/4998arestas. Passagens10alterados/106inalterados e6/110;0removidos. ASTcode-only/HTML semLLM/semântica/clusterização. Backups em.local/graphify-backup-20261028-meal-edit.5ARB não interpretados. [Complemento](execucao/v1/meal-grouping-edit-client-verification.json).

## Atualização28/10 — cliente de refeições045

113arquivosDart;4166nós/4863arestas. Passagem principal:27alterados/86inalterados/0removidos; ajuste final de data:3alterados/110inalterados. ASTincremental code-only e HTMLexportado, semLLM/semântica/clusterização; custoLLM0tokens.5ARB não interpretados. Backups exatos em.local/graphify-backup-20261028-meals/before,automatic eautomatic-final. Go/SQL permanecem nos contratos/Swagger/mapas. [Implementação e limites](execucao/v1/refeicoes-045.md).


## Atualização27/10 — configuração privada047

107arquivosDart;3873nós/4476arestas.17arquivos alterados/novos,90inalterados e0removidos. ASTincremental code-only e HTMLexportado, semLLM/extração semântica/clusterização.5ARBnão interpretados. Backup em.local/graphify-backup-20261027-training-config/before e automático emautomatic, fora doGit. Go/SQL descritos emSwagger e mapas; grafo não comprova persistência nem aceite humano. [Configuração e limites](execucao/v1/configuracao-treino-047.md).


## Atualização27/10 — consumo localizado e restauração tardia

102arquivosDart;3472nós/4015arestas. Primeira passagem6alterados/96inalterados e final2alterados/100inalterados,0removidos. ASTincremental code-only eHTMLexportado, semLLM/semântica/clusterização;5ARBnão interpretados. Backup em.local/graphify-backup-20261027-consumption-names comautomatic/automatic-final fora doGit. Go/SQLdescritos emSwagger/mapas, sem alegar extração semântica. Contagens abaixo preservam os checkpoints anteriores.


## Atualização em 27/10: recuperação de preferências

101 arquivos Dart, 3.420 nós e 3.949 arestas;9 alterados,92 inalterados e nenhum removido na passagem final. AST incremental e HTML exportado, sem semântica, clusterização ou LLM. Cinco ARB não interpretados. Backup em .local/graphify-backup-20261027-native-locale. Inclui controles de retentativa de leitura/escrita, diagnóstico fixo e recursos tipados gerados. [Recibo](execucao/v1/frontend-localization-native-verification.json). A passagem anterior do dia atualizou quatro gerados; contagens abaixo são checkpoints históricos.

## Atualização em 26/10: cliente de nomes revisados

100 arquivos Dart, 3.400 nós e 3.924 arestas; 11 alterados, 89 inalterados e nenhum removido. AST incremental e HTML exportado, sem clusterização, extração semântica ou LLM. Cinco ARB não interpretados. Backup em .local/graphify-backup-20261026-names-client. [Recibo](execucao/v1/frontend-food-names-verification.json). Go e SQL são documentados nos mapas e no Swagger; não foram indexados semanticamente por esta execução.

## Atualização26/10: formulários, privacidade e ajuda localizados

100Dart,3346nós/3864arestas;14alterados/86inalterados/0removidos. ASTincremental code-only eHTML, semclusterização/semântica/LLM;5ARB não interpretados. Backup.local/graphify-backup-20261026-locale-write. [Recibo](execucao/v1/frontend-localization-write-verification.json).

## Atualização26/10: consultas e resumos localizados

98Dart,2521nós/3029arestas;14alterados/84inalterados/0removidos. ASTincremental code-only eHTML, semclusterização/semântica/LLM;5ARB não interpretados. Backup.local/graphify-backup-20261026-locale-read. [Recibo](execucao/v1/frontend-localization-read-verification.json).

## Atualização25/10: fundação de idiomas

96arquivosDart,1699nós/2193arestas;18alterados/novos,78inalterados,0removidos. ASTincremental eHTMLexportado, sem semântica/clusterização/LLM. Backup.local/graphify-backup-20261025-locale-foundation. Inclui locale/controller/preferência, recursos Dart gerados e primeiras telas;5ARB não classificados peloGraphify, cuja cobertura não equivale à tradução do app. [Recibo048 parcial](execucao/v1/frontend-localization-verification.json).

## Atualização25/10: estado alimentar e ambientes

88arquivosDart,1294nós/1734arestas;7alterados/novos,81inalterados,0removidos. ASTincremental eHTMLexportado, sem semântica/clusterização/LLM. Backup.local/graphify-backup-20261025-nutrition-state. IncluiNutritionController/mensagens eAPP_ENV. [Aceite021](execucao/v1/frontend-state-verification.json).

## Atualização25/10: composição Flutter por conta

86arquivosDart,1265nós/1698arestas;11alterados/novos,75inalterados,0removidos. Update incremental code-only/AST eHTML exportado, sem clusterização/extração semântica/custoLLM. Backup.local/graphify-backup-20261025-composition. Inclui fábricas, escopo e injeção nas rotas ativas; comportamento coberto pelos testes do [recibo](execucao/v1/frontend-composition-verification.json), não inferido do grafo.

## Atualização24/10: frontend pontos07–12 — checkpoint dos fluxos disponíveis

83arquivosDart,1235nós/1665arestas;18alterados/novos,65inalterados,0removidos na passagem principal;1arquivo reextraído após a revisão da paginação (82inalterados). Update incremental code-only/AST e HTML exportado. Sem clusterização, leitura semântica ou custoLLM. Backup.local/graphify-backup-20261024-frontend-07-12. Guias de disponibilidade não equivalem a serviços implementados; ver [fonte frontend consolidada](execucao/v1/frontend-fidelidade-figma.md).

## Atualização24/10: Grafite e lima / rolagem por plataforma

80arquivosDart,1185nós/1578arestas;5arquivos alterados/novos,75inalterados,0removidos. ASTsomente e HTMLexportado; sem extração semântica. Backup em.local/graphify-backup-20261024-dark-scroll. Tokens semânticos e comportamento central de rolagem incluídos; sem alegação de validação nativa iOS27.

## Atualização23/10: frontend pontos01–06

79arquivosDart,1179nós/1573arestas;26arquivos alterados/novos,53inalterados,0removidos. Update incremental code-only/AST e HTMLexportado. Sem clusterização, leitura semântica ou custoLLM. Backup em.local/graphify-backup-20261023-frontend-stage01-06. Grafo reflete bootstrap, aparência, movimento, Hoje e loaders; não comprova aceite visual/nativoiOS ou escala.

## Atualização23/10: busca alimentar e porção

72arquivosDart,1038nós/1357arestas;3arquivos alterados,69inalterados,0removidos. Update incremental code-only/AST e HTMLexportado, sem semântica/clusterização. Backup em.local/graphify-backup-20261023-frontend-food.

## Atualização23/10: shell Figma, entrada e perfil

72arquivosDart,1031nós/1342arestas;12arquivos alterados/novos,60inalterados,0removidos. Update incremental code-only porAST e HTMLexportado, sem clusterização/semântica/custoLLM. Backup automático preservado em.local/graphify-backup-20261023-frontend-shell. Novos componentes e resumo diário mapeados; grafo não comprova fidelidade visual.

## Atualização23/10: identidade Figma e correções deexibição

65arquivosDart,918nós/1181arestas;7arquivos alterados/novos,58inalterados,0removidos. Tokens/marca/entrada e exibição alimentar incluídos porAST; HTMLexportado, semanálisesemântica/clusterização. Backup em.local/graphify-backup-20261023-figma-tokens. Fidelidade visual completa permanece pendente; grafo não a comprova.

## Atualização23/10: alimentação particular e consumo

64arquivosDart,905nós/1165arestas. Update incremental porAST:8arquivos alterados/novos,56inalterados,0removidos. Sem leitura semântica ou clusterização; backup em.local/graphify-backup-20261023-nutrition. HTML exportado após o update. O corpusGo permanece no inventário documental/Swagger, sem afirmar que foi semanticamente indexado no grafoFlutter.

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


## Atualização29/10 — clareza, fontes e idioma

121Dart/4370nós/5129arestas. Primeira passagem24alterados/97inalterados; complementos pontuais de privacidade e nutrientes,0removidos. ASTincremental/HTML, semLLM/semântica/clusterização; cincoARBnão interpretados. Backups em.local/graphify-backup-20261029-clean-content; não publicar as cópias datadas. Go/SQL permanecem nos mapas/Swagger. Verexecucao/v1/frontend-content-cleanup-verification.json.
