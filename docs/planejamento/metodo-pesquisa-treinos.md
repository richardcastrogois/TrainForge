# Método de pesquisa de treinos: base própria, comprovada e assinada por profissional

Registrado em **20/11/2026** e revisado no mesmo dia a pedido do autor. Substitui a forma anterior de procurar treino, que partia de catálogos e APIs de exercícios e chegou a 73 metadados de consulta sem nenhum programa liberado.

**Objetivo:** montar a **base própria de treinos do TrainForge** a partir de **evidências registradas e feitas por pessoas**. Cada informação deve dizer de onde veio, e cada treino publicado precisa de **um profissional que o garanta**. **Treino gerado por IA não entra.**

## Regra absoluta de validade (decisão do autor, 21/11/2026)

**Um treino ou exercício é válido para o app se, e somente se:**

1. **Não foi gerado por IA.**
2. **Foi feito por uma pessoa responsável identificável**: treinador, profissional de educação física, médico, fisioterapeuta, pesquisador da área ou instituição de saúde que responde pelo conteúdo.
3. **Essa fonte declara para que serve**: o exercício ou treino ajuda em algo determinado (equilíbrio, força, prevenção de quedas, dor lombar etc.).
4. **Fica registrado** de onde foi tirado (fonte, URL/DOI, data de acesso) e quem fez (nome, profissão ou registro quando houver, instituição).

Cumpridas as quatro condições, o conteúdo **é válido** e pode entrar no app. **O autor não fará revisão dos treinos**, e o método não exige mais um revisor CREF próprio: a garantia é a autoria profissional da fonte, sempre exibida no app. Na tela, cada treino mostra "Criado por [quem], [profissão/instituição] · Fonte: [onde]".

Como verificar "sem IA":

- Autor ou instituição nomeados, com profissão ou função na área.
- Publicação revisada por pares, material oficial de órgão de saúde ou material assinado por profissional.
- Desconfiar de texto sem autoria, sem data ou publicado em massa após 2023 sem responsável. Na dúvida, rejeitar.

O texto mostrado no app é **reescrito com palavras próprias** a partir da fonte (salvo licença que permita copiar). A reescrita não muda a prescrição nem o benefício declarado.

Esta regra substitui a exigência de "revisão humana por profissional (CREF)" das etapas 6–8 abaixo, que não se aplicam mais. Decisões do autor após o debate de 21/11:

- **Composição permitida com coerência.** O Claude pode juntar exercícios de autores humanos num treino (o objetivo é não *criar* exercício por IA), desde que o conjunto faça sentido: mesmo nível e intensidade (nada pesado num treino leve), grupos musculares compatíveis no mesmo dia, sem repetir força do mesmo grupo em dias seguidos, duração adequada, com aquecimento e volta à calma.
- **Modo único.** O app existe para a pessoa assistir, entender e fazer sozinha. Quando a fonte recomenda avaliação ou acompanhamento profissional, isso aparece no treino e nos **Termos de Uso que a pessoa aceita**. Não há modo separado "com profissional".
- **Praça tem obrigatoriamente dias com os aparelhos da praça** (ATI/academia ao ar livre). Quantos dias e com o que combinar segue a opção escolhida pela pessoa (abaixo). O exemplo do autor (4 dias: 2–3 com aparelhos, 1 de Tai Chi e 1 de caminhada) é exemplo, não regra de "metade dos dias" (correção do autor, 21/11).
- **Combinação de modalidades (21/11).** O app oferece "só força", "força + caminhada", "força + corpo e mente" e "completo", em casa, praça e academia. As regras vêm de fontes profissionais: mesmo grupo muscular não treina força em 2 dias seguidos e, para dias seguidos, alterna superiores e inferiores (NIA 2018, p. 104); idosos fazem força e equilíbrio 2–3 vezes por semana em dias alternados e adultos, força em pelo menos 2 dias (MS 2021, pp. 25 e 30); caminhada começa com 5–10 min e chega a 30 (NIA, p. 37); 65+ fazem multicomponente em 3 ou mais dias (OMS 2020); Tai Chi e programas multicomponentes reduzem quedas (Cochrane 2019). As distribuições semanais são composição do app apoiada nessas fontes. Detalhe em `biblioteca.json` → `frequencia.combinacaoModalidades`.
- **Opção "Equilíbrio e mobilidade (sem peso)" (21/11).** Para casa, pausa do cuidador e praça. Usa só sessões sem peso externo e com foco em equilíbrio, mobilidade, alongamento ou força com o próprio corpo (Otago, NIA, exercise snacking). Na praça, a opção não apaga os dias de aparelhos quando a pessoa escolhe treinar força.
- **Dose das máquinas de academia (21/11).** Vem da NSCA 2019 (Fragala et al., Tabela 1). Iniciantes fazem 1 série de 10–15 repetições com carga leve; quem progride faz 2–3 séries de 8–12. São 8–10 exercícios dos grandes grupos, em 2–3 dias não seguidos por grupo, sem chegar à falha, com 1,5–3 min de descanso. A execução de cada máquina segue o ATP 7-22.02, cap. 15.
- **Modalidades complementares.** Só entram com sessão fechada de autor humano. As demais ficam como candidatas em `biblioteca.json` → `modalidadesComplementares`: LiFE, Tai Ji Quan MBB, dança sênior, Square Stepping, Lian Gong, Pilates e Baduanjin (parcial).
- **Casa usa o que se tem em casa** (cadeira, parede, garrafa, toalha, almofada, cabo de vassoura, escada, sacos de arroz) e tem duração definida para caber no tempo que a pessoa informa; elástico, step, caneleira e halteres são opcionais, só quando a pessoa declara o recurso.
- **Meta de quantidade**: 3 sessões distintas por lugar e nível, ×3 de margem para intercalar e "mudar treino" = 9 por célula, 12 células = 108.
- **Frequência livre de 1 a 7 dias**, com sugestão de 3 e recomendação de 3 a 5, distribuída pela opção de combinação escolhida (`frequencia.combinacaoModalidades`). Os critérios das histórias V1-015/016 no backlog precisam ser ajustados para refletir essa decisão quando forem retomados.

## Princípio: compor, não só copiar programas prontos

Aceitar só programas completos perderia informação útil. A base é montada em **camadas**, cada uma com a sua evidência, e pode juntar fontes diferentes:

| Camada | O que é | Exemplos de fonte |
|---|---|---|
| **Exercício** | Como fazer, posição, cuidados, erros comuns, variações mais fáceis e mais difíceis | Protocolos publicados, manuais oficiais, metadados MoveKit (licenciados), wger (CC BY-SA) |
| **Segurança** | Contraindicações, sinais para parar, quando procurar um profissional | Diretrizes (OMS, ACSM, SBGG), manuais do Ministério da Saúde |
| **Dose** | Frequência, séries, repetições, intensidade, descanso, duração | Diretrizes e ensaios clínicos |
| **Progressão** | Quando e como aumentar ou diminuir | Protocolos (ex.: Otago), diretrizes |
| **Programa/sessão** | Seleção e ordem de exercícios para um público e contexto | Protocolos completos **ou** composição própria a partir das camadas acima |

Um treino do app pode ser:

- **(a) Programa publicado**, reescrito com as nossas palavras e com citação.
- **(b) Composição própria**: exercícios de uma fonte, dose de uma diretriz, progressão de um protocolo. Cada parte guarda a sua origem.

Nos dois casos, o **profissional responsável** revisa o conjunto e assina.

## Rastreabilidade (vai para o app)

Cada item da base guarda:

- **Origem por campo**: de onde veio cada informação (`instrucoes ← fonte X`, `dose ← diretriz Y`, `progressao ← protocolo Z`).
- **Fonte**: autores, órgão, data, DOI/PMID/ISBN/URL oficial arquivada, tipo de evidência (ensaio, revisão, diretriz, manual oficial, consenso).
- **Licença** do texto e da mídia, e o que foi feito (reescrito, traduzido ou adaptado).
- **Responsável técnico**: nome, registro (CREF), data da revisão, versão aprovada e observações.

No app, a pessoa vê, de forma simples: "Montado por [profissional, CREF] · Baseado em: [fontes]". Os detalhes completos ficam numa tela de "Fontes".

## Fontes aceitas, por ordem de força

1. Ensaios clínicos e protocolos publicados com a intervenção descrita (de preferência relatados com o checklist **CERT** ou **TIDieR**). Busca em PubMed, Europe PMC (API gratuita), PMC de acesso aberto, SciELO e Cochrane.
2. Manuais de órgãos públicos e programas institucionais validados: Ministério da Saúde (Guia de Atividade Física para a População Brasileira e cadernos da atenção básica), OMS, Otago, Vivifrail, LiFE, NIA/Go4Life.
3. Diretrizes de sociedades (ACSM, SBME, SBGG): para dose e segurança, como referência, sem copiar o texto.
4. Material de profissionais identificados (nome e registro), com licença de reuso ou autorização por escrito.

**Rejeitar:** conteúdo sem autor, blogs e redes sem credencial, apps sem licença, texto com sinais de geração automática sem autoria verificável e informação que não diz de onde veio.

Direitos: parâmetros de prescrição costumam ser informação reexpressável com citação. Texto, figuras e vídeos originais não podem ser copiados sem licença. Isso é **critério de triagem, não parecer jurídico**.

## Cobertura de vídeo MoveKit, em paralelo

Para cada exercício que entrar na base, conferir se o pacote **Complete** (588 exercícios) tem a demonstração correspondente:

- Antes da compra: comparar com a lista **pública** de nomes e filtros do site (só leitura de nomes, sem baixar nem capturar vídeos). Registrar `movekit: provavel | nao_encontrado`.
- Depois da compra: confirmar pelo `slug` no `metadata.json` real (`movekit: confirmado`).
- Exercício sem vídeo: buscar alternativa com direitos (outro exercício equivalente, mídia própria futura ou só texto e imagem licenciada). Nunca exibir mídia sem direito.

Isso também ajuda a decidir **qual pacote comprar**: se os exercícios para idosos estiverem quase todos no Starter ou no Home, o Complete pode não ser necessário.

## Etapas por público e contexto

Uma etapa por vez. Cada uma termina com treinos revisados e assinados antes de começar a próxima.

| Etapa | Público e contexto | Foco |
|---|---|---|
| 1 | **Idosos** | Força, equilíbrio e prevenção de quedas; mobilidade |
| 2 | **Cuidadores nas pausas** | Sessões curtas (≤ 15 min), postura, lombar, alívio de tensão |
| 3 | **Em casa** | Peso corporal e objetos domésticos, iniciantes |
| 4 | **Praça/parque** | Caminhada + funcional ao ar livre, equipamentos de praça |
| 5 | Academia e outros | Máquinas e programas de força |

## Fluxo de trabalho de cada etapa

1. **Perguntas de busca** (PICO: população, intervenção, comparação, desfecho). Exemplo, etapa 1: "força e equilíbrio domiciliar para idosos ≥ 65 anos, prevenção de quedas".
2. **Busca registrada**: base, termos, filtros, data e número de resultados.
3. **Triagem em duas fases** (resumo e texto completo), com o motivo de exclusão.
4. **Extração por camada** para as fichas JSON (exercícios, segurança, dose, progressão e programas), com a origem por campo.
5. **Cobertura MoveKit** de cada exercício.
6. **Montagem**: programas publicados reescritos e composições próprias, com status `aguarda_revisao`.
7. **Pacote de revisão** para o profissional: cada treino com as fontes lado a lado e as decisões de composição explicadas.
8. **Revisão e assinatura** pelo responsável técnico (autor providencia).
9. **Liberação no app** pelos gates atuais (programa, instrução, dose e mídia ligados a versão, fonte e direitos).

O Claude executa as etapas 1 a 7. As etapas 8 e 9 dependem do autor e do profissional.

## Entregáveis

- `docs/conteudo/pesquisa-treinos/`: protocolo, registro de buscas e fichas por camada.
- Matriz de status (`triagem`, `extraido`, `aguarda_revisao`, `aprovado`, `rejeitado`) com cobertura MoveKit.
- Meta da etapa 1: base de exercícios para idosos com segurança e dose, e **2 a 3 treinos** prontos para revisão.
