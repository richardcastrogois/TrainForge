# Melhoria: navegação em 5 posições e tela Hoje em dois cenários

Estado em 27/11/2026: **aprovado e implementado no código; não visto no celular nem publicado em APK**. Faz parte do C44 (redesenho didático) no [checklist](checklist-incremento-lancamento.md).

## Por que mudar

Simulação das 5 abas no primeiro uso (27/11):

- a tela inicial repetia a aba Planos;
- o mesmo destino, a biblioteca de treinos, tinha 7 entradas (Hoje, Planos e Atividade);
- quase todos os cartões diziam "indisponível";
- Atividade e Evolução mostravam o mesmo histórico.

Para pessoas mais velhas ou pouco familiarizadas com tecnologia, isso é informação demais e sem uma ação clara.

## Pesquisa de mercado (27/11/2026)

Fontes: páginas oficiais e imprensa. Os apps não foram abertos em mãos.

| App | Abas | Adicionar | Perfil |
|---|---|---|---|
| MyFitnessPal (abr/2026) | Hoje · Planos · **+** · Progresso | "+" central: comida, água, peso, exercício | foto no topo à direita |
| Strava | Início · Mapas · **Gravar** · Grupos · Você | Gravar com escolha do esporte | aba Você |
| Google Health (ex-Fitbit) | Hoje · Fitness · Sono · Saúde | coach flutuante | topo |
| Apple Fitness (iOS 26) | Resumo · Fitness+ · Treino · Busca | aba Treino | foto no topo |
| Samsung Health (jun/2026) | painel + atalhos no topo por área | — | topo |
| Nike Training Club | Início · Treinos · Atividade · Perfil | — | aba |
| adidas Running | Atividade · Comunidade · Progresso | um "iniciar" com 90+ esportes | aba |
| Yazio | Diário · Receitas · Jejum · Análise · Perfil | — | aba |
| Lifesum | Diário + "+" central | "+" para comida | — |
| Freeletics | Comunidade · Coach · Perfil | — | aba |

No Brasil, a Smart Fit lidera o uso em pesquisa de 2026 e as avaliações reclamam de navegação lenta.

### Padrões adotados

1. **A primeira aba é "Hoje":** mostra o resumo do dia e o próximo passo, sem repetir outras abas.
2. **O "+" no centro é atalho e não substitui as abas.** O MyFitnessPal perdeu nota em abr/2026 ao esconder o diário atrás do "+".
3. **Nenhum app cria uma aba por esporte.** As modalidades (academia, casa, rua, corrida, caminhada, yoga, pilates) entram como **filtros no topo de Treinos**; uma nova modalidade vira um filtro novo.
4. **Perfil, ajustes, termos e sair ficam na foto no canto superior direito.**
5. **Vidro só na camada de navegação** (Apple, WWDC25), e o "+" fica dentro da barra, não solto acima dela (crítica da NN/g).

## Estrutura aprovada

- **Barra:** Hoje · Treinos · **(+)** · Alimentação · Evolução.
  - O "+" é maior e fica no centro.
  - Cada ícone tem o nome escrito embaixo.
- **Hoje:** dois cenários (abaixo).
- **Treinos:** biblioteca com filtros de modalidade. Absorve "Treinos prontos", "Criar o meu plano" e "Ajuda-me a começar" de Planos.
- **Alimentação:** comida e água ([hidratação](melhoria-hidratacao.md)).
- **Evolução:** estatísticas e histórico. Absorve a aba Atividade.
- **(+):** janela de vidro que sobe de baixo (painel), fecha arrastando, com atalhos grandes:
  - Treino;
  - Corrida/caminhada;
  - Refeição;
  - Água;
  - Peso/medidas.
- **Foto no topo à direita:** painel igual, com perfil, ajustes, termos e sair.
- **Recursos indisponíveis saem da tela** até existirem. O código fica, como em [APK simples](melhoria-apk-simplificado.md).

## Tela Hoje: dois cenários

A troca de cenário acontece no **primeiro registro de qualquer tipo** (treino, refeição ou água). Não depende de tempo nem de meta.

### A. Acabou de instalar (nenhum registro)

**Meta:** uma pessoa idosa entende em 3 segundos o que fazer.

- Saudação curta e **uma frase**: "Vamos começar seu primeiro treino?".
- **Um único cartão grande com a foto do lugar escolhido, que é o próprio botão.**
  - Ele mostra o lugar, a duração e o nível.
  - Um botão escrito "Começar" ocupa a largura toda.
- Nada de números, semana, "—" ou cartões "indisponível".
- A barra continua igual nos dois cenários. Mudar a navegação depois confunde.
- **Sem dica flutuante no primeiro uso.** Depois do primeiro registro, uma única dica pode apontar o "+" ("Aqui você registra água, comida e treinos"), mostrada uma vez.

### B. Já usa (há algum registro)

- Saudação e data.
- O cartão do próximo treino fica menor: a foto passa a ser só visual e o botão principal continua presente.
- Uma faixa com o dia: treino feito ou não, copos de água e refeições registradas. Cada item leva ao detalhe.
- A semana aparece só aqui.

## Regras de acessibilidade (valem para as 5 telas)

- Texto do corpo com pelo menos 18; títulos de 24 a 28.
- Área de toque de pelo menos 56 × 56.
- Uma ação principal por tela, escrita com verbo ("Começar", "Registrar").
- Nomes visíveis sob os ícones da barra.
- Contraste AA: texto escuro sobre o laranja de destaque, branco só sobre o verde-escuro ou sobre foto com sombra.
- Animação para quando a opção de reduzir movimento estiver ligada.
- O vidro fica opaco com alto contraste (`glass_surface.dart`).

## Antes de implementar

1. Mockups da Hoje (cenários A e B), do painel do "+" e do painel do perfil, gerados no PC e aprovados pelo autor.
2. Textos em pt-BR: a simulação mostrou textos de Portugal ainda no `app_pt_BR.arb`, por exemplo "Olha o que já construíste", "Cada registo conta", "Planear e aprender", "Ajuda-me a começar" e "Criar o meu plano".
3. Implementar em incrementos:
   1. barra e painéis;
   2. Hoje A/B;
   3. fusão Planos→Treinos e Atividade→Evolução;
   4. esconder os "indisponível".

   Cada incremento tem testes, verificação no celular e commit próprio.

## Implementação (27/11/2026)

- Barra: `lib/shared/widgets/figma_bottom_nav.dart`, com textos em `shell_labels.dart`. O arrastar para trocar de aba foi mantido e pula o "+".
- Painéis de vidro: `glass_sheet.dart`. O "+" mostra só o que funciona nesta versão: treino, refeição e, com o diário offline, voz e foto (`NutritionPage.start`).
  - **Ficaram fora até existirem:** corrida/caminhada, água e peso/medidas.
- Perfil na foto: painel com Perfil e ajustes (página de conta), Privacidade e termos, Ajuda e Sair.
  - A foto do usuário ainda não existe; a foto mostra as iniciais.
- Hoje A/B: `today_page.dart` e `TrainingHeroCard(first:)`.
  - Com "registro" ainda contam só as refeições, porque os treinos da biblioteca não geram registro de sessão.
- Treinos: `workouts_overview.dart` com `TrainingLibraryView`; os lugares da pesquisa são os filtros de modalidade.
- Alimentação: sem os cartões Hidratação e Planejar; botão grande, voz e foto; energia só quando existe.
- Evolução: `EvolutionPage` reaproveita o motor de sessões da antiga aba Atividade (`ActivityPage` com título e estado vazio próprios) e o diário alimentar.
- Removidos: `plans_overview.dart`, `ActivityOverview`, `EvolutionOverview` e o cartão "Monte seu treino". Os textos pt-PT em `app_pt_BR.arb` foram trocados (11 chaves).
- Validação: análise 0 e 414 testes Flutter. As telas foram conferidas em imagens renderizadas no PC (Inter e fotos reais, 1080×2340); falta ver no aparelho.

### Revisão do autor (27/11/2026)

- **Barra:** sem nomes, só ícones; os nomes continuam para leitor de tela e dica de toque longo. Isso troca a recomendação de nome visível por decisão do autor.
  - A página aberta sobe num círculo verde encaixado num entalhe do vidro, no estilo das referências enviadas.
  - O arraste com o dedo leva o círculo e o entalhe com esticada "líquida" e volta com leve rebote; o efeito some com a opção de reduzir movimento.
  - O "+" laranja fica fixo no centro.
- **Perfil:** só a foto da conta Google em círculo, sem borda; sem foto aparecem as iniciais. O toque abre um cartão pequeno no topo (nome, e-mail, Perfil e ajustes, Sair) em vez do painel de baixo.
- **shadcn:** `shadcn/ui` é React/web. Para Flutter existem ports (`shad`, `shadcn_flutter`, `shadcn_ui`), não adotados; trocar a base de componentes é decisão à parte.

### Segunda revisão do autor (27/11/2026, testada no celular na 0.5.8)

Problemas vistos pelo autor e correções:

- **O círculo passava por cima do "+".** Agora ele afunda na barra perto do "+" e reaparece do outro lado, tanto no toque quanto no arraste. Soltar o dedo sobre o "+" leva à página mais próxima.
- **O círculo esticava e havia uma sombra que piscava.** O esticão foi removido. A "sombra" era o efeito de toque (ripple) do ícone, que saiu: a lente é o único retorno visual.
- **O entalhe tinha um corte reto.** Ele agora usa `CircularNotchedRectangle`, com ombros curvos, recortado nos cantos arredondados.
- **O "+" ficou maior (62) e saltado**, como os "+" centrais do MyFitnessPal e o Gravar do Strava, e fica fixo acima da barra.
- **Liquid Glass:** a lente do círculo ativo usa `liquid_glass_widgets` 1.22.0 (MIT, sem dependências de terceiros, Flutter ≥ 3.41), com qualidade premium e refração. Em Skia ou GLES o pacote cai para o modo leve. O `liquid_glass_renderer` 1.0 foi descartado: ainda é pré-lançamento e exige Flutter 3.47 com Flutter GPU.
- **Alimentação:** o ícone da aba agora é talheres com uma gota (comida e bebida).
- **Hidratação (C43, parcial):** o cartão "Água de hoje" na Alimentação e "Beber água" no "+".
  - Copo de 200 ml e garrafa de 500 ml, gravados como consumo de "Água" do catálogo (g = ml), com "Desfazer".
  - Decisões assumidas sem o autor: só água, volumes 200/500, sem meta nem referência EFSA e sem lembretes. Ver [hidratação](melhoria-hidratacao.md).
- **Foto do perfil:** a foto do Google é salva no login e buscada em silêncio uma vez para quem já estava logado. Em "Perfil e ajustes → Foto do perfil" dá para escolher da galeria, tirar uma foto, voltar à do Google ou remover.
  - A foto fica só no aparelho, em pasta privada, e é apagada junto com a conta. A API não guarda foto.

### Terceira revisão do autor (27/11/2026)

- **Liquid Glass no fundo da barra, não no ícone.**
  - A barra é um `GlassContainer` premium do `liquid_glass_widgets`: refração do conteúdo que passa atrás, luz na borda e aberração cromática leve. Os shaders são pré-aquecidos em `main.dart`.
  - O círculo da página aberta voltou a ser verde sólido.
  - O pacote não recorta o vidro, então o entalhe saiu. Alto contraste usa barra opaca.
- **Novo ícone de Alimentação:** garfo e copo com linha de água (`assets/figma/food-drink.svg`).

### Quarta revisão do autor (27/11/2026, referência: barra do Telegram no iOS 26)

- A barra passou a ser o `GlassTabBar.bottom` do `liquid_glass_widgets`, o padrão do iOS 26:
  - parada, a aba aberta fica numa pílula de vidro;
  - ao pressionar e arrastar, uma lente de vidro líquido cresce, segue o dedo e amplia o que está embaixo;
  - ao soltar, abre a aba e a lente volta a ser pílula.
- **Só o "+" fica saltado.** O espaço dele na barra abre o painel do "+" e nunca vira página. O círculo verde que subia na aba aberta saiu.
- Cada ícone é desenhado duas vezes pelo pacote (a lente usa uma cópia própria). Por isso os testes usam o primeiro ícone encontrado.

### Quinta revisão do autor (27/11/2026)

- **Fundo da barra:** vidro líquido com um pouco de fosco (`blur` 9 e tinta clara 26%), como no iOS, para os ícones continuarem legíveis sobre conteúdo cheio.
- **Lente sobre o ícone:** o ícone da aba fica laranja e a pílula ganha um tom laranja leve.
  - O laranja do ícone é mais escuro (`#D95C0B`) para manter contraste de 3:1 sobre o vidro claro; no tema escuro fica o laranja do destaque.
- **"+":** mais baixo, de vidro líquido laranja e sem a borda branca.
- **Vidro líquido no app:** `GlassSurface` agora é vidro líquido com fosco (painel do "+", menu do perfil e pílula "Ver treinos"). O novo `LiquidButton` é usado em "Registrar refeição" e "Ver treinos" (Evolução), e o "Começar" da Hoje também é de vidro. Alto contraste continua opaco.
- **Ainda sem vidro:** formulários, chips e cartões de lista, para manter a leitura.

### Sexta revisão do autor (27–28/11/2026)

Cores: **verde é a principal e laranja a secundária** (60% neutro, 30% verde, 10% laranja). O laranja marca só o que deve chamar o olho: o "+", o ícone da aba aberta, o "Começar" da Hoje, a chama da sequência e o botão do primeiro treino da Evolução.

- **Barra:** vidro líquido claro com um pouco de fosco (`blur` 3,2, tinta 24%), sem pílula colorida; só o ícone da aba aberta fica laranja. O "+" é laranja sólido sob a borda de vidro, com sombra leve.
- **"+":** abre um leque de três bolhas de vidro colorido (Treino, Refeição, Água) em arco acima dele, sem textos. O "+" gira suave até virar "×" e volta; as bolhas saem uma após a outra e voltam ao "+". Tocar em qualquer outro lugar fecha o leque e o toque segue para a tela.
- **Hoje, primeiro uso:** o card do treino ocupa 44% da altura da tela (entre 280 e 430) e, logo abaixo, a semana com hoje em laranja, só para ver. Sem rolagem.
- **Evolução:** painel único (`EvolutionPreview`), animado em loop enquanto a aba está aberta (parado com "reduzir movimento"):
  - **Consistência do mês:** um bloco por dia, de segunda a domingo, ocupando a largura. Cada dia ganha um terço de verde por treino feito, refeição registrada e água registrada.
  - **Sequência:** dias seguidos com algum registro; a chama cresce com a sequência (apagando em 0, fogo com brilho a partir de 7).
  - **Minutos e séries:** das sessões do mês (cancelada não conta). **kcal do dia** só quando o resumo está completo. **Água do dia** em ml, com ondas no card.
  - Antes de qualquer registro, os cards mostram uma prévia animada e o botão "Começar primeiro treino". O card "Meu diário alimentar" saiu (a aba Alimentação já cumpre esse papel).
  - Dados: `evolution_source.dart` lê as sessões já carregadas pela página e o diário do mês. Ainda **sem metas**: a sequência conta qualquer registro e a água não tem nível de meta.
- **Responsividade:** Evolução sem rolagem de 360x740 até tablet (inclusive texto 1,3×), com modo compacto abaixo de 800 de altura; em 360x640 e 320x568 a página rola.

### Alimentação (28/11/2026)

Mesma linguagem da Evolução: verde principal, um único botão laranja, cards brancos com cantos contínuos, sem rolagem a partir de 390x844 (e 411x891 do A34).

- **Primeiro acesso:** "Qual é o seu objetivo?" em 6 cards (ícone no canto, nome embaixo): Perder gordura, Manter o peso, Ganhar massa, Recompor o corpo, Render mais no treino e Comer melhor. "Definir eu mesmo" saiu. Em telas com menos de 860 de altura os cards ficam em 3 colunas.
- **Com objetivo:** o bloco vira "Sua meta do dia · objetivo" com proteína (alvo pelo peso) e energia de hoje; "Ajustar" volta à escolha. O objetivo fica salvo no aparelho junto das primeiras respostas (`foodGoal`).
- **Anéis do dia:** por fora uma fatia por refeição planejada (4 ou 5 conforme o objetivo; entradas de comida com até 1 h de distância contam como uma refeição); por dentro a água em relação à meta. Tocar abre o diário.
- **Água em gotas:** 8 gotas, cada uma 1/8 da meta (sem meta, 200 ml), com "+ copo" e "+ garrafa" (mesmo registro e desfazer de antes).
- **Registrar refeição** (laranja) e as formas: Falar, Foto, Buscar. Saíram o card de energia, os botões azul/amarelo e "Meus registros".

Metas sugeridas, todas como ponto de partida editável (`food_goals.dart`), com aviso para gestantes, menores de 18 e quem tem alguma doença:

| Objetivo | Refeições | Proteína (g/kg/dia) |
|---|---|---|
| Perder gordura | 4 | 2,0 |
| Manter o peso | 4 | 1,4 |
| Ganhar massa | 5 | 1,6 |
| Recompor o corpo | 4 | 2,0 |
| Render mais no treino | 5 | 1,6 |
| Comer melhor | 4 | 0,8 |

- Proteína: ISSN, posicionamento "Protein and exercise" (Jäger et al., 2017): 1,4–2,0 g/kg/dia para quem treina, mais em déficit para manter massa magra; 0,8 g/kg é a RDA geral (IOM).
- Refeições: ISSN "Nutrient timing" (Kerksick et al., 2017): proteína a cada 3–4 h ao longo do dia; mais refeições ajudam sobretudo o apetite.
- Água para beber: EFSA (2010), água total 2,0 L/dia mulheres e 2,5 L/dia homens, cerca de 20% vinda dos alimentos, logo 1,6 L e 2,0 L para beber; outro gênero ou não informado: 1,8 L.
- **Ainda sem meta de energia:** exige idade e nível de atividade (Mifflin-St Jeor × fator de atividade), que as primeiras perguntas ainda não coletam.
