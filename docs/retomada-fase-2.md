# Retomada após a revisão da fase 1

**Handoff histórico:** retomar atualmente por [visão integrada](planejamento/README.md) e [check-ins](planejamento/plano-de-execucao.md). O Figma evoluiu até v0.4 e recebeu apenas especificação de ajustes futuros em 24/09; números e pendências abaixo pertencem à data original. Publicação inicial no GitHub foi autorizada em 24/09; o resultado deve ser conferido no check-in.


**Prioridade atual — 14/09/2026:** o autor direcionou o trabalho ao Figma antes de definir tabelas e chamadas. As 33 telas estão conectadas por 83 rotas verificadas; abertura, carregamento e principais percursos foram testados na apresentação. O Scripter foi explicitamente autorizado e executado. Consulte [fluxos v0.3](design/fluxos-v03.md). GitHub, pesquisa aprofundada de APIs e skill global continuam pendentes. O relato abaixo preserva o histórico de 09–10/09, não substitui esse estado atual.

09/09/2026. O autor esclareceu que a entrega visual precisa estar no **Figma editável**, usa **Comet** e autorizou seguir à fase 2 depois desse ajuste. Pediu Graphify no início de cada trabalho e atualização ao final de cada incremento.

## Correção visual concluída

Arquivo: [TrainForge · Direção de produto v0.1](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl), nos Rascunhos da equipe Richard Gois - DEV, página `01 · Proposta mobile`.

- Favorito confirmado no menu: `Barra lateral: Favoritos`, opção `Favoritos` marcada.
- Seis frames preenchidos de 390 × 844: Hoje, Planos, Treino em curso, Atividade, Alimentação e Evolução.
- Textos e vetores editáveis. O editor exibiu propriedades de Texto/Tipografia para uma camada importada.
- Inspeção final do canvas e árvore confirmou exatamente seis telas; o frame vazio excedente foi removido.
- Dados fictícios, fonte Inter, adaptação do estudo local. Componentes reutilizáveis, auto layout do conteúdo e conexões de protótipo ficam para a fase 3.

Foi usada a aba Figma já aberta no **Comet**. A ferramenta reporta a família Chromium como Chrome; não foi aberto outro navegador. O MCP atingiu o limite Starter e o upload de arquivos locais foi bloqueado. A alternativa que funcionou foi colar SVG textual pelo clipboard, usando a edição normal do Figma. **Não é necessário habilitar acesso a URLs de arquivo nem alterar configurações da extensão.**

Uma tentativa de reload para conferir persistência foi rejeitada pela revisão automática por risco de perda de alterações não salvas. Não foi repetida nem substituída por outro método de recarregamento. O conteúdo foi conferido no editor aberto; reabertura independente não foi validada.

## Estado das próximas entregas

O ajuste visual encerra a pendência identificada da fase 1. Na fase 2, permanecem a publicação do app no GitHub, a pesquisa aprofundada de fontes e a skill global. A triagem oficial já realizada está em [fontes candidatas](pesquisa-fontes.md); não equivale à seleção final nem à pesquisa concluída.

Os remotes existentes são `richardcastrogois/bootcamp-treinos-api` e `richardcastrogois/bootcamp-treinos-frontend`. O Flutter ainda não tem repositório Git; `gh` não foi encontrado no PATH. Nenhum novo repositório, commit ou push foi feito neste incremento. Não alterar organização/histórico do backend implicitamente ao publicar o app.

A fase 3 continua dependente da revisão de escopo/arquitetura: telas e estados detalhados, decisões de primeiro lançamento, scripts, cenários de teste, versões de bibliotecas e implementação.

## Uso do Graphify

O início deste trabalho consultou `AuthRepository` e suas nove conexões no grafo existente, sem repetir a leitura dos 42 arquivos Dart. Este incremento mudou Figma e documentação; os corpora Dart, API e frontend não foram alterados. A atualização incremental ao encerrar preserva os grafos de referência inalterados e não dispara extração semântica de design/docs.

Resultado efetivo da atualização incremental: 0 arquivos de código/documentos/imagens alterados no corpus, 42 inalterados e 0 excluídos. Graphify preservou as saídas existentes com --no-cluster. A inspeção adicional no Figma confirmou a camada real 'O teu diário alimentar' como Texto, Inter Bold 14.

## Refinamento solicitado em 10/09/2026

Aplicado no Comet e nos arquivos locais: navbar com nome somente no item ativo, marca TF e nome ampliado, semana com feito/incompleto/não feito e tela Perfil. O Figma passa de seis para sete telas. Detalhes e limites em [refinamento v0.2](design/refinamento-v02.md). Este pedido visual não conclui as pendências da fase 2 listadas acima.
