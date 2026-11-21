# Pesquisa de treinos — protocolo e andamento

Segue o [método de pesquisa de treinos](../../planejamento/metodo-pesquisa-treinos.md): base própria em camadas (exercício, segurança, dose, progressão, programa), origem registrada por campo, profissional responsável que assina e nenhum treino gerado por IA. Não repetir a pesquisa de bibliotecas de exercícios já registrada no [catálogo de fontes](../catalogo-fontes.md). As fontes de programa citadas lá são reaproveitadas pelo id (`IC06`, `PR53` etc.).

## Arquivos

- [`buscas-etapa1.json`](buscas-etapa1.json): registro reproduzível das buscas (base, termo exato, data, total e os 20 primeiros por relevância).
- [`candidatos-etapa1.json`](candidatos-etapa1.json): matriz de candidatos com camadas, licença observada, prioridade e status, mais os excluídos da fase 1 e o motivo.
- Próximos: `fichas/` com a extração por camada e `revisao/` com os pacotes para o profissional.

## Protocolo de cada etapa

1. Perguntas PICO por público e contexto.
2. Busca no PubMed (E-utilities, `sort=relevance`). Bases complementares: Europe PMC, SciELO, órgãos públicos (MS, OMS) e programas validados.
3. Fase 1: título e resumo. Fase 2: texto completo. Registrar o motivo de cada exclusão.
4. Extração por camada, com a origem de cada campo, a licença observada e o que foi reexpresso.
5. Cobertura MoveKit por exercício (`provavel`/`nao_encontrado` pela lista pública de nomes; `confirmado` só com o `metadata.json` real).
6. Montagem dos treinos (`aguarda_revisao`) e pacote de revisão para o profissional (CREF).

## Etapa 1 — idosos (iniciada em 21/11/2026)

**Buscas executadas no PubMed (21/11):**

| Id | Pergunta | Resultados |
|---|---|---|
| E1-Q1 | Força + equilíbrio domiciliar, prevenção de quedas | 375 |
| E1-Q2 | Revisões sistemáticas: exercício e quedas na comunidade | 251 |
| E1-Q3 | Treino de força: dose (revisões) | 52 |
| E1-Q4 | Multicomponente e fragilidade (ensaios) | 92 |
| E1-Q5 | Diretrizes e consensos | 131 |
| E1-Q6 | Protocolos relatados com CERT | 3 |

**Fase 1 (títulos dos 103 primeiros resultados):**

- 23 candidatos, dos quais 3 são fontes oficiais ainda a localizar (Ministério da Saúde 2021, OMS 2020, diretrizes mundiais de quedas 2022).
- Exclusões com motivo: remédio, suplementação, hospital, videogame, outra população e instituição de longa permanência.

**Leitura preliminar (a confirmar no texto completo):**

- **Programa base para o primeiro treino:** Otago (casa, força e equilíbrio com níveis) e Vivifrail (multicomponente por nível funcional) são os candidatos mais fortes. Ambos têm ensaios clínicos e uso institucional.
- **Dose:** revisão Cochrane, consenso ICFSR, meta-análise de dose em força e revisão que embasou a diretriz da OMS.
- **Exercícios com licença aberta:** o LifeAge Guide (CC BY 4.0 declarada) e o material do NHS (OGL com atribuição) são os candidatos para a camada "como fazer". A MoveKit entra como mídia, se comprada.

**Limites desta rodada:**

- As licenças vieram do Europe PMC, e 6 consultas falharam (marcadas `a_conferir`).
- A licença de um artigo não cobre manuais, figuras ou vídeos citados (Otago e Vivifrail precisam de conferência própria).
- Nenhum texto completo foi lido ainda.

## Sessões por lugar e nível (meta do autor, 21/11/2026)

Meta: 3 sessões distintas por lugar e nível × 3 de margem para "mudar treino" = **9 por célula × 12 = 108**.

Regras do autor:

- **Praça:** o plano tem dias com aparelhos da ATI (dias de força, alternando superiores A e inferiores B); caminhada, Tai Chi e alongamento entram conforme a opção de combinação.
- **Combinação (21/11):** só força, força + caminhada, força + corpo e mente, completo; regras de MS 2021, NIA 2018, OMS 2020 e Cochrane 2019 em `biblioteca.json` → `frequencia.combinacaoModalidades`.
- **Casa:** a base usa material doméstico e tem duração definida. Programas com elástico, step ou caneleira aparecem quando a pessoa declara o material (pergunta opcional, itens C31/C32).

> Rodada 7 do debate (Codex): **suficiente com ajustes pontuais** (aplicados). **120 prontas de 162**; meta 9 cumprida nas **12 de 12 células** (com restrições de público; não é cobertura universal). Dose de máquinas pela NSCA 2019; opção "Equilíbrio e mobilidade (sem peso)" com 28 sessões, ainda sem 9 por célula; modalidades candidatas em `biblioteca.json` → `modalidadesComplementares`.

**Extração (antes da rodada 5):** [`sessoes.json`](sessoes.json) tinha **133 sessões, das quais 112 estavam marcadas como prontas** (lista fechada de exercícios, dose, duração e benefício declarado pela fonte). As outras 21 estão localizadas, mas o texto disponível não tem lista ou dose suficiente. São 95 sessões de fontes e 38 composições do Claude com coerência registrada.

| Célula | Prontas | Observação |
|---|---|---|
| Casa: sentado / iniciante / intermediário / avançado | 11 / 12 / 12 / 12 | 9 em cada nível só com material doméstico |
| Praça: iniciante / intermediário / avançado | 10 / 12 / 14 | 6 com aparelhos em cada nível + complementos |
| Academia: iniciante / intermediário / avançado | 9 / 10 / 15 | inclui as 12 sessões do programa periodizado Walker |
| Pausa do cuidador: sentado / em pé | 9 / 9 | todas com até 15 min, exceto a marcada como fora da pausa |

**Como foi extraído:**

- **ATP 7-22.02 (Exército dos EUA):** 20 sessões, dose e propósito por drill. Só para adultos sem limitação.
- **UFPR:** 9 sessões, com os 103 exercícios descritos a partir das tabelas das fases.
- **Vivifrail:** 8 sessões; parâmetros reescritos, sem copiar textos.
- **NIA:** composições e o Workout to Go, com as doses do guia.
- **Praça:** circuito de aparelhos do ensaio de 2024 e protocolo da UFES.
- **Artigos científicos:** texto completo pela API do Europe PMC.

**Ainda parciais:** Otago (o manual deixa a dose de força para o instrutor), HIIT em casa (protocolos em figura ou vídeo), treino tradicional de 2025, CALM, Eckardt, yoga e exercício em cadeira, Tai Chi, GO-OUT e ENJOY.

> **Atualização após o [debate Claude × Codex](debate-claude-codex-20261121.md):** a tabela de 1 a 7 dias e os níveis N1–N4 abaixo foram descontinuados; 4 composições foram excluídas, o NHS traduzido saiu por conflito de crédito, e 29 treinos dependem de profissional exigido pela fonte. Só o Workout to Go é candidato a uso autônomo. A seção abaixo fica como registro da rodada.

### Biblioteca consolidada (21/11/2026) — versão anterior ao debate

[`biblioteca.json`](biblioteca.json): **149 exercícios** e **42 treinos** de 17 fontes, todos válidos pela [regra do autor](../../planejamento/metodo-pesquisa-treinos.md#regra-absoluta-de-validade-decisão-do-autor-21112026): sem IA, responsável identificado, benefício declarado pela fonte, origem e autor registrados. Os PDFs desta rodada ficam em `.local/pesquisa-corpos/2026-11-21-treinos/` (fora do Git e do APK) como prova da fonte.

**Níveis usados para cobrir o app** (descritores, mapeados aos níveis das próprias fontes):

| Nível | Descrição | Equivalência nas fontes |
|---|---|---|
| N1 | Mobilidade reduzida ou começando do zero | Vivifrail A, UFPR fase 1, NHS sentado, nonagenários (STRONG) |
| N2 | Iniciante ou retorno após pausa | Vivifrail B/B+, Otago A/B, UFPR fase 2, AGUEDA 1, máquinas fase 1 |
| N3 | Prática regular | Vivifrail C/C+, Otago C, UFPR fase 3, AGUEDA 2, NIA, circuito ao ar livre |
| N4 | Avançado | Vivifrail D/E, Otago D, UFPR fase 4, AGUEDA 3, máquinas fase força |

**Opções por lugar e nível** (número de treinos diferentes):

| Lugar | N1 | N2 | N3 | N4 |
|---|---|---|---|---|
| Casa | 3 | 8 | 7 | 5 |
| Praça/parque | 2 | 4 | 3 | 3 |
| Academia | 2 | 3 | 3 | 3 |
| Pausa do cuidador | 6 (todos os níveis) | | | |

**De 1 a 7 dias por semana:** cada treino se distribui pelas regras das próprias fontes (MS 2021, Vivifrail, Otago, NIA, UFPR), sem inventar exercício ou dose. Com 3 dias, o treino completo é feito em dias não consecutivos. Com 4 a 7 dias, entram caminhadas e alongamento, como no desenho original do Vivifrail e do Otago. Com 1 ou 2 dias, o app avisa que está abaixo do recomendado (MS 2021). A tabela está em `frequencia.porDias`.

**Fontes:**

| Fonte | Responsável | Lugar | Exercícios / treinos |
|---|---|---|---|
| NHS Live Well | NHS England | casa, pausa | 41 / 7 |
| Otago | Campbell e Robertson, Univ. Otago | casa | 22 / 4 |
| NIA 2018 + Workout to Go | NIA/NIH, painel médico | casa, academia | 33 / 4 |
| Vivifrail A–E | Izquierdo, Casas-Herrero, Rodríguez-Mañas e outros | casa, praça, academia | 22 / 7 |
| UFPR Queda + Vida | Fisioterapia UFPR (Lopes, Zotz, Gomes) | casa | 103 exercícios em 4 fases / 4 |
| AGUEDA | Univ. Granada | casa, academia | — / 3 |
| Walker 2019 | Univ. Jyväskylä | academia | 13 / 3 |
| Krist 2013, STRONG 2009 | Charité; geriatria Madri | academia | — / 2 |
| Ensaio 2025 força + equilíbrio | ver artigo | academia | — / 1 |
| Marcos-Pardo 2023, Barbosa 2023 (UFES), ENJOY, GO-OUT | universidades de Múrcia, Espírito Santo, Victoria e Toronto | praça | 6 / 4 |
| UFDPar ginástica laboral, Alqhtani 2023 | fisioterapeutas | pausa | 12 / 2 |
| MS 2021, Gschwind 2013 | Ministério da Saúde; painel interdisciplinar | regras de dose e frequência | — |

**Limites:**

- **Extração por exercício pendente:** UFPR (103 exercícios), AGUEDA, Walker fase força, Krist e ENJOY estão como programa, sem a lista de exercícios detalhada.
- **Licenças:** Vivifrail (© Izquierdo), UFDPar, Krist e GO-OUT não têm licença aberta. Valem só parâmetros reescritos com citação, sem textos ou figuras.
- **Mídia:** nenhuma foto ou vídeo das fontes foi liberada. A cobertura MoveKit continua `a_verificar`.
- **Excluídos:** a cartilha da PUC-SP (copia figuras de terceiros) e a pausa ativa do TSE (servidor recusou o acesso).
