# Refinamento visual v0.2

10/09/2026. Incremento solicitado pelo autor a partir de seis capturas. Aplicado no [Figma editável](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl) pela aba existente do Comet e reproduzido nos artefatos locais. O código Flutter e a API não foram alterados.

## Alterações

- **Navegação:** nas cinco telas principais, somente o item selecionado exibe nome, centralizado abaixo do ícone. Ícone ativo de 28 px, inativos de 20 px. As áreas de toque da prévia continuam maiores que o desenho dos ícones; os nomes acessíveis dos botões permanecem disponíveis. Sessão de treino e Perfil usam retorno, sem acrescentar uma sexta aba.
- **Marca:** monograma vetorial TF em verde, branco e lima; nome `trainforge` passa de 16 para 24 px. Aplicado aos cabeçalhos das cinco telas principais e do Perfil. Arquivo separado: [marca SVG](trainforge-marca.svg). Trata-se de uma proposta de identidade para refinamento.
- **Semana:** exemplo de segunda concluída (✓ verde), terça não feita (× terracota), quarta incompleta (círculo parcial âmbar), quinta atual e dias seguintes neutros. Legenda explícita para os três estados de execução. O resumo conta `1 feito · 1 parcial`; sessão incompleta não conta como concluída. Datas e valores são demonstrativos.
- **Perfil:** novo frame `07 · Perfil`, 390 × 844, com avatar/iniciais e ação de editar, nome, dados pessoais, objetivos e preferências de treino, notificações, idioma/unidades, privacidade/dados, ajuda/feedback e terminar sessão. Foi mantida a identidade clara do TrainForge; as capturas serviram de referência de conteúdo.

## Artefatos e validação

- Figma: sete frames preenchidos, alinhados em uma linha; textos e vetores editáveis. Inspeção visual de Hoje e Perfil em aproximação e das sete telas em conjunto.
- Local: sete SVGs de telas, marca SVG, prancha e [prévia navegável](preview.html), gerados por `generate_concept.py`. O avatar abre Perfil na prévia; o retorno leva a Hoje. A sintaxe JavaScript da prévia foi validada, sem novo teste de interação no navegador neste incremento.
- Os nove SVGs passaram no parse XML. As sete telas têm dimensões 390 × 844. As cinco navbars têm exatamente um rótulo ativo com alinhamento central.
- Preferências, edição do perfil e logout são demonstrativos. Não existem persistência, sessão real ou dados pessoais novos. Conexões nativas de protótipo Figma e subtelas de configurações continuam para refinamento.
- O Graphify existente foi consultado na retomada. A extração incremental de encerramento usa somente `lib/`, sem reindexar API/web inalterados nem executar extração semântica dos desenhos.

Resultado do Graphify ao encerrar: 42 arquivos inalterados, 0 alterados e 0 excluídos; saídas existentes preservadas.
