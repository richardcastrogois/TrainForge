# Retomada: origem do conteudo BeFit e ganho de tempo na pesquisa

Data: 14/10/2026. Documento de passagem para outro chat do TrainForge.
Nao e fechamento da N15, aprovacao de conteudo ou autorizacao de implementacao.

## Pedido mais recente do usuario

O objetivo principal e descobrir de onde o BeFit obtem exercicios, instrucoes,
videos e programas, para buscar diretamente nas mesmas fontes o que servir ao
TrainForge. Nao e copiar a biblioteca do concorrente. O usuario considera que
a pesquisa atual acumulou registros sem entregar conteudo suficiente para o APK.

Separadamente, quer observar os fluxos do aplicativo e compara-los com o nosso
Figma, para identificar necessidades esquecidas e propor uma experiencia propria.
Nao quer um clone. Esclarecimento posterior: REA significa Reverse Engineer
Anything, do repositorio https://github.com/morluto/rea. O usuario quer preparar
seu uso e testar por emulador Android, sem conectar celular. Guia complementar:
[REA e emulador sem celular](guia-rea-emulador-befit-2026-10-14.md).
Essa preparacao nao concede permissao para desmontar ou copiar o BeFit.

## Por que mudar a abordagem

O agente reconheceu que priorizou estudos de beneficios antes de conferir se
existiam materiais completos, ensinaveis e com condicoes de reutilizacao viaveis.
Um artigo sobre eficacia nao necessariamente fornece programa, comandos ou midia.
O ajuste proposto e priorizar pacotes completos candidatos e verificar evidencia,
autoria, adequacao e direitos; nao eliminar essas verificacoes.

O TrainForge precisa de programas humanos existentes e orientacao clara. Nao
pressupor parceria, verba para licenciamento ou tempo do usuario para produzir
centenas de treinos. Nao substituir por IA gerando prescricoes. Biblioteca de
movimentos, programa completo, evidencia clinica e midia licenciada sao coisas
distintas; contar uma delas nao demonstra as demais.

## O que foi verificado no BeFit

Produto correto: app.befit, site appbefit.com, operado pela 3APPS.
Referencia do usuario: https://befit-3apps-llc.en.aptoide.com/app
Nao confundir com outros produtos, repositorios ou estudos chamados BeFit/BE-FIT.

As paginas abaixo foram lidas pela ferramenta web neste chat em 14/10/2026.
Sao declaracoes da empresa, nao auditoria independente das credenciais ou eficacia.
Nao foram baixados corpos locais nem produzidos hashes dessas paginas; os links
nao constituem recibos de coleta local ou concessoes de uso.

| Achado | Fonte | Limite |
| --- | --- | --- |
| Declara desenvolvimento com profissionais e especialistas | https://appbefit.com/about-us/ | Nao identifica origem de cada ativo |
| Apresenta Antonio Brandao e Ednardo Ribeiro; Ednardo e descrito como revisor do algoritmo/conteudo | https://appbefit.com/experts/ | Credenciais declaradas, nao verificadas em registro profissional |
| Declara algoritmo proprietario para personalizacao | https://appbefit.com/ai-personalized-plan/ | Nao sabemos proporcao de programas fixos, algoritmo ou outras formas de producao |
| Strapi gerencia biblioteca e conteudo | https://appbefit.com/privacy-policy/ (secao 4) | CMS, nao fornecedor de exercicios; nao acessar API privada |
| Anuncia videos, instrucoes e opcoes em casa/academia | https://appbefit.com/exercises-library/ e https://appbefit.com/exercises/ | Descricao publica nao substitui teste do APK |
| Termos vedam extracao automatizada, copia e engenharia reversa | https://appbefit.com/terms/ (7.3 e 10.3) | Nao assumir autorizacao para desmontagem ou reaproveitamento |

Buscas publicas e paginas consultadas NAO identificaram fornecedor externo
declarado da biblioteca ou uma base compartilhada que possamos importar.
Isso nao prova que nao exista. Nao afirmar que toda a biblioteca e interna,
que veio de wger/Gym Visual/MuscleWiki ou que pode ser reutilizada gratuitamente.
Alguns perfis de autores/links de categorias retornaram erro: nao sao fontes lidas.

APK nao baixado, instalado, executado ou descompilado; nenhum fluxo runtime testado.
REA nao disponibilizado como ferramenta nesta sessao; nenhuma instalacao feita.
Nenhuma mensagem enviada ao BeFit, nenhum custo assumido e nenhuma conta criada.

## Proximo trabalho: fontes primeiro

1. Fazer investigacao publica direcionada de autoria, creditos de midia e
   fornecedores/licenciadores. Nao repetir a mesma busca ampla sem nova pista.
2. Separar origem de movimentos/textos/videos da origem de programas completos.
   Identificar fornecedor, pacote, autoria, idiomas, licenca, custo e disponibilidade.
3. Se houver fornecedor confirmado, procurar diretamente seu material oficial.
   Se nao houver, registrar "origem externa nao identificada", nao especular.
4. Nesse caso, propor consulta ao contato oficial do BeFit perguntando se o acervo
   e proprio ou licenciado e se ha fornecedor publico. Pedir autorizacao especifica
   antes de enviar: a permissao Gmail anterior era para os estudos de cuidadores,
   nao para contatar concorrentes. Nao pagar ou assumir contrato.
5. Se o conteudo for exclusivo ou a pista ficar dependente de resposta, encerrar
   essa linha com evidencia e encaminhar fornecedores equivalentes, explicitamente
   marcados como alternativas, nao como fontes usadas pelo BeFit.

Entregar uma matriz curta: fonte/fornecedor, evidencia de vinculo com BeFit,
conteudo efetivamente disponivel, o que pode alimentar o APK, autoria, direitos,
custo e pendencia concreta. Nao abrir outra colecao interminavel de artigos.
Nao confundir dados de teste para desenvolvimento com conteudo aprovado para uso.

## Frente separada: fluxos e Figma

Depois de definir o acesso viavel, observar uso normal permitido, telas/gravacoes
fornecidas pelo usuario e documentacao publica. Comecar por escolher programa,
entender exercicio, executar/pausar/retomar sessao e registrar historico.
Separar recurso anunciado de comportamento observado. Nao e preciso presumir
descompilacao para estudar esses fluxos. Nao contornar premium/protecoes, extrair
dados privados ou copiar codigo, textos, ativos e identidade.

Comparar com docs/design/fluxos-v04.md e docs/design/ajustes-visao-integrada.md
antes de usar snapshots antigos. Nao editar Figma/app nesta investigacao sem
pedido especifico. O prototipo nao comprova persistencia, autenticacao ou backend.

## Requisitos preservados

- Exercicios destinados ao proprio cuidador, nao apenas tecnicas de cuidar de outra pessoa.
- Caminhos especificos para idosos e combinacoes de publico/ambiente, inclusive praca.
- BeFit anuncia casa; nao foi demonstrada cobertura especifica de cuidadores,
  idosos em casa ou aparelhos de praca. Nao declarar que ele nao tem essas categorias.
- A fonte nao precisa dizer literalmente "em casa": avaliar espaco, equipamentos,
  tempo, cansaco, preparo e apoio, mantendo movimento, dose e condicoes comprovadas.
- Pode haver caminhos com e sem orientacao profissional, conforme a fonte. Instrucao
  clara no APK nao autoriza remover supervisao ou acompanhamento exigido.
- Registrar autor, titulo, versao/data, URL/DOI, paginas/trechos, conteudo retornado,
  dose, publico, limites, direitos e forma de consulta/integracao. Para novas coletas
  locais, preservar recibos/hash e falhas, sem inventar HTTP200 ou arquivos recebidos.
- Nao misturar programas/doses e atribuir a combinacao a um ensaio que nao a testou.
- Autoria profissional fundamentada nao equivale a validacao clinica de cada programa
  e populacao. Manter afirmacoes proporcionais a evidencia efetivamente disponivel.

## Estado anterior preservado: N15-C

Conferido em AGENTS.md e docs/conteudo/fila-cuidadores.json nesta passagem.
Cinco fichas factuais CG-01 a CG-05 nao significam cinco programas executaveis.
Somente CG-01 atende os dois gates de pesquisa executavel no recorte restrito
profissional. Zero itens publicados/liberados; N15-C parcial e N21 retida.
executionSequence.activeItem = CG-02; oito perguntas de fonte pendentes.

- CG-02/Benson: material didatico legal/fiel, preservando ensino e reforco.
- CG-03/START: manual participante/audio e direitos; componentes vinculados ao programa.
- CG-04/ReViEEW: guias/partes de sessao; tese recebida ainda nao integralmente revisada.
- CG-05/Clinical Pilates: variantes, versao/transicoes e ativos.

Tese EHU recebida: docs/conteudo/evidencias/2026-10-14/raw/TESIS_ESPIN_ELORZA_ANDER.pdf.
9550390 bytes, 275 paginas; SHA256:
3a9441ae09ece4926b33204b86df0b4681c48549cee6589921eb9643b80ce90f.
Receber o PDF nao concede direitos nem fecha CG-04.
Tres pedidos de material/permissao CG-02/03/05 ja enviados via Gmail com autorizacao.
Nenhum grant/resposta registrado na fila; nao confundir com conferenca atual da inbox.
Nao reenviar ou criar monitoramento automatico. Ver o relatorio de acesso autorizado.

Nao avancar automaticamente para N21 nem marcar N01-N20 finalizadas por causa
da mudanca de estrategia. Esta investigacao nao modifica a fila anterior.

## Entrada local minima para o outro chat

Raiz real: C:/dev/TrainForge/trainforge. C:/dev/TrainForge e o diretorio externo.
Ler primeiro este documento e AGENTS.md; depois apenas arquivos pertinentes:

- docs/conteudo/fila-cuidadores.json
- docs/conteudo/evidencias/2026-10-14/n15c-acesso-autorizado/relatorio.md
- docs/conteudo/criterios-exercicios-apk.md
- docs/conteudo/cobertura-e-prioridades.md (contagens historicas, conferir datas)
- docs/design/fluxos-v04.md (somente quando analisar a frente de fluxos)

Ha mudancas locais preexistentes extensas; nao reverter, commitar ou fazer push.
Nao precisa reler todos os PDFs nem repetir coletas para recuperar contexto.
Graphify raiz cobre lib/, nao esta pesquisa. Consulta local encontrou nos de
workout_day_detail.dart; nao reindexar documentos ou referencias antigas.
Esta passagem e seu guia complementar alteram somente documentacao de retomada,
sem alterar corpus Dart, grafo, fila, evidencias, codigo, banco, Figma ou memoria global.
