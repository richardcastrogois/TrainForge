# N43 — atividade por imagem/vídeo

**Pesquisa concluída no recorte de pose auxiliar; classificação de exercício, contador e gasto não demonstrados.** [Contrato](contrato-atividade.json), [auditoria](auditoria-fechamento.json), [fontes](fontes-e-evidencias.json).

[ViTPose++small](https://huggingface.co/usyd-community/vitpose-plus-small), de Xu e colaboradores/conversores creditados, foi executado emCPUcomrevisão/hash fixados e entrada específica. Uma foto pública factualNASAe preto sintético passaram pelo estimador top-down com caixa manual, sem detector automático. Saíram17heatmaps, dos quais só12pontos não faciais foram retidos. [Resultado](resultado-pose-local.json). Não há referência anatômica independente e scores deheatmappodem exceder1; não são probabilidades calibradas. Não atribuímosAP81.1genéricodo cartão ao modelo small ou aos idosos.

O estimador fornece pontos, não nome/variante de exercício, repetições, tempo, carga ou gasto. Esses campos ficaram desconhecidos. [VideoMAE](https://huggingface.co/MCG-NJU/videomae-base-finetuned-kinetics) é classificação temporal distinta, comCCBYNCdeclarada e não selecionada para produto. [MediaPipe](https://developers.google.com/edge/mediapipe/solutions/vision/pose_landmarker) é outra referência de33pontos, não instalada ou transferida como capacidade testada.

A [fotoNASA](https://www.nasa.gov/image-article/exercising-t2-treadmill/) mostra exercício emT2comarnês. Uso somente factual/não promocional sob [diretrizes](https://www.nasa.gov/nasa-brand-center/images-and-media/), sem publicação no app ou endosso; não chamar toda mídiaNASAdepublicdomain. Microgravidade não equivale a máquina interna ou praça. A foto foi apagada após o teste.

Os quatro contextos preservam variante/apoio/máquina, consentimento e pessoa. Gesto de cuidar não é automaticamente dose. Foto/pose não aprova técnica nem mede capacidade clínica. Implementação móvel, sequências autorizadas, pessoas reais egroundtruthcontinuam pendentes. App/Figma/banco inalterados.

[Limpeza](limpeza-ensaio.json): ambiente/pesos/foto/cache removidos,1.304.473.808bytes;pipcheckpassou. As26dependências aprovadas foram reutilizadas por versão/hash, comSciPynecessário ao processamento; nenhumCUDA, serviço pago, conta ou mudança global.
