# Pesquisa Complementar E Autorizacao De Downloads - 05/10/2026

## Regra Atual

O usuario autorizou baixar o suplemento REACT neste site e retirar o teto de tamanho de PDFs durante a pesquisa. O limite antigo era uma protecao do nosso coletor, nao do fornecedor, da licenca ou da qualidade da fonte.

- PDF explicito: `Accept: application/pdf`, extensao `pdf`, `maxBytes: null`; gravacao em blocos de 1 MiB e SHA-256 incremental. Valores antigos `maxBytes` nos manifestos nao restringem novos PDFs. Recibos historicos/cache sao preservados.
- Novas coletas de PDF nesta etapa devem usar `coletar-nichos-off.py`; os coletores historicos de pilotos/expansao conservam limites antigos e nao devem ser reutilizados para novos PDFs.
- Sem teto de bytes nao significa armazenamento infinito: falhas de disco/rede continuam registradas. TLS permanece verificado, timeout de 25s por operacao bloqueante, sem retry automatico. Nao e timeout total de download.
- Outros formatos continuam limitados a 2 MiB. Excecao autorizada: suplemento REACT `Table_1.DOCX` no link publicado pelo PMC, ate 16 MiB. Nao autorizacao geral para ZIPs, videos ou executar conteudo.
- Corpos de erros/barreiras nao comprovam arquivo recebido. Novo coletor registra assinatura de formato; divergencia com tamanho conhecido mantem corpo/hash para auditoria, sem aprovacao.
- DOCX verdadeiro exigira inventario ZIP e limites de expansao/membros antes de ler XML/imagens. Nesta rodada nao houve DOCX nem extracao; nenhum desafio, macro ou codigo remoto executado.

Auditoria local de descartes antigos por tamanho: dois HTTP200 eram ZIPs acima de 2 MiB (`c15-ela-autocuidado-anexos`, `i18-pact-plano-anexo`); nenhum PDF HTTP200 descartado apenas por teto foi encontrado nos recibos. LifeAge retornou406 e o coletor anterior descartou corpo divergente; nao e PDF valido perdido pelo teto.

## Retornos E Fontes

Nove novas chamadas nesta rodada: cinco HTTP200, tres500 vazios e uma406 sem corpo salvo. Oito hashes novos incluem os tres vazios e a pagina de verificacao, nao oito documentos de pesquisa. Quatro corpos utilizaveis: metadados LifeAge, REACT HTML/XML e revisao de cuidadores XML.

Indice acumulado reproduzido: **329 chamadas / 273 HTTP200 / 289 hashes**. Catalogo: **127 familias** (24 candidatas,38 condicionais,14 incompativeis,51 referencias). Contagens incluem falhas/barreiras, nao demonstram prontidao do APK.

- PR55/LifeAge: licenca CC BY4.0 encontrada em metadados oficiais recebidos; livro de13.2MB nao recebido (406). Zero paginas/ativos do livro inspecionados.
- PR56/REACT2023: artigo integral e vinculo CC BY4.0 recebidos. Protocolo funcional supervisionado, nao regulagem de maquinas; suplemento autorizado retornou apenas1814bytes de HTML `POW_CHALLENGE`, mesmo com HTTP200. **DOCX nao recebido.** Nao repetir nem contornar barreira.
- PR57/revisao2025: identifica12 estudos de exercicio proprio de cuidadores; nao e manual nem transfere licencas aos estudos. IMPACCT/Otago Plus e rotinas de relaxamento sao pistas para pesquisa primaria, nao pacotes importaveis.

Detalhes: [LifeAge/REACT e proveniencia por campo](leitura-lifeage-react.json), [cuidador/referencias/extent de leitura](triagem-cuidador-2025.json), [manifesto do suplemento autorizado](requisicoes-react-suplemento.json), [recibo da barreira](i18-react-suplemento-docx.evidencia.json). Corpos em `../raw/` ficam locais e ignorados pelo Git; um clone nao permite conferir esses hashes sem os corpos.

## Uso Futuro No APK

Consultar `docs/conteudo/consultar-fontes.py --id PR56`, seguir `localEvidence` e vincular campo/variante ao recibo original, hash, DOI/autores/edicao e secao/tabela/figura. Os localizadores desta rodada descrevem metodos/limites; nao inventam instrucoes do suplemento. Traducao, calculo e decisao editorial devem ser diferenciados do original. Licenca do artigo nao aprova automaticamente imagens/terceiros nem a indicacao clinica.

Nenhum pacote novo, ativo visual ou mapeamento operacional aprovado. ES2019-DOM-01 permanece limitado aos cinco movimentos ja documentados, sem mudanca de hash. Pesquisa assistida por IA nao significa treino criado por IA; a afirmacao comercial deve corresponder aos programas humanos efetivamente selecionados.

**N18-I ativo/parcial; N15-C, N19-I e N20-I pendentes/parciais.** Permanecem abertos C15-G03/G04, I18-G03, I19-G03 e I20-G02/G03. N21 nao iniciada. Nenhum app/Figma/API/banco/commit/push neste incremento.

## Verificacao

Suite documental: **28 testes passaram**, incluindo PDF acima do teto antigo, cache sem retry, formato HTML nao DOCX e corpo divergente preservado. Quinze fichas revalidadas; fila20Ns conferida com N21false. Pacote ES2019-DOM-01 preserva SHA-256 `39ee2f7304123c223254ac7879c430421df4180304bae5a01ed1462c23df19ee`. Quatro hashes citados nos novos documentos foram confrontados com os recibos e corpos; HTML do suplemento confirmado como desafio, nao ZIP/DOCX.

Graphify incremental de `lib/ --code-only --no-cluster`: **0 alterados,42 inalterados,0 removidos**, saidas preservadas. Nao indexacao semantica dos documentos de pesquisa. Essas verificacoes nao sao testes do APK, exame clinico/legal ou aprovacao de publicacao; nao usar HTTP200 como criterio de fechamento.
