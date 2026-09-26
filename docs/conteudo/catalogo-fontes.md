# Catálogo comparativo de fontes

Gerado de [fontes.json](fontes.json) em 2026-09-26. 45 fontes/famílias; não é uma contagem de APIs nem de fornecedores aprovados. Não editar esta tabela separadamente: atualizar o JSON e executar `consultar-fontes.py --gerar-indice`.

Todas as ligações remetem a fontes primárias. Para nível de evidência, amostras, data e próxima ação por fonte, consultar o JSON pelo ID. Rodadas iniciais em 22–23/09; pilotos e atualização de fontes selecionadas em 26/09. A data individual indica o que foi reconferido. Páginas bloqueadas ou apenas indexadas estão identificadas no JSON.

- **candidato**: Permissão gratuita identificada para um escopo de dados/textos; falta curadoria e homologação do subconjunto.
- **condicional**: Direito, procedência, acesso ou condições específicas ainda precisam ser resolvidos.
- **referencia**: Fonte para pesquisa editorial; não autoriza copiar conteúdo para o aplicativo.
- **incompativel_zero**: Termos encontrados não atendem ao uso comercial gratuito pretendido.

## Exercícios e demonstrações

| ID / fonte | Situação | Direitos e operação | Achado |
|---|---|---|---|
| **EX01** · [wger](https://github.com/wger-project/docs/blob/master/docs/api/api.rst) | candidato | Licença por exercício, tradução e mídia; amostra com CC BY-SA 3 e 4. AGPL do código é assunto separado. | 75 exercícios: 6 com português, 37 com imagens, 8 com vídeo; 4 imagens marcadas IA; ID 1022 tem traduções semanticamente divergentes. |
| **EX02** · [free-exercise-db](https://github.com/yuhonas/free-exercise-db) | condicional | Unlicense declarada no repositório; cadeia de direitos das imagens e autoria por item não comprovadas. | Dados simples para uso local, mas a amostra não contém autoria/licença por registro. |
| **EX03** · [ExerciseDB API .dev](https://github.com/ExerciseDB/exercisedb-api) | condicional | AGPL do servidor não comprova licença de toda a mídia. Playground não se apresenta como serviço gratuito de produção. | Fornecedor diferente de exercisedb.io. |
| **EX04** · [ExerciseDB .io](https://exercisedb.io/faq) | incompativel_zero | Uso comercial mediante licença; redistribuição do dataset isolado é restrita. | Pode ser opção futura, mas não satisfaz custo inicial zero. |
| **EX05** · [API Ninjas Exercises](https://api-ninjas.com/tos) | incompativel_zero | Plano gratuito restrito a uso pessoal não comercial e desenvolvimento/teste nos termos consultados. | Não resolve lançamento comercial gratuito. |
| **EX06** · [MuscleWiki API](https://api.musclewiki.com/pricing) | incompativel_zero | Uso comercial incluído nos planos pagos; armazenamento permanente/cache longo de mídia proibido nos termos. | Vídeos podem melhorar demonstração, mas criam custo e dependência de transmissão. |
| **EX07** · [ExRx Exercise Library](https://exrx.net/Notes/Legal) | referencia | Termos oficiais indexados direcionam apps a licenciamento de conteúdo; gratuidade comercial não confirmada. | Útil para investigação técnica, não é fonte aberta demonstrada. |

## Programas humanos e modalidades

| ID / fonte | Situação | Direitos e operação | Achado |
|---|---|---|---|
| **PR01** · [DAREBEE](https://darebee.com/terms-of-use.html) | incompativel_zero | NC/ND e termos específicos impedem incorporar o material em apps, mesmo gratuitos, sem acordo. | Grande oferta visual não equivale a catálogo redistribuível. |
| **PR02** · [Boostcamp](https://www.boostcamp.app/terms-conditions) | incompativel_zero | Acesso pessoal não comercial não concede redistribuição dos programas. | Autoria visível é útil como padrão editorial, mas não transfere direitos. |
| **PR03** · [Liftosaur](https://www.liftosaur.com/terms.html) | condicional | Software, API da conta e direitos dos planos são camadas distintas; licença aberta comercial de cada plano não demonstrada. | API disponível não prova biblioteca editorial licenciada. |
| **PR04** · [The Fitness Wiki](https://thefitness.wiki/) | referencia | Licença comercial uniforme dos programas vinculados não localizada nesta revisão. | Curadoria comunitária e programas externos; não comprova revisão clínica ou direitos dos autores vinculados. |
| **PR05** · [NHS exercícios de força, sentados, equilíbrio e flexibilidade](https://www.nhs.uk/live-well/exercise/strength-exercises/) | candidato | Texto elegível sob OGL com condições NHS. Tradução é adaptação; atribuição específica e exceções de mídia devem ser respeitadas. | Piloto local: sete exercícios de força na sequência original, 20 passos instrucionais na fonte; quantidades conferidas. Rotina introdutória, não programa periodizado de academia. Sem publicação aprovada. |
| **PR06** · [NHS Couch to 5K](https://www.nhs.uk/better-health/get-active/get-running-with-couch-to-5k/) | candidato | Texto elegível sob OGL e termos NHS, com regras de adaptação/tradução, atribuição e data/atualização. Não inclui áudio, app, logos, imagens ou vídeos. | Piloto local de 27 sessões / 12 padrões; totais do HTML e intervalos de ambas as páginas do PDF conferidos. Objetivo temporal final: 30 minutos correndo, não garantia de 5 km. Não publicado no app. |
| **PR07** · [Swim England — Swimming Fitness Training Plan](https://www.swimming.org/members/swimming-fitness-training-plan/) | referencia | Licença de incorporação comercial não identificada. | Exemplo humano de sessões estruturadas de natação; é de 2017 e precisa de revisão de atualidade. |
| **PR08** · [British Cycling — Sofa to 50 km](https://cloud.britishcycling.org.uk/knowledge/article/izn20151216-Beginner-8-week-Sofa-to-50km-Training-Plan-0) | referencia | Permissão comercial para copiar/adaptar não confirmada. | Pode orientar os campos de sessão de ciclismo; material antigo, não homologado. |
| **PR09** · [FIFA Training Centre — manuais de futsal e futebol de praia](https://www.fifatrainingcentre.com/en/environment/resources/beach-soccer/beach-soccer-manual.php) | referencia | Acesso público; licença comercial de incorporação não identificada. | Conteúdo de treino técnico/coletivo não equivale a um plano individual de academia. |
| **PR10** · [Skadefri / Get Set — fichas de exercícios](https://www.skadefri.no/globalassets/documents/exercise-programs/body-parts/hamstrings/hamstrings_no.pdf) | referencia | Licença comercial para incorporar fichas/mídia não confirmada. | Material de prevenção de lesões com contexto específico; não deve virar tratamento automatizado. |
| **PR11** · [Growing Stronger — Tufts/CDC](https://stacks.cdc.gov/view/cdc/11447) | condicional | Metadados CDC dizem Public Domain, mas o PDF declara copyright Tufts 2002, créditos de terceiros e distribuição sem modificar o conteúdo. Não confirma direito de traduzir/adaptar para o app comercial. | Programa humano encontrado, mas a divergência jurídica impede tratá-lo como base livremente adaptável; não homologado. |
| **PR12** · [Competitive Edge — programa investigado em adultos](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2024.1439431/full) | referencia | Artigo sob CC BY 4.0 com atribuição e indicação de alterações; materiais externos citados exigem conferência própria. | 16 semanas, 2–3 sessões/semana, 43 adultos e supervisão profissional. Não foram obtidas todas as sessões/doses/progressões; não demonstra uso autónomo geral por aplicativo. |

## Ciência, educação e triagem

| ID / fonte | Situação | Direitos e operação | Achado |
|---|---|---|---|
| **CI01** · [ACSM — Resistance Training Position Stand 2026](https://acsm.org/resistance-training-guidelines-update-2026/) | referencia | Leitura gratuita anunciada não concede automaticamente licença de republicação de artigo/infográfico. | Atualização para adultos saudáveis; síntese de 137 revisões. Base editorial mais atual que o position stand de 2009. |
| **CI02** · [OMS — atividade física e sedentarismo 2020](https://www.who.int/publications/i/item/9789240015128) | referencia | Publicações abertas em CC BY-NC-SA 3.0 IGO; uso comercial requer verificar permissão específica. | Referência científica, não um catálogo de sessões nem licença para copiar tabelas para app monetizado. |
| **CI03** · [DGS — Programa Nacional para a Promoção da Atividade Física](https://www.dgs.pt/paginas-de-sistema/saude-de-a-a-z/exercicio-fisico.aspx) | referencia | Não foi confirmada licença aberta comercial aplicável a toda a coleção. | Página já anuncia dois novos manuais além da coleção de oito; não congelar inventário antigo. Populações clínicas exigem supervisão própria. |
| **CI04** · [IPDJ — Ser Ativo em Casa e brochuras](https://ipdj.gov.pt/brochuras) | referencia | Não foi identificada licença comercial uniforme; há contribuições de terceiros. | Boa adequação linguística/cultural. Contexto da pandemia e data precisam ser revistos antes de reutilizar recomendações. |
| **CI05** · [NIA — exercício e atividade física](https://www.nia.nih.gov/health/exercise-and-physical-activity/three-types-exercise-can-improve-your-health-and-physical) | candidato | Textos produzidos pelo NIA geralmente em domínio público, salvo indicação diferente; fotos e vídeos precisam de verificação própria. | Artigo atual revisado em 14/01/2025 usa três categorias principais de exercício. Link antigo dizia quatro. |
| **CI07** · [PAR-Q+ / ePARmed-X+](https://eparmedx.com/about/terms-and-conditions/) | incompativel_zero | Incorporação em produto comercial e formulários eletrônicos exige autorização; instrumento não pode ser alterado livremente. | Não é questionário open source que se pode traduzir e automatizar à vontade. |

## Atividades e gasto energético

| ID / fonte | Situação | Direitos e operação | Achado |
|---|---|---|---|
| **CI06** · [Compendium of Physical Activities 2024](https://pacompendium.com/) | candidato | Uso comercial gratuito explicitamente permitido; citar fonte e preservar códigos, descrição e MET, sem combinar atividades com MET diferentes. | Há compêndios adulto, idoso e cadeira de rodas. O adulto abrange 19–59 anos; MET não mede com precisão o gasto de uma pessoa. |

## Composição de alimentos e produtos

| ID / fonte | Situação | Direitos e operação | Achado |
|---|---|---|---|
| **AL01** · [USDA FoodData Central](https://fdc.nal.usda.gov/api-guide/) | candidato | Dados em domínio público/CC0; operação da API tem limites próprios. | 15 resultados de busca e um detalhe avaliados; inglês, relevância variável, porções podem exigir detalhe. |
| **AL02** · [Open Food Facts](https://github.com/openfoodfacts/openfoodfacts-server/blob/main/docs/api/index.md) | condicional | Base ODbL, conteúdo DbCL e imagens CC BY-SA; avaliar obrigação de base derivada e atribuição. | Consultas de 22/09 retornaram 503. Nova consulta v2 limitada a 30 produtos de Portugal em 26/09 também retornou 503; zero produtos recebidos. Não demonstra ausência de cobertura no catálogo. |
| **AL03** · [PortFIR / TCA](https://portfir.insa.min-saude.pt/pt/versoes-e-atualizacoes/) | condicional | Não foi localizada licença comercial aberta nem contrato de API nesta revisão. | Melhor adequação geográfica potencial. Página inglesa ainda descreve v7.0/2025: idioma pode expor versão antiga. |
| **AL04** · [Anses Ciqual 2025](https://doi.org/10.57745/RDMHWY) | candidato | Licence Ouverte Etalab 2.0 identificada no depósito oficial; atribuição e versão necessárias. | N01: 3.484 IDs únicos, nomes FR/EN em todos, 720 nomes científicos e 138 linhas de classificação. Um alimento sem grupo correspondente. Preparo no nome; sem campo PT. Amostra nutricional anterior de 29 linhas não é o catálogo normalizado de produção. |
| **AL05** · [CoFID 2021](https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid) | candidato | Open Government Licence v3.0, observadas exceções declaradas. | 27 linhas selecionadas; números, Tr, N e branco têm sentidos diferentes. Edição 2021 não significa análise nova de cada alimento. Em 26/09, piloto de 12 alimentos conferiu cálculo por massa e semântica de preparo/traço/zero/ausente; não recomenda porções nem valida equivalências portuguesas. |
| **AL06** · [Fineli](https://fineli.fi/fineli/en/avoin-data) | candidato | CC BY 4.0 na página oficial de dados abertos; atribuir THL/Fineli. | Dados em finlandês, sueco e inglês. API de exemplo retornou 403 no ambiente; disponibilidade prática não homologada. |
| **AL07** · [BLS 4.0](https://blsdb.de/download) | candidato | CC BY 4.0 explícita, incluindo apps; atribuir Max Rubner-Institut. | Alternativa europeia aberta adicional; não foi baixada ou avaliada por amostra nesta rodada. |
| **AL08** · [Swiss Food Composition Database 7.1](https://naehrwertdaten.ch/en/downloads/) | candidato | Página de downloads permite uso comercial com atribuição. É permissão específica dos dados, distinta do copyright geral do site. | Fonte complementar; API e cobertura ainda não testadas. |
| **AL09** · [Frida](https://frida.fooddata.dk/pdf/en-frida-5.2-dokumentation.pdf) | condicional | Documento 5.2 permite dados com atribuição; licença e pacote da versão corrente não confirmados. Não assumir CC BY a partir de apps terceiros. | Dados refletem alimentos dinamarqueses; revisão atual e licença exata pendentes. |
| **AL10** · [TBCA](https://www.tbca.net.br/) | incompativel_zero | Registros consultados indicam CC BY-NC-ND 4.0 e vedação comercial; manual de 2025 também restringe uso comercial. | Português brasileiro não resolve licença nem equivalência a alimentos portugueses. |

## Receitas, alimentação e educação

| ID / fonte | Situação | Direitos e operação | Achado |
|---|---|---|---|
| **NU01** · [DGS / PNPAS — receitas](https://alimentacaosaudavel.dgs.pt/receitas/) | referencia | Licença comercial aberta não confirmada para o catálogo; livros da mesma área têm termos restritivos diferentes. | Fonte culturalmente pertinente, com receitas económicas, peixe, leguminosas e vegetais; não é plano alimentar individual. |
| **NU02** · [DGS — manual do cabaz PO APMC](https://alimentacaosaudavel.dgs.pt/wp-content/uploads/2019/12/1517235944ManualdeorientacoesparaautilizacaoadequadadocabazdealimentosdoPOAPMC.pdf) | referencia | Documento veda fins comerciais; autorização específica ao programa não se estende ao TrainForge. | Útil para estudar alimentação acessível, mas não para republicação comercial. |
| **NU03** · [NHLBI — Healthy Eating Recipes](https://www.nhlbi.nih.gov/health/heart-healthy-living/healthy-foods/healthy-eating-recipes) | condicional | Informação geralmente em domínio público salvo exceções; política pede preservar publicações/multimídia e não usar como endosso/publicidade. Fotos e adaptações precisam de análise própria. | Receitas humanas concretas, como peixe com alho-francês; contexto americano e unidades precisam de revisão portuguesa. |
| **NU04** · [NHLBI — DASH](https://www.nhlbi.nih.gov/health/dash-eating-plan) | referencia | Política institucional e exceções por ativo; não equivale a aprovação da dieta do usuário. | Material de referência, não motor automático de prescrição para hipertensão. |
| **NU05** · [EFSA — Dietary Reference Values](https://www.efsa.europa.eu/en/topics/topic/dietary-reference-values) | referencia | Verificar licença de cada publicação/dataset antes de reproduzir; nesta pesquisa usado como referência. | A própria EFSA esclarece que DRVs não são metas nutricionais individuais; populações e tipos de referência importam. |
| **NU06** · [TheMealDB](https://www.themealdb.com/terms_of_use.php) | incompativel_zero | Publicar em app store exige assinatura paga; conteúdo de terceiros tem condições próprias. | O exemplo de API grátis não resolve a licença de lançamento. |
| **NU07** · [USDA MyPlate / receitas SNAP](https://www.myplate.gov/recipes/supplemental-nutrition-assistance-program-snap/2-step-chicken) | condicional | Autoria de receitas e imagens varia; domínio público de FoodData Central não se transfere automaticamente para cada receita MyPlate. | Não foi obtida uma licença específica suficiente para aprovar um lote nesta rodada. |
| **NU08** · [ASAE — rotulagem e alergénios](https://www.asae.gov.pt/perguntas-frequentes1/area-alimentar/rotulagem/rotulagem-ingredientes.aspx) | referencia | Referência regulatória/editorial; licença de republicação integral não verificada. | Ingrediente, alergénio declarado e risco de contaminação cruzada são conceitos distintos; dados ausentes não comprovam ausência de alergénio. |

## Imagens e vídeos

| ID / fonte | Situação | Direitos e operação | Achado |
|---|---|---|---|
| **MI01** · [Wikimedia Commons](https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia) | condicional | Conferir licença, autor, alterações e direitos de imagem por arquivo; não há uma licença única para qualquer mídia do site. | Possível complemento de ilustrações, não revisão biomecânica nem garantia de imagem adequada para ensinar exercício. |
