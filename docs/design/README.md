# TrainForge — referências e evolução do design

**Entrada atual — 24/09/2026:** a base aplicada é a [v0.4](fluxos-v04.md), com cópia preservada em 22/09. O próximo trabalho está detalhado em [ajustes da visão integrada](ajustes-visao-integrada.md); não foi aplicado ao Figma nesta entrega. Consultar esse documento antes de reutilizar geradores ou tratar o HTML como entrega atual.

**Histórico concluído em 14/09/2026:** o Figma contém 33 telas editáveis, 83 rotas verificadas, abertura animada, sete estados de carregamento e mapa navegável. Inventário, percursos testados e limites estão em [fluxos v0.3](fluxos-v03.md). A prévia HTML abaixo é o artefato histórico de sete telas, não a entrega atual do Figma.

Estudo original de interface, com dados fictícios. Não é implementação Flutter nem plano de treino para utilização real.

- Abra `preview.html` para navegar entre as sete telas, incluindo Perfil pelo avatar.
- Abra `trainforge-board.svg` para ver o conjunto e `trainforge-marca.svg` para a proposta de marca.
- Os SVGs individuais podem ser importados no Figma e usados como base de refinamento. Vetores são editáveis; tratamento de texto depende do importador/fontes. Eles não possuem auto layout nem componentes nativos Figma.
- `generate_concept.py` reproduz apenas esses artefatos de design; não executa ações do produto nem altera o app.

O arquivo Figma [TrainForge · Direção de produto v0.1](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl) contém as sete telas principais e 26 telas/estados adicionais. Está nos Rascunhos e foi adicionado aos Favoritos. O nome do arquivo foi preservado; seu conteúdo recebeu o [refinamento v0.2](refinamento-v02.md) e a expansão [v0.3](fluxos-v03.md) pelo Comet.

A colagem de SVG textual pelo clipboard funcionou pelo fluxo normal do editor. A inspeção confirmou texto editável e vetores; o arquivo não é uma captura plana do HTML. A versão online usa Inter e adapta o estudo local, sem sincronização automática. Componentes reutilizáveis e auto layout permanecem para refinamento. As conexões nativas foram aplicadas pelo Scripter autorizado e verificadas no Figma.

Decisões e limitações detalhadas em [proposta visual](../proposta-visual.md).
