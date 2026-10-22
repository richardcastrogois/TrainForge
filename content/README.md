# Manifestos de conteúdo

`manifests/pilot-candidates.json` é inventário documental de fontes e componentes candidatos, com caminhos relativos à raiz do repositório. Não é seed do aplicativo, lote aprovado ou cópia do catálogo de um fornecedor. Conserva referências, hashes e estados; não contém mídia de terceiros.

Cobertura e decisões: [cenários](../docs/execucao/v1/matriz-cenarios.md), [direção do piloto](../docs/execucao/v1/decisoes-piloto.md) e [comparação de fornecedores](../docs/conteudo/avaliacao-apis-exercicios-2026-10-21.md).

Conferência: `python tools/validar_manifesto_piloto.py`. Alteração de uma entrada exige revisão das referências/hashes e nova conferência, sem promover direitos ou fechar revisões automaticamente. Importadores futuros devem aceitar somente lotes explicitamente aprovados para o uso pretendido, em manifesto distinto.

## Preparação editorial e alimentar

`schemas/editorial-v1.schema.json` separa os tipos editoriais e direitos por operação. `manifests/pilot-prepared.json`, `pilot-rights-matrix.json` e `pilot-review-queue.json` registram a preparação local, sem incorporar os corpos de terceiros ao repositório. [Resultados, comandos e limites](../docs/conteudo/preparacao-local-2026-10-21.md).

`content/local/` é excluído do Git. `editorial-v1.json` e os alimentos continuam candidatos. `editorial-v1-reviewed.json` é a projeção de consulta das operações listadas em `manifests/pilot-approved.json`, com créditos/condições e sem liberação de prática. Não importar a pasta inteira. [Revisão e reconstrução](../docs/conteudo/revisao-consulta-2026-10-21.md).
