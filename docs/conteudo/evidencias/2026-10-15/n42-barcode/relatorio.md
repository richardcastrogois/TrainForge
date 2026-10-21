# N42 — código de barras

**Contrato de pesquisa concluído; scanner óptico e integração não testados.** [Contrato](contrato-barcode.json), [fontes](fontes-e-limites.json), [9verificações textuais](verificacoes-gtin.json), [auditoria](auditoria-fechamento.json).

[MLKitBarcodeAndroid](https://developers.google.com/ml-kit/vision/barcode-scanning/android) distingue região potencial de código decodificado; formato e rawValue são fundamentais. Modelo bundled e downloadPlayServices têm pré-requisitos diferentes. Os termos e privacidade N41foram reutilizados; não extraímos modelo nem instalamosSDK.

[GS1](https://www.gs1.org/services/how-calculate-check-digit-manually) explica o dígito de controle; o exemplo publicado passou no verificador textual e dois códigosN04foram reutilizados. GETda página retornou403; fórmula/exemplo têm leitura indexada primária, sem contorno ou novoGET. [FormatoGTIN](https://support.gs1.org/support/solutions/articles/43000734355-what-is-the-required-format-of-gtin-in-gs1-edi-standards-) recebido confirma a diferença entrestring14preenchida comzeros e outros formatos. Não transformarGTINeminteiro ou expandirUPC-Eporzfill.

Captura e lookup de produto são etapas distintas. N04continua fonte para nutrientes/identificador/data/porção; não houve nova chamadaOFFou repetição de503. Checksumválido não comprova autenticidade, produto encontrado, consumo ou alergénios. Barcode/QRsemproduto requer outro fluxo; não abrirURLsautomaticamente.

Casa, academia, praça e cuidador próprio têm confirmação acessível e alternativa manual. Compra/quem escaneia/quem come são papéis separados; quantidade permaneceN40. Não preencher ausentes com0ou atribuir refeição ao assistido. Não foi criado ambiente temporário ou instalado pacote nesta N.
