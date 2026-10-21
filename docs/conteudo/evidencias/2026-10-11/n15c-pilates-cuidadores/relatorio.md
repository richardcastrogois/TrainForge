# N15-C: Pilates Do Proprio Cuidador

Rodada de 11/10/2026, somente N15-C. [Leitura estruturada](leitura-fontes.json), [inventario](inventario.json) e recibos conservam URL exata, data, corpo/hash, pagina, versao, autoria, dose, resultados, conflitos e direitos. Sete GETs, sete corpos utilizaveis e hashes; tres PDFs/168 paginas, 19 paginas renderizadas e 11 efetivamente visualizadas. PDF sem teto de bytes conforme autorizacao, demais limites preservados.

## Ganhos Documentados

- PR135, [Karakaya/Genc 2024](https://doi.org/10.46413/boneyusbad.1466135): cuidadores de pessoas com esclerose multipla e lombalgia, seis semanas, duas sessoes/semana, cerca de 30 minutos, dois conjuntos de 5-10 repeticoes e 30 segundos entre conjuntos. Pratica em casa inclui ensino, brochura e encontro presencial semanal com fisioterapeuta. Nao excluir o programa por centro; nao remover o acompanhamento. Brochura mencionada ainda nao recebida.
- PR136, [dissertacao original Senturk 2019](https://i-rep.emu.edu.tr/xmlui/handle/11129/5008), relacionada ao [artigo 2021](https://pubmed.ncbi.nlm.nih.gov/33709771/): 55 cuidadores randomizados, 28 Pilates/27 controle sem exercicio; oito semanas, duas sessoes de 45-60 minutos, materiais e cinco elementos de preparo ensinados por fisioterapeuta. Programa foi pensado considerando sedentarismo e falta de tempo do cuidador, nao apenas renomeado de treino geral. Fotografias, aquecimento, encerramento e tabela raster com fases recebidos e vistos; isso corrige a lacuna de falta de programa original, mas nao fornece comandos de todos os movimentos.

## Resultados E Limites

PR135: VAS do grupo acompanhado tem P=0.59 tanto na narrativa como na tabela visual, nao 0.059 nem melhora significativa de todos. Os contrastes entre grupos sao nao significativos; nao demonstram equivalencia, nao inferioridade ou dispensabilidade do fisioterapeuta. Dois tratamentos ativos, nao controle inativo. EDSS/MS54 pertencem aos pacientes, nao aos cuidadores. Elegibilidade, comparador e escala Beck diferem entre registro e artigo; conservar as versoes.

PR136: resultados comparativos proprio cuidador incluem flexibilidade, resistencia de tronco e fadiga; caminhada de seis minutos e enfrentamento nao foram significativos entre grupos. Forca de costas/pernas/preensao nao tem o mesmo resultado comparativo do teste abdominal. Valores impressos P=0.00 sao arredondados, nao probabilidade exatamente zero. Ponte lateral esquerda e calendario de progressao apresentam divergencias entre tabela/narrativa/resumo; nao corrigir ou automatizar silenciosamente. Fotos dos testes nao sao exercicios de treino.

## Recuperacao Para O APK

Seguir PR135/136 -> versao/DOI ou handle -> recibo -> hash do corpo -> pagina PDF/impressa e tabela/figura -> alegacao/campo. O catalogo e a ficha principal apontam para estes documentos. Nao montar novo roteiro por IA a partir dos nomes ou fotos, nem reduzir a dose por cansaco sem fonte. A individualizacao e o apoio profissional originais continuam reais.

CC BY-NC do artigo PR135 e rodape CC BY-NC-ND do site EMU nao sao autorizacao comercial geral dos materiais. O metadado especifico `dc.rights` informa acesso aberto. O `license.txt` de 1.958 bytes, anunciado no HTML estruturado e recebido separadamente, concede direitos de deposito/preservacao/distribuicao a universidade, nao permissao geral comercial de traducao/fotografias ao TrainForge. Fatos/metodos sao distintos de expressao, fotografias, musica e guias. Pesquisa permanece parcial, C15-G03/G04 falsos, nenhum novo pacote/APK liberado. Continuar originais operacionais/licenca especifica e revisar impedimentos reais das fontes anteriores, sem outras Ns ou N21.

Incidente tecnico conservado: Accept JSON isolado foi recusado antes do GET dos registros; o PDF ja recebido nao foi repetido, e os primeiros GETs restantes constam de manifesto separado. Nenhum retry de falha de rede ou acesso foi feito.
