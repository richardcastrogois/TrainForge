# Referências visuais e apresentação

O desenho atual parte do [arquivo Figma TrainForge](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl) e da [fonte de interface/validação](../execucao/v1/validacao-e-entrega.md#interface-e-figma). Esta pasta conserva o estudo visual e sua evolução; os SVGs antigos usam dados demonstrativos. A última leitura registrada em 23/10 identificou a página `0:1`, “01 · Produto interativo · v0.5”, com 401 quadros de topo/398 móveis, incluindo variantes. Esta limpeza não fez nova leitura do arquivo vivo.

## Abrir as imagens preservadas

Todos os 42 SVGs originais permanecem intactos. Abra a [prancha](trainforge-board.svg) para mostrar o conjunto, a [marca](trainforge-marca.svg) separadamente ou a [prévia HTML](preview.html) para navegar pelas sete telas históricas. A prévia não é o app atual.

| Tela | Estudo original | Versão do fluxo v0.3 |
|---|---|---|
| Hoje | [SVG](01-hoje.svg) | [SVG](fluxos-v03/01.svg) |
| Planos | [SVG](02-planos.svg) | [SVG](fluxos-v03/02.svg) |
| Treino em curso | [SVG](03-sessao.svg) | [SVG](fluxos-v03/03.svg) |
| Atividade | [SVG](04-atividade.svg) | [SVG](fluxos-v03/04.svg) |
| Alimentação | [SVG](05-alimentacao.svg) | [SVG](fluxos-v03/05.svg) |
| Evolução | [SVG](06-evolucao.svg) | [SVG](fluxos-v03/06.svg) |
| Perfil | [SVG](07-perfil.svg) | [SVG](fluxos-v03/07.svg) |

Demais quadros preservados:

| Quadro | Imagem |
|---|---|
| 08 · Abertura A | [SVG](fluxos-v03/08.svg) |
| 09 · Abertura B | [SVG](fluxos-v03/09.svg) |
| 10 · Entrar | [SVG](fluxos-v03/10.svg) |
| 11 · Criar conta | [SVG](fluxos-v03/11.svg) |
| 12 · Recuperar acesso | [SVG](fluxos-v03/12.svg) |
| 13 · Confirmar e-mail | [SVG](fluxos-v03/13.svg) |
| 14 · Antes de começar | [SVG](fluxos-v03/14.svg) |
| 15 · Escolher áreas | [SVG](fluxos-v03/15.svg) |
| 16 · Treino · objetivo | [SVG](fluxos-v03/16.svg) |
| 17 · Treino · contexto | [SVG](fluxos-v03/17.svg) |
| 18 · Treino · dados opcionais | [SVG](fluxos-v03/18.svg) |
| 19 · Alimentação · preferências | [SVG](fluxos-v03/19.svg) |
| 20 · Alimentação · horários | [SVG](fluxos-v03/20.svg) |
| 21 · Rotina · configurar | [SVG](fluxos-v03/21.svg) |
| 22 · Rever configuração | [SVG](fluxos-v03/22.svg) |
| 23 · Planos · por configurar | [SVG](fluxos-v03/23.svg) |
| 24 · Diário · por configurar | [SVG](fluxos-v03/24.svg) |
| 25 · Rotina · por configurar | [SVG](fluxos-v03/25.svg) |
| 33 · Recuperação · enviada | [SVG](fluxos-v03/33.svg) |
| 26 · A carregar · hoje | [SVG](fluxos-v03/26.svg) |
| 27 · A carregar · planos | [SVG](fluxos-v03/27.svg) |
| 28 · A carregar · sessao | [SVG](fluxos-v03/28.svg) |
| 29 · A carregar · atividade | [SVG](fluxos-v03/29.svg) |
| 30 · A carregar · alimentacao | [SVG](fluxos-v03/30.svg) |
| 31 · A carregar · evolucao | [SVG](fluxos-v03/31.svg) |
| 32 · A carregar · perfil | [SVG](fluxos-v03/32.svg) |

O [manifesto das 33 telas](fluxos-v03/manifest-all.json) e as [83 rotas históricas](fluxos-v03/routes-all.json) preservam o inventário. SVG importado oferece vetores/texto conforme fonte e importador; não cria automaticamente auto layout ou componentes nativos Figma. A versão online usou Inter e recebeu ajustes manuais, sem sincronização automática com o HTML.

## Decisões e uso correto

A [evolução visual](evolucao-visual.md) consolida v0.2, v0.3, v0.4, as validações datadas e a especificação F01–F12. Para apresentar, diferencie o conceito daquela época, a implementação atual e as capacidades ainda pendentes. O [roteiro pessoal](../aprendizado/desenvolvimento-e-apresentacao.md) ajuda a preparar essa explicação. O material SeNAS em `docs/apresentacao-senas/` permanece separado e preservado.

A identidade TF, os rótulos do item ativo, os estados completo/parcial/não feito e o carregamento por região têm decisões registradas. As 372 reações de 17/09 não eram 372 funcionalidades. Formulários, mapas, números, planos e autenticação do protótipo eram ilustrativos; não são conteúdo aprovado para prática.

<a id="reproduzir-os-auxiliares-historicos"></a>

## Reproduzir os auxiliares históricos

Os scripts abaixo só preparam arquivos locais. A saída padrão agora é `.local/design-generated/`, ignorada pelo Git; `--output <pasta>` escolhe outro destino. Nenhum executa o Scripter, escreve no Figma, abre navegador ou inicia o app.

```powershell
python docs/design/build_figma_script.py
python docs/design/prepare_flows.py
python docs/design/build_v04.py
```

| Script | Fontes preservadas | Derivados |
|---|---|---|
| `build_figma_script.py` | `finish_figma_template.js`, `fluxos-v03/routes-all.json` e `manifest-all.json` | `finish_figma.scripter.js` e `script-transfer.html` |
| `prepare_flows.py` | Sete SVGs originais, inventário/rotas v0.3; `routes-all.json` também conserva hotspots de entrada | `transfer.html`, sete cópias SVG com hotspots e manifestos/rotas reunidos |
| `build_v04.py` | Seu catálogo, `v04-template.js` e `fluxos-v03.json` | `v04-spec.json`, `v04-input-audit.json` e `v04.scripter.js` |

Quatro derivados redundantes saíram do Git após reprodução idêntica: `transfer.html`, `script-transfer.html`, `finish_figma.scripter.js` e `v04.scripter.js`. Todos os JSON de origem/inventário e todos os SVGs permaneceram. Os dois JSON v0.4 também foram reproduzidos de forma idêntica, conservando seus originais nesta pasta.

`generate_concept.py` e `generate_flows.py` são as fontes históricas dos desenhos e ainda escrevem nas saídas originais; só usar para uma regeneração intencional após comparar mudanças manuais. `v04-loading-fix.scripter.js` e `v04-validate.scripter.js` são utilitários históricos para o editor: o segundo atualiza pluginData/rodapé no Figma, portanto sua execução também é uma escrita. Não aplicar scripts antigos à página atual por hábito. A reconstrução local foi verificada sem executar nenhum deles no Figma.
