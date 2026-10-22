# V1-019 — preflight alimentar offline

Incremento de22/10/2026, independente do loginGoogle e de decisões comerciais. **Validação e staging candidatos implementados; nenhum alimento importado no banco, API ou APK. V1-019 permanece doing.** Não equivale a homologação nutricional, clínica ou de direitos.

## Cobertura processada

Reutilizados os arquivos JSONL e as planilhas já preparados/auditados em21/10. Não foi executado novamente o parserExcel, nem pesquisa, download ou acesso externo. O preflight confere hash do JSONL, da planilha e do reciboHTTP original, além dos manifestos de entrada.

| Fonte local | Identidades por código+nome | Linhas por tabela | Células preservadas | Distinção encontrada |
|---|---:|---:|---:|---|
| Ciqual2025 |3484|3484|261300|3484células do fatorJones separadas das257816células de nutrientes |
| CoFID2021 |2887|37531|808360|13tabelas,14435células de fatores;1código conflitante com2identidades mantidas separadas |
| Total técnico |6371|41015|1069660|Não é total de alimentos semanticamente únicos entre fontes |

Inventário cobre as22famílias de alimentação existentes no manifesto:2com snapshots preparados,8outras famílias de datasets sem lote preparado (incluindo restrições já documentadas) e12referências de reconhecimento visual, métodos ou ferramentas, que não viram tabelas de composição. Nenhuma dessas classificações libera conteúdo ou exige nova busca ampla. Termos/licenças permanecem os registros históricos; aprovação por fonte/uso/versão ainda não foi emitida.

[Recibo agregado](food-preflight-verification.json) guarda contagens, bloqueios e hashes, sem registros completos de alimentos. Cabeçalhos/células/staging/atribuições ficam locais emcontent/local, ignorados. Não sobrescreve a preparação nem os recibos históricos.

## Contrato candidato

Fonte canônica de normalização: `tools/alimentos_lote.py`; execução/checagem: `tools/preparar_alimentos_v1.py`. Contrato `trainforge.food-staging/1`, uma linha por linha/tabela de origem, permitindo ligar as tabelas sem misturar denominadores.

- `candidateIdentity` deriva do conjunto fonte+versão+código+nomeoriginal. É chave técnica candidata, não código inventado de fornecedor nem identidade editorial definitiva. Mesma identidade em várias tabelas permanece ligada; fontes/versões e nomes distintos não se fundem.
- `sourceRowKey`, tabela/linha, versão, código e cabeçalhos vinculados por hash preservam proveniência por célula. Linha repetida idêntica é contada; a mesma chave com conteúdo diferente interrompe o processo.
- `nameOriginal`/idioma preservados; `namePt` e `preparation` separados permanecemnull. O preparo contido no nome não é inferido ou traduzido automaticamente.
- Cada medida aponta para cabeçalho original, unidade detectada e eventual denominador explícito da coluna. Não unifica automaticamente métodos de energia/proteína/fibra ou diferentes nutrientes de fontes distintas.
- Estados `numeric`, `missing`, `trace`, `present_quantity_unknown`, `less_than` e `unparsed` preservados. Números e limites usam strings decimais exatas; valor “menor que” tem limite próprio, nunca valor exato. Raw é retido somente no staging ignorado.
- FatorJones/proporção comestível/densidade e outros fatores não são nutrientes. Valores por100gdeácidosgraxos não são por100gdealimento; essa diferença também é detectada dentro da própria folhaProximates.
- ExceçãoCoFID100g/100ml segue sem unidade resolvida. Mesmo um cabeçalho com100gfood não atribui gramas à base da linha que ainda depende da exceção. Nenhuma densidade vira conversão automática de ml.
- CódigoCoFID conflitante é bloqueado para ambas as identidades, sem escolher primeira linha.15marcadoresnãointerpretados permanecem como tais; negativos e parênteses não viram quantidades válidas.
- `technicalCalculationCandidate` só indica número exato com unidade/base de alimento explícitas, sem conflito/fator/denominadorFA. **Não é autorização de cálculo.** Todos os registros e manifestos fixam `calculationsApproved=false` e `runtimeImportApproved=false`.

Bloqueios são contagens por motivo e podem se sobrepor; não somá-los como total de alimentos excluídos. Compatibilidade técnica de uma célula não aprova a identidade, a cobertura da fonte ou seu uso comercial.

## Comandos sem rede/banco

```powershell
cd C:\dev\TrainForge\trainforge
python tools/preparar_alimentos_v1.py          # analisa; não grava staging
python tools/preparar_alimentos_v1.py --write  # atualiza candidatos locais + recibo agregado
python tools/preparar_alimentos_v1.py --check  # confere hashes já existentes sem recalcular planilhas
python -m unittest discover -s tools -p test_alimentos_lote.py
```

Usar o Python existente do host quando `python` não estiver noPATH. Não repetirwrite sem mudança de insumo/validador. Seminsumos locais legítimos, a execução falha claramente; não baixa substitutos nem cria fixtures de runtime. Caminho externo ao clone é recusado. Temporários exclusivos são removidos somente pelo processo que os criou. Manifesto local, cabeçalhos e arquivos normalizados ficam ligados ao recibo por hashes; alteração invalida a checagem.

A importaçãoGo não foi adicionada nesta fatia: o staging continua sem aprovação. Nenhuma migration, rotaHTTP, contratoSwagger ou tela foi apresentada como entregue apenas por haver candidatos. O APKdebug0.1.1+2 mantém exatamente o hash já validado.

## Validação e próximo incremento

13testes isolados cobrem: ausência/zero/traço/N/limite, adulteração do estado/valor, fatores, denominadoresFA dentro deProximates, basealcoólica sem resolução, separação de cru/cozido com código conflitante, linha divergente, cobertura de tabelas/colunas, hash alterado, tentativa de autopromoção e caminho fora do clone. Mesmo número tecnicamente elegível continua sem permissão. Relocação do clone produz o mesmo resultado; adulterar cabeçalho no manifesto é detectado.

Processamento integral passou com contagens/estados iguais aos insumos auditados; hashes do staging conferidos. Fixtures só existem em diretórios temporários de testes. Nenhum usuário, consumo ou dado demonstrativo criado.

Próximos passos autônomos: revisar evidências de direitos já arquivadas por fonte/operação; resolver correspondência de base/grupoCoFID sem adivinhar álcool; fechar política de identidade/duplicados e mapeamento de nutrientes/métodos. Só então aprovar um manifesto específico e implementar importadorGo idempotente com dryrun e testes em DBdescartável. Pendências que exijam decisão do autor devem ser registradas individualmente, sem transformar todo o módulo em dependência do login.

V1-020/025 continuam dependentes de019/013e dos critérios próprios: busca, cadastro privado e consumo real não foram integrados. [Retomada Android](avaliacao-android.md), [handoff](handoff.md) e [backlog](backlog.md).
