# Mapas do TrainForge

> Índice gerado de `mapas.json` por `tools/gerar_diagramas.py`; não editar à mão.

Comece por produto, arquitetura e telas. Abra [o índice visual](index.html) localmente ou cada SVG no navegador/editor. O [arquivo draw.io](trainforge.drawio) contém os mesmos 15 mapas em páginas separadas, editáveis no draw.io Desktop/extensão VS Code.

| Página | Mapa | Prévia |
|---|---|---|
| 01 | O que o TrainForge oferece | [SVG](01-produto.svg) |
| 02 | Quem conversa com quem | [SVG](02-arquitetura.svg) |
| 03 | Mapa das telas ativas | [SVG](03-telas.svg) |
| 04 | Como a sessão nasce e continua | [SVG](04-login.svg) |
| 05 | Da quantidade ao registro alimentar | [SVG](05-consumo.svg) |
| 06 | Publicação e leitura do catálogo | [SVG](06-catalogo.svg) |
| 07 | O que fica em cada lugar | [SVG](07-dados-no-aparelho.svg) |
| 08 | Iniciar, observar e parar | [SVG](08-ambiente.svg) |
| 09 | MoveKit: proposta de integração | [SVG](09-midia-proposta.svg) |
| 10 | Como uma alteração chega ao GitHub | [SVG](10-qualidade.svg) |
| 11 | Banco: identidade e privacidade | [SVG](11-banco-identidade.svg) |
| 12 | Banco: treino e configuração | [SVG](12-banco-treinos.svg) |
| 13 | Banco: alimentos e refeições | [SVG](13-banco-alimentacao.svg) |
| 14 | Banco: editorial e importação | [SVG](14-banco-editorial.svg) |
| 15 | Banco separado: catálogo | [SVG](15-banco-catalogo.svg) |

Verde: existente; amarelo: parcial; cinza tracejado: planejado; lilás: externo. Setas de tela representam navegação; HTTP/SQL representam comunicação; FK representa referência, sem ordem de INSERT. Uma tabela pode aparecer repetida para manter as relações legíveis.

[APIs](apis.md) · [Tabelas e colunas](banco.md) · [Arquitetura explicada](../README.md) · [Operação diária](../../aprendizado/operacao-local.md).

Fontes revisadas: `mapas.json`; metadados sem registros: `schema-publico.json`. Alterar a fonte e regenerar; uma edição direta do derivado é substituída na próxima geração. O snapshot de schema conserva sua data original, sem alegar nova consulta ao banco.

Aplicada a skill [draw-io-diagram-generator](https://github.com/github/awesome-copilot/tree/5269f7ea2d6c3a9bfda5ed878b6726cf509121fd/skills/draw-io-diagram-generator), fixada nessa revisão. Arquivos locais, sem envio a serviço externo e sem conteúdo de fornecedor copiado.
