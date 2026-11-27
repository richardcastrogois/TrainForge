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
