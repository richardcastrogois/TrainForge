# Qualidade, autoria e curadoria

Proposta de processo editorial em 23/09/2026. A pesquisa identifica fontes; **a aprovação de conteúdo específico é uma etapa separada**. Um programa criado por uma pessoa pode estar errado, desatualizado ou ser inadequado à população. O diferencial defensável é autoria identificável, revisão, limites e correção contínua, além de não gerar treinos por IA.

## Cobertura da visão de 24/09/2026

Aplicar este processo a [R01–R18](../planejamento/README.md): programas de várias modalidades, alimentação guiada, educação simples/técnica, mídia e dados capturados. Parceiros/revisores são papéis necessários conforme o escopo, **não pessoas contratadas ou disponíveis**. Priorizar material humano existente elegível; medir o esforço de conferência em lote antes de afirmar que o catálogo pode ser mantido sem recursos.

Uma ficha de programa deve registrar progressão e unidades da modalidade (tempo/distância, sequência/posição, blocos/rondas ou séries/carga). Experiência, intensidade e complexidade são distintos. Critérios do autor da fonte não podem ser substituídos por níveis universais inventados.

Para planos alimentares, guardar autoria/método, população, objetivos, limites, composição das refeições, substituições autorizadas e base nutricional. Diferenciar organizador livre, modelo humano e orientação individual. Alterar ingredientes/quantidades ou transformar informação populacional em meta pessoal requer avaliação própria.

Para tutoriais, as versões simples e técnica devem concordar. Exemplos de embalagem precisam de base/porção/unidade corretas e direitos de imagem; orientar ingredientes/alergénios sem certificar segurança por ausência de dado.

Para captura assistida, avaliar sugestão, correção e confirmação separadas. Proveniência acompanha a métrica: manual, sensor/importação, extração OCR ou estimativa. Não publicar reconhecimento como prescrição, pesagem ou medição clínica. Uma boa experiência de captura não corrige uma base alimentar errada.

## Quatro avaliações independentes

| Avaliação | Pergunta | Evidência necessária |
|---|---|---|
| Direitos | Podemos usar este texto/dado/ativo comercialmente, adaptar e guardar offline? | Licença aplicável à versão e ao objeto, titular, atribuição e restrições |
| Evidência e autoria | Quem produziu? Qual revisão e fundamento sustentam a orientação? | Autor, instituição/qualificação quando relevante, revisão e referência primária |
| Adequação | Serve para esta pessoa, modalidade, idioma e contexto? | População-alvo, equipamento, preparação, limitações e revisão pt-PT |
| Operação | Conseguimos manter o conteúdo disponível, correto e atualizado? | Versão, proveniência, lote, custo, atualização, retirada e fallback |

Uma avaliação positiva não compensa uma reprovação crítica em outra. Uma licença aberta não certifica saúde; uma instituição respeitada não concede direitos de republicação por ser respeitada. Um endpoint HTTP 200 não prova completude ou validade.

## Fluxo de aprovação proposto

`descoberto → direitos conferidos → amostrado → adaptado → revisto → aprovado para um público → publicado → monitorizado`

Estados paralelos: `aguarda autorização`, `erro encontrado`, `suspenso`, `substituído`, `rejeitado`. Cada mudança deve guardar responsável, motivo e versão. Nesta pesquisa não há responsável clínico/editorial nomeado; não marcar itens como revistos por especialista.

Uma correção cria nova versão. Sessões e refeições já registadas preservam a versão usada; o histórico não muda silenciosamente quando o fornecedor altera o catálogo. Se a correção for relevante à segurança, definir retirada, aviso e tratamento do histórico com o responsável apropriado.

## Ficha mínima de programa humano

O programa precisa de título, autor e origem verificáveis, licença, público, experiência necessária, contexto, equipamento, duração e frequência. Cada sessão precisa de sequência, exercícios inequívocos, dose/intensidade com unidade, descanso, progressão/regressão e instruções para adaptação prevista, interrupção e retorno.

Separar os campos **declarados pelo autor**, os **traduzidos**, os **inferidos durante a pesquisa** e os **aprovados pelo revisor**. Não preencher uma lacuna com uma regra de outra rotina e continuar atribuindo o resultado ao autor original.

Para progressão, registrar o critério completo e sua origem: quando ocorre, o que muda, quais limites se aplicam e o que acontece se a sessão for parcial. A aplicação determinística de uma regra também pode produzir recomendações inadequadas; retirar IA não elimina a necessidade de revisão.

A referência ACSM de 2026 trata de adultos saudáveis. Não estender resultados automaticamente a reabilitação, gravidez, menores ou patologias. A coleção DGS de atividade adaptada mostra que populações diferentes exigem documentação própria. [ACSM](https://acsm.org/resistance-training-guidelines-update-2026/), [DGS](https://www.dgs.pt/paginas-de-sistema/saude-de-a-a-z/exercicio-fisico.aspx).

## Ficha mínima de exercício e mídia

| Grupo | Informações necessárias |
|---|---|
| Identidade | ID próprio estável; ID/versão da origem; nome original e nome pt-PT revisto; variante claramente diferenciada |
| Contexto | Equipamento, posição, padrão de movimento, lado/unilateral/bilateral, músculos quando a fonte justificar |
| Instrução | Preparação, execução e término; observações e limites do autor; não apenas um nome e uma imagem |
| Mídia | Arquivo/URL, autor, licença própria, versão, autorização de imagem quando aplicável, legenda, áudio e acessibilidade |
| Revisão | Revisor, data, escopo, divergências e decisão; sincronia entre texto, foto e vídeo |

Preferir um conjunto pequeno de fotografias reais ou vetores aprovados quando não houver vídeo licenciado. Não usar uma imagem anatómica decorativa como demonstração suficiente de movimento. Não usar imagem/vídeo gerado por IA para certificar execução humana correta. Se a proposta de produto exigir mídia inteiramente sem IA, registrar a origem comprovada; flag falsa ou ausente não basta.

No wger, revisar as versões linguísticas por significado. O caso 1022 é um controle de qualidade útil: o sistema editorial deve conseguir bloquear uma tradução ou ativo sem presumir que todo o ID esteja validado. [Evidência local](evidencias/wger-amostra-ampliada.json).

## Ficha mínima de alimento

Manter código/fonte/versão, nome original e tradução, país/contexto, alimento ou produto, marca/código quando aplicável, preparo, parte comestível, condição escorrida e base de quantidade. Cada nutriente precisa de unidade, método quando disponível, valor original, qualificador e proveniência.

Representar separadamente: **zero informado**, **valor numérico**, **traço**, **abaixo de um limite**, **desconhecido** e **não aplicável**. Não preencher campo desconhecido com zero para completar o dashboard. Não confundir sódio em mg com sal em g, 100 ml com 100 g ou proteína calculada por fatores distintos. A conversão de volume para massa precisa de densidade/medida documentada.

Uma porção sugerida pelo dataset não é uma porção obrigatória para o utilizador. Preservar a massa e a origem da medida caseira. Produtos embalados podem mudar fórmula; verificar rótulo e data, não apenas código de barras. Não fundir alimentos de vários países como se fossem medições repetidas do mesmo item.

## Ficha mínima de receita

Receita não é plano alimentar. Guardar autor/origem, permissão, ingredientes e estado de preparo, quantidades, rendimento/porções, instruções, tempo e cuidados culinários aplicáveis. Registrar como os nutrientes foram estimados, a base dos ingredientes, perdas/rendimento considerados e quais valores são desconhecidos.

Se o utilizador muda um ingrediente ou o rendimento, o resultado deixa de ser numericamente idêntico à receita original. Não conservar selo de revisão ou valor nutricional da versão anterior sem registrar a adaptação. Contaminação cruzada, marcas e substituições podem modificar a informação sobre alergénios; filtro simples não certifica uma receita como segura. [ASAE](https://www.asae.gov.pt/newsletter2/asaenews-n-117-julho-2019/a-seguranca-alimentar-e-as-substancias-ou-produtos-que-provocam-alergias-ou-intolerancias.aspx).

Metas de ingestão têm outro nível de responsabilidade. Valores populacionais EFSA não devem ser colocados automaticamente como meta pessoal; guardar contexto e método, com revisão profissional quando houver recomendação individual. [EFSA](https://www.efsa.europa.eu/en/topics/topic/dietary-reference-values).

## Ficha mínima de atividade e estimativa

Separar o que foi **medido pelo dispositivo**, **informado pelo utilizador** e **estimado por método**. Guardar modalidade/contexto, duração efetiva, pausas, unidades, fonte e versão da fórmula. Distância GPS não é automaticamente gasto energético medido.

Para o Compêndio, preservar a entrada original. A escolha da atividade/intensidade exige contexto; não usar o mesmo MET para toda corrida, ciclismo ou musculação. Há populações específicas e o conjunto adulto consultado é de 19–59 anos. Não aplicar silenciosamente o conjunto adulto a adolescentes ou idosos. Não alterar o MET original para ajustar resultados; manter qualquer cálculo derivado identificado separadamente e validar seu uso. [Compêndio](https://pacompendium.com/adult-compendium/), [limitações](https://pacompendium.com/corrected-mets/).

## Localização e revisão por pessoas

Revisar termos como hidratos de carbono, pequeno-almoço, registo, treino e equipamento usado em Portugal. Respeitar nomes alimentares originais internamente. Tradução literal não garante equivalência: bacalhau salgado/demolhado não é qualquer entrada de peixe fresco; farinha, pão e iogurte podem ter formulações distintas.

Papéis propostos: autor/titular aprova uso e identidade; profissional de exercício revê movimentos/programas; nutricionista revê conteúdo alimentar e estimativas aplicáveis; revisor pt-PT verifica linguagem; desenvolvedor preserva unidades, versões e regras. Uma mesma pessoa só acumula funções quando tiver competência correspondente. Não atribuir qualificação profissional fictícia a autores comunitários.

## Critérios de rejeição antes da publicação

- Licença comercial ausente ou incompatível para o objeto escolhido.
- Texto, nome e mídia descrevem exercícios diferentes.
- Promessa de tratar condição clínica sem avaliação e escopo profissional adequado.
- Programa sem autoria identificável ou progressão importante inventada para preencher lacunas.
- Alimento com erro de preparo, unidade, espécie ou parte consumida.
- Nutriente desconhecido apresentado como zero; estimativa mostrada como medição exata.
- Receita declarada livre de alergénios apenas porque a base não preencheu o campo.
- Conteúdo adaptado apresentado como endosso da instituição original.

Estes controles dizem respeito ao catálogo. Não substituem a avaliação regulatória, de privacidade e da segurança do aplicativo nas etapas posteriores.

## Manutenção proposta

Na homologação, definir periodicidade por fonte e risco. Conferir termos e edição antes de cada lote público; comparar identificadores/hashes e revisar diferenças, sem republicar cegamente a base inteira. Conteúdo com prazo contratual de atualização deve seguir esse prazo. Demais intervalos serão política interna, não requisitos inventados do fornecedor.

Manter canal para reportar erro, possibilidade de retirar um ativo/versão e registro do motivo. O dashboard interno de conteúdo deve separar quantidade descoberta, licenciada, traduzida, revista e publicada. Um total agregado de fontes nunca deve ser apresentado como total de conteúdos seguros.
