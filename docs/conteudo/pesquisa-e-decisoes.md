# Pesquisa de conteúdo e decisões

Registro consolidado das consultas de **09/09 a 21/10/2026**. As pesquisas posteriores delimitadas de fornecedores estão em [opções de APIs/mídias](opcoes-apis-exercicios.md) e [MoveKit](avaliacao-movekit-2026-10-29.md). Esta organização não refez chamadas, conferiu condições comerciais atuais nem aprovou conteúdo para prática.

A [linha do tempo](../historico/README.md) explica a sequência completa. Para localizar a origem, consultar [fontes.json](fontes.json), o [catálogo legível gerado](catalogo-fontes.md), o [acervo de evidências](evidencias/README.md) e a [memória documental](../historico/README.md). O catálogo final contém 331 fontes/famílias, não 331 APIs ou fornecedores homologados.

<a id="triagem-inicial"></a>
## Triagem inicial — 09/09/2026

A pergunta inicial foi como substituir geração de treino por conteúdo humano verificável, com custo controlado. A pesquisa separou biblioteca de movimentos, programa com sequência/dose/progressão e composição nutricional. Nenhuma fonte demonstrou resolver sozinha os três problemas.

| Fonte investigada | Achado e consequência registrados |
|---|---|
| [wger](https://wger.readthedocs.io/en/stable/api/api.html) | Recursos públicos de exercícios e licenças por objeto; rotinas pessoais exigiam autenticação. Código AGPL e dados/mídias não receberam uma licença única. Candidato ao catálogo, sem prova de programas humanos completos. |
| [free-exercise-db](https://github.com/yuhonas/free-exercise-db) | JSON com instruções/imagens e Unlicense declarada, derivado de [wrkout](https://github.com/wrkout/exercises.json). A declaração do repositório não encerrou a cadeia de direitos da mídia. |
| [ExerciseDB/AscendAPI](https://exercisedb.dev/) e [ExerciseDB.io](https://exercisedb.io/terms) | Produtos/domínios/versões distintos, com condições próprias. Plano, limite e licença de um não foram transferidos ao outro. |
| [DAREBEE](https://darebee.com/terms-of-use.html) | Condições examinadas impediam incorporar os materiais em apps/produtos; ficou fora do caminho comercial gratuito. |
| [USDA FoodData Central](https://fdc.nal.usda.gov/api-guide/) | Dados de composição como candidato aberto; API com chave e downloads. Cobertura portuguesa, identidade e unidades exigiam análise. |
| [Open Food Facts](https://github.com/openfoodfacts/openfoodfacts-server/blob/main/docs/api/index.md) | Produtos embalados, licença de base e imagens separadas; qualidade, limites e obrigações de base derivada a conferir. |
| [PortFIR/INSA](https://portfir.insa.min-saude.pt/pt/) | Interesse pela composição portuguesa; download público não demonstrou licença comercial nem API disponível. |

Não houve assinatura, cadastro de chave, contato com fornecedor ou integração por essa triagem. Preços/quotas daquele período não são recomendações comerciais atuais.

<a id="amostras"></a>
## Amostras, pilotos e erros encontrados

Em **22/09/2026**, os manifestos em `docs/planejamento/evidencias/` registraram URL, instante UTC, resultado e hash quando o corpo foi recebido. O resumo analisou 25 exercícios wger, 25 do dataset alternativo e 15 alimentos USDA. O dataset alternativo continha 876 registros; sua revisão consultada foi `79ca7b47d77cd5a6dd7a50440e9f0bf24da6a142`, de 29/08/2026. A coleta usou `main`, e o hash do corpo identifica os bytes recebidos; não houve segundo download fixado no commit para comparação.

Os arquivos `wger-25.json` e `wger-languages.json` permanecem insumos locais da preparação editorial. A resposta de idiomas era paginada; português aparecia com ID 7, sem representar um censo completo. Os resultados USDA vieram de buscas por relevância e não constituíam amostra representativa de alimentos portugueses. Open Food Facts retornou HTTP 503 sem produtos, tanto na tentativa v3.6 como na v2. Arquivos `*.sandbox-denied.json` indicam bloqueio da rede local, não indisponibilidade do fornecedor.

O [manifesto](../planejamento/evidencias/manifesto.json), o [resumo](../planejamento/evidencias/resumo-amostras.json) e os scripts de coleta/análise preservam a metodologia. Respostas integrais de fornecedores são somente locais quando assim indicado; um clone limpo não pode reconstruir tudo sem obter legitimamente os mesmos insumos. Não apagar falhas antigas para forçar nova tentativa nem trocar silenciosamente a versão da entrada.

| Exemplo de investigação | O que foi efetivamente encontrado | Decisão/limite |
|---|---|---|
| Tradução wger do movimento 1022 | Versões linguísticas descreviam movimentos incompatíveis. | Não escolher uma tradução por conveniência nem liberar a instrução sem revisar a variante. |
| Mídias e créditos wger | Objeto de movimento, tradução, imagem e vídeo tinham metadados próprios; a preparação identificou quatro imagens sinalizadas como IA e outros bloqueios. | Não herdar licença/aprovação do exercício para a mídia; ausência de flag não prova autoria humana. |
| Pilotos NHS em 26/09 | Corrida com 27 sessões conferidas contra HTML/PDF; força com sete movimentos/20 passos, sem periodização integral. | Completude documental não foi confundida com adequação clínica ou publicação. |
| PR06/Better Health em 30/09 | Termos específicos encontrados no material contradiziam a conclusão ampla baseada na OGL geral. | O item passou a condicional; a conclusão antiga foi corrigida sem apagar a coleta. |
| Growing Stronger/CDC-Tufts | Metadados indicavam domínio público, enquanto o PDF informava copyright Tufts e condições de modificação. | Adaptação/tradução comercial permaneceu condicional. |
| Ciqual/CoFID | Bases de quantidade, marcadores e identidades exigiam preservação por fonte; CoFID repetia o código 13-669 em duas linhas distintas. | Não fundir linhas nem converter desconhecido em zero para completar o banco. |

<a id="complementos"></a>
## Complementos e mudança dos critérios

As rodadas de **03–07/10** ampliaram a análise por públicos e ambientes. Não se exigiu que toda modalidade viesse de uma API nem que todas as opções formassem um treino único. Artigo, protocolo, manual e qualificação podiam complementar a mesma ficha quando família/versão/variante correspondiam; isso não autorizava inventar sessão com doses de fontes diferentes.

Em **07/10**, o autor explicitou autoria profissional verificável, fundamento para o público/contexto e instrução clara para todos os exercícios futuros e anteriores. Foram aceitos caminho autônomo e caminho com orientação, conforme a fonte. Local literal deixou de ser filtro isolado: registrar ambiente estudado e proposto e verificar espaço, equipamentos, tempo, preparo e apoio. Caber em casa não demonstra eficácia estudada em casa e não permite mudar dose ou remover supervisão. [Contrato documental preservado](criterios-exercicios-apk.json).

Os estados intermediários de N15-C e da fila mudaram ao longo das rodadas. Eles estão nos registros datados e na memória documental; não são uma nova fila ativa. O fechamento final de 21/10 prevalece para interpretar o balanço de pesquisa, enquanto a aprovação por uso continua separada.

<a id="cuidadores"></a>
## Cuidadores: fichas, seleção e limites

Em **12/10**, foram consolidadas cinco fichas independentes CG01–CG05, com 90 campos/localizadores, 14 leituras e 28 recibos primários selecionados conferidos. Fechar a ficha factual não aprovou publicação. O catálogo indexava 19 componentes e três fases de Pilates; essas contagens não eram exercícios executáveis liberados.

| Ficha | Fonte/população e resultado documental | Limite preservado |
|---|---|---|
| CG01 / PR42 | Autoalongamento estático no recorte de profissionais de reabilitação que cuidavam de crianças. | Caminho profissional; PNF e seus tempos não foram transferidos à seleção estática. |
| CG02 / PR61 | Método Benson no estudo de cuidadores familiares de pessoas em hemodiálise. | Ensino/apoio e material didático fiel/legal; o CD original não foi recebido nem substituto aprovado. |
| CG03 / PR115 | Oito roteiros originais do contexto START para cuidadores familiares de pessoas com demência. | O resultado pertence ao programa inteiro; exige materiais, líder treinado e supervisão correspondentes. Imaginação guiada não virou caminhada física. |
| CG04 / PR68 | ReViEEW: nove movimentos/27 variantes para trabalhadores formais do cuidado a idosos. | Variantes, fisioterapeuta, cointervenção e limites permanecem vinculados ao protocolo; fotos não viraram guia narrado inventado. |
| CG05 / PR136 | Pilates para cuidador principal de criança com deficiência, com fases/listas e dose documentadas. | Divergências de calendário/tabela e transições permaneceram abertas; três fases não se tornaram três exercícios completos. |

A [fonte estruturada](catalogo-cuidadores.json) liga os campos a leituras por `alias#/json/pointer`, DOI/versão/localizador e recibos com URL, data, bytes e SHA-256. A [fila](fila-cuidadores.json) conserva decisões e mudanças da seleção. Para consulta documental, sem criar treino ou alterar o catálogo:

```powershell
python docs/conteudo/consultar-cuidadores.py --item CG-01
python docs/conteudo/consultar-cuidadores.py --item CG-03
```

O fechamento modular de **21/10** selecionou 11 componentes: um alongamento estático CG01/PR42, oito variantes nível 1 de ReViEEW CG04/PR68 com apoio profissional e duas práticas escritas CaregiversFIRST CG06/PR261. Benson, START, Pilates e variantes não selecionadas conservaram suas lacunas. Não foram declarados cinco programas originais integrais, circuito novo ou eficácia independente herdada por componente.

<a id="idosos-e-cuidadores"></a>
## Idosos e cuidadores

Atividade do próprio cuidador, atividade do paciente e eventual acompanhamento de terceiros continuam distintas. Um estudo com cuidadores de crianças não foi generalizado automaticamente para cuidadores de idosos, nem um programa do paciente foi reclassificado como exercício do cuidador.

Os cinco movimentos domésticos **ES2019-DOM-01/PR28** para idosos ficaram separados da seleção N15-C. Na academia, N18–N20 fecharam pesquisa modular de nove componentes e percursos humanos nos limites registrados; variantes de máquina e imagens não correspondentes permaneceram diferenciadas. N21 reuniu nove componentes textuais para praça, sem promover componentes ambíguos ou ciclos não replicados a execução fechada. Ensino, segurança, revisão, suporte e direitos de publicação continuaram gates.

<a id="cobertura-e-lacunas"></a>
## Cobertura e lacunas — fechamento N01–N46

O fechamento de **21/10/2026** registrou **40 pesquisas concluídas nos recortes e seis reusos documentados**, sem N ativa ou pausada. O índice histórico tinha **840 tentativas GET, 694 HTTP 200 e 780 hashes de corpos locais conferidos**. Tentativa, sucesso HTTP, corpo retido, família e conteúdo aprovado são medidas diferentes.

| Temas | Resultado de pesquisa | O que não foi demonstrado |
|---|---|---|
| N01–N14: identidade, composição, porções, produtos/rótulos, receitas, educação e modelos alimentares | Reuso ou pesquisa por recorte, unidades/ausentes e limites por população. | Dieta individual automática, metas clínicas ou foto que mede quantidade. |
| N15–N21: casa, apoios, instrução, academia e praça | Componentes e percursos humanos documentados; seleção modular e variantes identificadas. | Programa universal, liberação de prática ou guia autônomo quando a fonte exige profissional. |
| N22–N31: caminhada, corrida, ciclismo, natação, yoga, Pilates, mobilidade, equilíbrio, circuito e remo | Recortes de programas/componentes específicos. N23, por exemplo, preservou percurso de 25 sessões/9 semanas para público elegível. | Cobertura integral de modalidade, curso de iniciação de cada esporte ou transposição de dose entre públicos. |
| N32–N38: dor/limitações, artrose, seleção/progressão, estimativas, GPS e plataformas | Mapas documentais de limites, método, permissões, origem e disponibilidade. | Diagnóstico, triagem clínica validada, precisão GPS de campo, integração Health Connect/HealthKit pronta. |
| N39–N46: alimentos/quantidade por foto, OCR, código, atividade por imagem, acompanhamento, pt-PT/acessibilidade e manutenção/custo | Viabilidade e contratos de sugestão/confirmação, proveniência e operação. | Reconhecimento português automático validado, gramas por foto, repetições/carga/gasto por imagem, teste de compreensão com pessoas ou plano financeiro validado. |

O registro completo por N está em `2026-10-15/consolidacao-n01-n46.json`, atualizado com o fechamento modular; as decisões finais N15 estão em `2026-10-21/n15c-composicao/`. Esses caminhos são consultáveis no [acervo](evidencias/README.md). A [integração](evidencias-para-integracao.md) parte da triagem editorial, não da suposição de que toda pesquisa encerrada é conteúdo publicável.

<a id="befit-e-rea"></a>
## BeFit e REA — investigação datada de 14/10

O autor buscou entender origem de conteúdo e comportamentos de um aplicativo de referência para ganhar tempo na pesquisa. Os guias e handoffs BeFit registraram ferramentas, ambiente e observações daquela análise. Eles não demonstraram licença para copiar mídia, programas ou traduções, nem autorizaram atribuir fonte externa sem prova.

As instruções antigas de emulador/REA e os relatos completos estão na memória documental. Não são procedimento operacional vigente: caminhos, ferramentas e estado do aparelho podem ter mudado. Para operar o TrainForge, usar o [guia local atual](../aprendizado/operacao-local.md). Uma referência funcional pode informar uma implementação própria; não transfere código, direitos, conteúdo ou evidência clínica.
