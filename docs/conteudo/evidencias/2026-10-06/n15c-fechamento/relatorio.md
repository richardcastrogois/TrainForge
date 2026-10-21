# N15-C: manuais e rastreabilidade - 06/10/2026

## Resultado

Escopo exclusivo: exercicios do **proprio cuidador em casa**, nao movimentos executados para transferir ou exercitar a pessoa assistida. Nenhuma pesquisa nova de N18-I/N19-I/N20-I/N21, nenhum app/API/Figma/banco/commit/push.

**N15-C ainda nao atende aos criterios de fechamento vigentes.** Esta rodada foi lida e registrada integralmente; isso nao significa que um programa executavel foi selecionado. C15-G01/G02 atendidos, C15-G03/G04 nao atendidos. Nao houve fechamento por exaustao de busca ou declaracao de inexistencia.

O impedimento atual nao e o tamanho dos PDFs: o livro de 12.262.747 bytes foi recebido integralmente. Falta um mesmo pacote humano com instrucao/dose/progressao e entrega/direitos compativeis. Nao preencher esses campos combinando outros programas.

## Retornos

Oito chamadas novas do coletor: cinco HTTP200 com corpo utilizavel, seis corpos com bytes/SHA256 conferidos **incluindo um404**, duas falhas TLS sem corpo. Consultas web indexadas nao entram nessa contagem e nao recebem hash de corpo inexistente.

| Fonte | O que foi recebido ou observado | Decisao |
| --- | --- | --- |
| PR62 - Pasqualini/Macht/Ellgring2024 | Pagina da editora e livro integral366paginas. Programa psicoterapeutico para cuidadores, pratica domiciliar e roteiro de relaxamento. | Profissional qualificado mantido, material Tausch de terceiro e erratum nao recebido. Nao pacote autonomo escolhido. |
| PR63 - VA Workbook Module1 | PDF54paginas; caminhada, respiracao e relaxamento muscular proprios do cuidador. Workbook integral retornou404, nao livro. | Dose pontual10s recebida; calendario/progressao muscular e direitos das fotos nao demonstrados. |
| PR64 - eduCAPES2021 | Metadados primarios indexados: video2 e alongamento proprio, video1 e transferencia. TLS local falhou. | MP4 nao recebido/assistido; pergunta sobre excecao de8MiB sem resposta. Nao repetir TLS mesmo com eventual autorizacao de tamanho. |
| PR65 - UFBA/Sampaio2024 | Resumo primario: Pilates por teleatendimento,13cuidadoras. TLS local falhou. | Texto completo marcado Restrito/Embargado ate30/12/2026; cartilha/videos nao recebidos. Nao contornar acesso. |
| PR66 - Ramadia/Ekaputri/Sumandar2023 | Pagina editorial e PDF9paginas. Demonstracao de PMR para40participantes. | Texto menciona14grupos, procedimento enumera12, repeticao3-6 com unidade nao resolvida. Sem ciclo/progressao domiciliar integral. |

Fontes primarias: [editora do livro](https://www.wup.uni-wuerzburg.de/aktuelles/meldungen/single/news/cognitive-behavioral-therapy-for-people-with-parkinsons-disease-and-caregivers/), [modulo VA](https://www.caregiver.va.gov/CAREGIVER/pdfs/DailyAttentionDiary/Caregiver_Workbook_V3_Module_1.pdf), [eduCAPES](https://educapes.capes.gov.br/handle/capes/922438?mode=full), [registro UFBA](https://repositorio.ufba.br/handle/ri/40795), [artigo PMR](https://ejurnalmalahayati.ac.id/index.php/kreativitas/article/view/12524).

## Direitos e instrucao

- Livro: texto principal CC BY-SA4.0, capa CC BY-NC-ND4.0 e terceiros excluidos no expediente. A pratica de consciencia corporal indicada junto ao relaxamento deriva de Tausch1993; concessao especifica nao demonstrada. Nao afirmar que todos os ativos estao liberados.
- VA: fonte institucional nao garante direitos de todas as fotos. Declaracao indexada do workbook integral nao foi verificada no corpo atualV3 e nao e transferida automaticamente.
- PMR: CC BY-SA4.0 do artigo confirmada na pagina editorial recebida. Isso nao entrega o moduloTobing2012/folheto citado, nem resolve as lacunas operacionais.
- Relaxamento muscular progressivo e sequencia de grupos; nao e automaticamente progressao de carga por semanas. Contagem respiratoria10 nao e dose10segundos. Evento09-11 nao e duas horas de exercicio.

## Como recuperar para o APK

[Inventario](inventario.json) liga URL, URL final, horario UTC, bytes, SHA256, recibo e paginas. [Leitura](leitura-manuais.json) separa autoria/versao, dose publicada, ausentes, populacao, ambiente, supervisao e direitos. [Mapa de campos](mapa-apk-campos.json) mostra a cadeia fonte -> corpo -> pagina -> informacao, com exemplos **nao aprovados para execucao** e zero novos programas executaveis aprovados.

Consultar o catalogo por PR62-PR66 com `python docs/conteudo/consultar-fontes.py --id PR62`. Reproduzir hash/ancoras/renderizacao sem rede com `python docs/conteudo/evidencias/analisar-n15c-manuais.py --render`.

22paginas foram renderizadas; **14 efetivamente inspecionadas visualmente**, discriminadas na leitura. Ancora textual e hash nao constituem validacao clinica ou teste de compreensao.

Um futuro treino apresentado como humano precisa conservar a autoria do programa inteiro e suas adaptacoes, nao apenas citar artigos separados. Nenhuma dose faltante foi produzida por IA. Os corpos locais ficam ignorados pelo Git; recibos e analises ficam registrados.

## Decisao de escopo pendente

Pergunta enviada ao autor: exigir programa criado/testado especificamente com cuidadores ou aceitar programa humano geral em casa para cuidadores elegiveis, **rotulado geral**, sem alegar eficacia especifica nesse publico?

Sem resposta, nao alterar C15-G03/G04 ou promover o NHS/qualquer programa geral ao fechamento de N15-C. Aceitar a segunda via permitiria avaliar uma selecao geral ja recebida; nao garante fechamento automatico, seguranca individual ou licenca de todos os ativos.

N15-C e o foco ativo exclusivo. Ficha cumulativa em [retomada N15-C](../../2026-10-04/n15c-retomada/pesquisa-complemento.json). N21 permanece retida.

## Verificacao

- 41testes documentais passaram. Na primeira execucao, um teste ainda removia o focoN18 fixo; corrigido para localizar o foco ativo antes da mutacao. Segunda execucao integral passou.
- Ficha cumulativa N15-C:41corpos de evidencia e17dependencias conferidos por bytes/hash/ancoras. Estado continua parcial; validacao documental nao e criterio de fechamento.
- Fila20Ns conferida: N15-C ativo,6reusos/10Ns fechadas para pesquisa/3pendentes/1ativa; N21false. Nenhum novo fechamento.
- Indice cumulativo regenerado:350chamadas/291HTTP200/308corpos com hash conferido, incluindo erros/desafios. Catalogo136familias:24candidatas/45condicionais/16incompativeis/51referencias; nao136programas aprovados.
- Pacote anterior ES2019-DOM-01 reproduzido, hash39ee2f7304123c223254ac7879c430421df4180304bae5a01ed1462c23df19ee preservado. Nao pacote de cuidadores.
- Graphify estrutural incremental:0alterados/42inalterados/0removidos, saidas preservadas. Nao indexacao semantica destes documentos.
- Seis documentos conferidos sem erros de links locais; avisos heuristicos de placeholder preservados.17JSONs da rodada parseados. Diff sem erros de whitespace, avisos LF/CRLF. Raw06/10 ignorado e nenhum diff em lib/test/pubspec.

Sem testes do APK, testes com pessoas ou homologacao clinica/editorial. Reproducao offline exige os corpos locais; o clone Git sozinho nao inclui os PDFs brutos.
