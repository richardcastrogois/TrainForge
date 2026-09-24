# Base de conteúdo do TrainForge

**Visão revista em 24/09/2026; pesquisa ampliada entregue em 23/09/2026.** Reabre e aprofunda o estudo de 22/09 a pedido do autor. Esta pasta é a entrada atual para decidir conteúdo; a [primeira rodada](../planejamento/etapa-01-pesquisa.md) e suas amostras continuam preservadas. O produto, o Figma e o banco não foram alterados.

**Escopo atual:** guia integrado de treino, movimento, alimentação e acompanhamento, do iniciante ao experiente. [Visão R01–R18](../planejamento/README.md), [cobertura](cobertura-e-prioridades.md) e [balanço da etapa 01](../planejamento/etapa-01-pesquisa.md). Dores/cirurgias são contextos adicionais, não foco principal. Programas prontos são necessários; plano próprio é complementar. Não pressupor parceria, orçamento de conteúdo ou criação manual dos treinos pelo autor.

## O que muda com esta pesquisa

Há conteúdo gratuito aproveitável, mas a oferta precisa ser composta por camadas: **exercícios**, **programas completos**, **composição de alimentos**, **receitas/educação** e **métricas de atividade**. Uma API com milhares de exercícios não fornece automaticamente programas seguros; uma tabela nutricional não fornece dietas.

A recomendação agora é avaliar uma **base própria, selecionada e versionada**, abastecida por fontes com permissão adequada. O app não precisa consultar várias APIs durante cada treino ou abrir uma dependência por fornecedor. Importação local pode reduzir requisições e permitir offline quando a licença autorizar. Esta é direção proposta para a arquitetura futura, não implementação feita.

| Necessidade | Direção após a expansão | Condição decisiva |
|---|---|---|
| Exercícios de musculação | Subconjunto wger revisto; mídia aprovada separadamente | Foram encontradas traduções divergentes no mesmo ID; importação automática não é aceitável como homologação |
| Programas humanos completos | Priorizar programas humanos existentes elegíveis, importação conferida em lote e direitos específicos; NHS é caminho parcial, não solução universal | A pesquisa ainda não comprovou catálogo completo por modalidade em pt-PT, com revisão humana adequada e direitos comerciais claros |
| Alimentos genéricos | **Ciqual como candidato europeu prioritário**, USDA/CoFID como complementos; comparar antes de escolher | Cobertura e correspondências portuguesas precisam de teste; não juntar bases indiscriminadamente |
| Alimentos portugueses | PortFIR como prioridade de autorização e adequação local | Licença comercial de incorporação ainda não confirmada |
| Produtos embalados | Open Food Facts, condicionado à amostra portuguesa e cumprimento da ODbL | A consulta anterior retornou 503; cobertura não foi medida |
| Receitas | Pequeno lote textual NHLBI condicionado à política de adaptação; DGS/PNPAS como referência e possível acordo | Fotos, tradução, publicidade e revisão culinária/nutricional precisam de tratamento próprio |
| Educação e hábitos | Textos elegíveis NIA/NHS; revisão apoiada em ACSM, DGS, OMS e EFSA | Separar permissão para reutilizar texto de validade da recomendação para cada população |
| Corrida, caminhada e outras atividades | Compêndio 2024 para valores de referência e classificação | Não transformar estimativa de gasto em medição individual ou autorização de treino |

As permissões, evidências e fontes primárias de cada linha estão no [catálogo comparativo](catalogo-fontes.md). A classificação **candidato** confirma um caminho documental de reutilização; não significa conteúdo já pronto para os utilizadores.

## Ler na ordem

1. [Catálogo de fontes](catalogo-fontes.md): fontes úteis, condicionais e incompatíveis com custo zero comercial.
2. [Amostras e achados](amostras-e-achados.md): o que foi realmente recebido e os problemas encontrados.
3. [Cobertura e prioridades](cobertura-e-prioridades.md): oferta por modalidade, nutrição, educação e contexto, sem ordem de lançamento pressuposta.
4. [Qualidade e curadoria](qualidade-e-curadoria.md): requisitos para aprovar um item, corrigir erros e preservar autoria.
5. [Direitos e acordos pendentes](direitos-e-acordos.md): condições por tipo de licença e perguntas concretas aos titulares, ainda não enviadas.

Para agentes: consultar [fontes.json](fontes.json) por ID/tema em vez de reler toda a pesquisa. [Evidências locais](evidencias/README.md) incluem os datasets elegíveis recebidos, subconjuntos, hashes e scripts sem dependências externas.

## O que já existe nesta base

- Catálogo estruturado de **43 fontes/famílias**: 10 candidatos, 10 condicionais, 8 incompatíveis com o caminho gratuito comercial e 15 referências; com instituição/autoria, data, forma de acesso, licença, limitações, evidência e próximo passo.
- Dados CoFID 2021 e Ciqual 2025 preservados para avaliação; 27 e 29 registros selecionados por regras explícitas. São amostras, não um seed de produção aprovado.
- Amostra wger ampliada de 25 para 75 exercícios únicos, incluindo um problema semântico concreto.
- Vinte registros originais do Compêndio, distribuídos por cinco categorias; códigos e valores preservados.
- Matriz de conteúdo, critérios de aceite, bateria de avaliação portuguesa e processo editorial proposto.

Não há nesta entrega traduções profissionais aprovadas, contratos assinados, vídeos licenciados para todo o catálogo, prescrição clínica, catálogo de receitas homologado ou autores parceiros contratados. Essa distinção evita apresentar pesquisa como conteúdo publicado.

## Situação da etapa 01

- [x] Pesquisa ampliada e comparação de direitos/qualidade — 23/09/2026.
- [x] Amostras adicionais e evidências reproduzíveis — 23/09/2026.
- [x] Critérios de formação, revisão e manutenção do catálogo — 23/09/2026.
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
