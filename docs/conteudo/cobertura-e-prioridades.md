# Cobertura de conteúdo e prioridades

**Organização de 26/09/2026:** a visão abaixo permanece integral; a execução agora segue a [fila de 46 nichos](../planejamento/etapa-01-pesquisa.md#fila-da-etapa-01-por-nicho), um por vez. [Retornos exatos e chamadas](evidencias-para-integracao.md) são a referência para implementar. N01 identificou 3.484 alimentos Ciqual em XML, com nomes FR/EN, classificação e 30 exemplos; nomes pt-PT, calorias, marcas, guias e fotos têm seus próprios nichos. A conclusão de N01 é de pesquisa, não de publicação.

**Atualização de evidências — 26/09/2026:** mantida a visão completa abaixo. Há pilotos de corrida (27 sessões), força introdutória (sete movimentos) e porções de 12 alimentos; [resultados](evidencias/2026-09-26/pilotos-resumo.json). São importações de pesquisa, não catálogo homologado no app. A etapa 01 permanece aberta; a sequência foi organizada por nichos a pedido do autor.

Revisão de **25/09/2026**, alinhada aos [requisitos R01–R18](../planejamento/README.md). Esta matriz descreve a oferta desejada e a pesquisa que falta; não afirma que os programas, dietas, mídias ou integrações já estejam disponíveis. Saúde corporal é o eixo do produto; situações clínicas são uma dimensão adicional.

O inventário abaixo responde a três perguntas: **o que o app fará e entregará à pessoa; o que esperamos receber de fontes/APIs; o que existe de fato e o que falta, com origem e motivo**. As evidências de conteúdo foram coletadas em 22–23/09 e relidas localmente em 25/09; isso não é uma nova medição de disponibilidade dos fornecedores. Código e amostras são coisas diferentes: um JSON recebido para pesquisa ainda não abastece o aplicativo.

## 1. O aplicativo deve fazer e devolver

“Devolver” aqui significa o resultado que a pessoa vê, entende e consegue usar. Não é ainda a definição de endpoints, tabelas ou contrato Swagger. A tabela descreve a visão completa, sem declarar que todos os módulos estarão no primeiro lançamento.

| O aplicativo deve permitir | O que precisa entregar à pessoa |
|---|---|
| Começar sem saber montar um treino | Explicação das opções, coleta apenas dos dados necessários, programas humanos compatíveis com o contexto coberto, motivo da escolha, requisitos e primeira sessão compreensível |
| Treinar na academia | Plano organizado por semanas/dias; exercícios com máquinas ou pesos livres, região trabalhada, execução visual, séries/repetições ou outras unidades, descanso e progressão prevista pelo autor |
| Treinar em casa | Programas compatíveis com espaço e equipamento informado: peso corporal, elásticos, halteres e outros materiais; alternativas somente quando previstas e conferidas |
| Treinar em praça, parque ou outro espaço ao ar livre | Sessões para o equipamento realmente disponível, como barras e apoios adequados; identificação de material/local necessário e opções sem equipamento. O app não pode presumir que toda praça tem a mesma estrutura |
| Caminhar e correr | Percursos de iniciação, continuidade e objetivos específicos; blocos de caminhada/corrida quando previstos; duração, distância, ritmo e intervalos. Durante a atividade: iniciar, pausar, retomar e terminar; mapa/percurso real quando houver GPS |
| Praticar yoga, Pilates, mobilidade, alongamento e equilíbrio | Sequências próprias de cada prática, posições/transições, ordem, duração, apoios e demonstrações. Não transformar uma lista de movimentos de musculação numa aula dessas modalidades |
| Fazer funcional, circuitos e cross training | Sessões por blocos/estações/rondas, trabalho e descanso, material, instrução técnica e progressões específicas, sem geração aleatória de circuitos |
| Praticar ciclismo, natação, dança e desportos | Conteúdo e registo adequados à modalidade: por exemplo distância/tempo no ciclismo, metros/estilo/piscina na natação e duração/contexto em aula ou jogo. Sensores adicionais só quando disponíveis |
| Fortalecer regiões e lidar com retorno/limitações | Conteúdo com finalidade, público e limites identificados. Distinguir fortalecimento geral, retorno após pausa e situações de dor, diagnóstico ou cirurgia; mostrar quando o catálogo não cobre a situação, sem transformar uma queixa em prescrição automática |
| Escolher, trazer ou montar o próprio treino | Pesquisa de exercícios e programas, filtros, explicações, ordenação de sessões, agenda e ajustes; guardar a origem e indicar quando se trata de uma versão pessoal modificada |
| Executar e registar o treino | Orientação da etapa atual, descanso/temporizador e registo do realizado: séries, carga, repetições, duração ou distância conforme a prática; conclusão parcial/completa, não feito e descanso separados |
| Organizar alimentação e montar refeições/dietas | Rotina alimentar, refeições e porções editáveis; modo livre e ajuda guiada baseada em conteúdo/método validado; modelos humanos quando disponíveis. Planeado separado do que efetivamente foi consumido |
| Pesquisar alimentos e calcular o consumido | Nome/preparo corretos, gramas/porções, calorias e nutrientes da quantidade confirmada; ingredientes/alergénios quando documentados, fonte e campos desconhecidos visíveis |
| Aprender a cuidar da alimentação | Exemplos visuais de embalagem, tabela por 100 g/100 ml, porção, ingredientes, alergénios, pesagem e cru/cozido; explicação simples com detalhe técnico opcional |
| Usar fotos, códigos, listas ou digitação | Foto de alimento: candidatos e confirmação de preparo/quantidade. Rótulo: texto/dados extraídos. Código: produto encontrado ou entrada manual. Foto de exercício/painel: identificação ou importação assistida dos dados realmente presentes |
| Usar o celular e conectar dispositivos | Atividade acompanhada por GPS/sensores compatíveis, importação autorizada, origem e horário de cada métrica, tratamento de duplicados e possibilidade de corrigir registos |
| Relacionar alimentação, atividade e objetivos | Visão conjunta de ingestão registada, atividade, medidas e metas; mostrar estimativas e dados incompletos, sem equiparar gasto a perda de gordura medida nem ajustar dieta automaticamente sem método validado |
| Acompanhar evolução e rotina | Dashboard pessoal com o que fazer hoje, semana planeada/realizada, continuidade, evolução pertinente ao objetivo e próxima ação útil; gráficos claros com acesso ao detalhe e comparação consigo mesmo |
| Gerir conta, preferências e privacidade | Entrar com Google, Apple no percurso iOS e email/senha; cadastro/recuperação, perfil, unidades/idioma, notificações, permissões, exportação/exclusão e configuração separada de cada módulo |
| Usar o app com rapidez e continuidade | Estado/rascunhos preservados entre telas, retomada de sessão, conteúdo disponível offline quando permitido, carregamento só do necessário, teclado e acessibilidade corretos; Android inicial e variante iOS/Liquid Glass posterior |

### Informações que mudam a seleção e a experiência

| Dimensão | O que o app precisa conhecer ou permitir ajustar |
|---|---|
| O que a pessoa quer | Saúde/hábito, força, mobilidade, capacidade cardiorrespiratória, modalidade, ganho de massa, redução de gordura, ganho/perda/manutenção de peso; objetivos podem coexistir |
| Experiência e retorno | Familiaridade e técnica **por modalidade**, prática recente, interrupções, intensidade e volume suportados no contexto do programa; não limitar tudo a três níveis universais |
| Onde e com o quê | Academia, casa, praça/parque, outros locais; equipamento real, espaço, percurso/terreno quando relevante |
| Quando e quanto tempo | Dias disponíveis, minutos por sessão, horários, outras atividades, descanso, lembretes e rotina variável; adaptar agenda não equivale a alterar livremente a prescrição |
| Alimentação | Preferências, ingredientes/restrições declaradas, refeições, tempo/orçamento de preparo, unidades e porções; metas nutricionais dependem de método e dados próprios |
| Contexto pessoal | Dados físicos e limitações somente quando necessários à função; explicar finalidade e permitir adiar módulos opcionais. Registar uma refeição não exige completar toda a ficha física |
| Como quer usar | Modo guiado ou livre, linguagem simples/técnica, registo manual/foto/dispositivo e permissões aceites |

Se faltar informação indispensável para uma função, o resultado esperado é **explicar o que falta e abrir somente aquele complemento de cadastro**. Não bloquear todo o app por um módulo alimentar ainda não configurado.

## 2. O que precisamos receber de APIs ou outras fontes

Uma fonte pode ser API, dataset, documento ou programa humano licenciado. Não precisamos obrigatoriamente de uma API por tela nem de consultar fornecedores durante cada sessão. A proposta é importar/normalizar conteúdo elegível numa base própria versionada; API externa continua sendo uma dependência onde for necessária. Isso ainda não foi implementado.

**Programa, sessão e exercício são objetos diferentes:** programa organiza semanas e progressão; sessão organiza uma prática num dia; exercício explica um movimento. Uma biblioteca de exercícios não entrega automaticamente os outros dois. As fichas abaixo são requisitos de informação, não o schema final do banco e não a afirmação de que um fornecedor oferece todos os campos.

### Programas humanos completos e sessões

- **Identificação:** ID estável, nome, descrição, autor/instituição, fonte original, versão/data, idioma, licença e direitos do texto/mídia.
- **Para quem e para quê:** objetivo, modalidade, público contemplado, experiência/requisitos, ambiente, equipamentos e situações excluídas segundo a fonte.
- **Organização:** duração do programa, semanas/fases, frequência, sessões e ordem; descanso e critérios de progressão/regressão previstos pelo autor.
- **Cada sessão:** nome/foco, duração prevista quando fornecida, aquecimento/parte principal/retorno à calma quando presentes no original, exercícios/blocos ordenados e referências às instruções.
- **Dose de cada bloco/exercício:** séries, repetições, tempo, distância, ritmo/carga/intensidade e pausas conforme a modalidade. Unidades e significado explícitos; nem todo treino usa séries e repetições.
- **Alterações admitidas:** alternativas de material/movimento e condições de uso, sem completar parâmetros ausentes inventando uma prescrição.
- **Fundamento e revisão:** referências declaradas, responsável/data de revisão e limites de uso; se a fonte não fornece algum dado essencial à oferta pretendida, registrar a lacuna.

### Exercícios e instruções visuais

- **Nome e pesquisa:** ID, nome principal, nomes alternativos e idioma.
- **O que trabalha:** região, músculos principais/secundários, tipo de movimento e categoria, conforme a classificação da fonte.
- **Como executar:** posição inicial, passos, equipamento e ajustes, observações de execução, erros comuns e respiração quando descritos.
- **Mídia:** foto/sequência de imagens, ilustração, animação ou vídeo que realmente demonstre a execução; URL/arquivo, formato, duração quando aplicável, legenda/descrição acessível, autoria e licença de cada recurso.
- **Variações:** movimentos relacionados, alternativas e requisitos; “trabalha o mesmo músculo” não basta para afirmar equivalência.
- **Limites:** indicações/precauções e público descritos na fonte. Um campo `muscle = quadriceps` não responde se o exercício serve para uma cirurgia específica.

Imagem de capa do dia, desenho de músculo e demonstração de execução têm funções diferentes. O app deve ter instrução visual aprovada onde prometê-la; não é necessário exigir foto **e** vídeo em todos os itens, mas a ausência de ambos precisa de solução explícita.

### Atividades, gasto estimado e mapa

- **Catálogo de atividades:** ID/código, nome, descrição e condições que diferenciam práticas; unidade pertinente e referência populacional.
- **Estimativa de esforço/gasto:** valor de referência, como MET quando apropriado, contexto, fonte/versão e método/limites. Não é um programa nem a medição do gasto individual.
- **Dados de atividade real:** início/fim/fuso, pausas, duração ativa/total, distância, percurso e qualidade/origem dos dados; ritmo, frequência cardíaca, passos, cadência ou potência apenas se a fonte/dispositivo os fornecer.
- **Mapa:** cartografia/tiles ou estilo compatível, cobertura, atribuição, condições de cache/offline e quotas. Rota e localização vêm de dados GPS; um mapa não mede o exercício.

### Alimentos e produtos embalados

| Grupo de dados necessário | Campos e distinções esperadas |
|---|---|
| Identidade | ID, nome, sinónimos, idioma, grupo; marca/código de barras/mercado quando for produto embalado |
| Estado do alimento | Cru, cozido, preparado, escorrido; parte comestível, com/sem pele/casca/osso, preparação e composição relevantes |
| Base e quantidade | Base de referência, como 100 g/100 ml; porção documentada, unidade e peso em gramas quando disponíveis; densidade/rendimento quando necessários à conversão |
| Energia e nutrientes | Energia em kcal/kJ, proteína, hidratos de carbono, gordura, fibra; açúcar, gordura saturada, sal/sódio e micronutrientes conforme disponibilidade; valor + unidade + método/qualificador |
| Ingredientes e restrições | Ingredientes, alergénios declarados e avisos de traços quando presentes na fonte; informação ausente permanece desconhecida |
| Imagens | Foto de alimento/produto e, quando útil, do rótulo; finalidade, origem, licença e correspondência com o item/preparo. Imagem ilustrativa não comprova porção |
| Proveniência | Fonte/ID original, data/versão, qualidade e licença. Separar valor zero, não informado, traço e abaixo do limite de quantificação |

**Quantidade consumida vem do utilizador ou de uma medição confirmada.** A fonte pode dizer quanto pesa uma unidade ou porção; não sabe quanto a pessoa comeu. O app fará a conversão para a quantidade confirmada, usando a base correta. Não converter ml em g sem uma relação adequada, nem substituir automaticamente alimento cru por cozido.

### Receitas, planeamento alimentar e ensino

- **Receita:** nome/ID, autor, ingredientes com quantidades/unidades, preparo, rendimento/peso final e porções quando conhecidos, tempo, mídia licenciada e origem do cálculo nutricional.
- **Modelo de rotina/plano alimentar:** autoria/fundamento, público/objetivo, refeições, opções/quantidades, substituições permitidas e limites. Uma tabela nutricional não fornece esse modelo.
- **Metas:** método e dados necessários para metas de energia/nutrientes, população e limites; separar meta escolhida, modelo educativo e orientação individual. Ainda precisamos selecionar e validar esse caminho.
- **Educação:** explicações, exemplos de embalagem/refeição/treino, glossário, versão simples/técnica, imagens acessíveis, fonte, licença e revisão. Não presumir que uma API de alimentos ensina a interpretar seus campos.

### Reconhecimento por imagem e conexões

| Entrada | Retorno necessário e confirmação |
|---|---|
| Foto do prato/alimento | Candidatos de alimento/preparo e correspondência com a base; capacidade real de reconhecer múltiplos itens, limite/incerteza informados e confirmação. Peso/porção precisa de dado adicional ou estimativa validada e corrigível |
| Foto do rótulo | Texto extraído, campos reconhecidos, unidade e base por 100 g/porção, com possibilidade de comparar e corrigir. OCR não confirma sozinho se o rótulo corresponde ao alimento escolhido |
| Código de barras | Código lido e resultado da consulta: produto identificado, dados disponíveis, ausência de correspondência ou erro; código não contém a ficha nutricional inteira |
| Foto de exercício | Candidatos de movimento/equipamento, quando tecnicamente demonstrado; confirmação. Foto isolada não informa a duração da sessão, repetições totais ou gasto |
| Foto de painel/resumo | Dados realmente visíveis, como tempo/distância/unidade, origem declarada e correção antes de salvar; não tratar imagem de resumo como medição direta do app |
| Health Connect/HealthKit ou outra conexão | Tipo/valor/unidade, intervalo e fuso, ID e origem, permissões/disponibilidade, atualizações/exclusões e informação suficiente para tratar duplicados |

Modelo de reconhecimento, custo, licença, desempenho local/remoto e proteção de imagens ainda precisam de prova. Não exigir uma “confiança em percentagem” inventada se o serviço não fornece medida adequada. Reconhecimento assistido permanece desejado; a restrição de IA para prescrever treino não o torna automaticamente implementado ou proibido.

### O que será responsabilidade do TrainForge

| Responsabilidade | Por que não basta pedir isso à API externa |
|---|---|
| Selecionar e apresentar programas elegíveis | É preciso combinar contexto do utilizador e requisitos de conteúdo aprovado; uma busca textual não demonstra adequação |
| Agenda e continuidade | Horários, plano escolhido, reagendamento, rascunhos, sessão em curso e lembretes são dados/estado do utilizador |
| Registo do realizado | Série feita, carga usada, quantidade comida e correções precisam ser capturadas e preservadas pelo app |
| Cálculos e dashboard | Converter quantidade confirmada, agregar histórico e comparar planeado/realizado exige regras próprias com unidade, período, origem e duplicados corretos |
| Velocidade e falhas | Cache permitido, pré-carregamento, funcionamento offline, sincronização, tentativas e mensagens de erro são responsabilidades da solução |
| Confiança | Preservar atribuição/licença, consentimento, direitos de acesso/exclusão, versão do conteúdo e limites conhecidos ao longo de todo o percurso |

Nos contratos futuros também serão definidos campos opcionais/nulos, paginação, limites de chamadas, cache, versões e erros. O contrato externo deve ser traduzido para as necessidades do produto, sem copiar automaticamente sua estrutura para o banco.

## 3. O que temos exatamente, onde está e o que falta

### Conteúdo e evidências existentes

**Estados usados:** *amostra local* é material recebido para avaliar; *referência documental* é um caminho pesquisado; *código inicial* é implementação existente com limites; *homologado* significaria conteúdo conferido e liberado para a oferta pretendida. **Não há catálogo de programas/receitas/dietas homologado e integrado.** Não somar contagens de bases distintas como alimentos ou exercícios únicos prontos para uso.

| Origem | O que temos com exatidão | Onde está registrado | O que falta e por quê |
|---|---|---|---|
| **wger — EX01** | **75 exercícios únicos** em três páginas de 25. Campos de nome/tradução/descrição, categoria, músculos, equipamento e licenças; **6** com tradução em português, **37** com imagens e **8** com vídeo. Guardamos JSONs e URLs/metadados, não um acervo de mídias aprovado | [Amostra ampliada](evidencias/wger-amostra-ampliada.json) e [achados](amostras-e-achados.md) | **Não são 75 programas.** Tradução/instrução/mídia e direitos precisam de conferência por item; 4 imagens estão marcadas IA e o ID 1022 tem traduções divergentes. URLs existentes não comprovam qualidade, disponibilidade atual ou revisão clínica |
| **free-exercise-db — EX02** | Arquivo com **876 exercícios**; auditoria registrada de **25**. Campos `name`, `force`, `level`, `mechanic`, `equipment`, músculos primários/secundários, passos `instructions`, categoria, caminhos `images` e ID | [Resumo da primeira coleta](../planejamento/evidencias/resumo-amostras.json). Bruto local: `docs/planejamento/evidencias/free-exercise-db.json` | Inglês, campos ausentes em parte da amostra, autoria/licença por item não demonstradas. A declaração Unlicense do repositório não resolveu a cadeia de direitos das imagens. Sem lote aprovado/importado |
| **CoFID 2021 — AL05** | Planilha recebida; **2.760 alimentos lidos** na aba de composição principal e **27 linhas selecionadas**. IDs, nomes/preparo, referências e energia/proteína/gordura/hidratos/fibra; valores especiais preservados | [Amostra CoFID](evidencias/cofid-amostra.json) e [método](amostras-e-achados.md) | Sem tradução/correspondência portuguesa aprovada, fotos de alimento ou rotina alimentar. Piloto de 26/09 conferiu conversão por massa de 12 registros e semântica de valores; sem equivalência pt-PT/dieta aprovada. Os 27 exemplos não homologam os 2.760 |
| **Ciqual 2025 — AL04** | Excel: **3.484 alimentos**, 29 linhas nutricionais selecionadas. N01 acrescentou XMLs de alimentos/grupos: os mesmos 3.484 IDs, nomes FR/EN, 720 nomes científicos, 138 linhas de classificação e 30 exemplos de identidade. Campos de identidade cruzados com a planilha | [Retorno e chamadas](evidencias-para-integracao.md#n01--retorno-xml-de-identidade-alimentar), [resumo N01](evidencias/2026-09-26/n01-alimentos/resumo-identidades.json) e [amostra nutricional anterior](evidencias/ciqual-amostra.json) | Sem nomes portugueses ou preparo estruturado; um alimento genérico sem grupo. Composição/calorias serão o foco N02: métodos, valores `<`, `traces` e ausentes precisam de tratamento; não temos toda a proveniência por nutriente do XML. Não traz fotos ou dietas homologadas |
| **USDA FoodData Central — AL01** | **15 resultados de busca**, todos com energia e macronutrientes, sem `servingSize` nessa amostra; **um detalhe de alimento** analisado com duas entradas de porção | [Resumo USDA](../planejamento/evidencias/resumo-amostras.json). Detalhe bruto local: `docs/planejamento/evidencias/usda-egg-detail.json` | Relevância das buscas e porções precisam ser conferidas: procurar “rice” trouxe também snacks. O detalhe de um ovo não demonstra cobertura de alimentos portugueses nem porções para todos |
| **Compêndio 2024 — CI06** | **20 registros**: quatro de cada grupo corrida, caminhada, ciclismo, condicionamento e atividades aquáticas. Código, descrição e MET originais | [Coleta e exemplos](amostras-e-achados.md); `docs/conteudo/evidencias/compendium-*.evidencia.json` | São referências de atividade/esforço, **não treinos completos**, instruções em vídeo ou calorias individuais medidas. Importação, método aplicável e apresentação das estimativas pendentes |
| **Open Food Facts — AL02** | Documentação e duas tentativas HTTP 503 em 22/09; [nova consulta limitada](evidencias/2026-09-26/network/off-portugal-30.evidencia.json) em 26/09 também 503, recebendo **zero produtos** | [Resultado negativo](../planejamento/evidencias/resumo-amostras.json) e [catálogo](catalogo-fontes.md) | Não temos amostra que comprove marcas/códigos portugueses, imagens, porções ou completude. É necessário obter e conferir produtos reais; não inferir que a base não tem conteúdo a partir dessa falha |
| **PortFIR — AL03 / Fineli — AL06** | Referências documentais; PortFIR com versões diferentes nas páginas por idioma; Fineli com chamada de exemplo **403** | [Catálogo](catalogo-fontes.md) e [achados](amostras-e-achados.md) | PortFIR: dataset e permissão adequada ainda não obtidos nesta pesquisa. Fineli: nenhum registro recebido por essa tentativa. Nenhum dos dois abastece o app |
| **Programas humanos e contextos de saúde** | Candidatos/referências como NHS, NIA, IPDJ/DGS e entidades por modalidade; análise de obtenção sem parceria e de limites dos contextos clínicos | [Programas prontos e cenários clínicos](programas-prontos-e-cenarios-clinicos.md), [catálogo](catalogo-fontes.md) e matriz de modalidades abaixo | **Zero programas homologados no app.** Em 26/09 há importação experimental de corrida NHS (27 sessões) e rotina de força (sete movimentos), com [resumo conferido](evidencias/2026-09-26/pilotos-resumo.json). Academia e demais percursos continuam sem lote completo aprovado; falta revisão pt-PT, adequação e integração. Citar uma instituição não aprova automaticamente um programa ou indicação individual |
| **Receitas, dietas e ensino** | Candidatos documentais, como NHLBI/MyPlate, pautas de ensino e critérios de seleção | [Catálogo](catalogo-fontes.md), [curadoria](qualidade-e-curadoria.md) e seções de alimentação abaixo | **Zero lotes de receitas/dietas/fichas didáticas homologados e integrados.** Falta seleção, direitos de texto/imagens, adaptação e método de orientação. Fonte de nutrientes não resolve essas entregas |
| **Imagens, mapas e conexões** | Requisitos e triagem documental, além de mídia de exercícios referenciada nas amostras | [Fontes e custos](../planejamento/fontes-custos-e-hospedagem.md), [viabilidade](../planejamento/viabilidade-operacional.md) e [ajustes visuais futuros](../design/ajustes-visao-integrada.md) | Não há acervo aprovado de fotos de alimentos, reconhecimento validado, percurso GPS real, mapa integrado ou conexão com dados do dispositivo no aplicativo |

O [catálogo estruturado](fontes.json) registra **43 fontes/famílias** com URLs originais, data, acesso, direitos, achado e próxima ação: 10 candidatos, 10 condicionais, 8 incompatíveis com o caminho gratuito comercial avaliado e 15 referências. Essa classificação descreve a pesquisa datada, não uma aprovação de 43 integrações. As políticas/licenças precisam ser conferidas novamente para a versão/objeto selecionado antes de publicação.

Os resumos acima estão versionados. Arquivos brutos de terceiros permanecem **locais e fora do Git** conforme o escopo da publicação inicial; não prometer que um clone do GitHub contém as planilhas, os JSONs completos ou vídeos. [Inventário de evidências](evidencias/README.md).

### Exemplos concretos dos campos que recebemos

| Caso conferido | Informação existente | O que isso não fornece |
|---|---|---|
| wger, exercício **12** | Nome traduzido, categoria/músculos e referência de imagem/vídeo com metadados; a imagem de exemplo tem `license_author` vazio | Programa de semanas, prescrição para uma dor ou mídia já revista. Metadado incompleto demanda conferência |
| USDA, alimento **748967**, ovo inteiro | Energia/nutrientes e duas descrições de porção; uma delas informa **1 ovo sem casca = 50,3 g** | Quanto o utilizador comeu, foto aprovada ou uma porção universal para todo ovo |
| CoFID, **11-867**, arroz basmati integral cozido sem sal | **131 kcal por 100 g** no registro, com proteína/gordura/hidratos/fibra e referência original | Equivalência ao arroz cru; o registro cru **11-866** tem **355 kcal por 100 g**. Não intercambiar os IDs |
| Ciqual, **25088**, arroz cantonês pré-embalado | Nome/preparo e energia/nutrientes do registro francês selecionado | Equivalência a arroz simples ou a qualquer receita portuguesa com nome semelhante |

São exemplos de leitura de dados, não recomendações de treino, alimento ou porção. Não reproduzimos aqui instruções extensas de terceiros.

### O que já existe no aplicativo e backend

Conferência pontual em **25/09/2026** dos modelos Flutter, onboarding, estatísticas e builder da API, orientada pelo grafo existente. A análise funcional completa registrada continua em [documentação técnica](../../documentacao-tecnica.md). Não houve teste integrado em aparelho/banco nesta entrega.

| Parte | Implementação existente | Limite em relação ao produto esperado |
|---|---|---|
| App e API | Flutter em `trainforge/lib`; API ativa em `C:\dev\bootcamp-treinos-api`, com Fastify/Prisma/PostgreSQL | A API continua fora deste repositório. Não há backend novo independente na pasta Flutter |
| Conta e perfil | Fluxo inicial Google, sessão e dados físicos/perfil; [repositório de autenticação](../../lib/features/auth/data/auth_repository.dart) | Login Apple/email-senha e todos os fluxos de conta desenhados não estão demonstrados como funcionais no app; refresh/logout ainda têm pendências da auditoria |
| Criação inicial de plano | [Onboarding](../../lib/features/onboarding/data/onboarding_api.dart) envia dados físicos, objetivo, dias, experiência, duração e restrições. O builder da API contém templates e regras de séries/repetições/descanso | **Não usa wger nem programa humano importado.** Usa quatro objetivos e três níveis fixos; restrições não entram no builder. A duração declarada não reorganiza a sessão. Ainda existe também a rota de geração por IA, contrária à direção futura |
| Plano/dia/exercício | [Modelo atual](../../lib/features/workouts/domain/workout_plan_item.dart): plano com ID/nome/ativo/dias; dia com nome, dia da semana, descanso, duração estimada, capa e exercícios; exercício com **ID, ordem, nome, séries, repetições e descanso** | Sem descrição de execução, músculos, equipamento, autoria/licença/versionamento ou mídia instrucional no objeto do exercício. `coverImageUrl` pertence ao dia e não é demonstração técnica |
| Execução | Início e conclusão de sessão, consulta de exercícios e histórico associado ao dia | Não regista carga/repetições efetivamente realizadas por série; sem pausa persistida. Defeito conhecido de recorrência bloqueia o dia após uma conclusão histórica |
| Estatísticas | [Modelo atual](../../lib/features/stats/domain/stats_data.dart): sequência, quantidade concluída, taxa de conclusão, tempo total e dias iniciados/concluídos | Não é o dashboard integrado. Métricas centradas no plano ativo, com semântica/recorrência a rever; sem alimentação, percurso, composição corporal ou evolução de carga |
| Protótipo visual | Inventário histórico de **105 telas/estados e 372 reações** das telas na base v0.4, preservado em 22/09 | Figma contém simulações e dados demonstrativos. Contagem datada, sem nova auditoria visual em 25/09; não prova funcionamento dos módulos no código |

### Lacunas prioritárias e motivo

| O que falta | Por que ainda falta / evidência necessária |
|---|---|
| Catálogo de programas completos para academia, casa, praça e demais modalidades | As amostras mais estruturadas são de movimentos, alimentos e MET. Selecionar programas humanos completos com sessões/progressão, direitos e contexto conferidos; não pressupor parceria ou escrita manual um a um |
| Seleção por dias, tempo, objetivo, local e experiência | Precisamos de requisitos reais dos programas e regras de compatibilidade. O builder atual não demonstra essa cobertura nem leva restrições em conta |
| Cobertura de dor, operações, limitações e retornos | Referências publicadas não demonstram indicação individual. Delimitar público/cenários, conteúdo e condições de uso; fortalecimento geral não resolve todo contexto clínico |
| Biblioteca instrucional visual em português | Tradução parcial, mídia heterogénea, campos/autoria incompletos e divergência concreta no wger; precisamos de lote coerente, acessível e permitido |
| Base alimentar útil em Portugal, com imagens e porções | Os datasets recebidos são estrangeiros; produtos portugueses ainda sem amostra, fotos sem acervo aprovado e correspondência cru/cozido/porções por validar |
| Refeições, receitas e planos/dietas guiados | Nutrientes não dizem como montar uma rotina ou que meta individual usar. Faltam modelos/métodos, direitos, adaptação e revisão |
| Foto de alimento/exercício, rótulo e painel | Não selecionamos nem testamos um caminho de reconhecimento/OCR. Identificar imagem é diferente de medir gramas, tempo ou gasto; faltam confirmação, privacidade e custo demonstrado |
| GPS, mapas, sensores e dados de saúde | Há pesquisa, mas falta prova no dispositivo, permissões, segundo plano, bateria, tratamento de pausas e duplicados; fornecedor de mapa não substitui captura |
| Agenda e dashboard integrados | Regras de metas/períodos/estimativas e modelos de registo ainda não implementados; o histórico atual cobre somente parte do treino |
| Didática simples/técnica com exemplos | Temos pautas; faltam fichas e recursos visuais conferidos, com testes de compreensão, acessibilidade e direitos |
| Aplicação completa, persistência e publicação | Fluxos Figma futuros, contratos, banco, cache/sincronização, correções, testes em aparelho, infraestrutura e loja pertencem às etapas seguintes. Publicar o código no GitHub não publicou o app |

**Resultado deste inventário:** sabemos quais entregas queremos, quais campos procuramos e quais evidências realmente possuímos. A entrega documental está concluída; **a etapa 01 continua aberta**. O próximo avanço útil é demonstrar percursos completos com conteúdo elegível, começando pelas lacunas que impedem uma pessoa sem conhecimento de receber orientação real.

## Dois percursos igualmente necessários

**Quero ajuda para começar:** explicar opções e objetivos, selecionar um programa humano completo dentro do contexto coberto, ensinar execução e registo e acompanhar continuidade. Ter apenas movimentos avulsos ou pedir que a pessoa escreva o próprio treino não atende esse percurso.

**Quero montar ou ajustar:** procurar exercícios/atividades, conhecer instruções, ordenar sessões, configurar agenda e doses, importar um plano próprio e personalizar. Diferenciar programação original de alterações pessoais. A mesma pessoa pode usar os dois percursos em modalidades diferentes.

## Matriz de modalidades e unidades

Nenhuma linha abaixo está homologada como catálogo de programas do TrainForge. “Referência” indica ponto de pesquisa, não autorização para copiar ou recomendação individual.

| Família | Conteúdo que precisa existir | Particularidades de configuração/registo | Base e lacuna atual |
|---|---|---|---|
| Força em academia | Programas completos, máquinas/pesos livres, técnica e progressão | Séries, repetições, carga, descanso, ordem, unilateralidade quando relevante | wger/ACSM como insumos; faltam programas prontos elegíveis e mídia revista |
| Força em casa | Peso corporal, elásticos, halteres e alternativas previstas pelo autor | Espaço, equipamentos realmente disponíveis e apoios; não pressupor equivalência de carga | NHS/NIA/IPDJ como referências; falta homologar sequências e alternativas |
| Força em praça/parque e calistenia | Programas ao ar livre, com ou sem barras/apoios, conforme o local real | Equipamentos disponíveis, espaço e requisitos de apoio/segurança definidos no conteúdo | Contexto explicitado em 25/09; sem lote próprio de programas homologado |
| Caminhada | Iniciação, continuidade e progressão humana | Tempo, distância, terreno, pausa; indoor/outdoor | Referências gerais e Compêndio; programa completo e critérios ainda pendentes |
| Corrida | Começar, alternar andar/correr, prática contínua e objetivos específicos | Intervalos, duração/distância, ritmo, terreno, descanso e retorno após pausa | Couch to 5K como candidato documental; direitos/pt-PT e demais percursos pendentes |
| Yoga | Sequências humanas por objetivo/contexto, posições e transições | Tempo, sequência, apoios e variações previstas; experiência específica | Sem lote de sequências e mídia homologado |
| Pilates | Solo e equipamentos separados, sequência e instrução próprias | Material, controle, repetições/tempo conforme a fonte | Sem programa e direitos demonstrados para integrar |
| Funcional / circuitos / cross training | Sessões completas, técnica, estações e progressões | Blocos, rondas, intervalos de trabalho/descanso, equipamento e complexidade | Precisa de pesquisa específica; não montar misturando exercícios aleatórios nem pressupor licença de marca |
| Mobilidade / flexibilidade / equilíbrio | Sequências e uso pretendido claros | Região/movimento, tempo, apoio e nível funcional quando declarado | NHS/NIA como referências; sem promessa de corrigir lesões |
| Ciclismo | Indoor, estrada e outros contextos separados | Tempo, distância, terreno, cadência/potência apenas se disponíveis | British Cycling e Compêndio como referências; faltam programas autorizados |
| Natação | Iniciação e sessões por capacidade/contexto | Estilo, metros, comprimento da piscina, pausas e contexto aquático | Swim England como referência; direitos e adequação não resolvidos |
| Dança e atividades em grupo | Sequências/aulas com autoria e meios de acompanhar | Duração e participação; mídia, música e coreografia têm direitos próprios | Registo possível como conceito; conteúdo instrucional ainda não selecionado |
| Desportos e preparação física | Sessões humanas para contextos reais, sem confundir jogo com exercício técnico | Modalidade, treino/jogo, duração, grupo e material | FIFA e outras fontes são referências; cobertura precisa de investigação específica |
| Atividade adaptada e envelhecimento | Programas próprios para populações/contextos definidos | Acessibilidade, apoio, capacidade funcional e equipamento adaptado | DGS/IPDJ/NIA e compêndios específicos; falta lote elegível |
| Retorno e contextos de saúde | Material correspondente à situação e ao público, dentro dos limites publicados | Retorno após pausa separado de retorno após lesão/cirurgia; plano assistencial quando aplicável | [Análise específica](programas-prontos-e-cenarios-clinicos.md); não há indicação clínica automática validada |

Outras práticas podem entrar com a mesma ficha de avaliação. Não transformar “muitos tipos” numa lista sem programa, explicação e forma de registo. Sono, hidratação e recuperação podem ser investigados como apoios à rotina; ainda não são promessa de módulo clínico completo ou substituição da visão acima.

## Personalização sem três níveis fixos

A seleção deve cruzar: modalidade; familiaridade/técnica; prática recente; tempo de interrupção; objetivo; dias e minutos disponíveis; local; equipamentos; preferências; limitações declaradas; requisitos do programa. Dificuldade técnica, intensidade, volume e experiência são eixos diferentes.

Há espaço para quem está a descobrir a atividade, aprender técnica, consolidar hábito, seguir programação estruturada ou aprofundar desempenho. Os rótulos finais virão do conteúdo e dos testes de compreensão, não de uma escala universal inventada. Não chamar um utilizador de “extremo”.

Objetivos podem coexistir: saúde/hábito, força, capacidade cardiorrespiratória, mobilidade, prática de uma modalidade, ganho de massa, redução de gordura, ganho/perda/manutenção de peso. Definir como medir cada um; metas de peso não demonstram por si só mudança de músculo ou gordura. Tempo/dias livres não autorizam comprimir qualquer programa ou saltar a progressão original.

## Alimentação: além da composição de alimentos

| Necessidade | Conteúdo/fluxo esperado | Lacuna a resolver |
|---|---|---|
| Aprender a comer e registar | Percurso visual sobre alimentos, refeições, quantidades e leitura de rótulo | Produzir/adaptar fichas elegíveis com revisão; ainda são pautas |
| Organizar rotina alimentar | Horários flexíveis, refeições, preferências, orçamento/tempo de preparo e rotina de atividade | Especificar composição do planeamento e relação com agenda |
| Montar dietas/planos alimentares | Modo livre e ajuda guiada; modelos humanos quando direitos e contexto permitirem | Composição/receita não resolve plano individual; fonte, método, população e revisão pendentes |
| Ganhar/perder/manter e acompanhar | Objetivos partilhados, ingestão registada, medidas e evolução contextualizada | Método das metas, limites, qualidade dos dados e revisão; sem ajuste automático arbitrário |
| Pesquisar e quantificar | Genéricos, embalados, receitas, favoritos; gramas, porções e medidas documentadas | Cobertura portuguesa, preparo cru/cozido, densidades/rendimento e duplicados |
| Restrições e escolhas | Ingredientes, alergénios declarados, preferências e limites da informação | Ausência de informação não significa alimento seguro; orientações clínicas são escopo próprio |
| Foto / código / rótulo | Identificar candidatos, extrair ou consultar dados e pedir confirmação | Avaliar reconhecimento, OCR e código de barras separadamente; nenhum está implementado |
| Personalizar | Trocar ingrediente/porção, guardar receita própria, rever registo e editar rotina | Alteração não conserva automaticamente nutrientes, autoria/revisão ou adequação do original |

O ensino deve explicar onde olhar: tabela nutricional, base de 100 g/100 ml, porção da embalagem versus quantidade consumida, ingredientes e alergénios. Exemplo didático de cálculo: se um rótulo informa 200 kcal por 100 g, 30 g correspondem a 60 kcal; isso ensina a conta, não recomenda uma porção. A referência europeia descreve declaração por 100 g/100 ml e apresentação adicional por porção. [Comissão Europeia](https://europa.eu/youreurope/business/product-rules-compliance/food/nutrition-declaration/index_en.htm), consultada em 24/09/2026.

Evitar uma lista universal de “pode/não pode comer”. Explicar escolhas no contexto de quantidade, objetivo, preferências e informação disponível, separando restrições pessoais de alegações de segurança alimentar.

## Obtenção de programas sem parceria disponível

1. Procurar **programas humanos completos já publicados** em instituições, federações, projetos abertos e documentos elegíveis. A matriz precisa abranger modalidades e contextos, não só musculação ou reabilitação.
2. Verificar direitos por versão e objeto, população, sessões, frequência, progressão e instruções. Autoria humana sozinha não prova qualidade.
3. Importar um piloto sem alterar a prescrição: normalizar campos e comparar cada sessão com o original; não completar parâmetros em falta por IA ou combinar regras de autores diferentes.
4. Expandir por lotes com controles reutilizáveis, revisão dos casos ambíguos, proveniência e retirada de conteúdo.
5. Onde não houver programa adequado, registrar lacuna e oferecer apenas caminhos efetivamente suportados. Plano próprio é complementar; parceria futura é opcional, não recurso pressuposto.

Não foi homologada uma fonte única gratuita e comercial que cubra toda a visão. Isso não comprova inexistência; delimita a evidência atual. Automatizar coleta reduz trabalho técnico, mas não torna opcional conferir licença, traduções e adequação. A carga editorial real continua pendente de medir no piloto.

## Lotes de avaliação e prioridade

A pesquisa anterior sugeriu 40–60 exercícios, 4–6 programas, 150–250 alimentos, 12–20 receitas, 12 fichas e 15–25 atividades. **São estimativas históricas de trabalho, não catálogo existente nem escopo aceito de lançamento.** Recalibrar depois de medir cobertura dos requisitos e esforço por item.

Primeiro resolver dependências que mudam a promessa: programas prontos em contextos distintos; planeamento alimentar além de dados nutricionais; instruções visuais; registro por sensores/imagem e integração com acompanhamento. Para cada modalidade priorizada, seguir um programa inteiro até ao histórico; não avaliar só uma tela ou um movimento.

## Bateria portuguesa para escolher as bases alimentares

Antes da integração, selecionar a correspondência correta de cada caso e registrar ID, versão, preparo, base, porção e lacunas. A lista abaixo é um protocolo de avaliação proposto, ainda não executado integralmente:

| Grupo | Casos de pesquisa |
|---|---|
| Cereais e tubérculos | Arroz carolino cru e cozido; aveia em flocos; pão de mistura; pão integral; batata cozida; massa cozida; broa de milho |
| Proteína e laticínios | Bacalhau demolhado/cozido; sardinha em azeite escorrida; atum ao natural escorrido; peito de frango sem pele; ovo cozido; leite meio-gordo; iogurte natural sem açúcar; queijo fresco |
| Leguminosas e vegetais | Grão-de-bico cozido; feijão encarnado cozido; lentilhas cozidas; tomate cru; couve; brócolos cozidos; cenoura crua; alface |
| Fruta e gorduras | Banana sem casca; maçã com casca; laranja sem casca; pera; morangos; azeite; amêndoas; nozes |
| Preparações e produtos | Sopa de legumes; caldo verde; arroz de marisco; uma refeição caseira de receita própria; bebida vegetal; produto sem lactose; produto embalado identificado por código; prato de restaurante sem ficha técnica |

Proposta de aceite: nenhum erro crítico cru/cozido, espécie, escorrido ou peso comestível; no máximo cinco casos sem correspondência adequada entre os 40, todos com alternativa explícita. Essa meta é decisão de produto sugerida, não propriedade comprovada dos fornecedores. Confirmar os resultados de um conjunto de 30 códigos de barras reais separadamente, cobrindo marcas e lojas usadas pelo público.

Quando não houver equivalente adequado, o aplicativo deve permitir entrada manual ou indicar indisponibilidade. Não escolher automaticamente outro alimento porque o nome parece semelhante. Não prometer estimativa precisa de prato de restaurante sem informação suficiente.

## Pautas didáticas e acompanhamento

Preparar conteúdo em duas profundidades, simples e técnica, com a mesma informação: como ler treino/série/descanso; escolher equipamento; entender progressão/retorno; como executar e observar uma demonstração; como pesar; cru/cozido; porção e receita; rótulo; ingredientes/alergénios; estimativas; como interpretar evolução e dados incompletos.

Mostrar ajuda junto à tarefa, com imagem/exemplo acessível, fonte e revisão. O dashboard pessoal deve responder “o que tenho hoje?”, “o que consegui fazer?”, “como estou a evoluir?” e “o que falta registar ou ajustar?”. Deve permitir detalhe técnico e personalização, sem culpabilizar dias incompletos ou transformar comida em dívida de exercício.

## Consequência para o desenho futuro

A especificação está em [ajustes da visão integrada no Figma](../design/ajustes-visao-integrada.md). Representar programas/guias, montagem livre, diferentes unidades por modalidade, alimentação planeada e consumida, aprendizagem visual, captura assistida com confirmação, integração sem duplicados e acompanhamento pessoal.

A foto privada permanece alternativa útil, mas **não substitui o requisito de reconhecimento assistido**. Não desenhar precisão ou cobertura universal que a pesquisa ainda não sustentou. Figma e código não foram alterados nesta revisão.
