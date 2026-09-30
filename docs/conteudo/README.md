# Base de conteúdo do TrainForge

**Estado atual — 30/09:** N01–N10 concluídos para pesquisa nos recortes documentados; etapa 01 permanece aberta. N08: oito receitas distintas; N09: cinco guias, 14 exemplos de refeições e seis batidos; N10: quatro guias, oito rascunhos de lições e diário demonstrativo de 13 itens. Verificações: 61 / 59 / 49. Índice acumulado: 147 chamadas / 114 HTTP 200 / 113 hashes; catálogo: 61 fontes/famílias. **Correção: PR06 (Couch to 5K) agora é condicional**, pois os termos específicos Better Health não permitem presumir importação comercial pela OGL geral. Próximo da fila: N11; não iniciado. Retomar pelo dossiê e resumos, sem repetir coletas. Pesquisa não homologa publicação, integração ou adequação individual.

**Foco por decisão do autor:** continuar a etapa 01 em [46 nichos](../planejamento/etapa-01-pesquisa.md#fila-da-etapa-01-por-nicho), um de cada vez. N01: identidades; N02: composição; N03: quantidades/porções; N04: produtos por marca/código; N05: ingredientes/alergénios/proveniência; N06: fotografias e direitos; N07: leitura de rótulos. [Retornos, chamadas e limites](evidencias-para-integracao.md). N08/N09/N10 concluídos para pesquisa; N11 é o próximo da fila. Integração/publicação continuam pendentes.

**Para implementar a partir das evidências:** [retornos, origens e chamadas observadas](evidencias-para-integracao.md). O documento distingue corpo original, envelope do coletor e campos normalizados; liga os exemplos aos arquivos/hashes. O [índice de chamadas](evidencias/retornos-observados.json) permite recuperar a evidência sem consultar novamente os fornecedores.

**Pilotos anteriores, 26/09/2026:** [resultados conferidos](evidencias/2026-09-26/pilotos-resumo.json) com 27 sessões de corrida NHS, sete movimentos de força e cálculo por massa de 12 alimentos CoFID. Catálogo naquela rodada: **45 fontes/famílias**; apenas as fichas datadas de 26/09 foram reconferidas/ampliadas. OFF voltou a responder 503. O autor decidiu continuar a [etapa 01](../planejamento/etapa-01-pesquisa.md) por nichos antes de retomar o design. Os pilotos não são conteúdo homologado no app.

**Visão revista em 24/09/2026; pesquisa ampliada entregue em 23/09/2026.** Reabre e aprofunda o estudo de 22/09 a pedido do autor. Esta pasta é a entrada atual para decidir conteúdo; a [primeira rodada](../planejamento/etapa-01-pesquisa.md) e suas amostras continuam preservadas. O produto, o Figma e o banco não foram alterados.

**Escopo atual:** guia integrado de treino, movimento, alimentação e acompanhamento, do iniciante ao experiente. [Visão R01–R18](../planejamento/README.md), [cobertura](cobertura-e-prioridades.md) e [balanço da etapa 01](../planejamento/etapa-01-pesquisa.md). Dores/cirurgias são contextos adicionais, não foco principal. Programas prontos são necessários; plano próprio é complementar. Não pressupor parceria, orçamento de conteúdo ou criação manual dos treinos pelo autor.

**Inventário de 25/09/2026:** começar pela [lista do que o app entrega, do que fontes/APIs devem fornecer e do que já existe ou falta](cobertura-e-prioridades.md). Contagens e campos confrontados com amostras locais e código; não houve nova coleta nem integração.

## O que muda com esta pesquisa

Há conteúdo gratuito aproveitável, mas a oferta precisa ser composta por camadas: **exercícios**, **programas completos**, **composição de alimentos**, **receitas/educação** e **métricas de atividade**. Uma API com milhares de exercícios não fornece automaticamente programas seguros; uma tabela nutricional não fornece dietas.

A recomendação agora é avaliar uma **base própria, selecionada e versionada**, abastecida por fontes com permissão adequada. O app não precisa consultar várias APIs durante cada treino ou abrir uma dependência por fornecedor. Importação local pode reduzir requisições e permitir offline quando a licença autorizar. Esta é direção proposta para a arquitetura futura, não implementação feita.

| Necessidade | Direção após a expansão | Condição decisiva |
|---|---|---|
| Exercícios de musculação | Subconjunto wger revisto; mídia aprovada separadamente | Foram encontradas traduções divergentes no mesmo ID; importação automática não é aceitável como homologação |
| Programas humanos completos | Priorizar programas humanos existentes elegíveis, importação conferida em lote e direitos específicos; NHS é caminho parcial, não solução universal | A pesquisa ainda não comprovou catálogo completo por modalidade em pt-PT, com revisão humana adequada e direitos comerciais claros |
| Alimentos genéricos | **Ciqual como candidato europeu prioritário**, USDA/CoFID como complementos; comparar antes de escolher | Cobertura e correspondências portuguesas precisam de teste; não juntar bases indiscriminadamente |
| Alimentos portugueses | PortFIR como prioridade de autorização e adequação local | Licença comercial de incorporação ainda não confirmada |
| Produtos embalados | Open Food Facts, condicionado à amostra portuguesa e cumprimento da ODbL | N04 fechado com 24 produtos e quatro marcas; N05 com cinco perfis e 66 verificações. Cobertura ampla, revisão de rótulos e integração ainda pendentes |
| Receitas | N08: oito receitas distintas; MedlinePlus candidato textual, NHLBI condicional; Healthier Families exige licença comercial | Fotos, tradução, publicidade, porções e revisão nutricional precisam de tratamento próprio |
| Educação e hábitos | Textos elegíveis NIA/NHS; revisão apoiada em ACSM, DGS, OMS e EFSA | Separar permissão para reutilizar texto de validade da recomendação para cada população |
| Corrida, caminhada e outras atividades | Compêndio 2024 para valores de referência e classificação | Não transformar estimativa de gasto em medição individual ou autorização de treino |

As permissões, evidências e fontes primárias de cada linha estão no [catálogo comparativo](catalogo-fontes.md). A classificação **candidato** confirma um caminho documental de reutilização; não significa conteúdo já pronto para os utilizadores.

## Ler na ordem

1. [Catálogo de fontes](catalogo-fontes.md): fontes úteis, condicionais e incompatíveis com custo zero comercial.
2. [Amostras e achados](amostras-e-achados.md): o que foi realmente recebido e os problemas encontrados.
3. [Cobertura e prioridades](cobertura-e-prioridades.md): funções e resultados do app, campos esperados das fontes, inventário exato de evidências/código e lacunas; oferta por modalidade e contexto, sem ordem de lançamento pressuposta.
4. [Qualidade e curadoria](qualidade-e-curadoria.md): requisitos para aprovar um item, corrigir erros e preservar autoria.
5. [Direitos e acordos pendentes](direitos-e-acordos.md): condições por tipo de licença e perguntas concretas aos titulares, ainda não enviadas.

Para agentes: consultar [fontes.json](fontes.json) por ID/tema em vez de reler toda a pesquisa. [Evidências locais](evidencias/README.md) incluem os datasets elegíveis recebidos, subconjuntos, hashes e scripts; o analisador N03 usa `pypdf` para conferir o guia local.

## O que já existe nesta base

- Catálogo estruturado de **61 fontes/famílias** em 30/09: 15 candidatos, 12 condicionais, 10 incompatíveis com o caminho gratuito comercial e 24 referências. Contém instituição, data, acesso, licença, limites, evidência e próximo passo. São fontes; a fila de 46 nichos é outro inventário.
- Programa de corrida estruturado como pesquisa (27 sessões) e rotina introdutória de força (sete movimentos), sem publicação aprovada. PR06 agora tem direitos condicionais por termos Better Health; programa geral completo de academia continua em falta.
- Dados CoFID 2021 e Ciqual 2025 preservados para avaliação; 27 e 29 registros selecionados por regras explícitas. São amostras, não um seed de produção aprovado.
- Amostra wger ampliada de 25 para 75 exercícios únicos, incluindo um problema semântico concreto.
- Vinte registros originais do Compêndio, distribuídos por cinco categorias; códigos e valores preservados.
- N08–N10: receitas e guias para ganhar/perder peso, exemplos com origem e políticas específicas; sem prescrição individual ou lote comercial aprovado.
- Matriz de conteúdo, critérios de aceite, bateria de avaliação portuguesa e processo editorial proposto.

Não há nesta entrega traduções profissionais aprovadas, contratos assinados, vídeos licenciados para todo o catálogo, prescrição clínica, catálogo de receitas homologado ou autores parceiros contratados. Essa distinção evita apresentar pesquisa como conteúdo publicado.

## Situação da etapa 01

- [x] Pesquisa ampliada e comparação de direitos/qualidade — 23/09/2026.
- [x] Amostras adicionais e evidências reproduzíveis — 23/09/2026.
- [x] Critérios de formação, revisão e manutenção do catálogo — 23/09/2026.
- [x] Pilotos de corrida/força e porções alimentares, nova verificação de acesso/direitos e caminhos de captura — 26/09/2026.
- [ ] Demonstrar programas humanos por modalidade, alimentação guiada, conteúdo visual e captura por sensores/imagem para a cobertura selecionada.
- [ ] Autor revisar a sequência de entrega, preservando a visão completa.
- [ ] Resolver licenças específicas dos conteúdos escolhidos, especialmente PortFIR/programas/receitas.
- [ ] Homologar cobertura portuguesa e autoria/revisão dos itens que sustentarão as promessas de lançamento.

**A pesquisa desta rodada está concluída; a passagem da etapa 01 para a 02 permanece aberta.** A condição é ter um caminho viável aceito para cada função do lançamento. Não basta marcar a pesquisa como feita e conservar promessas que ainda dependem de conteúdo indisponível. O [plano de execução](../planejamento/plano-de-execucao.md) registra esse estado.

## Continuidade com poucas requisições

```powershell
# Apenas contagens/temas; não usa rede nem modelo de IA.
& 'C:\Users\richa\AppData\Roaming\uv\tools\graphifyy\Scripts\python.exe' 'C:\dev\TrainForge\trainforge\docs\conteudo\consultar-fontes.py'

# Abrir somente a ficha Ciqual ou os candidatos alimentares.
& 'C:\Users\richa\AppData\Roaming\uv\tools\graphifyy\Scripts\python.exe' 'C:\dev\TrainForge\trainforge\docs\conteudo\consultar-fontes.py' --id AL04
& 'C:\Users\richa\AppData\Roaming\uv\tools\graphifyy\Scripts\python.exe' 'C:\dev\TrainForge\trainforge\docs\conteudo\consultar-fontes.py' --tema alimentos --estado candidato
```

O Graphify principal continua indexando `lib/`; não afirmar que ele passou a conter esta pesquisa documental. A consulta local acima supre essa necessidade sem extração semântica paga. Infraestrutura/mapas continuam em [viabilidade operacional](../planejamento/viabilidade-operacional.md); não foram novamente pesquisados em profundidade, pois este incremento prioriza conteúdo.

## Conferência da entrega

Em 23/09/2026, o analisador local reproduziu as amostras e contagens; foram conferidos 43 IDs únicos e os hashes/tamanhos dos 25 arquivos do manifesto. Quinze documentos novos/atualizados passaram no validador documental, sem erros ou links locais quebrados detectados. Os avisos de placeholder foram revistos e correspondem a palavras portuguesas, não a campos esquecidos. Consultas locais por ID e por tema/estado funcionaram sem rede. Esses checks não certificam validade científica, licença de cada ativo ou cobertura portuguesa.

Graphify incremental: **0 alterados, 42 inalterados e 0 removidos** em `lib/`, com saídas preservadas. Não foram executados testes de aplicativo, pois este incremento não alterou código de produto. O [check-in do plano](../planejamento/plano-de-execucao.md) registra pesquisa concluída e condições ainda pendentes para passar à etapa 2.
