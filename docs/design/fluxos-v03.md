# TrainForge — acesso, configuração e navegação v0.3

**Histórico:** a revisão atual está em [fluxos-v04.md](fluxos-v04.md), aplicada pelo Figma Desktop em 17/09/2026. Não reaplicar o script v0.3 sobre as conexões novas.

Estado verificado em 14/09/2026. O foco atual é definir a experiência no **Figma editável** antes de voltar à arquitetura, tabelas e chamadas. Não foram alterados Flutter, API ou banco neste incremento.

Retomada de 16/09/2026: o mapa salvo foi novamente aberto e conferido no Comet, com os quatro fluxos disponíveis. Não foi necessário reaplicar o script. Graphify consultado e atualizado novamente: 0 alterados, 42 inalterados e 0 excluídos no corpus Dart.

## Entrega confirmada

O [arquivo Figma](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl) mantém o nome `TrainForge · Direção de produto v0.1`, na página `01 · Proposta mobile`. Foram confirmadas **33 telas editáveis**, incluindo as sete anteriores. O título antigo não indica a versão do conteúdo.

Em 14/09, após autorização explícita do autor, o Scripter foi executado no Comet e retornou `status: VERIFICADO`, **33 telas e 83 rotas**, com mapa `54:94`. As reações indevidas nos quadros inteiros foram removidas. As 74 ações por clique pertencem aos grupos dos botões; nove transições temporizadas pertencem às telas de abertura/carregamento. O mapa acrescenta cartões navegáveis de revisão e setas visíveis entre etapas.

O [mapa editável](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl?node-id=54-94) está à direita das telas. No modo Protótipo, selecionar um botão exibe a ligação nativa ao destino. No modo Apresentação há quatro pontos de partida: Começar, Explorar, Completar alimentação e Mapa. Para ver a tela móvel inteira no computador, usar Opções → Largura e altura ajustáveis; o modo Responsivo estica estes quadros e não representa a proposta.

## Inventário

| Telas | Conteúdo |
| --- | --- |
| 01–07 | Hoje, Planos, Treino em curso, Atividade, Alimentação, Evolução e Perfil |
| 08–09 | Dois estados da abertura, para demonstrar a animação da marca |
| 10–13 | Entrar, criar conta, recuperar acesso e confirmar e-mail |
| 14–15 | Explicação do uso das informações e escolha das áreas a configurar |
| 16–18 | Treino: objetivo/experiência, contexto e dados opcionais |
| 19–20 | Alimentação: preferências e horários |
| 21–22 | Configuração da rotina e revisão do treino |
| 23–25 | Estados pendentes de treino, alimentação e rotina, cada qual com ação própria |
| 26–32 | Carregamento das sete telas principais |
| 33 | Confirmação condicional do pedido de recuperação de acesso |

## Percursos propostos

- Acesso: abertura → entrar com e-mail/utilizador e senha, Google ou Apple no iOS. Criar conta leva à confirmação de e-mail; recuperação tem resposta condicional, sem afirmar que uma conta existe.
- Primeiro uso: explicação → escolha de áreas. Treino, alimentação e rotina podem ser configurados separadamente, agora ou depois.
- Treino: objetivo e experiência → local, equipamento, dias e duração → dados opcionais → revisão. Os campos propostos precisam ser confrontados com a fonte de planos antes da implementação.
- Alimentação pendente: ação de configurar abre somente as etapas de alimentação, depois volta ao diário. Registar refeições não depende de prescrição automática de dieta.
- Rotina pendente: ação de configurar abre somente a rotina. Nome, atividade e dias são obrigatórios no esboço; horário e lembretes são opcionais.
- Avatar de Hoje e das áreas principais → Perfil. A navegação inferior conserva os ícones e mostra nome apenas no item selecionado.

Altura, peso e informações sobre movimentos/restrições são opcionais no esboço de treino. Preferências e alergias alimentares também são opcionais. Esses dados não representam uma avaliação clínica nem habilitam recomendação automática. O tratamento de informações sensíveis e a necessidade de cada campo permanecem decisões de produto a validar.

## Carregamento e limites do protótipo

A estrutura da tela deve aparecer imediatamente quando disponível: marca, navegação, pesquisa, filtros e definições. O estado de carregamento ocupa apenas os dados ainda indisponíveis. Os ajustes das telas 27 e 32 foram aplicados e vistos na apresentação: pesquisa/filtros de Planos e definições do Perfil permanecem visíveis enquanto os dados carregam.

As transições de 250–350 ms são tempos demonstrativos do protótipo, não esperas artificiais a implementar no app. A abertura tem dois estados para Smart Animate. Redução de movimento, cache, atualização em segundo plano e comportamento sem rede ainda precisam de especificação e teste na plataforma real.

Os formulários, valores, botões sociais e dados são ilustrativos. O protótipo não autentica, não envia e-mails e não guarda informações. `Reenviar e-mail` não tem uma reação simulada. Estados de validação dos campos, erro de envio e salvamento dos formulários ainda precisam de detalhamento. Auto layout, componentes reutilizáveis e acessibilidade real também não estão concluídos.

## Artefatos e reprodução

- `fluxos-v03/manifest-all.json`: nomes e SVGs das 33 telas.
- `fluxos-v03/routes-all.json`: 83 rotas propostas, incluindo nove transições temporizadas.
- `generate_concept.py`: sete telas originais.
- `generate_flows.py`: telas adicionais e estados de carregamento.
- `prepare_flows.py`: reúne os artefatos e as rotas. Preserva as rotas principais do catálogo existente.
- `finish_figma_template.js` e `build_figma_script.py`: geram `finish_figma.scripter.js` para o editor Scripter no arquivo correto. O script confere nomes e destinos antes das alterações e verifica as reações depois; não realiza chamadas de rede. Sintaxe e execução no Figma validadas. Rodar novamente reaplica o catálogo e recria o conteúdo do mapa; revisar antes caso existam ajustes manuais posteriores.
- `transfer.html` e `script-transfer.html`: auxiliares locais de transferência; **não são o Figma entregue**. `preview.html` continua sendo a demonstração histórica de sete telas.

## Validação realizada no Figma

- O script releu as reações das 83 rotas e confirmou os destinos. Isso cobre o catálogo inteiro; a inspeção manual percorreu os casos abaixo, não cada clique alternativo.
- Hoje → avatar → Perfil: destino confirmado na apresentação.
- Criar conta → confirmar e-mail → introdução → escolher áreas → três etapas do treino → continuar sem dados opcionais → revisão: confirmado.
- Alimentação pendente → preferências → horários → diário: confirmado sem repetir as etapas de treino.
- Hoje → rotina pendente → configurar → guardar → Hoje: confirmado.
- Recuperar acesso → enviar instruções → confirmação condicional: confirmado, sem envio real.
- Abertura exibiu a marca e avançou automaticamente para Entrar.
- Os sete cartões de carregamento no mapa avançaram automaticamente aos respectivos destinos: Hoje, Planos, Sessão, Atividade, Alimentação, Evolução e Perfil. Pesquisa/filtros e definições preservados foram inspecionados visualmente.
- Mapa com setas e cartões sem sobreposição foi visto no modo Apresentação. Quatro pontos de partida disponíveis.

GitHub, pesquisa aprofundada de APIs e skill global continuam pendentes e fora deste incremento visual.

## Graphify neste incremento

A retomada consultou `AuthRepository` e suas nove conexões. Ao encerrar a atualização documental em 14/09/2026, `graphify extract .../lib --code-only --no-cluster --out .../trainforge` retornou: **0 alterados, 42 inalterados, 0 excluídos**. O grafo existente foi preservado. Design e documentação não integram esse corpus Dart; não houve extração semântica nem reindexação dos projetos de referência.
