# Diagramas do TrainForge

Mapas de aprendizado do estado em 29/10/2026. Comece pelos números01–05; depois avance para dados e operação. A propostaMoveKit está claramente separada do sistema implementado.

**Ver:** abra index.html no navegador local, ou osSVG no VSCode/navegador. **Editar:** abra o.drawio com draw.io Desktop ou a extensãoVSCode hediet.vscode-drawio. Nenhum arquivo foi enviado a serviço externo. A extensão não foi instalada automaticamente.

| Mapa | Prévia | Editável |
|---|---|---|
| O que o TrainForge oferece | [SVG](01-produto.svg) | [draw.io](01-produto.drawio) |
| Quem conversa com quem | [SVG](02-arquitetura.svg) | [draw.io](02-arquitetura.drawio) |
| Mapa das telas ativas | [SVG](03-telas.svg) | [draw.io](03-telas.drawio) |
| Como a sessão nasce e continua | [SVG](04-login.svg) | [draw.io](04-login.drawio) |
| Da quantidade ao registro alimentar | [SVG](05-consumo.svg) | [draw.io](05-consumo.drawio) |
| Publicação e leitura do catálogo | [SVG](06-catalogo.svg) | [draw.io](06-catalogo.drawio) |
| O que fica em cada lugar | [SVG](07-dados-no-aparelho.svg) | [draw.io](07-dados-no-aparelho.drawio) |
| Iniciar, observar e parar | [SVG](08-ambiente.svg) | [draw.io](08-ambiente.drawio) |
| MoveKit: proposta de integração | [SVG](09-midia-proposta.svg) | [draw.io](09-midia-proposta.drawio) |
| Como uma alteração chega ao GitHub | [SVG](10-qualidade.svg) | [draw.io](10-qualidade.drawio) |
| Banco: identidade e privacidade | [SVG](11-banco-identidade.svg) | [draw.io](11-banco-identidade.drawio) |
| Banco: treino e configuração | [SVG](12-banco-treinos.svg) | [draw.io](12-banco-treinos.drawio) |
| Banco: alimentos e refeições | [SVG](13-banco-alimentacao.svg) | [draw.io](13-banco-alimentacao.drawio) |
| Banco: editorial e importação | [SVG](14-banco-editorial.svg) | [draw.io](14-banco-editorial.drawio) |
| Banco separado: catálogo | [SVG](15-banco-catalogo.svg) | [draw.io](15-banco-catalogo.drawio) |

## Como interpretar

- Verde: existente; amarelo: parcial; cinza tracejado: planejado; lilás: sistema externo.
- Setas de tela são navegação. SetasHTTP/SQL são comunicação. FK nos mapas de banco significa referência, não chamada.
- Nos mapas de banco uma tabela pode aparecer mais de uma vez para evitar cruzar linhas; a lista completa de colunas está em banco.md.
- Layout resumido não substitui contratos/permissões/testes. Tabelas vazias de treino não equivalem a produto pronto.

[Todas as tabelas/colunas/restrições](banco.md) · [Todas asAPIs](apis.md) · [Aprender e operar](../aprendizado/README.md)

## Manutenção e skill

Fontes: mapas.json contém relações revisadas; schema-publico.json guarda apenas metadados, sem registros. tools/gerar_diagramas.py gera XML eSVG da mesma fonte; --check detecta divergência. Mudança de schema exige novo snapshot read-only e revisão dos mapas. As fontes de cada mapa estão emmapas.json.

Aplicada a skill[draw-io-diagram-generator](https://github.com/github/awesome-copilot/tree/5269f7ea2d6c3a9bfda5ed878b6726cf509121fd/skills/draw-io-diagram-generator), fixada nessa revisão e instalada em.local/skills. Artefatos são fontes do projeto; nenhum conteúdo de fornecedor foi copiado para os diagramas.
