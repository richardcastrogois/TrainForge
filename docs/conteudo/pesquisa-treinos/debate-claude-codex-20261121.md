# Debate Claude × Codex sobre a biblioteca de treinos (21/11/2026)

A pedido do autor, o Codex (CLI 0.171.0, plugin oficial `codex@openai-codex` 1.0.6, conta ChatGPT do autor) revisou a [biblioteca](biblioteca.json) em modo somente leitura, comparando-a com a [regra absoluta](../../planejamento/metodo-pesquisa-treinos.md#regra-absoluta-de-validade-decisão-do-autor-21112026), a visão do produto, o escopo, as licenças e o código da configuração. Foram duas rodadas. **Veredito final do Codex: "não pronto" enquanto as ações abaixo forem apenas propostas;** depois delas, uma seleção menor pode ser integrada, com as combinações sem oferta explícitas.

## Onde houve acordo

| # | Achado | Decisão aplicada em 21/11 |
|---|---|---|
| 1 | Treinos montados pelo Claude a partir de exercícios avulsos não têm autor humano | PRG-12, 13, 14 e 15 marcados `excluido_composicao_ia` |
| 2 | A tabela global de 1 a 7 dias alterava os programas | Removida. Cada programa só será oferecido nas agendas previstas pela própria fonte (`agendasPermitidas`, a extrair). Com 1 dia/semana, nenhum programa conferido tem oferta |
| 3 | N1–N4 misturava experiência, capacidade e fase do programa (conflito com R04) | Descontinuado como classificação da pessoa; usar o critério de entrada de cada fonte. Fases UFPR são progressão |
| 4–5 | Várias fontes exigem avaliação, prescrição ou supervisão profissional | Estado `com_profissional`: Otago, Vivifrail, UFPR (p. 4), AGUEDA, ensaios supervisionados, ENJOY, GO-OUT, Alqhtani |
| 6 | Doses genéricas incorretas (Vivifrail) | Marcadas "a extrair; não usar" |
| 7 | "42 treinos" não eram 42 programas executáveis | Cada treino tem `estadoOferta`; a matriz de cobertura antiga foi removida |
| 8 | Autoria não identificada (ensaio PMC12523087) | Pendente; PRG-34 fora de oferta |
| 9–10 | Público e contexto ampliados sem base (PRG-23/30/39) | PRG-39 (30 min, para profissionais de saúde) saiu da pausa ≤15 min |
| 11 | "Reescrito com citação" não encerra a análise de direitos | Materiais sem licença aberta ficam como referência até conferir o uso concreto (Vivifrail ©, MS 2021 NC, UFDPar, Krist, GO-OUT) |
| 12 | Termos NHS 3.6(b): adaptação/tradução não pode citar o NHS como fonte | Conflita com a regra 3 do autor. PRG-01 a 06 e 16 marcados `fora_credito_nhs`. Saídas possíveis: usar o conteúdo original sem tradução (3.6a) ou obter autorização do NHS |
| 13 | Correspondências MoveKit "aproximadas" mudam apoio e carga | Mantidas só como candidatas; conferir com a amostra antes de exibir |
| 14 | Checklist e método com estados desatualizados | C17 reaberto; exigência antiga de assinatura removida do método |

Ressalvas do Codex aceitas:

- "Com profissional" precisa registrar **qual** acompanhamento a fonte exige: avaliação, prescrição individual ou supervisão durante a sessão.
- "Uso autônomo" é classificado por **material e versão**, não pela instituição. Um guia de autoajuda não autoriza montar sessões novas com o catálogo dele.
- "Pelo menos 2x/semana" não libera automaticamente qualquer frequência até 7 dias.

## Resultado por estado de oferta

| Estado | Treinos | Situação |
|---|---|---|
| `autonomo_extracao_pendente` | 1 (Workout to Go, NIA) | Único candidato a uso autônomo; falta extrair a dose por exercício e as precauções |
| `a_confirmar` | 1 (UFDPar) | Confirmar se a cartilha é para autoaplicação |
| `com_profissional` | 29 | Válidos pela regra do autor, mas a fonte exige profissional |
| `fora_credito_nhs` | 7 | Fora por conflito de crédito |
| `excluido_composicao_ia` | 4 | Fora pela regra do autor |

## Consequência para o produto (decisão do autor)

Com a regra do autor somada às exigências das próprias fontes, **quase nenhum treino pode ser oferecido para uso sozinho**. Os programas mais completos (Otago, Vivifrail, UFPR, AGUEDA) foram feitos para serem prescritos ou supervisionados por profissional. Caminhos possíveis, a decidir:

1. Oferecer esses programas no modo "com orientação de profissional": a pessoa informa que tem acompanhamento e o profissional dela escolhe o programa.
2. Continuar pesquisando **programas escritos para autoaplicação** por órgãos de saúde ou profissionais identificados, com licença que permita tradução e crédito.
3. Para o NHS: usar o conteúdo original em inglês, sem tradução, ou pedir autorização.

## Cobertura MoveKit após o debate

- Workout to Go (único autônomo): 13 exercícios, 2 com clipe exato, 5 aproximados e 6 sem clipe.
- Programas `com_profissional` que têm lista de exercícios: 53 exercícios, 20 exatos, 11 aproximados e 22 sem clipe. Os exatos vêm sobretudo da academia em máquinas e do Vivifrail E.

Detalhes em [`cobertura-movekit.json`](cobertura-movekit.json). Pacotes corrigidos e alternativas de mídia dentro do orçamento: [midia-orcamento-20261121.md](midia-orcamento-20261121.md).

## Decisões do autor depois do debate (21/11)

| Ponto do debate | Decisão do autor | Efeito na biblioteca |
|---|---|---|
| Composições do Claude (achado 1) | Permitidas: o Claude juntou exercícios de autores humanos, não os criou. Exigência: o treino precisa ser coerente (nível, intensidade e grupos compatíveis) | PRG-12 a 15 voltam como `valido_composicao`; PRG-12 deve ser dividido em A/B e PRG-14 fica só em casa |
| Frequência (achado 2) | A pessoa escolhe de 1 a 7 dias, priorizando a flexibilidade; com 1 dia o app avisa | `frequencia.regraAgenda`: sugestão de 3 e recomendação de 3–5, como Fitbod e os apps para idosos; dias extras só com caminhada ou alongamento leves |
| Dois modos (achados 4–5) | Rejeitado: modo único. A pessoa vê, entende e faz; se a fonte recomenda profissional, isso aparece no treino e nos Termos de Uso aceitos | 31 treinos `valido`, com `recomendacaoProfissionalDaFonte` quando houver |
| NHS (achado 12) | Não discutido | Continua `fora_credito_nhs` |

Divergência registrada: o Codex considerava que a dispensa de revisão não dispensa o profissional exigido pela fonte. A decisão do autor prevalece; a mitigação é informar no treino e nos Termos, com aceite registrado.

### Minuta de cláusula para os Termos de Uso (versão 1.1, junto com a liberação dos treinos)

Texto a revisar antes de publicar. A mudança altera o hash dos Termos e pede novo aceite no app.

> **2.1 Treinos e exercícios do App.** Os treinos e exercícios do App vêm de programas e materiais publicados por profissionais e instituições de saúde, que são identificados em cada treino. O App apresenta esse conteúdo para você assistir e fazer por conta própria; ele não avalia sua condição física nem adapta o treino a você. Alguns programas foram criados para serem aplicados com avaliação ou acompanhamento de fisioterapeuta, educador físico ou médico. Quando for o caso, o treino informa essa recomendação. Antes de começar, e sempre que tiver dúvida sobre um exercício, procure um desses profissionais, por exemplo o da sua academia ou unidade de saúde. Não faça exercícios que a fonte desaconselha para a sua condição. Use apoio firme (cadeira, parede) quando o exercício indicar e interrompa ao sentir dor, tontura, falta de ar ou desequilíbrio. Ao iniciar um treino, você declara que leu essas orientações e assume a decisão de praticá-lo.

O texto deve ser revisado junto com a revisão jurídica já prevista antes do lançamento comercial.

## Rodada 4 — biblioteca de sessões com as regras de praça e casa (21/11)

Pedido do autor: 9 sessões por lugar e nível (3 × 3 de margem) em 12 células = 108; praça só com aparelhos; casa só com material doméstico e tempo definido. **Veredito do Codex: insuficiente para integrar e para afirmar 108 sessões prontas.**

Achados aceitos e já corrigidos:

- **Variantes que só invertiam a ordem** do circuito ATI não são alternativas distintas e foram removidas.
- **Autoria do ensaio PMC12523087** preenchida (Claußen, Groß e Kibele, Univ. Kassel).
- **PRG-39** (30 min) saiu da pausa.
- **PRG-15** marcado para refazer sem os exercícios do NHS.
- **NIA-A** ficou sem a remada com elástico.

Situação depois das correções: 117 sessões únicas (89 de fonte e 28 composições).

| Célula | Sessões | Sem duração registrada |
|---|---|---|
| Casa: sentado / iniciante / intermediário / avançado | 9 / 9 / 9 / 9 | 5 / 5 / 6 / 8 |
| Praça: iniciante / intermediário / avançado | **6 / 6 / 6** | 0 / 1 / 0 |
| Academia: iniciante / intermediário / avançado | 9 / 9 / 12 | 6 / 6 / 9 |
| Pausa: sentado / em pé | 9 / 9 | 8 / 8 |

Pendências apontadas pelo Codex, que o Claude também reconhece:

1. **Nenhuma sessão está "pronta comprovada"**: falta extrair, sessão por sessão, a lista fechada de exercícios, a dose, a duração e o benefício. As sessões estão localizadas na fonte, não extraídas.
2. **Praça**: faltam 3 sessões distintas por nível. "Aparelhos da ATI" deve virar uma lista concreta (praças diferentes têm aparelhos diferentes).
3. **Academia**: sessões que exigem barra, landmine ou medicine ball precisam declarar o equipamento. Drills militares não podem ser oferecidos a idosos frágeis.
4. **Composições** só têm coerência comprovada depois da lista fechada com dose; o mesmo vale para a sobreposição de grupos ao "mudar treino".
5. **Fase de progressão ≠ nível da pessoa**: UFPR fase 4, Vivifrail D e as semanas finais do circuito ATI não equivalem a "avançado" adulto.

## Rodada 5 — sessões extraídas (21/11)

**Veredito do Codex: insuficiente.** Depois da extração (112 "prontas"), ele encontrou listas abertas, doses "conforme o manual", exercícios em pé em treinos sentados, pausas de 20 min, duplicatas do circuito ATI e recomendações das fontes que não foram transportadas. O Claude concorda e aplicou 34 correções:

- **Descrições UFPR:** separadas as que estavam fundidas (14–16, 43, 58–59, 90).
- **Treinos sentados:** sem movimentos em pé.
- **Pausa do cuidador:** sem sessões de 20 min.
- **Praça:** duplicatas removidas; fase 5–6 separada da 7–8.
- **Prontidão:** listas e doses abertas voltaram para "parcial".
- **Recomendações da fonte:** transportadas para todas as sessões.
- **Agenda:** regra de exceção da praça registrada (pelo menos metade dos dias com aparelhos).

**Recontagem honesta depois das correções:** 90 sessões prontas, 43 parciais.

| Célula | Prontas | Observação |
|---|---|---|
| Casa: sentado / iniciante / intermediário / avançado | 6 / 17 / 8 / 10 | só doméstico: 6 / 12 / 5 / 7 |
| Praça: iniciante / intermediário / avançado | 6 / 8 / 10 | com aparelhos: 4 / 3 / 4 |
| Academia: iniciante / intermediário / avançado | 7 / 8 / 14 | |
| Pausa: sentado / em pé | 8 / 4 | |

**Meta 9 × 12 ainda não cumprida.** O que falta:

1. Fechar as doses do manual do Exército por exercício.
2. Expandir os drills agregados.
3. Mais sessões com aparelhos de praça por nível.
4. Mais sessões curtas em pé para a pausa.
5. Casa sentado e intermediário só com material doméstico.


## Rodada 6 (21/11)

**Correção do autor:** "metade dos dias com aparelhos" era exemplo. Pediu pesquisar o que profissionais dizem sobre mesclar modalidades e oferecer opções.

**O que entrou:**
- `frequencia.combinacaoModalidades` com opções só força, força + caminhada, força + corpo e mente e completo. Cada regra marca `origem` (fonte ou composição do app). Fontes: MS 2021 pp. 24/25/29/30, NIA 2018 pp. 32/35/37/43/104, OMS 2020, Cochrane 2019. A regra dos 48 h da ACSM foi vista só em resumo secundário e não foi usada.
- 16 sessões novas (NIA e Marcos-Pardo): caminhada em 3 níveis, 5 pausas em pé, 1 pausa sentada, casa sentado G/H, casa intermediário dia A/B, ATI B2 (pernas + equilíbrio) por nível.
- Correções: NIA-06 (em pé) saiu de SENT-B e PAUSA-FORCA.

**Veredito do Codex:** suficiente com ajustes pontuais. Ajustes aplicados:
- separar regra da fonte de composição do app;
- unificar a agenda;
- cadeira com braços só para o NIA-10;
- recomendação supervisionada nos ATI;
- durações recalculadas (sustentações × lados);
- critério de nível declarado como do app.

| Célula | Prontas | Observação |
|---|---|---|
| Casa: sentado / iniciante / intermediário / avançado | 8 / 18 / 11 / 11 | só doméstico: 8 / 13 / 8 / 8 |
| Praça: iniciante / intermediário / avançado | 8 / 10 / 12 | com aparelhos: 5 / 4 / 5 |
| Academia: iniciante / intermediário / avançado | 7 / 8 / 14 | |
| Pausa: sentado / em pé | 9 / 9 | |

Meta 9 cumprida em 6 de 12 células. O Codex aceita cotar mídia com as lacunas registradas (C34), sem afirmar 9×12 concluída.


## Rodada 7 (21/11)

**Pedido do autor:**
- pesquisa mais profunda da dose das máquinas;
- novas modalidades complementares;
- opção sem levantar peso, com foco em equilíbrio, para casa, cuidador e praça.

**O que entrou:**
- **Dose das máquinas:** veio da NSCA 2019 (Fragala et al., Tabela 1, p. 2025; descanso na p. 2024). O texto original está em `.local`. Sessões novas: academia iniciante A/B, intermediário A/B e intermediário superiores/inferiores. As sessões STM e INI-MOD ficaram prontas.
- **Sem peso:**
  - campo `semCarga` + `focoEquilibrioMobilidade` nas sessões;
  - Otago equilíbrio em 3 níveis;
  - exercise snacking A/B (Fyfe et al. 2022, CC BY 4.0, 9 min);
  - sessão sentado I;
  - opção `equilibrio_mobilidade`.
- **Modalidades:** em `modalidadesComplementares`. Prontas: caminhada, Otago, snacks e alongamento com respiração. Candidatas: LiFE (BMJ 2012, menos quedas, licença NC), Tai Ji Quan MBB, dança sênior (licença NC), Square Stepping, Lian Gong (SUS) e Pilates. Baduanjin ficou parcial.

**Veredito do Codex:** suficiente com ajustes pontuais. Ajustes aplicados:
- Baduanjin voltou a parcial;
- a marcação sem carga da UFPR1-C foi corrigida (ela usa garrafas);
- a proveniência da STM foi corrigida;
- os limites das licenças NC ficaram explícitos;
- o filtro sem peso passou a exigir foco em equilíbrio e mobilidade e público sem restrição.

| Célula | Prontas | Observação |
|---|---|---|
| Casa: sentado / iniciante / intermediário / avançado | 9 / 20 / 13 / 12 | só doméstico: 9 / 15 / 10 / 9; sem peso: 4 / 7 / 5 / 3 |
| Praça: iniciante / intermediário / avançado | 9 / 11 / 13 | ATI: 5 / 4 / 5; sem peso: 3 / 2 / 3 |
| Academia: iniciante / intermediário / avançado | 11 / 12 / 14 | |
| Pausa: sentado / em pé | 9 / 11 | sem peso: 4 / 7 |

A meta de 9 está cumprida nas 12 células, contando sessões com restrições de público. O Codex não conseguiu ler os PDFs em `.local` (acesso negado). A fidelidade à NSCA foi conferida pelo Claude no original.
