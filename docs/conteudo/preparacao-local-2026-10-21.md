# Preparação local de conteúdo — 21/10/2026

Continuação da etapa01 solicitada pelo autor, com prioridade gratuita e referência de cerca deUS$19 em pagamento único. O inventário V1-001 estava concluído; esta rodada concretizou o contrato editorial V1-004 e preparou dados reais para a revisão V1-005. Não iniciou Go, Flutter, banco, infraestrutura ou APK.

## O que existe agora

| Tipo | Quantidade e origem | Limite |
|---|---|---|
| Movimentos/práticas |109:75exercícios dos snapshots wger e34componentes documentais já selecionados | Não109programas; nenhuma prática automaticamente liberada |
| Registros textuais |329:295traduções originais wger e34registros factuais/rascunhos dos dossiês | Só6traduções wger em português; os rascunhos documentais não são instrução publicada/revisada |
| Referências de mídia |68objetos wger:51imagens e17vídeos | Metadados/URLs; nenhum arquivo de mídia baixado. Não68exercícios ilustrados |
| Programa-fonte |1referência ao protocolo original ES2019-DOM-01/PR28 |5movimentos e contexto originais; oferta no app ainda exige revisão, sem benefício herdado |
| Coleções documentais |5:CG01,CG04,CG06,academia,praça | Não criar circuito de8variantes ReViEEW nem misturar população/apoio/ambiente |
| Ciqual2025 |3.484registros franceses;261.300células de composição preservadas | Base100g conforme cabeçalhos; nomes pt não foram inventados |
| CoFID2021 |2.887registros por código+nome;2.886códigos distintos;13tabelas,37.531linhas e808.360células preservadas | Não somar tabelas como novos alimentos nem fundir as bases; exceções de100ml/100gFA e fatores mantidas |

São registros de fontes diferentes, com possíveis sobreposições;3.484+2.887 não é contagem de alimentos semanticamente únicos. As contagens atuais resultam da leitura integral dos arquivos locais com hash verificado; não reutilizam contagens de amostras antigas.

## Integridade e lacunas concretas

- Cada um dos512ativos editoriais possui fonte, versão disponível, ponteiro JSON e hash do snapshot; movimento, instrução, mídia, protocolo e coleção são distintos. Ausências permanecem explícitas.
- Há14ativos com bloqueios documentais específicos, incluindo divergências doID1022, quatro imagens sinalizadas comoIA e créditos não resolvidos. Os demais continuam candidatos aguardando revisão por uso; esse número não os homologa.
- Direitos são tratados por operação: metadados, texto, mídia, prática guiada e exportação de dataset. Nenhuma operação é autorizada apenas por haver uma URL ou licença de outro ativo. Apoio exigido não pode desaparecer.
- CoFID usa o código13-669 em berinjela preparada e agrião cru. Ambas as linhas foram preservadas, com chave de origem por tabela/linha e conflito sinalizado; não escolher a primeira nem criar um código de fornecedor.
- Numericamente distintos: zero, vazio, traço, quantidade presente desconhecida e limite “menor que”. Quinze valores CoFID permaneceram como marcadores não interpretados, incluindo um negativo e valores entre parênteses; não foram convertidos silenciosamente em nutrientes válidos.
- Na CoFID, tabelas por100gdeácidosgraxos não são por100gdealimento; fatores não são nutrientes. Nas tabelas com exceção para bebidas alcoólicas, a unidade por alimento permanece pendente de correspondência antes de cálculo. Não aplicar regra genérica de100g.
- A leitura de CoFID emite aviso de cabeçalho/rodapé decorativo não interpretável pela biblioteca. As planilhas originais não foram alteradas; a auditoria compara as células de dados preservadas. Não houve renderização/edição de workbook.

## Arquivos e reconstrução

No Git ficam o [schema editorial](../../content/schemas/editorial-v1.schema.json), [resumo do lote](../../content/manifests/pilot-prepared.json), [matriz de direitos](../../content/manifests/pilot-rights-matrix.json), [fila por ativo](../../content/manifests/pilot-review-queue.json), ferramentas e auditoria. Não incluem textos instrucionais completos nem mídia de terceiros.

Os arquivos derivados ficam somente em `content/local/`, excluído do Git: `editorial-v1.json`, `al-ciqual-2025-foods.jsonl` e `al-cofid-2021-foods.jsonl`. São candidatos para preparação, **não seeds autorizados do app**. Os snapshots/planilhas originais permanecem intactos nos caminhos registrados. Um clone sem esses arquivos lê a documentação, mas não reconstrói o lote sem obter legitimamente os mesmos insumos. A ferramenta não faz download automático nem busca outro computador.

Com o Python e openpyxl já existentes no ambiente local:

```powershell
python tools/preparar_conteudo_local.py --write --check
python tools/auditar_conteudo_local.py
python -m unittest discover -s tools -p test_conteudo_editorial.py
python tools/gerar_documentacao.py --write --check
python -m unittest discover -s tools -p test_documentacao.py
```

As operações são locais e não acessam rede/banco. A reconstrução é determinística para os mesmos insumos; `--check` confere hashes, referências, contrato e sincronia da matriz de direitos. O validador local verifica regras do domínio; não alega implementar todo o padrão JSON Schema ou uma API de produção. O schema formal acompanha o contrato para a implementação futura.

## Próxima ação na etapa01

V1-005: revisar a fila por ativo/operação, começando pelos6textos portugueses wger e pelos34componentes dos dossiês, sem excluir o restante da cobertura. Distinguir metadado consultável, expressão textual/mídia incorporável e prática permitida. Registrar responsável, evidência e resultado reais; nenhum profissional/parceiro foi presumido. Ampliar somente a partir de lacuna concreta.

Alimentação: os insumos completos estão preparados; localização, resolução de identidades/bases e aprovação por fonte/uso continuam antes da importaçãoV1-019, que também depende do bancoV1-010. Nenhum alimento foi gravado em banco nesta rodada. Não marcarV1-006/019ouAPK concluídos por existir JSON local.

[Auditoria de512ponteiros e1.069.660células](../execucao/v1/verificacao-preparacao-local.json), [decisões do autor](../execucao/v1/decisoes-piloto.md), [cenários](../execucao/v1/matriz-cenarios.md) e [backlog](../execucao/v1/backlog.md).

## Atualização posterior na mesma rodada

A [revisão de consulta](revisao-consulta-2026-10-21.md) já conferiu os seis textos portugueses e separou73entradas de catálogo/2textos para consulta, com créditos/condições. O lote candidato e sua matriz permanecem sem aprovações automáticas; a projeção revisada é outro arquivo/manifesto. Vinte mapas de exceções de direitos agora ficam no campo próprio `sourceRightsFacts`, com etiqueta de licença desconhecida, respeitando o schema. V1-005 permanece em andamento; prática, mídia, alimentação e entrega noAPK não foram homologadas.
