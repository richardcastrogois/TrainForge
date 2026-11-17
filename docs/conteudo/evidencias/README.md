# Acervo de pesquisa: originais sem milhares de arquivos soltos

Os **1.901 registros anteriormente versionados** estão em [pesquisas.zip](pesquisas.zip). O [índice](indice.json) conserva caminho original, tamanho e SHA256 de cada arquivo. Foram preservados os bytes do checkout anterior à limpeza, inclusive finais de linha. O checkpoint Git de referência é `b77cf94`; a normalização de EOL doGit pode produzir outro hash do blob sem mudar o texto.

São recibos, levantamentos, análises e scripts datados. O acervo mantém fontes, URLs, falhas, direitos e decisões, sem transformá-los em instruções atuais ou conteúdo aprovado. Arquivos privados ignorados, como corposPDF/HTML e planilhas de terceiros, **não foram adicionados aoZIP público**: continuam em`.local/pesquisa-corpos/docs/conteudo/evidencias/` neste notebook. Ausência em outro clone permanece uma ausência, sem download automático.

## Consultar

Na raiz do projeto:

```powershell
python tools/evidencias.py listar --filtro n15c
python tools/evidencias.py mostrar docs/conteudo/evidencias/2026-10-15/consolidacao-n01-n46.json
python tools/evidencias.py extrair docs/conteudo/evidencias/2026-10-15/consolidacao-n01-n46.json
python tools/evidencias.py verificar
```

`mostrar` lê o original arquivado; `extrair` recupera somente o arquivo pedido em`.local/consulta-evidencias/`, preservando a árvore e sem sobrescrever uma cópia editada. ParaPDF/imagem, extrair e abrir localmente. `verificar` confere todos os hashes sem extrair ou fazer rede. Os consultores de fontes/cuidadores e o preparador usam o leitor de acervo para resolver os caminhos antigos.

Os antigos scripts de rodada são preservados para auditoria, não executados automaticamente. Alguns geram recibos ou dependem de corpos locais e contexto de época. Consultar um documento não autoriza repetir coleta, contornar bloqueio, importar dose ou publicar mídia.

## Por onde ler primeiro

- [Pesquisa, achados e decisões](../pesquisa-e-decisoes.md): perguntas e resultados por etapa.
- [331 fontes/famílias](../catalogo-fontes.md) e [registro estruturado](../fontes.json): nomes, URLs, direitos declarados e pendências.
- [Direitos e curadoria](../direitos-e-curadoria.md): critérios e limites.
- [Integração](../evidencias-para-integracao.md): o que entrou no lote e o que continua bloqueado.
- [Histórico do projeto](../../historico/README.md): como pesquisa e implementação se conectaram para a apresentação.
