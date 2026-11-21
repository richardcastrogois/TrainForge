# Conteúdo, fontes e integração

O TrainForge conserva origem, autoria, versão e direitos por uso. Pesquisa concluída não equivale a programa publicado ou prática liberada. O fechamento de pesquisa N01–N46 e a triagem editorial são etapas diferentes; o estado atual está no [handoff](../execucao/v1/handoff.md).

| Preciso encontrar | Documento canônico |
|---|---|
| O que foi pesquisado, quando e por quê | [Pesquisa e decisões](pesquisa-e-decisoes.md) e [história para apresentação](../historico/README.md). |
| Fonte, URL, versão, resultado e lacunas por ID | [331 fontes/famílias em JSON](fontes.json) e [catálogo legível gerado](catalogo-fontes.md). |
| Direitos, autoria profissional, revisão e limites de uso | [Direitos e curadoria](direitos-e-curadoria.md). |
| O que foi preparado/revisado e como integrar | [Integração e operações editoriais](evidencias-para-integracao.md). |
| Comparação de APIs, datasets e mídia | [Registro único de opções](opcoes-apis-exercicios.md) e [avaliação MoveKit](avaliacao-movekit-2026-10-29.md). |
| Pesquisa de treinos comprovados por etapa (método de 20/11) | [Protocolo e andamento](pesquisa-treinos/README.md): etapa 1 (idosos), com buscas registradas e matriz de candidatos. |
| Como integrar as mídias após receber o pacote | [Plano MoveKit para o Claude](plano-integracao-midias-movekit.md): inspeção primeiro, ajustes concretos depois, um exercício completo antes do lote. |
| A prova original de uma rodada | [Acervo de pesquisa](evidencias/README.md), com ZIP, índice e consulta por caminho antigo. |
| Uma instrução ou relato anterior à consolidação | [Memória documental e cronologia](../historico/README.md). |

A pesquisa N01–N46 encerrou seus recortes em **21/10/2026**. O balanço, as fontes e os limites da seleção modular estão no guia de pesquisa; esse fechamento não aprovou conteúdo para publicação.

A triagem posterior de **512 ativos** deixou **73 metadados para consulta e 439 excluídos**, sem liberar programa, instrução, dose ou mídia para prática. O catálogo no banco e as rotas de execução não removem esse gate. Não completar dados ausentes por IA nem promover fixture a conteúdo real.

## Consultar sem refazer buscas

```powershell
python docs/conteudo/consultar-fontes.py --help
python docs/conteudo/consultar-cuidadores.py --item CG-01
python tools/evidencias.py listar --filtro n15c
python tools/evidencias.py mostrar docs/conteudo/evidencias/2026-10-15/consolidacao-n01-n46.json
```

`fontes.json`, `catalogo-cuidadores.json`, `fila-cuidadores.json` e `criterios-exercicios-apk.json` conservam registros estruturados. O índice legível de fontes deriva do JSON por `consultar-fontes.py --gerar-indice`; não editar a tabela de fontes separadamente.

O ZIP público contém somente metadados e arquivos já versionados. Corpos de terceiros, planilhas locais, capturas privadas, credenciais e bancos permanecem fora dele. Sua existência local ou um hash coincidente não autorizam redistribuição nem atestam qualidade clínica. Antes de outra pesquisa, localizar a lacuna e a tentativa anterior; não repetir barreiras, contatos ou testes sem necessidade nova.
