# N15-C: conteudo para a secao Cuidadores

07/10/2026. Pesquisa documentada, ainda nao pacote homologado. N15-C permanece unico foco; N18-I/N19-I/N20-I pendentes, N21 nao iniciada.

## O requisito agora registrado

A secao precisa apresentar exercicios e rotinas humanos pensados para o proprio cuidador em casa. Tempo disponivel e somente uma dimensao. Demanda fisica do cuidado, fadiga, tensao e contexto domestico orientam a busca e a organizacao, mas nao autorizam prometer efeitos clinicos de cada movimento.

Publico, praticante e ambiente sao independentes: cuidar de um idoso nao torna o treino do cuidador um treino do idoso. Cuidadores, idosos em casa, jovens na praca, idosos na praca e idosos em academia precisam de conteudo adequado ao cruzamento. Essa regra fica registrada para as proximas Ns, sem iniciar sua pesquisa aqui.

## Conteudo concreto recebido

[Conteudo documentado](conteudo-documentado.json): 11 registros de pesquisa, tres conjuntos originais e zero sessoes sinteticas ou aprovadas para importacao. Os registros nao sao apenas uma lista de necessidades. Guardam movimento/tecnica, autoria herdada da fonte, pagina/secao/figura, equipamentos, dose publicada, ausentes, contexto de entrega e direitos.

| Fonte humana | Conteudo localizado | Limite para a secao do app |
| --- | --- | --- |
| PR67, Ministerio da Saude, 2008 | Secao7.1: cinco grupos de mobilidade/autocuidado do proprio cuidador | Orientacao educativa sem dose/ciclo completos; restricao comercial expressa |
| PR52, cartilha SEDIS-UFRN2021, na tese2023 | Bastao, ponte, elevacao lateral da perna, prancha, com doses pontuais | Parte da semana2, nao nova sessao de quatro movimentos; acompanhamento e BY-ND preservados |
| PR63, VA, Module1 V3 | Respiracao profunda e relaxamento muscular, duas tecnicas distintas | Relaxamento nao substitui treino fisico; direitos de todos os ativos e aplicabilidade ainda nao demonstrados |

Fontes primarias: [Guia do Ministerio](https://bvsms.saude.gov.br/bvs/publicacoes/guia_pratico_cuidador.pdf), [cartilha na tese UFRN](https://repositorio.ufrn.br/server/api/core/bitstreams/4c936b7f-5e35-46bc-ba99-4d2c0d2d8d91/content), [modulo VA](https://www.caregiver.va.gov/CAREGIVER/pdfs/DailyAttentionDiary/Caregiver_Workbook_V3_Module_1.pdf). [Inventario](inventario.json) registra URL final, recibo, tamanho, SHA-256 e paginas. Uma nova coleta local e dois corpos reutilizados/verificados; nao houve repeticao de falhas anteriores.

O guia tem secao propria para o cuidador, diferente da secao de exercicios da pessoa cuidada. E referencia concreta, nao permissao comercial ou evidencia experimental de eficacia. A fonte UFRN e especifica para cuidadores de ELA e nao pode ser generalizada automaticamente. As duas tecnicas VA nao demonstram que o app trate fadiga ou estresse.

## Conferencia e correcao

14 paginas renderizadas, nove visualmente conferidas neste incremento; o JSON enumera exatamente quais. Isso verifica leitura/figuras, nao seguranca clinica. A ponte manda contar ate cinco: corrigi a anotacao anterior que convertia isso indevidamente em cinco segundos. A respiracao VA tambem usa contagens, nao segundos. Intervalos ausentes nao sao copiados de outro movimento.

## Como aproveitar no APK

Contrato documental, nao importador implementado: `id -> sourceId -> inventario -> recibo -> bodyFile/SHA-256`, com `locator` e `containerId` para rastrear movimento e contexto. Temas sao indexacao editorial, nao objetivos terapeuticos comprovados. Autoria humana da fonte e autoria da sintese documental ficam distintas; pesquisa auxiliada por IA nao transforma os resumos em treinos humanos prontos para publicar.

Os conjuntos originais permanecem separados. Nao montei uma sequencia combinando doses da UFRN, mobilidade do Ministerio e relaxamento VA. O historico, as divergencias e as licencas continuam vinculados aos registros. Antes de publicar uma sessao, sera preciso escolher o programa humano, conferir instrucao/dose/ciclo e entrega, demonstrar direitos por ativo e concluir revisao editorial/de seguranca. Citacao sozinha nao concede direito de adaptacao.

## Estado de fechamento

A lacuna deixou de ter somente analise de publico: ha conteudo especifico rastreavel. Ela ainda nao esta fechada para o APK. C15-G03/G04 continuam falsos por completude operacional, entrega e direitos. A nova fonte nao resolve as restricoes das anteriores, e nenhum desses registros foi promovido a exercicio aprovado. Proximo trabalho segue N15-C buscando um conjunto humano domestico completo e reutilizavel; nao refazer a decisao especifico versus generico nem avancar para N21.

## Verificacao local

47 testes documentais passaram, incluindo seis deste conteudo: fonte/hash, referencias entre registros/conjuntos, localizadores, ausencia de aprovacao, contagens distintas de segundos e nao transferencia de direitos/intervalos. Ficha cumulativa N15-C validada:42corpos e20dependencias. Fila:20Ns, seis reusos, dez fechadas para pesquisa, N15-C ativa e tres pendentes; N21 nao permitida.

Indices regenerados:351chamadas/292HTTP200/309corpos com hash (incluem falhas/barreiras) e137familias, nao137programas aprovados. Graphify incremental em lib/:0alterados/42inalterados/0removidos; nao indexacao semantica destes documentos. Sem diff em lib/test/pubspec; nao testes do APK, validacao clinica/juridica ou mudanca em API/Figma/banco. Validacao de links locais sem erros, apenas avisos heuristicos de placeholder em documentos. `git diff --check` sem erros, avisos de finais de linha preservados.
