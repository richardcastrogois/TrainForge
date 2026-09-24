# Fontes candidatas — triagem preparatória

**Pesquisa histórica:** a síntese vigente está em [etapa 01](planejamento/etapa-01-pesquisa.md), com a visão ampliada de 24/09 e o balanço do que temos/falta; fontes detalhadas em [conteúdo](conteudo/README.md). As recomendações abaixo não são seleção final ou conteúdo homologado.


**Pesquisa aprofundada em 22/09/2026:** consultar [etapa 1 — resultados e amostras](planejamento/etapa-01-pesquisa.md). A coleta wger/USDA/dataset foi executada; Open Food Facts retornou 503. Este arquivo mantém a triagem histórica de 09/09 e seus bloqueios da época, não o estado atual do Figma ou da pesquisa.

Consulta em 09/09/2026. A fase 2 depende de concluir a correção visual solicitada. Este registro preserva a pesquisa já feita enquanto a importação Figma aguarda permissão da extensão. **Nenhuma fonte está aprovada para integração.** Não houve assinatura, cadastro de chave, importação de dados no produto ou contato com fornecedores.

## Separar os problemas

Uma biblioteca de exercícios fornece movimentos/instruções/mídia. Um programa define sequência, volume, progressão e público. Uma base nutricional fornece composição por quantidade. Não há evidência de que um só fornecedor resolva os três requisitos do TrainForge.

| Fonte | Evidência oficial consultada | Adequação inicial e pendência |
| --- | --- | --- |
| wger | API REST `/api/v2/`; exercícios públicos sem login; rotinas de utilizadores exigem autenticação. Código AGPL; conteúdo com licenças Creative Commons, a conferir por entrada | Candidato ao catálogo de exercícios. A existência de API de rotinas não comprova catálogo público de programas humanos revisados. Verificar licença/autoria da amostra, cobertura pt-PT, limites e mídia. [API](https://wger.readthedocs.io/en/stable/api/api.html), [licenças](https://wger.readthedocs.io/en/stable/) |
| free-exercise-db | Repositório anuncia mais de 800 exercícios em JSON sob Unlicense, com instruções/imagens; deriva de `wrkout/exercises.json` e reconhece campos incompletos e imagens duplicadas | Candidato a dataset local, não API de programas. Auditar a proveniência dos arquivos de mídia e manter versão fixa antes de uso comercial; o anúncio de licença do repositório não prova por si só a cadeia de direitos de cada imagem. [Repositório](https://github.com/yuhonas/free-exercise-db), [origem](https://github.com/wrkout/exercises.json) |
| ExerciseDB / AscendAPI | `exercisedb.dev` apresenta AscendAPI e uma API V1 gratuita sem chave; quickstart de outro produto na RapidAPI anuncia 2.000 chamadas/mês e 200 exercícios no Basic | Produtos/versões distintos: não misturar limite, catálogo ou termos. Ainda faltam direitos comerciais de dados/mídia, cache/offline e condições do endpoint gratuito. [Site](https://exercisedb.dev/), [quickstart](https://docs.ascendapi.com/quickstart/overview) |
| ExerciseDB.io | Produto de dados/mídia adquirido com licença própria e restrições de redistribuição | Não é alternativa comprovadamente gratuita; não confundir com o domínio `.dev` nem com a licença AGPL de um servidor homônimo. [Termos](https://exercisedb.io/terms), [FAQ](https://exercisedb.io/faq) |
| DAREBEE | Termos proíbem incorporar os materiais em apps/produtos, inclusive gratuitos; licença anunciada contém NC e ND | **Descartado para incorporar os programas no app** sob os termos atuais. Ser gratuito para leitura não autoriza distribuição no TrainForge. [Termos do autor](https://darebee.com/terms-of-use.html) |
| USDA FoodData Central | Dados CC0/domínio público; API exige chave, padrão documentado de 1.000 requisições/hora/IP; também oferece downloads CSV/JSON | Candidato forte a alimentos genéricos, com adaptação de nomes e cobertura portuguesa a avaliar. Usar backend para chave. É possível estudar subconjunto local versionado para reduzir chamadas. [API/licença](https://fdc.nal.usda.gov/api-guide/), [downloads](https://fdc.nal.usda.gov/download-datasets/) |
| Open Food Facts | Base ODbL com atribuição/share-alike; exige User-Agent próprio. Documentação consultada indica 15 leituras de produto/min/IP e 10 buscas/min/IP | Candidato a produtos embalados/código de barras. Não usar busca por tecla. Definir separação de fontes e obrigações de base derivada antes de combinar dados; não concluir que diários privados de utilizadores precisam ser publicados. Qualidade/cobertura local e licença de fotos ainda por conferir. [Condições](https://support.openfoodfacts.org/help/en-gb/12-donnees-api/94-y-a-t-il-des-conditions-pour-utiliser-l-api), [limites](https://github.com/openfoodfacts/openfoodfacts-server/blob/main/docs/api/index.md) |
| PortFIR / INSA | Fonte portuguesa de composição, oferece Excel e valores por 100 g de parte edível. Boletim oficial anuncia TCA 7.0/2025, com 1.372 alimentos e 50 compostos/nutrientes | Melhor aderência geográfica a investigar, mas não foi encontrada autorização explícita para redistribuição comercial nas páginas lidas nem contrato de API pública. Consulta/download público não resolve essa licença. [Portal](https://portfir.insa.min-saude.pt/pt/), [boletim oficial](https://portfir.insa.min-saude.pt/wp-content/uploads/2025/12/Info_FIR-numero-2-2025-12.pdf) |

Limites e planos acima são um retrato das páginas consultadas e precisam ser conferidos no momento da integração. O site wger apresentou proteção contra bots ao leitor web; os termos completos de Open Food Facts também não foram renderizados por esse leitor. Foram utilizadas as documentações oficiais acessíveis; esses bloqueios não foram contornados.

## Direção a investigar, não arquitetura aprovada

Para musculação, estudar um catálogo com proveniência rastreável e registo de plano próprio/profissional. Ainda falta uma fonte que atenda simultaneamente a programas completos, autoria humana, licença comercial e custo zero. Não preencher essa lacuna com o builder atual nem gerar treinos com IA e chamá-los de curadoria.

Para alimentação, comparar alimentos genéricos e embalados separadamente. USDA e Open Food Facts podem atender necessidades complementares; PortFIR pode melhorar a cobertura portuguesa se os direitos permitirem. Não fundir bases antes de entender a licença e a normalização. Manter fonte/ID/versão, porção, unidade e data da informação.

Para corrida, registo manual de modalidade, tempo e distância não exige catálogo externo. GPS, mapas, elevação, roteamento e sincronização com dispositivos são problemas distintos a pesquisar apenas conforme o recorte aprovado.

## O que falta para a pesquisa profunda

1. Verificar licença por tipo de conteúdo, incluindo imagens, tradução, armazenamento e redistribuição offline.
2. Inspecionar uma amostra pequena de registros reais: completude, IDs estáveis, unidades, português, autoria e última atualização.
3. Avaliar programas completos adicionais e possibilidades de autorização de autores, sem enviar mensagens sem autorização específica.
4. Comparar custo operacional de API versus subconjunto local, dependência de fornecedor, rate limits e falhas.
5. Documentar recomendação final e alternativas; levar decisões de integração para a arquitetura da fase 3.
