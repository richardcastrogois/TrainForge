# TrainForge — proposta visual

**Referência histórica.** Para a base aplicada, usar [Figma v0.4](design/fluxos-v04.md); para a visão atual de 24/09/2026, [R01–R18](planejamento/README.md) e [ajustes futuros do Figma](design/ajustes-visao-integrada.md). Os recortes de telas/conteúdo e alternativas de foto deste estudo inicial não limitam o produto esperado. Nenhuma mudança visual foi aplicada neste incremento.


**Atualização de 14/09/2026:** há 33 telas editáveis no Figma, com acesso, configuração independente das áreas, 83 rotas verificadas, abertura animada, carregamento e mapa navegável. Leia primeiro [fluxos v0.3](design/fluxos-v03.md), com os percursos testados e limites. As sete telas e a prévia local descritas abaixo são a base histórica v0.2.

Base de 09/09/2026, refinada em 10/09/2026. **Proposta para revisão, não escopo aprovado nem funcionalidades prontas.** Os exemplos usam dados fictícios. A escolha de fontes de exercícios/alimentos e a arquitetura definitiva pertencem às fases seguintes. [Refinamento v0.2](design/refinamento-v02.md): navbar, marca TF, estados de execução na semana e nova tela de Perfil.

## Abrir a proposta

- [Protótipo local navegável](design/preview.html): sete telas e ligações demonstrativas.
- [Prancha com as sete telas](design/trainforge-board.svg).
- [Arquivos individuais e instruções de importação](design/README.md).
- [Figma editável e favoritado](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl): sete telas preenchidas de 390 × 844 na página `01 · Proposta mobile`. Montagem inicial concluída em 09/09/2026 e refinada pelo Comet em 10/09/2026, com textos e vetores editáveis. Componentes reutilizáveis, auto layout e conexões de protótipo ficam para o refinamento da fase 3. O limite Starter afetou o MCP; a colagem pelo editor permitiu concluir o esboço.

## Direção proposta

Uma experiência calma e legível, centrada em executar e registar a rotina. O treino do dia recebe destaque; a origem de cada programa fica visível; estatísticas explicam o que contam. A confiança deve vir de autoria, licença, revisão e limites claros, não da simples ausência da palavra IA.

Sugestão de navegação: **Hoje, Planos, Atividade, Diário e Evolução**, com perfil nas iniciais do utilizador. A sessão abre num fluxo próprio, para concentrar espaço no registo. Essa estrutura mostra a visão ampliada; não exige lançar as cinco áreas juntas. Musculação com plano e diário de execução é a hipótese de primeiro recorte a discutir.

Não há chat de IA no conceito. Anúncios não foram desenhados nesta versão: localização, frequência e fornecedor ainda precisam de decisão. A sessão em andamento deve priorizar leitura e interação, evitando interrupções acidentais. Nada foi implementado em `lib/` a partir dessas telas.

## Telas e relação com o código atual

| Tela | Objetivo do conceito | Existe hoje | Falta para chegar ao conceito |
| --- | --- | --- | --- |
| Hoje | Próximo treino, semana e atalhos | Resumo do dia e consistência | Reaproveitar bootstrap, corrigir semântica da semana, estado local e novos atalhos |
| Planos | Descobrir origem, guardar ou trazer plano próprio | Lista/detalhe de planos e geração manual/IA | Catálogo, autor, licença, versão, detalhe da origem e editor/importação |
| Sessão | Registar carga, repetições e séries, consultar técnica | Iniciar/concluir o dia | Execução por série, cronómetro, retomada, persistência/sincronização e mídia licenciada |
| Atividade | Corrida/caminhada com tempo, distância e ritmo | Não implementado | Domínio de atividade; registo manual; GPS opcional a estudar |
| Alimentação | Registar porções e energia ingerida estimada | Não implementado | Fonte nutricional, pesquisa, unidades, porções e diário |
| Evolução | Histórico contínuo e métricas compreensíveis | Estatísticas só do plano ativo | Agregação entre planos, execução detalhada, atividades e filtros |

Os botões de registo da prévia mostram avisos de demonstração. Terminar o treino leva à tela de evolução, sem gravar sessão real. O mapa é esquemático, não usa geolocalização. As 1 480 kcal do diário representam apenas uma soma fictícia de ingestão; não são meta recomendada nem gasto energético.

## Sistema visual inicial

| Papel | Cor | Uso |
| --- | --- | --- |
| Fundo | `#F6F6F1` | Superfície quente e clara |
| Superfície | `#FFFFFF` | Listas e cartões |
| Texto principal | `#142F2C` | Títulos, números e leitura |
| Texto secundário | `#64736E` | Metadados |
| Primária | `#215E52` | Ação principal, treino, seleção |
| Acento | `#D8EB90` | Destaque pontual e estado ativo |
| Atividade | `#DFEAF7` | Percurso e distância |
| Alimentação | `#F5E3D5` | Contexto do diário alimentar |

Tipografia proposta: DM Sans; os SVGs usam Segoe UI/sans-serif como alternativa local. A prévia não baixa fontes. Espaçamento base 8 px, margem de tela 24 px, botões principais 52 px, cartões arredondados e hierarquia de uma ação dominante por tela. Evitar tratar cores como único indicador de estado.

Textos foram aproximados de português europeu: registar, ginásio, pequeno-almoço e hidratos. Revisão editorial nativa, contraste em todos os estados, leitor de tela e escala de texto ainda precisam de validação no Flutter. SVG com hotspots serve para avaliação visual, não prova acessibilidade do app final.

Liquid Glass pode ser explorado no iOS para navegação e controles de contexto; não foi simulado como vidro sobre todo o conteúdo. A integração técnica com Flutter continua em aberto. O primeiro conceito Android usa superfícies opacas, com legibilidade suficiente para ler séries e números.

## Referências efetivamente inspecionadas

As seis referências foram abertas pela integração Figma e examinadas visualmente. A análise respeita o nó fornecido: uma prancha promocional não equivale à inspeção de cada tela editável do kit.

| Referência e nó | O que foi observado | Princípio aproveitado / limite |
| --- | --- | --- |
| [FIT.AI](https://www.figma.com/design/FuPFfoVyIp0QOViMNjh6C0?node-id=47-1546) | Fluxo branco/preto/azul, chat, planos, exercícios, consistência, perfil e diagrama de entidades | Contexto histórico e organização do treino. O schema local já diverge do diagrama inicial; chat não faz parte da direção desejada |
| [AI Fitness / Health](https://www.figma.com/design/doaUlA7YglxS1uIHldNSnG?node-id=0-1) | Prancha com onboarding, cartões de métricas, mapa e temporizador; roxo, verde claro e azul | Separar registo de atividade e análise, sem importar identidade ou fluxo de IA |
| [Highfits](https://www.figma.com/design/FIQlkRhLYNrQLREKAMCGLH?node-id=0-1) | Preview promocional claro/escuro, cartões de atividade diária, guias, laranja e verde | Rotina diária fácil de percorrer. Não foram auditadas todas as telas internas anunciadas |
| [FITBODY / Fitness App](https://www.figma.com/design/71zjiSv7mYq4IBIeHuaVrI?node-id=3263-101) | Prancha extensa promovendo treino, tracking, alimentação e comunidade, com roxo e verde-lima | Visão modular de produto; amplitude não vira obrigação de lançamento |
| [Nakafit](https://www.figma.com/design/JUto8GRSmbq8uEMKzAFAnV?node-id=2513-53) | O nó indicado é seleção de assinatura, claro, com preto/roxo e opções de plano | Leveza visual. **O diário alimentar descrito pelo autor não estava nesse nó e não foi validado visualmente**; alimentação na proposta vem do requisito, não dessa tela |
| [Fitness Activity](https://www.figma.com/design/6BzPImBcCzEZ32VaueecRh?node-id=0-1) | Dashboard pastel, calendário e treino | Hierarquia dos números e intervalos. A prancha declara uso **não comercial**: não copiar assets/telas para o produto vendável |

Os layouts e vetores entregues são um estudo original. Não foram reutilizadas imagens, ícones ou componentes desses kits. Licenças de cada kit, fonte e eventual mídia precisam ser verificadas antes de qualquer incorporação no produto; acesso público ao Figma não comprova licença comercial.

## Refinamento previsto

Após sua revisão, confirmar o recorte inicial, a presença de Diário/Atividade no lançamento e a preferência por plano próprio versus catálogo. Só então detalhar entrada, autoria do plano, exercício, descanso, término, histórico, perfil e estados vazios/erro/sem rede. A fase 3 deve ligar essas telas aos contratos reais e decidir o tratamento por plataforma.
