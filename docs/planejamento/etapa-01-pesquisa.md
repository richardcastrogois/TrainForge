# Etapa 01 — Conteúdo, fontes e viabilidade

**Atualizado em 24/09/2026. Etapa aberta.** As rodadas de 22–23/09 estão concluídas como pesquisa, mas não homologaram a oferta integral. A revisão atual compara a evidência com a [visão completa R01–R18](README.md): orientação do iniciante ao experiente, múltiplas práticas, alimentação integrada, registos manuais/conectados/por imagem e acompanhamento didático.

Este documento concentra o balanço da etapa; não cria outra base paralela. **No fim há a matriz “o que temos e o que falta”.** Figma, contratos e banco não foram alterados. O envio ao GitHub foi solicitado posteriormente pelo autor e será tratado como publicação da base existente, sem transformar pesquisa em implementação.

## Correções de escopo

- O catálogo precisa oferecer **programas humanos prontos**, além de exercícios e montagem livre. “O utilizador traz o treino” não resolve sozinho a proposta.
- Cobrir modalidades/contextos diferentes, com experiência específica, progressão, equipamento e agenda; musculação e situações de joelho/coluna não delimitam o produto.
- A alimentação inclui aprendizagem, rotina, quantidades, receitas, montagem de refeições e dietas/planos alimentares. Uma tabela de nutrientes não homologa essas recomendações.
- Reconhecimento de alimento e atividade por imagem permanece desejado; exige investigação própria. Foto privada, OCR, código de barras, identificação visual e sensores são capacidades diferentes.
- O dashboard deve integrar planeado/realizado, objetivos, atividade e alimentação com informação útil e linguagem escolhida.
- Não há parceiros disponíveis nem orçamento para comprar conteúdo. A rota de aquisição a investigar é conteúdo humano existente com direitos adequados, importação em lote e conferência. A pesquisa não demonstrou manutenção sem trabalho editorial.

## Evidência acumulada e alcance real

| O que foi feito | Evidência | O que isso ainda não prova |
|---|---|---|
| Classificar 43 fontes/famílias | [Catálogo](../conteudo/catalogo-fontes.md), com 10 candidatos, 10 condicionais, 8 incompatíveis com o caminho gratuito comercial e 15 referências | 43 integrações, 43 programas ou catálogo aprovado |
| Examinar exercícios | 75 IDs wger; 6 com tradução portuguesa, 37 com imagens, 8 com vídeos; divergência semântica identificada. Primeira coleta também recebeu 876 registros free-exercise-db | Adequação de todo o catálogo, instrução correta por ativo, programas completos ou cobertura pt-PT |
| Receber composição alimentar | CoFID: 2.760 alimentos; Ciqual: 3.484; subconjuntos de 27/29. USDA: amostras de pesquisa/detalhe | Dietas individuais, porções para todos os alimentos ou equivalência portuguesa resolvida |
| Avaliar produtos embalados | Open Food Facts respondeu 503 nas duas consultas registradas | Catálogo vazio, indisponibilidade permanente ou cobertura portuguesa medida |
| Registrar atividade/métricas | 20 registros do Compêndio em cinco categorias | Plano de treino ou gasto individual medido |
| Comparar programas e casos clínicos | Fontes institucionais, termos e protocolos em [análise específica](../conteudo/programas-prontos-e-cenarios-clinicos.md) | Tratamento automático, permissão universal de mídia ou adequação de protocolo a uma pessoa |
| Preparar processo editorial | Matrizes de cobertura, curadoria, direitos, origem e retirada | Revisor contratado, lote homologado ou tempo de manutenção conhecido |
| Estudar infraestrutura/mapas | [Viabilidade operacional de 22/09](viabilidade-operacional.md) | Host/mapa integrado, cotas atuais garantidas ou operação comercial sem custo |

Detalhes e problemas observados: [amostras e achados](../conteudo/amostras-e-achados.md). As contagens desta tabela vêm da coleta preservada, não de nova consulta a todos os fornecedores em 24/09. O catálogo estruturado continua com 43 fichas; a triagem técnica abaixo é complementar, não foi somada artificialmente à contagem.

## Triagem técnica complementar — 24/09/2026

Consulta documental primária, sem SDK integrado, teste em celular, conta criada ou envio de fotos.

| Capacidade | O que a documentação sustenta | Próxima prova necessária |
|---|---|---|
| Health Connect / Android | Tipos próprios para sessões, percursos, nutrição e energia ativa; esta última é estimada e exclui metabolismo basal. [Android](https://developer.android.com/reference/android/health/connect/datatypes/package-summary) | Compatibilidade dos dispositivos/alvos, permissões, fontes disponíveis, leitura/escrita e prevenção de duplicados. Repositório de dados não equivale a sensor presente |
| HealthKit / Apple | Um workout guarda atividade e associa amostras de métricas. [Apple](https://developer.apple.com/documentation/healthkit/hkworkout) | Definir o que vem do iPhone, Apple Watch ou terceiros, acesso e recuperação; integração Flutter ainda não escolhida |
| Identificação de imagem | ML Kit documenta rotulagem de objetos com modelo no dispositivo ou obtido dinamicamente. [Google](https://developers.google.com/ml-kit/vision/image-labeling/android) | Um classificador genérico não demonstra identificação nutricional, gramas, ingredientes ocultos ou atividade concluída; faltam modelo específico e avaliação |
| Código de barras | Há leitura de códigos a partir de imagens. [Google](https://developers.google.com/ml-kit/vision/barcode-scanning/android) | Ler o código não fornece composição por si; consultar produto correto, lidar com ausente/desatualizado e confirmar quantidade |
| Educação de rótulo | Referência europeia explica declaração nutricional por 100 g/100 ml e expressão adicional por porção. [Comissão Europeia](https://europa.eu/youreurope/business/product-rules-compliance/food/nutrition-declaration/index_en.htm) | Elaborar exemplos próprios/licenciados, traduzir de forma compreensível e conferir contexto/ingredientes/alergénios |

Estas fontes sustentam possibilidades e distinções técnicas, não uma recomendação final de fornecedor. Não foi estabelecido que reconhecimento automático seja gratuito, preciso e comercialmente utilizável no produto completo.

## Investigações que precisam acompanhar a nova visão

1. **Programas por modalidade/contexto (R01–R06):** matriz de fontes humanas por força/academia/casa, caminhada/corrida, yoga/Pilates, circuitos e demais práticas. Conferir cada programa completo e variações permitidas. Não misturar prescrições para preencher lacunas.
2. **Alimentação guiada (R07–R09):** separar composição, porção, receita, modelo de refeição, plano alimentar e indicação individual. Investigar métodos/fontes, objetivos, substituições e limites; dados alimentares não são autorização para gerar dieta.
3. **Ensino visual (R05/R08/R15):** direitos de texto, imagens/vídeos, versões simples/técnicas e material sobre rótulos; protótipo didático testado com pessoas do público.
4. **Captura multimodal (R10–R13):** listas/manuais; cronómetro/GPS/sensores; dados de apps/dispositivos; OCR; códigos; imagem de prato/exercício. Comparar custo total, taxa de acerto por caso, correção e privacidade.
5. **Integração e acompanhamento (R09/R14/R16):** regra de origem, medidas, agenda, dados incompletos e duplicação. Peso, massa muscular, gordura, gasto estimado e ingestão são grandezas distintas.
6. **Sustentação (R17/R18):** permissões e background, offline, quotas, mídia, inferência local/remota, termos comerciais, anúncios e proteção de dados. Nenhum custo deve ser omitido por não ser “token”.

Para R12, distinguir: foto do movimento/equipamento pode sugerir identificação; foto de um painel/resumo pode conter tempo/distância legíveis; sequência/vídeo e sensores fornecem dados temporais diferentes. Uma foto isolada sem esses dados não comprova duração, repetições feitas ou calorias gastas. O produto deve mostrar o que foi extraído, o que foi sugerido e o que o utilizador confirmou.

Para R13, o utilizador deve poder corrigir alimento, preparo, ingredientes conhecidos e quantidade antes de salvar estimativas. Não apresentar uma fotografia como prova de ausência de alergénios ou pesagem. A decisão de reconhecer por imagem não autoriza gerar programas por IA.

## Critérios para encerrar a etapa

- [x] Visão integral organizada e conectada à pesquisa — 24/09.
- [x] Evidências anteriores preservadas; lacunas adicionais explicitadas — 24/09.
- [ ] Escolher o catálogo/cobertura de lançamento sem descartar silenciosamente os requisitos da visão.
- [ ] Demonstrar obtenção e importação conferida de programas humanos completos para os percursos selecionados, com instruções e direitos comerciais.
- [ ] Demonstrar dados/conteúdo para alimentação guiada e sua relação com os objetivos; declarar o que será organização pessoal, modelo ou orientação individual.
- [ ] Validar amostras portuguesas, incluindo alimentos/preparos, 30 códigos reais de produtos como proposta atual, tradução e unidades.
- [ ] Definir caminho técnico e económico para cada captura prometida; capacidades ainda não demonstradas ficam explicitamente condicionais.
- [ ] Resolver os direitos dos itens usados, público, manutenção e adequação. Não é necessário homologar as 43 fontes, mas sim o conjunto que sustenta as promessas.
- [ ] Autor revisar a cobertura fundamentada e aceitar a sequência de entrega. Só então fechar campos/fluxos definitivos da etapa 02.

O documento final de design pode mapear toda a visão, identificando capacidades condicionais. Não colocar uma função como disponível ao utilizador no protótipo aprovado sem decidir o que fará quando faltar fonte, permissão, equipamento ou dados.

## Evidências históricas da primeira rodada — 22/09/2026

O registro a seguir preserva resultados, links, amostras e limitações originais. **Suas recomendações de priorizar USDA, plano próprio e foto apenas como anexo foram revistas pela pesquisa de 23/09 e pela visão de 24/09 acima.** Não usar estes parágrafos históricos para fechar o escopo atual. Preços/termos devem ser reconferidos antes da integração.

### Recomendações históricas de 22/09 — não usar como escopo atual

Recomendo **wger como primeiro candidato ao catálogo de exercícios**, **USDA para alimentos genéricos** e **Open Food Facts como complemento de produtos embalados, condicionado à validação de cobertura**. São necessidades distintas, não três APIs obrigatórias desde o primeiro dia. Para mapas, Geoapify merece a primeira prova de integração; seus termos permitem uso comercial limitado no gratuito, com atribuição e cotas.

Ainda não há uma biblioteca de programas completos de musculação, em português, com revisão humana demonstrada e direitos comerciais confirmados, pronta para incorporar. O caminho de menor dependência é permitir **registar o plano do próprio utilizador/profissional** e acrescentar programas licenciados posteriormente. Isso deve ser apresentado como alternativa ao autor, não como mudança silenciosa da ideia original.

Existe também um caminho documental a explorar: textos elegíveis do NHS para atividade física. Isso não equivale a importar o app Couch to 5K, imagens ou vídeos, nem resolve um catálogo de hipertrofia. As condições de tradução e atribuição exigem atenção.

O app pode ser desenhado agora com os campos observados e os estados de fallback abaixo. Não deve prometer vídeos em todos os exercícios, tradução portuguesa completa, prescrição clínica ou reconhecimento automático de refeições.

### O que foi efetivamente testado

Evidência estruturada: [resumo das amostras](evidencias/resumo-amostras.json). As respostas originais, URLs, momento UTC, SHA-256 do corpo e duração estão na mesma pasta. São amostras de conveniência, não um censo ou benchmark de disponibilidade.

| Fonte / procedimento | Resultado observado | Consequência |
|---|---|---|
| wger: primeira página de 25 exercícios por ID | HTTP 200; total informado 910. Nos 25: 25 com autor, 4 com nome/descrição em português, 16 com imagens, 8 com vídeos. Licença principal: 10 CC-BY-SA 4 e 15 CC-BY-SA 3. | Há dados úteis e rastreabilidade, mas cobertura linguística/mídia é irregular. `pt` não comprova revisão pt-PT. |
| wger: metadados de imagens | Quatro imagens da amostra marcadas `is_ai_generated: true` (exercícios 31, 41, 75, 79). | “Base humana” não garante mídia sem IA. Se esse for requisito, filtrar o indicador e auditar a origem; flag falsa/ausente não é certificação. |
| free-exercise-db: JSON público | 876 registros recebidos; amostra distribuída de 25. Dois sem equipamento, dois sem mecânica; nenhum dos 25 tem autoria/licença por registro no schema. | Fácil de operar localmente, menor rastreabilidade por ativo. Campos nulos não devem quebrar filtros. |
| USDA: três buscas (`rice`, `milk`, `egg`), cinco resultados por busca | HTTP 200; 15 IDs distintos, todos com energia e macronutrientes; nenhum traz `servingSize` ou `foodPortions` na resposta de pesquisa. | A busca serve para seleção, não para fechar todas as porções. Os resultados são em inglês e incluem derivados/snacks. |
| USDA: detalhe do alimento 748967 | HTTP 200; duas porções em `foodPortions`, incluindo massa em gramas. | A ausência de porção na busca não significa ausência no detalhe. Prever consulta de detalhe antes da escolha de unidade. |
| Open Food Facts: busca de 20 produtos com país Portugal | HTTP 503 em v3.6 e, numa segunda consulta limitada, v2. Zero produtos recebidos. | Cobertura portuguesa e completude **pendentes**. Parar repetição; desenhar erro/repetir/registro manual. Não interpretar 503 como catálogo vazio. |

A primeira tentativa local foi impedida pelo sandbox (`WinError 10013`), antes de chegar aos fornecedores. Uma consulta isolada confirmou HTTP 200 com permissão de rede; as amostras foram então coletadas. O erro inicial de impressão Unicode não foi erro da API. Arquivos `*.sandbox-denied.json` preservam esse diagnóstico; as durações dessas falhas não medem servidor.

As consultas bem-sucedidas da coleta principal levaram aproximadamente 0,4–1,8 s neste ambiente, uma vez por pedido. O detalhe USDA levou 2,2 s. Não extrapolar para o celular, Portugal ou percentis de produção.

### Comparação de exercícios e programas

| Fonte | Direitos, operação e custo | Recomendação |
|---|---|---|
| [wger](https://github.com/wger-project/docs/blob/master/docs/api/api.rst) | Exercícios públicos sem autenticação; paginação e JSON. Rotinas privadas têm autenticação própria. A API não comprovou oferta de programas públicos revisados. Dados/mídia precisam de licença por objeto, diferente da licença AGPL do software. | **Preferido para prova de catálogo**, importando subconjunto revisado com proveniência. Não depender de chamadas externas durante cada série. |
| [free-exercise-db](https://github.com/yuhonas/free-exercise-db) | Projeto anuncia Unlicense; arquivo local elimina limite de chamadas do fornecedor. A origem das imagens precisa de verificação além da licença geral. Não fornece progressão de programas. | **Alternativa técnica**, sem liberar toda a mídia automaticamente. Fixar revisão e validar/traduzir somente subconjunto necessário. |
| [ExerciseDB/AscendAPI](https://github.com/ExerciseDB/exercisedb-api) | O repositório consultado descreve playground para exploração, não recomendado para produção, sujeito a limites/instabilidade. AGPL do repositório não comprova direito sobre todos os dados/vídeos. | **Não selecionar o playground para produção gratuita**. Não confundir com o domínio `.io`. |
| [ExerciseDB.io](https://exercisedb.io/faq) | Dataset adquirido por compra, com licença de uso em app; não é API gratuita mensal. Restringe redistribuição dos arquivos como biblioteca concorrente. | **Fora da meta de custo inicial zero**; alternativa paga se orçamento mudar. |
| [API Ninjas](https://api-ninjas.com/tos) | Termos de 13/09/2026 restringem plano gratuito a uso pessoal/não comercial ou desenvolvimento/teste/avaliação. | **Excluir do lançamento comercial gratuito**. |
| [DAREBEE](https://darebee.com/terms-of-use.html) | NC/ND e proibição expressa de incluir materiais em produtos/apps, mesmo gratuitos. | **Rejeitado para incorporar programas**. Não copiar, traduzir ou importar para o catálogo. |
| [Boostcamp](https://www.boostcamp.app/terms-conditions) | Acesso pessoal à plataforma não concede redistribuição comercial de programas. | **Não usar como base importável sem autorização específica**. |
| [Liftosaur](https://www.liftosaur.com/terms.html) / [API](https://www.liftosaur.com/doc/api) | API permite gerir programas/histórico, mas não estabelece licença geral para republicar programas de terceiros. Termos do conteúdo do serviço limitam uso pessoal/não comercial. | **Não tratar API de conta como catálogo livre**. Eventual importação autorizada é outra investigação. |

Na amostra wger, conservar licença do exercício, tradução, imagem e vídeo separadamente. [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) admite uso comercial e adaptações, com crédito, indicação de mudanças e compartilhamento da adaptação sob os termos aplicáveis. A versão 3.0 exige sua própria conferência. Isso não obriga automaticamente abrir todo o código do app, mas exige tratar corretamente o conteúdo distribuído, inclusive traduções. Não colocar restrições incompatíveis sobre esse material.

Dados a preservar no catálogo interno: `source`, `sourceId`, versão/hash, data de consulta, idioma original, tradução/revisor, licença/URL, autor/crédito, equipamentos, músculos e mídia por ativo. Remoção ou alteração da fonte não deve reescrever o histórico executado.

### Documentos de origem humana: NHS

Foram avaliadas três referências em conteúdo e adequação:

| Documento | Estrutura observada | Adequação ao TrainForge |
|---|---|---|
| [Couch to 5K](https://www.nhs.uk/better-health/get-active/get-running-with-couch-to-5k/) | Programa progressivo de corrida de nove semanas e acesso a app próprio | Referência para corrida; não é um programa de musculação nem autorização para copiar áudio/app. |
| [Strength exercises](https://www.nhs.uk/live-well/exercise/strength-exercises/) | Sequência de exercícios suaves, execução, repetições e frequência; revisão indicada de fevereiro/2024 | Candidato a texto educativo; não é progressão completa para hipertrofia ou adaptação a condições clínicas. |
| [Balance exercises](https://www.nhs.uk/live-well/exercise/balance-exercises/) | Exercícios de equilíbrio, frequência e instruções; revisão indicada de novembro/2023 | Referência complementar, com público/limites próprios. |

Os [termos NHS](https://www.nhs.uk/our-policies/terms-and-conditions/) permitem reutilização comercial de conteúdo elegível sob OGL, com exceções. Tradução é adaptação: exige atribuição apropriada e não permite apresentar a adaptação como endossada/revista pelo NHS. Texto copiado também exige política de data/atualização. Imagens, pessoas, marcas e conteúdo de terceiros não ficam automaticamente licenciados. Conferir a [lista de exclusões](https://www.nhs.uk/our-policies/terms-and-conditions/content-not-licensed-for-re-use/) e cada ativo antes de publicação. **Recomendação: trabalhar apenas com texto elegível após revisão editorial e de licença; mídia excluída dessa aprovação preliminar.** Não houve contato com autores nem autorização individual obtida.

### Comparação de alimentação

| Fonte | Licença/acesso | Qualidade e recomendação |
|---|---|---|
| [USDA FoodData Central](https://fdc.nal.usda.gov/api-guide/) | Domínio público/CC0; API com chave, limite padrão documentado de 1.000 pedidos/hora/IP; downloads disponíveis. Usou-se somente `DEMO_KEY` pública no estudo. | **Primeiro candidato para genéricos**, com curadoria de nomes/estado cru/cozido. Guardar chave de produção no servidor e cachear subconjunto versionado. |
| [Open Food Facts](https://github.com/openfoodfacts/openfoodfacts-server/blob/main/docs/api/index.md) | ODbL, conteúdo individual DbCL e imagens CC BY-SA. Leitura pública com identificação do app; 15 leituras de produto/min/IP e 10 buscas/min/IP na documentação consultada. | **Candidato complementar, não homologado**: amostra bloqueada por 503. Revisar base derivada/atribuição antes de mesclar fontes; nunca publicar diários privados por confusão com licença. |
| [PortFIR/INSA](https://portfir.insa.min-saude.pt/pt/) | Referência portuguesa; página não abriu nesta sessão. A consulta de 09/09 registrou tabela de composição, mas não licença comercial/API confirmada. | **Pendente autorização/licença e formato**. Não presumir que Excel público permite incorporar/redistribuir. |

A documentação atual do Open Food Facts recomenda v3 e mantém v2 por compatibilidade; fixar versão efetivamente validada na integração. As fotos enviadas à base podem tornar-se públicas: o recurso de foto privada de refeição deve usar armazenamento próprio. Centralizar chamadas num único servidor concentra a cota por IP; estimar demanda, cache e deduplicação antes de escolher acesso direto/proxy. Esta pesquisa não enviou fotos nem alterou produtos.

Amostras demonstram um problema de relevância: `milk` devolveu crackers, sobremesa e chocolate, além de bebida. Não traduzir “leite” para uma busca e aceitar automaticamente o primeiro resultado. Mostrar nome, categoria, preparo e fonte para confirmação. Guardar unidade, base da composição, porção em massa e valor desconhecido como nulo. Múltiplos métodos de cálculo de energia precisam de regra explícita no adaptador, não seleção acidental pela ordem do JSON.

### Efeitos imediatos no Figma e nos campos

| Tela/fluxo | Campo ou estado necessário |
|---|---|
| Detalhe/origem do plano | Autor, origem, versão, público e disponibilidade da revisão; diferenciar plano pessoal de catálogo curado |
| Instruções do exercício | Texto, idioma/tradução, crédito e mídia opcional; ausência de vídeo tem fallback textual, sem player vazio |
| Escolher treino | Não prometer “montado para a sua condição clínica” a partir de filtros genéricos. Separar objetivo/equipamento/disponibilidade de restrições médicas não tratadas. |
| Pesquisa alimentar | Origem, nome/preparo, marca quando existir, lista de resultados e ação manual quando fonte falhar |
| Porção | Massa/unidade, informação da porção disponível no detalhe, valor desconhecido e confirmação antes do registro |
| Foto alimentar | Foto privada opcional e edição manual; sem promessa de reconhecer calorias |
| Atividade/mapa | Atribuição visível, permissão, mapa indisponível, GPS fraco e registro manual; dados GPS são diferentes de tiles |
| Configuração inicial | Treino: objetivo, experiência, equipamento, dias/duração. Diário manual não exige peso/altura/sexo para simplesmente registrar alimentos. Campos adicionais só quando uma função justifica. |

Isso é entrada para a etapa 2; nenhuma tela foi redesenhada nesta pesquisa.

### Escopo de referência e alternativas explícitas

Proposta para revisão: adultos em Portugal, Android primeiro, sem geração de treinos por IA. Núcleo viável sem catálogo externo permanente: plano próprio/profissional, execução/registro, histórico e perfil. Diário manual e atividade manual são caminhos sem prescrição automática. Esses fallbacks permitem continuar desenhando se uma API estiver indisponível, mas **não substituem o objetivo de ter programas humanos curados sem decisão do autor**.

Se programas prontos forem obrigatórios para o primeiro lançamento, a publicação desse módulo continua condicionada à obtenção de conteúdo adequado e autorizado. Alimentação por busca depende da validação/tradução/porções; mapa depende de chave, quotas e prova em dispositivo. Hospedagem e orçamento estão em [viabilidade operacional](viabilidade-operacional.md).

### Pendências de homologação — não escondidas pelo check-in

- [ ] Obter amostra de 20 produtos portugueses do Open Food Facts após normalizar o acesso; verificar rótulos/porções e qualidade.
- [ ] Selecionar subconjunto wger, auditar licença de cada tradução/mídia e revisar pt-PT; filtrar mídia marcada IA se esse requisito for mantido.
- [ ] Validar os programas concretos e direitos antes de os oferecer; NHS é candidato documental, não catálogo de hipertrofia aprovado.
- [ ] Validar nomes, preparo e porções USDA com casos portugueses; a amostra acessível de 15 registros não comprova cobertura local.
- [ ] Confirmar direitos PortFIR se for priorizado, sem enviar mensagem a terceiros sem autorização explícita.
- [ ] Aprovar recorte de lançamento, política de mídia e orçamento antes da implementação; executar provas técnicas de mapa/host nas etapas correspondentes.

O check-in `[x]` refere-se ao estudo de viabilidade e à entrega de caminhos/fallbacks, inclusive resultados negativos. Nenhum item acima está marcado como aprovado ou testado sem evidência.

### Validação do encerramento

Em 22/09/2026: 11 documentos do conjunto de planejamento/evidências passaram no validador documental, sem erros nem links locais quebrados detectados. Avisos de placeholder são correspondências da expressão `TODO` com palavras portuguesas como “todos”; não são campos esquecidos. Os JSONs foram lidos novamente e os dois scripts passaram na verificação de sintaxe, sem executar testes de aplicativo.

Graphify consultado no início e atualizado incrementalmente no fim: **0 alterados, 42 inalterados, 0 removidos** no corpus `lib/`. Saídas preservadas; pesquisa/documentação não foram submetidas a extração semântica. [Manifesto dos arquivos de evidência](evidencias/manifesto.json) permite conferir integridade local sem refazer consultas. Não houve integração, commit, push, migração ou deploy.

## Balanço final — o que temos e o que falta para a visão completa

**Temos uma base de pesquisa e um app inicial, não a oferta final pronta.** O Figma v0.4 representa parte dos percursos com dados demonstrativos. Os itens “temos” abaixo descrevem evidência ou base de trabalho; não significam funcionalidade publicada.

| Requisito | O que temos hoje | O que falta demonstrar/concluir |
|---|---|---|
| R01 — Iniciante e experiente | Visão dos dois modos e esboços de planos/montagem | Programa pronto que permita começar sem plano próprio, ajuda guiada e montagem livre completas |
| R02 — Múltiplas práticas | [Matriz de modalidades](../conteudo/cobertura-e-prioridades.md) e fontes de referência | Conteúdo humano, instrução e percurso completo por modalidade/contexto selecionado; yoga/Pilates/circuitos ainda sem lote homologado |
| R03 — Programas humanos | Fontes candidatas, direitos comparados e caminho de importação proposto | Catálogo efetivamente autorizado, conferido e versionado; piloto sem parceiros/produção manual um a um |
| R04 — Contexto e progressão | Critérios multidimensionais documentados | Dados de programas que sustentem dias, tempo, equipamento, objetivos e progressões; regras de seleção/alteração revistas |
| R05 — Como executar | Amostras de descrição/mídia e falhas conhecidas | Texto/visual coerentes, licenciados e acessíveis em pt-PT; progressões e alternativas realmente previstas pela fonte |
| R06 — Saúde e retorno | Limites da pesquisa e exemplos ampliados além de joelho/coluna | Cobertura por situação/população, direitos, adequação e enquadramento; nenhum algoritmo de diagnóstico/tratamento validado |
| R07 — Planos alimentares/dietas | Fontes de composição, candidatos de receita e requisitos de planeamento | Modelos humanos, métodos, direitos e revisão para ajuda guiada; prescrição individual não resolvida |
| R08 — Quantidade/rótulo | CoFID, Ciqual, USDA amostrados; pauta de ensino e fonte europeia | Bateria portuguesa, produtos OFF, porções/preparo, exemplos visuais e informação de ingredientes/alergénios adequados |
| R09 — Alimentação + treino | Relações e limites conceituais definidos | Método de metas/estimativas, tratamento de calorias ativas/totais, duplicados e provas de consistência dos resumos |
| R10 — Manual/lista/customização | Código inicial de treino e formulários Figma demonstrativos | Fluxos completos por modalidade/refeição, edição, histórico, autoria de adaptações, offline e validação |
| R11 — Celular/dispositivos | Triagem oficial Health Connect/HealthKit e pesquisa de mapa | SDK/compatibilidade, sensores/GPS reais, permissões, bateria, background, importação/exportação e deduplicação |
| R12 — Imagem de atividade | Casos de uso separados e limites registrados | Fonte/modelo, direitos/custo e teste de identificação/OCR; duração/gasto só com informação apropriada e confirmação |
| R13 — Imagem de alimento | Fluxo assistido desejado e triagem de imagem/código | Reconhecimento alimentar/porção, OCR e busca real, correção, privacidade, desempenho e custo demonstrados |
| R14 — Dashboard pessoal | Telas Hoje/Evolução e objetivos de experiência | Resumos integrados úteis, métricas por objetivo, dados incompletos/origem, explicações e avaliação com utilizadores |
| R15 — Didática/linguagem | Pautas e modo simples/técnico especificados | Conteúdo revisado com exemplos/imagens, glossário, acessibilidade e teste de compreensão |
| R16 — Rotina/configuração | Estados de configuração parcial no esboço e requisitos | Campos realmente necessários por função, agenda multimodal/alimentar e retorno contextual completos |
| R17 — UX/plataformas | Flutter inicial; esboço, movimento/teclado/persistência planejados | Refinamento posterior do Figma, provas em Android/iOS, estado durável, desempenho e acessibilidade reais |
| R18 — Custos/confiança | Pesquisa de licenças/infra e critérios de publicação | Escolha sustentável, direitos por lote, revisão/retirada, privacidade e monetização compatíveis; nenhuma garantia de custo zero ilimitado |

**Lacunas que mais mudam o produto:** programas completos por modalidade; planeamento alimentar guiado; conteúdo visual/didático em Portugal; reconhecimento e conexões com confirmação/origem; regras que unem tudo num acompanhamento útil. Situações clínicas continuam pendentes em trilha própria e não devem absorver a identidade inteira do app.

**Próximo trabalho da etapa 01:** investigar essas lacunas usando o catálogo existente, obter pilotos conferidos e registrar a evidência faltante. Esta revisão documental está concluída; **a etapa 01 ainda não pode receber o check de conclusão integral**.
