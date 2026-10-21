# N41 — OCR de rótulo e visor

**Pesquisa de contrato concluída; app/Android e equipamento real não testados.** [Contrato](contrato-ocr.json), [fontes](fontes-e-evidencias.json), [auditoria](auditoria-fechamento.json).

Foi reutilizado Windows.Media.Ocr existente, idioma pt-BR. A projeção WinRT não funcionou no PowerShell7; o WindowsPowerShell5.1 já instalado executou3figuras sintéticas próprias. [Saída original](resultado-windows-ocr.json): leu o rótulo de100g/30g,840kJ/200kcal e10,5g; confundiu O0/l1 e omitiu os números de tempo/carga/velocidade. [11verificações do parser](verificacoes-parser.json) mantêm ausentes como desconhecidos, sem corrigir por suposição. Isso não valida OCRdept-PT, visor real, reflexo ou7segmentos.

[MLKitAndroid](https://developers.google.com/ml-kit/vision/text-recognition/v2/android) é candidato específico; o corpo exige minSDK23, embora o resumo automático diga21. Modelos Latin bundled/unbundled e download inicial são diferentes. [Termos](https://developers.google.com/ml-kit/terms) distinguem entrada/saída processadas no dispositivo de métricas e atualizações em rede; não extrair SDK/modelos. Documentação e exemplo não concedem direitos sobre rótulos/mídias de terceiros. Nenhum SDKfoi instalado ou foto enviada.

A documentação de [RUN100](https://support.decathlon.co.uk/run100) demonstra unidadeMI/KMselecionável e contadores acumulados. [LifeFitnessAtmos/SE4](https://support.lifefitness.com/hc/en-us/articles/42862424978583-Life-Fitness-Atmos-Bike-How-to-Use-Constant-or-Adaptive-Power-Workouts-on-Your-SE4-Console) distingue resistência level e potência; peso do usuário não é carga levantada. São modelos específicos vistos em fonte pública, sem operação de máquina ou cópia de programas/visuais.

Casa/academia/praça e cuidador próprio estão separados. Praça pode não ter visor; nenhum campo é inventado para preencher ausência. Confirmar campo, unidade, modo, pessoa e sessão antes de registrar; rótulo100g não é consumo. Testes acessíveis com pessoas e equipamento real continuam pendentes de implementação.

As3imagens temporárias foram apagadas: [limpeza](limpeza-ensaio.json),57.523bytes. O OCRdoWindowspré-existente foi preservado. Sem mudança emapp/Figma/banco, pacote novo, conta ou contato.
