# Visão do produto — R01–R18

Visão aprovada pelo autor em setembro, preservada em 21/10/2026. Intenção de produto; escopo e fases atuais em [V1](../execucao/v1/escopo.md). Android e iOS são plataformas do produto; desenvolvimento e primeiro teste em Android.

## O produto que queremos construir

Um guia pessoal de treino, movimento e alimentação que ajuda a pessoa a **saber por onde começar, entender o que está a fazer, organizar uma rotina, registar de diferentes formas e acompanhar a evolução**. Deve servir tanto quem precisa de orientação desde o início como quem já sabe montar o seu próprio plano.

Treino, alimentação, objetivos e rotina precisam conversar entre si. O resultado esperado não é uma coleção de ferramentas isoladas: a pessoa entende o que planeou, o que fez, o que comeu, o que mudou e qual é a próxima ação útil. A linguagem começa simples e pode revelar detalhes técnicos por escolha do utilizador.

O conteúdo de treino deve vir de **programas humanos existentes, com origem, fundamento e direitos demonstráveis**. Não gerar a prescrição por IA. O autor não dispõe de parceiros, orçamento para comprar conteúdo ou tempo para escrever cada programa. Importação e organização em lote são caminhos a investigar; não eliminam a conferência do conteúdo. Trazer o próprio treino é complementar e não satisfaz sozinho a necessidade de quem não sabe começar.

## Pessoas e situações que a experiência precisa atender

| Situação | Resultado que a pessoa deve conseguir |
|---|---|
| Não sabe nada e quer cuidar da saúde | Entender as opções, escolher uma atividade acessível, receber um percurso humano completo e aprender a executá-lo |
| Sabe o objetivo, mas não montar o plano | Comparar programas adequados ao seu contexto e perceber requisitos, frequência e progressão |
| Já tem experiência | Montar, importar e ajustar treino/rotina alimentar, escolher métricas e consultar detalhe técnico sem tutoriais obrigatórios |
| Treina em casa, na academia ou ao ar livre | Encontrar opções compatíveis com espaço, equipamento real, tempo e modalidade; uma máquina específica não pode ser pressuposta |
| Pessoa idosa autónoma, iniciante ou experiente | Encontrar programa humano cujo público/apoios estejam demonstrados, sem decidir intensidade ou treino sentado apenas pela idade |
| Pessoa idosa que precisa de apoio digital ou físico | Distinguir ajuda para usar o app de assistência à execução; programa e instruções devem cobrir o contexto real, sem substituir profissional exigido |
| Cuidador informal/familiar ou profissional | Acompanhar/registar para pessoa legitimamente autorizada, separando autoria/origem, autonomia, partilha e dados da pessoa assistida dos seus próprios |
| Alterna atividades e tem semana variável | Combinar força, caminhada, corrida e outras práticas sem perder histórico nem duplicar registos |
| Está a regressar após pausa ou tem uma limitação | Explicar o contexto e encontrar conteúdo cujo público e limites estejam identificados; quando não houver cobertura, receber um limite claro |
| Quer ganhar massa, perder gordura, mudar/manter peso ou melhorar capacidade | Organizar objetivos e acompanhar medidas pertinentes, sem transformar toda evolução em quilos ou calorias |
| Precisa de ajuda com alimentação | Aprender a escolher, pesar, ler rótulos, montar refeições e registar; receber orientação compatível com a cobertura efetivamente validada |

Dores, cirurgias, condições diagnosticadas e recuperação fazem parte dos contextos de uso. **Não são o foco principal nem se restringem a joelho ou coluna.** Idosos e cuidadores passam a públicos prioritários explícitos de pesquisa por solicitação de 03/10; não ficam escondidos em “casa” ou “reabilitação”. Cobertura e faixa etária de lançamento ainda exigem evidência; “para todos” não é garantia universal. Cuidador também pode ter percurso próprio de saúde, separado da pessoa assistida. Potencial de mercado permanece hipótese a validar.

## Requisitos de referência

Os IDs abaixo ligam esta visão à pesquisa, ao desenho futuro e aos critérios de qualidade. Não são tabelas de banco ou nomes de endpoints. **Recorte transversal idosos/cuidadores:** R01/R03/R04 consideram público, capacidade, apoios e supervisão da fonte; R05/R15/R17 exigem instrução e acessibilidade verificadas; R07–R10 distinguem consumido/observado e pessoa assistida/autor; R11/R14/R18 distinguem dispositivos, partilha legítima, autonomia e privacidade. Implementação e testes com esse público pendentes.

| ID | O que o autor espera | Como reconhecer o resultado esperado |
|---|---|---|
| R01 — Orientação e autonomia | Entrada guiada para iniciantes e ferramentas de montagem/customização para experientes | A pessoa consegue começar sem trazer um plano; quem já sabe pode escolher diretamente sem refazer todo o onboarding |
| R02 — Diversidade de práticas | Musculação, força em casa/peso corporal/elásticos, caminhada, corrida, yoga, Pilates, treino funcional/circuitos/cross training e outras atividades de saúde corporal | Cada modalidade tem conteúdo, unidades e execução próprios; ciclismo, natação, dança, mobilidade, equilíbrio e desportos ampliam a matriz sem virar apenas etiquetas |
| R03 — Programas humanos prontos | Programas reais obtidos de fontes existentes, sem IA a inventar treinos e sem pressupor parceria | Fonte, autoria, versão, público, direitos, sessões e progressão conferidos; biblioteca de exercícios isolados não conta como programa completo |
| R04 — Objetivos e progressão | Dias/semana, duração disponível, ambiente, equipamento, experiência por modalidade, retorno após pausa e objetivos de saúde/composição/desempenho | Seleção multidimensional; não reduzir pessoas a três níveis. Peso, massa muscular e gordura não são a mesma medida; metas não prometem resultado ou prazo garantido |
| R05 — Aprender a executar | Explicação visual de cada exercício/prática e de como ler um treino | Posição, sequência, respiração quando prevista pela fonte, dose, descanso, erros comuns e alternativas aprovadas; imagem/animação/vídeo com direitos e alternativa acessível |
| R06 — Contextos de saúde e retorno | Considerar dores comuns, limitações, diagnósticos, operações e regresso à prática, além dos exemplos iniciais | Conteúdo por população/contexto e limites explícitos; não indicar tratamento individual apenas pela localização da dor ou nome da cirurgia |
| R07 — Planeamento alimentar | Montar e customizar refeições, dietas/planos alimentares e rotinas para objetivos diferentes, com ajuda para quem não sabe | Distinguir organizador pessoal, modelos humanos autorizados e orientação nutricional individual; esta última exige viabilidade própria, ainda pendente |
| R08 — Alimentos, quantidades e rótulos | Calorias, gramas, porções, medidas caseiras, nutrientes, ingredientes, restrições e aprendizagem de embalagem | Pesquisa/lista útil em Portugal; alimento/preparo correto; leitura visual de 100 g/100 ml versus porção, ingredientes e alergénios; desconhecido não equivale a zero ou seguro |
| R09 — Integração alimentação e atividade | Relacionar o que a pessoa quer alcançar, planeia, pratica e consome | Visão conjunta com origem e limites das estimativas; não somar calorias duplicadas nem alterar metas alimentares automaticamente a cada atividade |
| R10 — Registo e personalização manual | Digitar, escolher da lista, usar favoritos/recentes, trazer plano e corrigir registos | Treino, atividade e refeição editáveis; planeado separado do realizado; rascunho, parcial, completo, não feito e descanso diferenciados |
| R11 — Celular e dispositivos | Registar durante a atividade, usar sensores/GPS e conectar fontes compatíveis | Iniciar/pausar/retomar/terminar; origem, permissões, disponibilidade de cada métrica, importação e duplicados tratados. Não pressupor relógio nem integração universal |
| R12 — Imagem de atividade | Usar fotografia/imagem para ajudar a identificar ou importar o que foi feito | Investigar foto de exercício, foto de painel/resumo e eventual sequência/vídeo como problemas distintos; tempo e gasto não ficam comprovados por uma foto isolada |
| R13 — Imagem de alimento | Fotografar alimento para identificação assistida e registo | Reconhecimento desejado permanece no plano: mostrar candidatos, confirmar alimento/preparo e quantidade, corrigir ou usar entrada manual; separar foto do prato, OCR de rótulo e código de barras |
| R14 — Acompanhamento pessoal | Dashboard intuitivo, visual e útil para o quotidiano | Hoje, semana e tendências mostram ações, consistência, progresso e contexto; detalhes explicáveis, comparação consigo mesmo e escolha de métricas, sem aparência de painel empresarial |
| R15 — Ensino e linguagem | Exemplos visuais e orientação contextual, do básico ao técnico | Versões simples/detalhadas consistentes; glossário e ajuda no momento da tarefa, sem obrigar o utilizador a ler uma aula antes de cada registo |
| R16 — Rotina e configuração progressiva | Explicar por que pedir informações, permitir adiar módulos e voltar só ao que falta | Campos obrigatórios por função, metas e agenda ajustáveis, lembretes e descanso; alimentação não configurada abre o seu próprio percurso de configuração |
| R17 — Experiência e plataformas | Rapidez, estado preservado, formulários/teclado, acessibilidade, transições e animações; Android inicial e variante iOS 26/Liquid Glass | Componentes e dados disponíveis aparecem sem recarga total; sessões/rascunhos sobrevivem à interrupção; movimento reduzido e diferenças de plataforma especificados |
| R18 — Sustentação e confiança | Conteúdo relevante, seguro no escopo demonstrado e gratuito para o utilizador, custo controlado, Portugal, privacidade e monetização futura | Direitos comerciais por conteúdo, manutenção, quotas e custos conhecidos; dados de saúde/fotos/percurso protegidos; anúncios sem comprometer confiança ou prática |

Exemplos de experiência: sem familiaridade; aprendizagem da técnica; prática regular; prática estruturada; experiência específica; retorno após interrupção. São descritores de contexto a validar com o conteúdo, **não seis níveis clínicos ou uma classificação definitiva**. Uma pessoa experiente em força pode ser iniciante em corrida. Intensidade do treino também não é sinónimo de experiência.

## Integração sem falsas certezas

O modo guiado deve ensinar a escolher e organizar conteúdo humano aprovado; o modo livre permite montar e ajustar. Se uma alteração modificar dose, sequência ou progressão fora das opções do autor, mostrar que é uma versão personalizada, sem conservar uma aprovação que já não se aplica.

A visão inclui reconhecimento por imagem. A restrição “sem treino por IA” refere-se à geração de prescrição; não decide automaticamente se visão computacional será local ou remota. Modelo, licença, precisão, confirmação humana, privacidade e custo precisam de pesquisa. Não remover reconhecimento da visão por ser difícil, nem apresentá-lo como resolvido por uma API genérica de imagem.

Alimentação e atividade partilham objetivos e histórico. O app deve distinguir ingestão registada, gasto estimado, métricas do dispositivo e metas escolhidas/justificadas. Não tratar calorias de exercício como perda de gordura medida, nem inferir massa muscular a partir de peso isolado. Recomendações de dieta individual, tratamento e progressões para populações específicas permanecem condicionadas à validação apropriada.
