# História do TrainForge e roteiro de apresentação

Este registro reúne a evolução do problema, da pesquisa e da implementação. As datas pertencem às verificações originais; a consolidação documental de **16–17/11/2026** não representa nova coleta, nova aprovação de conteúdo ou repetição de testes. Para o estado operacional, usar o [handoff](../execucao/v1/handoff.md); para o produto pretendido, a [visão R01–R18](../planejamento/visao-produto.md).

Os documentos anteriores e grafos das referências legadas estão preservados, com seus caminhos originais, em [memória documental](memoria-documental.zip) e [índice](indice.json). A origem é o checkpoint Git `b77cf94`, anterior a esta limpeza. Esse material permite auditar o relato sem manter dezenas de instruções antigas soltas como se fossem vigentes. As evidências de pesquisa têm [acervo e instruções próprios](../conteudo/evidencias/README.md).

## Como apresentar na faculdade

Uma sequência possível é: problema observado → alternativas investigadas → critérios de seleção → achado que mudou a decisão → implementação verificável → limites que continuam abertos. Mostrar uma fonte primária e seu registro de coleta é mais explicativo que uma grande contagem de arquivos.

Para cada exemplo, identificar: **pergunta, data, fonte/URL, resultado recebido, decisão e limite**. Diferenciar o relato do autor, a leitura de código, a coleta documental, o teste automatizado e o aceite humano. Um protótipo ilustra uma jornada; um recibo de SQL ou Android demonstra somente o recorte que declara.

| Marco | Pergunta e fontes | Achado e decisão | Evidência e limite |
|---|---|---|---|
| Origem e evolução anterior à retomada | O relato do autor descreveu a passagem de uma imersão web com geração por IA para um produto móvel. O Git local da API foi consultado em setembro; registrava trabalho de desempenho/ambiente em 13/03/2026, autenticação mobile em 16/03 e geração manual/validação em 22/03. | O Flutter existente tinha trabalho aproveitável. A preocupação com uso cotidiano, custo de tokens e adequação motivou buscar conteúdo humano rastreável. | Guia de retomada original no acervo documental. O HEAD da API observado naquela análise era `523f6d9`; não é certificação do estado atual do repositório externo. |
| 09/09/2026 — diagnóstico e primeira direção visual | Inspeção de Flutter, API Fastify e web anterior; análise estática e referências Figma. | Foram separados produto existente, falhas observadas e proposta futura. A proposta visual inicial não substituiu o app. | [Diagnóstico histórico](#diagnostico-da-base-anterior), [referências legadas](#referencias-legadas) e [decisões de experiência](../planejamento/decisoes-e-viabilidade.md#experiencia-e-figma). Integração autenticada não foi exercitada nessa etapa. |
| 17–24/09/2026 — visão, alternativas e amostras | Como obter exercícios, programas humanos e alimentos com origem e direitos? Foram consultados wger, USDA, Open Food Facts, datasets e instituições; a visão foi ampliada para R01–R18 em 24/09. | Biblioteca de exercícios, programa com progressão e composição nutricional foram tratados como problemas distintos. Público, ambiente, autoria e licença passaram a limitar a seleção. | [Triagem e amostras](../conteudo/pesquisa-e-decisoes.md#triagem-inicial), manifestos de 22/09 e catálogo estruturado de fontes. A primeira publicação no GitHub foi registrada em 24/09; isso não foi lançamento de produto. |
| 26–30/09/2026 — pilotos e correção de direitos | A leitura de HTML/PDF e termos verificou programas reais, dados e condições por ativo. | O piloto Couch to 5K tinha 27 sessões tecnicamente conferidas, mas PR06 foi reclassificado como condicional em 30/09 pelos termos específicos Better Health. CDC/Tufts também apresentou conflito entre metadados e copyright do PDF. | [Pesquisa e decisões](../conteudo/pesquisa-e-decisoes.md#amostras) e [direitos](../conteudo/direitos-e-curadoria.md#direitos). Completude técnica não concedeu permissão comercial. |
| 03–21/10/2026 — públicos, ambientes e N01–N46 | A pesquisa passou por alimentação, programas/modalidades, idosos/cuidadores, captura, sensores, acessibilidade e operação. Fontes e resultados ficaram ligados a recibos, leituras e localizadores. | O fechamento registrou 40 pesquisas concluídas nos recortes e seis reusos documentados, 331 famílias, 840 tentativas GET, 694 HTTP 200 e 780 hashes locais conferidos. N15 terminou com 11 componentes modulares para cuidadores; cinco movimentos domésticos para idosos permaneceram separados. | [Balanço por tema](../conteudo/pesquisa-e-decisoes.md#cobertura-e-lacunas), [catálogo de fontes](../conteudo/fontes.json) e acervo de pesquisa. As contagens não significam programas executáveis, eficácia de componentes isolados ou publicação aprovada. |
| 21/10/2026 — contrato editorial e triagem | O que pode entrar no produto, em qual operação, com qual responsável e versão? A preparação reuniu snapshots e dossiês já obtidos. | Foram triados 512 ativos; o fechamento conservou 73 metadados de consulta e excluiu 439. A revisão parcial de dois textos não se tornou liberação de ensino/prática no fechamento. | [Integração e revisão editorial](../conteudo/evidencias-para-integracao.md#revisao-editorial), manifests em `content/manifests/` e fechamento da etapa 01. Zero programas, instruções, doses ou mídias liberados para prática. |
| 21–23/10/2026 — fundação e primeira integração | Go/PostgreSQL, migrations, importação idempotente, recuperação, identidade Google, sessão e privacidade foram implementados e verificados nos recortes documentados. | A base local passou a oferecer API e dados reais; autenticação teve aceite Android debug. | [Diário de execução](README.md) e recibos das histórias 006–014/019. Restore e testes locais não equivalem a distribuição HTTPS/release ou aceite iOS. |
| 24–28/10/2026 — decisões e jornadas | Auditoria do produto e respostas Q1–Q6 esclareceram treino, cuidador, configuração, fotos, refeições, idiomas, exclusão e offline. | Configuração 047 teve criação humana, edição autorizada e leitura da revisão 2. A capacidade 048 e o trabalho de refeições 045 tiveram verificações próprias. | [Decisões do piloto](../execucao/v1/escopo.md), backlog e recibos. Fluxos alimentares ainda têm aceites pendentes; registro de teste não foi promovido a consumo real. |
| 29–30/10/2026 — operação, qualidade e catálogo | Ensaios de CI, isolamento SQL, imagem, restore, retirada e falha/recuperação acompanharam a primeira extração do catálogo. O autor pediu comparação de arquitetura e avaliação MoveKit. | O catálogo ganhou ownership de dados e contrato próprios. Foram removidos 31 Dart sem referência e 63 arquivos de scaffolds fora de Android/iOS; adicionados guias e diagramas. | [Aprendizado](../aprendizado/README.md), arquitetura, recibos e [avaliação MoveKit](../conteudo/avaliacao-movekit-2026-10-29.md). Não foram extraídos todos os domínios, comprados ativos ou contratada hospedagem. |
| 16/11/2026 — execução própria e Atividade | Implementação própria de sessão com agregado Go, persistência, eventos, idempotência e integração Flutter; comportamentos de outros produtos foram considerados sem incorporar código/rotinas AGPL. | Quatro rotas privadas elevaram a API a 0.10.0/38 operações; testes SQL/HTTP descartáveis, Flutter e verificações documentais passaram no recorte registrado. APK 0.4.7+29 foi gerado e conferido. | [Handoff](../execucao/v1/handoff.md) e recibos de atividade. APK não instalado/publicado; 015/016 mantêm o gate de conteúdo e 017/023 não foram encerradas. Não há fila offline durável ou aceite nativo de treino completo. |
| 16–17/11/2026 — consolidação documental | Como preservar pesquisa e cronologia sem milhares de arquivos soltos? | Guias foram reunidos por finalidade, relatos antigos separados do estado vigente e evidências compactadas com índice de integridade. | Memória documental e acervo de pesquisa. A organização não altera licenças, aprova conteúdo, fecha histórias ou certifica novamente testes históricos. |

<a id="diagnostico-da-base-anterior"></a>
## Diagnóstico da base anterior

Os achados A01–A15 foram registrados em **09/09/2026** por leitura de código/configuração, sem incidente de produção comprovado e sem correção naquela entrega. Referiam-se ao Flutter de então e à API externa do bootcamp. Esta tabela preserva a motivação técnica; não é uma lista de defeitos confirmados na implementação Go atual.

| Achados | Evidência histórica e consequência |
|---|---|
| A01 | Corpos de requisição/resposta e dados de autenticação passavam pelo logger Dio; motivou redação e restrição de logs. |
| A02/A14 | Restrições recebidas não chegavam ao builder, e a chave Gemini continuava obrigatória. Renomear geração como manual não criava curadoria humana. |
| A03/A09/A10 | Sessão concluída de outra semana bloqueava nova execução; métricas só do plano ativo e contagem de streak tinham semântica inadequada. |
| A04/A11 | Migration removia índices parciais; rotação de refresh tinha janela concorrente antes da transação. Exigiam ensaio isolado e invariantes. |
| A05 | Flutter ignorava refresh token e logout não revogava na API. |
| A06 | Identidade `com.example`, assinatura debug, rede e URL loopback não constituíam configuração de distribuição. |
| A07/A08 | Bootstrap descartado e abas sem cache compartilhado produziam recargas; ausência de offline não foi resolvida por trocar a interface. |
| A12/A13 | Limites/locks locais e atualização de perfil antes de gerar plano exigiam revisão de concorrência, proxy e atomicidade. |
| A15 | Não foi localizada suíte de produto nos diretórios analisados; tipagem não verificava autorização, recorrência, offline ou release. |

O diagnóstico também registrou escolhas aproveitáveis: Flutter por features, Dio/secure storage centrais, casos de uso separados, validação de domínio, transações e preservação de planos anteriores. A lentidão relatada pelo autor não teve sua causa integral reproduzida. A arquitetura deve ser julgada pelas decisões e evidências posteriores, não pelas recomendações iniciais deste snapshot.

<a id="referencias-legadas"></a>
## Referências legadas e Graphify

`C:/dev/bootcamp-treinos-api` e `C:/dev/bootcamp-treinos-frontend` explicam a origem do produto. O primeiro foi o backend efetivamente consumido na retomada de setembro; o segundo era a referência web histórica. Isso não os torna dependências operacionais da API Go atual.

Na conferência estrutural de **21/10/2026**, os registros eram: Flutter 42 arquivos/470 nós/607 arestas, Fastify 33/193/495 e web anterior 53/295/422. Flutter e API retornaram ausência de mudanças incrementais; o grafo web foi preservado. Os antigos JSON/HTML/manifestos e o snapshot frontend de 09/09 foram reunidos na memória documental. Esses números não descrevem o grafo atual nem provam comportamento de rede. [Uso atual do Graphify](../graphify.md).

<a id="validacoes-e-limites"></a>
## Validações e limites

Preservar a data, o comando, o ambiente e o escopo de cada recibo. Teste com fixture verifica uma regra naquele cenário; leitura SQL, aceite humano e inspeção nativa têm evidências diferentes. Um teste posterior não transforma retroativamente uma falha de coleta em sucesso.

Os corpos de terceiros, capturas privadas, credenciais, assinatura, bancos e backups locais não são material público para a apresentação. Para demonstrar rastreabilidade, usar fonte/ID/versão, status da coleta, hash e localizador; só exibir material cuja reprodução esteja permitida. A sanitização histórica autorizada em 29/10 preservou árvore/autores/mensagens/datas segundo o recibo, mas alterou IDs de commits: links antigos precisam dessa contextualização.

Para uma demonstração curta, escolher três casos já documentados: a divergência de tradução wger 1022; a correção de licença PR06; e a diferença entre seleção modular de cuidadores e programa completo. Finalizar com o que está implementado e o que continua bloqueado, consultando o handoff vigente no dia da apresentação.


## 17/11/2026 — consolidação documental

Guias atuais reunidos por público, arquitetura com diagramas,100anotações pessoais movidas para aprendizado e fontes preservadas emZIPs com índice/SHA. Documentos originais continuam auditáveis sem milhares de arquivos soltos. SENAS,42SVG/7JSON de design e84recibos de execução mantiveram bytes;49histórias conservaram critérios e status. [Registro e mapa de caminhos](reorganizacao-2026-11-17.json). A limpeza não é uma nova validação do produto ou uma aprovação de conteúdo.


## 17/11/2026 — o CI revelou diferenças de ambiente

Depois dos commits b77cf94 e2d0c960, a validação remota encontrou problemas ausentes no cache local aquecido. O [job de documentação](https://github.com/richardcastrogois/TrainForge/actions/runs/44093324109) identificou que a varredura do Swagger de catálogo capturava o novo módulo privado; a correção restringe as fontes públicas sem afrouxar o guard. Os [jobsSQL](https://github.com/richardcastrogois/TrainForge/actions/runs/44093324046) e [catálogo](https://github.com/richardcastrogois/TrainForge/actions/runs/44093324088) mostraram que mensagens `go: downloading` em stderr eram misturadas ao JSON: a reprodução com cache descartável confirmou stdout válido, stderr de download e exit 0. Separar streams conserva a prova de teste estrita e os detalhes privados.

O [check de vulnerabilidades](https://github.com/richardcastrogois/TrainForge/actions/runs/44093324013) apontou a biblioteca padrão Go 1.27.3. A [base oficial Go](https://pkg.go.dev/vuln/GO-2026-6859) informa correção em 1.27.4 para a corrida de headers com MaxBytesReader no HTTP/1. O SDK Windows foi obtido do [catálogo oficial de downloads](https://go.dev/dl/) e verificado por SHA256; a imagem Docker usa o digest do registro oficial. O SDK antigo ficou preservado. Não foram alterados endpoints, dados ou regras de treino/alimentação. A validação posterior passou: 167 testes Python, Go/testes/vet, Swagger principal e catálogo, e zero vulnerabilidades alcançadas no scanner. Os sete workflows do commit `08d5774` terminaram aprovados; os IDs e limites estão no [registro da reorganização](reorganizacao-2026-11-17.json).
