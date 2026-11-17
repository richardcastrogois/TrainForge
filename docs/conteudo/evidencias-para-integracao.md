# Conteúdo para integração

Este guia separa pesquisa, preparação, revisão e uso efetivamente permitido. O estado funcional está no [handoff](../execucao/v1/handoff.md); o [backlog](../execucao/v1/backlog.json) define os critérios das histórias. A consolidação documental de **16–17/11/2026** não importou conteúdo, executou migrations, gerou traduções ou aprovou prática.

O fechamento editorial conservou **73 metadados de movimentos para consulta e 439 ativos excluídos, entre 512 triados**. Não há programa, instrução, dose ou mídia liberados para prática. Tabelas/rotas de execução e APK não substituem esse gate. A aprovação pertence à identidade, versão e operação selecionadas, sem herança automática por fonte.

<a id="preparacao-local"></a>
## Preparação local — 21/10/2026

A preparação V1-004 reuniu insumos já obtidos para a revisão V1-005. Os arquivos candidatos não eram seeds autorizados do app. O inventário original foi:

| Tipo | Quantidade/origem | Distinção necessária |
|---|---|---|
| Movimentos/práticas | 109: 75 exercícios dos snapshots wger e 34 componentes documentais | Não eram 109 programas; nenhuma prática ganhou aprovação por estar no lote. |
| Registros textuais | 329: 295 traduções wger e 34 registros/rascunhos de dossiês | Havia seis traduções wger em português; rascunho factual não era instrução publicada/revisada. |
| Referências de mídia | 68 objetos wger: 51 imagens e 17 vídeos | Metadados/URLs; nenhum arquivo de mídia foi baixado nessa preparação. |
| Programa-fonte | Uma referência ES2019-DOM-01/PR28 | Cinco movimentos com contexto próprio, sem benefício herdado pela integração. |
| Coleções | CG01, CG04, CG06, academia e praça | Não criar circuito novo ou misturar população, apoio e ambiente. |
| Ciqual 2025 | 3.484 registros; 261.300 células de composição | Base conforme cabeçalhos, sem nomes portugueses inventados. |
| CoFID 2021 | 2.887 registros; 2.886 códigos; 13 tabelas, 37.531 linhas e 808.360 células | Não somar tabelas como novos alimentos nem fundir as bases. Exceções de base e fatores permaneceram explícitas. |

As contagens são da preparação, não o censo de alimentos sem sobreposição ou de versões efetivamente publicadas no banco. O código CoFID 13-669 aparecia em berinjela preparada e agrião cru; as linhas foram preservadas por tabela/linha, sem escolher a primeira. Quinze marcadores não interpretados, incluindo negativo/parênteses, não foram transformados silenciosamente em nutrientes válidos.

Separar zero, vazio, traço, presente com quantidade desconhecida e menor que. Uma tabela por 100 g de ácidos graxos não é por 100 g de alimento; fator de conversão não é nutriente; 100 ml não vira 100 g sem correspondência documentada. A auditoria preservou células de dados sem editar as planilhas originais.

No Git, manter os contratos e decisões:

- [Schema editorial](../../content/schemas/editorial-v1.schema.json).
- [Resumo do lote](../../content/manifests/pilot-prepared.json), [matriz de direitos](../../content/manifests/pilot-rights-matrix.json) e [fila por ativo](../../content/manifests/pilot-review-queue.json).
- [Manifesto de consulta](../../content/manifests/pilot-approved.json) e [decisões de revisão](../../content/manifests/pilot-review-decisions.json).

Os derivados completos em `content/local/` e os corpos/planilhas de terceiros continuam locais, fora do Git. Um clone novo não deve inventar os insumos ausentes nem fazer download automático para substituí-los. Os snapshots wger e idiomas de `docs/planejamento/evidencias/` continuam entradas de `tools/preparar_conteudo_local.py`.

A verificação de preparação usa `python tools/preparar_conteudo_local.py --check`. Reconstruir com `--write` ou revisar o lote é ação distinta; primeiro conferir insumos/hashes e decisões. Os verificadores históricos que gravam recibos não devem ser repetidos apenas para atualizar a aparência das datas.

<a id="revisao-editorial"></a>
## Revisão editorial e fechamento da etapa 01

A revisão de **21/10** foi documental, pelo agente Codex identificado como tal, sem atribuir qualificação profissional fictícia. Um primeiro recorte separou 73 entradas de catálogo e dois textos para consulta; o fechamento integral posterior deixou somente os 73 metadados e excluiu os outros 439 ativos. A seleção parcial de texto não constitui instrução liberada no produto atual.

| Controle da revisão parcial | Resultado documentado |
|---|---|
| Traduções 2138 e 2789 | Textos existentes conferidos para consulta, com autoria/licença/alterações; não dose, programa ou prática. |
| Tradução 2847 | Revisão técnico-editorial necessária para redação/variante. |
| Traduções 2888 e 2775 | Retidas: redação sem sentido ou descrição de benefícios/anatomia sem execução suficiente. |
| Tradução 2794 / movimento 1670 | Divergência entre círculos e balanço frente/trás; variante retida. |
| Movimento 1022 | Divergência semântica entre traduções preservada, sem escolher uma por inferência. |

O manifesto `pilot-approved` autoriza somente as operações que lista. `runtimeSeed:false`, `practiceApproved:0` e o escopo de entrega precisam ser respeitados; o nome do arquivo não libera todo `content/local/`. O registro prende cada decisão ao hash do candidato. Uma versão nova/alterada exige nova decisão.

Vinte mapas de exceções de direitos foram preservados em `sourceRightsFacts`, com licença desconhecida em `rights.label` quando cabível. Não foram convertidos numa licença uniforme. O validador passou a rejeitar o desvio de tipo sem descartar a informação original.

Os manifests, os recibos de triagem e a [implementação de curadoria](../execucao/v1/implementacao.md#curadoria) distinguem candidato, consulta, expressão incorporável e prática. Continuam exigidos autoria, versão, público, instrução suficiente, direitos por ativo e modo de apoio real. Não inventar programa para ensaiar a jornada e fechar 015/016.

## Proveniência na passagem para API e cliente

Preservar fonte/ID/versão, nome original, ponteiro e hash do snapshot, créditos/licença e alterações da projeção. Nome de apresentação não reescreve o original nem transfere revisão para outra variante. O cliente deve apresentar ausências reais e conservar a comprovação em Fontes e transparência.

Instrução, metadado, mídia, protocolo e coleção são objetos diferentes. A API não pode liberar prática por encontrar movimento no catálogo. Retirada editorial também precisa ser respeitada na leitura; não apagar em cascata a versão usada no histórico.

Na alimentação, a identidade e a base nutricional permanecem vinculadas à fonte/versão. Quantidade informada e cálculo derivado são diferentes do valor original. Alimento particular, nome privado, composição e consumo têm regras próprias de propriedade e não podem ser misturados com publicação editorial.

<a id="nomes-alimentares"></a>
## Nomes alimentares revisados — operação V1-048

A ferramenta local `services/api/cmd/food-names` foi conferida em **26/10/2026** e teve verificações posteriores próprias. Não cria traduções, verifica automaticamente a identidade do revisor ou valida juridicamente a licença. Não existe endpoint editorial público; a API/Flutter/runtime não recebem a credencial de publicação.

A cobertura real registrada era **zero nomes editoriais ativos entre 6.369 versões por idioma**, com fallback ao original. Mensagens da interface e nomes de apresentação não são publicação de nomes profissionais revisados. A capacidade implementada de 048 não autoriza preencher essa ausência por IA. O estado posterior e seus aceites estão no handoff.

Um pacote de publicação conserva:

| Arquivo | Contrato e limite |
|---|---|
| `record.json` | `trainforge.food-names/1`; até 64 KiB brutos e 32 KiB canônicos; identidade/versão e idioma exatos, nome e até 16 aliases. |
| `review.txt` | Revisão humana de até 1 MiB; hash exato em `review.evidenceSha256`. |
| `rights.txt` | Evidência de direitos de exibição/busca de até 1 MiB; hash em `review.rightsEvidenceSha256`. |

O record preserva `foodId`, `foodVersion`, `nameOriginal` e `nameLocale` originais. A revisão identifica `reviewerRef`, data, hashes, atribuição, licença e permissões de exibição/busca para `pt-BR`, `pt-PT`, `en` ou `es`. Um idioma não aprova outro. Campos duplicados/desconhecidos, texto inválido, ambiguidades, excesso de tamanho, evidência alterada e data futura são recusados. [Contrato implementado](../../services/api/internal/nutrition/names.go).

O operador deve verificar a pessoa, a evidência e a identidade/preparo/versão, antes de qualquer publicação. `humanReviewed=true`, um nome digitado ou hash coincidente não substituem essa revisão; hash prova bytes. Pacotes privados ficam em armazenamento controlado, fora do Git. A ferramenta não fornece repositório durável dos documentos nem autenticação de revisores.

O preflight abaixo não lê credenciais nem abre banco; exige substituir o caminho pelo pacote real, não por fixture:

```powershell
./tools/go-api.ps1 -GoArgs @('run','./cmd/food-names','--operation','check-publish','--package','C:/caminho/pacote-revisado')
```

`publish` exige a variável de processo `TF_FOOD_NAMES_DATABASE_URL` com papel migrator no alvo local estrito, confirmação SHA-256 do pacote e `--verified-reviewer-ref`. Não colocar senha em comando, documentação ou chat. Não inicia serviços, cria credencial ou aplica migrations. `inserted=true` significa inserção editorial, não promessa de exibição futura se a fonte for retirada. Reenvio idêntico não incrementa a revisão; versão retirada não revive por republicação idêntica.

Para retirada, o pacote usa `trainforge.food-name-withdrawal/1` e `decision.txt` de até 1 MiB, identificando alimento/versão/idioma/nome exatos, motivo, responsável, data e hash. Usar `check-withdraw` antes de `withdraw`, com confirmação do pacote e responsável verificado. Outra razão não sobrescreve a decisão anterior. A leitura retorna ao original sem ressuscitar tradução antiga. [Contrato de retirada](../../services/api/internal/nutrition/names_withdraw.go).

`coverage` usa papel runtime e transação repeatable-read/read-only. Separa nomes ativos, retirados e fallbacks das versões públicas mais recentes, sem ler nomes privados ou consumos nem alegar qualidade linguística. Os ensaios do binário, retries, permissões e revisão monotônica estão nos recibos e em [verificar_nomes_alimentares.py](../../tools/verificar_nomes_alimentares.py); fixtures descartáveis não foram publicadas na base entregue.

## Consultar uma prova sem repetir a pesquisa

Os metadados originais estão no [ZIP de pesquisa](evidencias/pesquisas.zip), com [índice de caminhos e integridade](evidencias/indice.json). Corpos locais de terceiros permanecem privados em `.local/pesquisa-corpos/`, com a árvore original; não são redistribuídos pelo ZIP público.

```powershell
python tools/evidencias.py listar --filtro n15c
python tools/evidencias.py mostrar docs/conteudo/evidencias/2026-10-15/consolidacao-n01-n46.json
python tools/evidencias.py extrair docs/conteudo/evidencias/2026-10-15/consolidacao-n01-n46.json
python tools/evidencias.py verificar
```

A extração mantém a árvore em `.local/consulta-evidencias/`. A verificação confere hashes sem rede ou regravação de recibos. Os leitores adaptados resolvem os caminhos antigos no acervo; preservar esses ponteiros e os hashes permite auditar a origem sem milhares de arquivos soltos.
