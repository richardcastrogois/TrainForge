# Pesquisa: registrar refeição por voz e por foto, gratuito e no aparelho

Plano em **20/11/2026**; pesquisa documental em **21/11/2026**; **reanálise de compatibilidade em 21/11/2026** com quatro frentes paralelas (produto, voz, texto→alimentos, foto). **Nada foi instalado, medido ou testado em aparelho.** Números vêm das fontes no fim; "não confirmado" marca o que não foi verificado.

## Decisão do autor (21/11): só IA discriminativa

O autor descartou **IA gerativa** (Whisper, Qwen, Gemma, VLMs): o produto só usa modelos que **escolhem entre opções conhecidas** (alimentos do catálogo), nunca que escrevem conteúdo. O reconhecimento de fala é delegado ao motor que já existe no celular (Google/Apple); a parte do TrainForge é discriminativa e devolve itens do banco local.

| Etapa | Decisão | Situação |
|---|---|---|
| Voz → texto | **Motor de fala do sistema** via `speech_to_text` (BSD-3): 0 MB de modelo, nenhum download, só o nosso botão de microfone na tela | **Decidido** — esquema abaixo |
| Texto → alimentos | **Nossa parte discriminativa**: regras + busca no catálogo SQLite + reordenação; mesma para voz, teclado e digitação | Em desenho |
| Foto → alimentos | **Modelo aluno próprio** (MobileNet/EfficientNet int8, ~4–8 MB no APK) destilado do SigLIP 2 no PC; multirrótulo para **mais de 300 alimentos**; mesmo modelo gera a impressão digital para aprender os pratos da pessoa | **Decidido** — esquema abaixo |
| Quantidade | Dita/digitada pela pessoa; porções declaradas do catálogo | Mantido |

### Esquema de voz decidido

```
Toca no 🎤 do app (só o nosso botão, animação "ouvindo")
 ├─ A. Motor offline pt-BR disponível → transcreve no aparelho
 ├─ B. Só motor online → transcreve no servidor Google/Apple (coberto pelos termos)
 └─ C. Sem motor → campo de texto + dica "você também pode ditar pelo 🎤 do teclado"
        ↓
 Texto → nossa parte (regras + catálogo) → 3–5 opções → pessoa confirma
```

- **Verificação na hora do toque:** o app inicializa o motor, confere `pt-BR` nos idiomas disponíveis e se há reconhecimento no aparelho (Android 12+/API 31 com pacote de voz; iOS conforme o sistema). Ordem: **offline primeiro, online como reserva**. A forma exata de consultar o modo offline pelo `speech_to_text` fica para o protótipo.
- **Online sem aviso a cada uso:** o envio do áudio ao Google/Apple no caso B é informado nos **Termos/Política de Privacidade** (nova versão dos documentos legais, com o resumo de mudança já exibido pelo app), não em pergunta a cada gravação. Recomendação a confirmar: opção "somente transcrição no aparelho" nas configurações de privacidade.
- **Caso C sem bloqueio permanente:** o resultado é guardado, mas refeito quando a versão do sistema mudar ou periodicamente; o botão volta sozinho quando o celular passar a ser compatível. Atalho para as configurações de voz do sistema quando houver (não confirmado).
- **Microfone do teclado não pode ser mascarado:** é outro app (IME); não há API para acioná-lo nem escondê-lo. Serve só como dica no caso C.
- **Produto:** `RECORD_AUDIO` e `<queries>` para `RecognitionService` no Android; `NSMicrophoneUsageDescription` e `NSSpeechRecognitionUsageDescription` no iOS. Não exige subir `minSdk` nem o alvo iOS: abaixo do suportado, cai no caso B ou C. Reforço de vocabulário do motor só existe no Android 13+/API 33; a precisão de alimentos vem da nossa parte.
- **Limite aceito:** a qualidade da transcrição varia por aparelho e não é controlada pelo produto; a medição precisa cobrir 2–3 aparelhos e os casos A e B.

### Esquema de foto decidido (22/11)

```
Treino (uma vez, no PC do autor: RTX 3050 6 GB, 32 GB RAM; nada fica rodando depois)
  bases públicas com licença comercial → professor SigLIP 2 marca os alimentos de cada foto
  → revisão por amostra → aluno pequeno treina → prova em fotos nunca vistas
  → .tflite int8 (Android) e Core ML (iOS) → asset do APK com recibo (SHA, origem, licenças)

No celular (sem internet, sem servidor)
  foto → embalado? código de barras
       → aluno responde "tem arroz? tem feijão? ..." (multirrótulo, >300 alimentos)
       → refeições já confirmadas pela pessoa e horário sobem na ordem (impressão digital local)
       → 5 opções do catálogo por alimento (forma pronta no topo) → pessoa confirma e informa a quantidade
       → não reconheceu: refeições frequentes do horário + 🎤 "diga o que tem no prato"
```

- **IA discriminativa:** o aluno só responde sim/não para alimentos de uma lista fechada ligada ao catálogo; o professor (SigLIP 2, Apache 2.0) só roda no PC durante o treino e é descartado. Destilação de conhecimento.
- **Lista:** mais de 300 alimentos (decisão do autor), partindo da lista curada de preparo padrão da voz e ampliada pelas classes das bases públicas; cada rótulo aponta para um item do catálogo.
- **Dados:** **somente bases públicas**, o máximo disponível com licença que permita uso comercial e treino; fotos em `.local`, nunca no repositório nem no APK. Sem fotos próprias nesta etapa.
- **Tamanho:** ~4–8 MB do modelo; motor 0 MB no iOS (Core ML) e 0 MB no Android se usar o LiteRT do Google Play Services, ou alguns MB por ABI se embutido (medir em build de teste; App Bundle resolve). Meta: **+5 a 10 MB**, nenhum download após instalar.
- **Aprendizado pessoal:** impressões digitais das fotos confirmadas ficam só no banco local; a foto em si não precisa ser guardada.
- **Descartados como principal:** cor/textura (sensível à luz), classificador genérico do sistema (rótulos amplos), TinyCLIP (41% zero-shot no ImageNet), SigLIP no celular (55–95 MB).
- **Referência pública:** MobileNetV2 82,1% e EfficientNet-B2 87,5% top-1 no Food-101; pratos brasileiros não medidos. Meta: top-5 ≥ 70% por item.
- **A verificar:** licença dos pesos iniciais (ImageNet), tamanho do motor por ABI, plugin Flutter de inferência.

## Análise anterior (gerativa, descartada em 21/11)

A tabela abaixo registra a primeira recomendação, mantida como evidência. Whisper, Qwen e Gemma ficaram fora por decisão do autor.

| Etapa | Escolha principal | Alternativa | Por quê |
|---|---|---|---|
| Voz → texto | **Whisper small q5_1** via whisper.cpp (`whisper_ggml` 2.10.0, MIT), `lang: 'pt'`, VAD e `initialPrompt` com vocabulário de alimentos. Modelo de **190 MB baixado sob demanda** | **Whisper base q5_1 (59,7 MB)** em aparelho fraco; `speech_to_text` (motor do sistema) só como modo rápido opcional | Melhor WER pt com licença MIT e tamanho viável: small FLEURS 7,3 / Common Voice 9 12,5 contra base 13,0 / 23,7. O motor do sistema não garante offline nem publica WER |
| Texto → itens | **Regras em Dart** + busca FTS do catálogo + reordenação aproximada (`string_similarity` ou `rapidfuzz`, MIT) + fonética Metaphone-PTBR portada (BSD) | Qwen3 0.6B/1.7B (Apache 2.0, ~0,5–1,3 GB) com gramática JSON, **só se as métricas falharem** | Não há evidência de que LLM pequeno supere regras nesse caso; regras são determinísticas, testáveis e não pesam |
| Foto → itens | **SigLIP 2 base p16-224 zero-shot** (Apache 2.0): só a torre de visão em ONNX (**~55 MB q4f16 ou 94,6 MB int8**, sob demanda) contra embeddings de 300–1.500 rótulos canônicos do catálogo, gerados no PC | **Gemma 4 E2B** (Apache 2.0, ~2,6 GB) como modo avançado opcional em aparelho forte | SigLIP B/16 tem 91,6% zero-shot no Food-101; vocabulário fechado no catálogo não inventa itens; roda em aparelho fraco. Gemma lista vários itens, mas é pesado e não tem benchmark de comida |
| Quantidade | Dita/digitada pela pessoa; porções declaradas do catálogo | Tabela de medidas caseiras IBGE POF 2008-2009, **após confirmar a licença** | Foto não mede peso: erro de calorias ~51% só com imagem, ~29% com a massa informada |

Download total sob demanda: ~250–285 MB (voz small + foto) ou ~115–155 MB (voz base + foto). Acréscimo ao APK: só bibliotecas nativas (whisper.cpp e ONNX Runtime, ~15 MB + JNI por ABI na documentação do sherpa/ONNX); medir.

## Restrições do produto (auditoria de 21/11)

- **Regras:** foto e voz só sugerem candidatos editáveis; a pessoa informa a quantidade e confirma ([escopo](../execucao/v1/escopo.md)). Sem APIs de fornecedor no cliente, sem AGPL, sem licença não comercial/pesquisa/desconhecida, sem promessa de prescrição por IA. Áudio e foto processados no aparelho; áudio descartado após a transcrição.
- **APK atual:** 0.5.4+34 com 139.268.925 bytes e 3 ABIs; o catálogo embarcado tem ~40 MB. Não há orçamento numérico; o plano do [APK simples](melhoria-apk-simplificado.md) quer reduzir. Logo, **nenhum modelo vai dentro do APK**; considerar divisão por ABI/App Bundle.
- **Android:** `minSdk = max(flutter, 23)`. `whisper_ggml` exige API 24 → subir o mínimo para 24 ou desativar voz abaixo disso. O modo on-device do `SpeechRecognizer` exige API 31; o pacote `flutter_edge_ai` (Gemma 4) exige API 30 e arm64. Faltam `RECORD_AUDIO` e, se usar o motor do sistema, `<queries>` para `RecognitionService`. R8 está ativo: bibliotecas nativas novas precisam de regras de keep.
- **iOS:** alvo 13.0; `whisper_ggml` exige 15.6 → subir o alvo ou desativar voz abaixo disso. Faltam `NSMicrophoneUsageDescription` e, se usar o motor do sistema, `NSSpeechRecognitionUsageDescription`.
- **Catálogo:** FTS4 com tokenizador `simple`, busca por prefixo em `search_name` sem acento. Porções em `portions_json` só em g/ml (rótulos USDA como "2 cup", OFF só com g/ml explícito) e **sem medidas caseiras em português**. Quantidade = porção declarada × contagem ([portion_quantity.dart](../../lib/features/nutrition/domain/portion_quantity.dart)). FTS5 com trigram depende da versão do SQLite do aparelho; testar `sqlite_version()` antes de migrar.
- **Licenças no app:** a página de licenças usa a coleta automática do Flutter; pesos de modelo (Whisper MIT, SigLIP Apache 2.0) precisam de entrada manual no `LicenseRegistry` e em `THIRD_PARTY_NOTICES.md`.

## Voz: candidatos verificados

| # | Opção | Licença código/pesos | Tamanho | WER pt | Situação |
|---|---|---|---|---|---|
| 1 | Whisper small (whisper.cpp) | MIT/MIT | q5_1 190 MB; q8_0 264 MB | FLEURS 7,3; CV9 12,5; MLS 13,0 | Descartado (gerativo) |
| 2 | Whisper base | MIT/MIT | q5_1 59,7 MB | FLEURS 13,0; CV9 23,7 | Descartado (gerativo) |
| 3 | `speech_to_text` 7.5.0 (BSD-3) | motor Google/Apple | 0 MB | não publicado | **Escolhido**; offline depende do aparelho; reforço de vocabulário só API 33+ |
| 4 | Parakeet TDT 0.6B v3 (sherpa-onnx) | Apache 2.0/CC BY 4.0 | int8 ~640 MB | FLEURS 4,76; MLS 7,50 | Treinado em português europeu; pesado; avaliar depois |
| 5 | wav2vec2-xlsr-53-pt | Apache/Apache | ~300M parâmetros | CV 11,3 (9,0 com LM) | Sem integração pronta |
| 6 | Vosk small-pt 0.3 | Apache | 31 MB | CV 32,6; CORAA 68,9 | Descartado |

Descartados por licença: FastConformer pt da NVIDIA (CC BY-NC), Vosk FalaBrasil (GPLv3), Moonshine (sem português; não-inglês não comercial). Ajustes pt de Whisper medium (Apache 2.0, WER 6,6–8,1) existem, mas são maiores que o small; conversão para GGML não verificada.

## Texto → alimentos: desenho decidido (22/11)

Mesma camada para voz, ditado do teclado e digitação; só escolhe itens do catálogo local (discriminativa) e nunca grava sem confirmação. Exemplo: *"comi duzentos gramas de arroz com feijão e um ovo frito no almoço"* → almoço/hoje; `200 g arroz`, `? feijão`, `1 unidade ovo frito`.

1. **Normalizar:** minúsculas, sem acento para comparar, números por extenso → dígitos (um/uma, dois/duas, meio/meia, "uma e meia", "meia dúzia").
2. **Extrair por regras:** refeição (café da manhã, almoço, lanche, jantar, ceia), dia (hoje, ontem, dia da semana), quantidade e unidade, inclusive medidas caseiras no singular/plural casadas com porções declaradas; sem correspondência, a quantidade fica vazia para a pessoa preencher.
3. **Segmentar** por vírgula, " e ", " com ", " mais ", testando antes a leitura composta ("arroz com feijão", "café com leite") contra o catálogo.
4. **Gerar candidatos:** a busca atual exige todas as palavras (`AND`) e ordena alfabeticamente ([local_food_repository.dart](../../lib/features/food_reference/data/local_food_repository.dart)); para voz, usar FTS com **qualquer** palavra (`OR`) + sinônimos versionados ("aipim" = "mandioca") + semelhança de escrita (`string_similarity`/`rapidfuzz`, MIT) e fonética (Metaphone-PTBR portado, BSD) para tolerar erros de transcrição.
5. **Ordenar (núcleo discriminativo):** nota por candidato somando cobertura de palavras, fonte brasileira (TACO) antes de USDA/OFF, **preparo padrão**, **histórico da pessoa** e semelhança escrita/fonética. Pesos manuais no início; depois regressão logística treinada no PC com correções consentidas (poucos KB no APK).
6. **Mostrar 5 opções por item** com kcal/macros calculadas para a quantidade; a primeira vem marcada só quando a nota dela se destaca claramente.
7. **Aprender no aparelho:** correções da pessoa viram preferência local, que sobe a opção escolhida na próxima vez.

Decisões do autor (22/11):

- **Histórico pessoal:** sim, alimentos já registrados pela pessoa sobem na ordenação.
- **Preparo padrão:** sem preparo dito, a forma **pronta para consumo** fica no topo (ex.: "arroz" → arroz cozido) e as demais variações aparecem abaixo (integral, parboilizado, cru...). "Cru" só vai ao topo quando a pessoa disser. Exige lista curada de ~100 alimentos comuns com o item padrão do catálogo.
- **Quantidade de opções:** 5 por item.

Fontes de medidas caseiras: **IBGE POF 2008-2009 "Tabela de Medidas Referidas"** tem medidas → gramas, mas a licença de reuso não foi confirmada (pedir confirmação ao IBGE antes de distribuir). Tabela de Pinheiro et al. é livro com direitos reservados: **não incorporar**. Evitar `fuzzywuzzy` (licença ambígua, menção a GPLv2).

## Foto: candidatos verificados

| # | Modelo | Licença | Tamanho | Evidência | Situação |
|---|---|---|---|---|---|
| 1 | SigLIP 2 base p16-224 (ou SigLIP B/16) zero-shot | Apache 2.0 | visão 54,6 MB q4f16 / 94,6 MB int8 | SigLIP B/16: 91,6% Food-101 zero-shot; B/16-384: 93,6% | **Professor no PC** (não vai ao app) |
| 2 | Gemma 4 E2B-it | Apache 2.0 | ~2,6 GB `.litertlm` | sem benchmark de comida; 0,7–1,7 GB de RAM num topo de linha | Opcional avançado |
| 3 | Moondream 2 | Apache 2.0 | 2B parâmetros | recall 90,0 com um item, 71,5 com vários | Pesado |
| 4 | Qwen3-VL-2B / SmolVLM2-256M | Apache 2.0 | 2B / 0,3B | não confirmado | Reserva |
| ✗ | MobileCLIP/MobileCLIP2 | pesos "apple-amlr" (pesquisa) | — | — | Proibido comercial |
| ✗ | LFM2-VL | LFM Open License (limite de receita) | — | — | Fora |
| ✗ | Gemma 3n/PaliGemma 2 | Gemma Terms of Use | — | — | Gemma 4 já resolve com Apache 2.0 |
| ✗ | ML Kit Image Labeling base | termos Google | — | rótulos genéricos | Não serve para pratos |

Como o SigLIP funciona no produto: no PC, gerar embeddings de texto para rótulos curtos ("arroz branco", "feijão", "farofa", "frango grelhado"...) com mapeamento rótulo → alimento do catálogo; no app, só a torre de visão gera o vetor da foto e compara com a matriz. Para vários itens no prato, classificar recortes em grade e aceitar rótulos acima de um limiar. Testar rótulos em português e inglês (inglês tende a ser mais forte; não confirmado). Limite: classifica, não detecta; pratos brasileiros sem benchmark publicado.

Evolução: cabeça linear sobre o encoder SigLIP treinada com fotos próprias consentidas + datasets **CC BY 4.0** (MyFood, Zenodo, 9 classes/1.250 imagens; Brazilian food images, Mendeley, 20 classes; Nutrition5k). Evitar UEC-Food (não comercial), FoodSeg103 e Food-101 (imagens sem licença comercial clara).

OCR de rótulo continua recomendado: ML Kit Text Recognition no aparelho + parser próprio → alimento pessoal revisado. Descartados: extrator do Open Food Facts (CC BY-NC-SA) e Nutri-Score YOLO (AGPL).

## Medição de precisão

- **Desenvolvimento:** 50 frases e 30 fotos próprias para iterar.
- **Decisão:** 300–500 frases reais de pessoas diferentes (±5 p.p. a 95% com 400), incluindo idosos, regionalismos e ruído, em 2–3 aparelhos de entrada; 30% para desenvolvimento, teste travado. Áudio fora do repositório e com consentimento.
- **Métricas:** WER da transcrição; F1 de segmentação; acerto exato de quantidade, unidade, refeição e dia; Recall@1/@3/@5 e MRR do alimento; erro em gramas e kcal; taxa de correção manual; latência e memória por aparelho. Na foto: Recall@3/@5 por item.
- **Metas propostas:** Recall@5 ≥ 95% e quantidade dita exata ≥ 90% na voz; top-5 ≥ 70% por item na foto; zero item gravado sem confirmação.

## Ordem de execução

1. Nossa parte texto → alimentos (regras + catálogo + reordenação) + conjunto de 50 frases + testes de unidade (sem aparelho, sem dependência nova).
2. Piloto de voz com `speech_to_text`: verificação dos casos A/B/C em 2–3 aparelhos, revalidação após atualização do sistema, medição de acerto por caso.
3. Permissões, nova versão dos Termos/Política cobrindo o caso B, entradas de licença.
4. Foto: inventário de bases públicas com licença → lista de >300 alimentos → marcação pelo professor → treino e prova do aluno → build de teste medindo o acréscimo no APK.
5. OCR de rótulo e correção do teste EAN.

## Pendências não confirmadas

- Latência/RTF em celular de qualquer candidato; tamanho real das bibliotecas nativas por ABI.
- Plugin Flutter de ONNX Runtime para o SigLIP (escolher e conferir licença/manutenção).
- Licença do IBGE POF para medidas caseiras; desempenho do SigLIP com rótulos em português e pratos brasileiros.
- Status atual de `flutter_gemma` (relatado como descontinuado em favor de `flutter_edge_ai`) e da Prompt API do ML Kit.
- `pt-BR` em `SpeechTranscriber.supportedLocales` no iOS 26.

## Relação com o backlog

- Voz: proposta de **nova história** em EP06/EP07, dependente de V1-025 e V1-045; criar no `backlog.json` quando o autor aprovar escopo e metas.
- Foto: dentro da **V1-042**, sem mudar critérios.

## Fontes

- Precisão por foto: [tese Virginia Tech](https://vtechworks.lib.vt.edu/items/b67c2a61-f283-41ba-9602-9798306b9529), [arXiv 2507.07048](https://arxiv.org/html/2507.07048v1), [Nutrients 2025](https://www.mdpi.com/2072-6643/17/22/3613), [VLMs para avaliação dietética](https://arxiv.org/html/2504.06925v1).
- Voz: [Whisper (tabelas 10, 11, 13)](https://ar5iv.labs.arxiv.org/html/2212.04356), [modelos whisper.cpp](https://huggingface.co/ggerganov/whisper.cpp/tree/main), [whisper_ggml](https://pub.dev/packages/whisper_ggml), [speech_to_text](https://pub.dev/packages/speech_to_text), [SpeechRecognizer](https://developer.android.com/reference/android/speech/SpeechRecognizer), [RecognizerIntent](https://developer.android.com/reference/android/speech/RecognizerIntent), [Parakeet v3](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3), [sherpa-onnx NeMo](https://k2-fsa.github.io/sherpa/onnx/pretrained_models/offline-transducer/nemo-transducer-models.html), [sherpa hotwords](https://k2-fsa.github.io/sherpa/onnx/hotwords/index.html), [sherpa_onnx](https://pub.dev/packages/sherpa_onnx), [build sherpa-onnx Android](https://k2-fsa.github.io/sherpa/onnx/android/build-sherpa-onnx.html), [wav2vec2 pt](https://huggingface.co/jonatasgrosman/wav2vec2-large-xlsr-53-portuguese), [Vosk](https://alphacephei.com/vosk/models), [FastConformer pt](https://huggingface.co/nvidia/stt_pt_fastconformer_hybrid_large_pc), [Moonshine](https://github.com/moonshine-ai/moonshine), [whisper-medium-portuguese](https://huggingface.co/pierreguillou/whisper-medium-portuguese), [whisper-medium-pt-cv17](https://huggingface.co/deepdml/whisper-medium-pt-cv17), [fórum Apple SpeechTranscriber](https://developer.apple.com/forums/thread/802863).
- Texto: [IBGE POF 2008-2009](https://agenciadenoticias.ibge.gov.br/pt/agencia-sala-de-imprensa/14059-asi-pof-2008-2009-mais-de-90-da-populacao-comem-poucas-frutas-legumes-e-verduras.html?lang=pt-BR), [método Rev. Nutr.](https://periodicos.puc-campinas.edu.br/nutricao/article/download/9304/6682/35393), [Pinheiro (BVS)](https://pesquisa.bvsalud.org/portal/resource/en/biblio-927080), [sqlite3 Dart](https://pub.dev/packages/sqlite3), [FTS5](https://sqlite.org/fts5.html), [rapidfuzz](https://pub.dev/packages/rapidfuzz), [string_similarity](https://pub.dev/packages/string_similarity), [fuzzywuzzy score](https://pub.dev/packages/fuzzywuzzy/score), [Metaphone-PTBR](https://sourceforge.net/p/metaphoneptbr), [COCO JMIR 2021](https://jmir.org/2021/12/e26988), [arXiv 2509.13268](https://arxiv.org/abs/2509.13268), [Qwen3 0.6B GGUF](https://huggingface.co/ggml-org/Qwen3-0.6B-GGUF), [Qwen3 1.7B GGUF](https://huggingface.co/ggml-org/Qwen3-1.7B-GGUF), [local_ai_llama_cpp](https://pub.dev/packages/local_ai_llama_cpp), [llamadart](https://pub.dev/packages/llamadart), [Gemma 4 no LiteRT-LM](https://developers.google.com/edge/litert-lm/models/gemma-4).
- Foto: [SigLIP 2 base](https://huggingface.co/google/siglip2-base-patch16-224), [SigLIP 2 ONNX](https://huggingface.co/onnx-community/siglip2-base-patch16-224-ONNX/tree/main/onnx), [resultados OpenCLIP (Food-101)](https://github.com/mlfoundations/open_clip/blob/main/docs/openclip_classification_results.csv), [Gemma 4 E2B-it](https://huggingface.co/google/gemma-4-E2B-it), [Gemma 4 LiteRT-LM](https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm), [Gemma 4 model card](https://ai.google.dev/gemma/docs/core/model_card_4), [flutter_edge_ai](https://pub.dev/packages/flutter_edge_ai), [Moondream 2](https://huggingface.co/vikhyatk/moondream2), [Qwen3-VL-2B](https://huggingface.co/Qwen/Qwen3-VL-2B-Instruct), [SmolVLM2-256M](https://huggingface.co/HuggingFaceTB/SmolVLM2-256M-Video-Instruct), [MobileCLIP2](https://huggingface.co/apple/MobileCLIP2-S0), [LFM2-VL](https://huggingface.co/LiquidAI/LFM2-VL-450M), [licença LFM](https://www.liquid.ai/lfm-license), [ML Kit Image Labeling](https://developers.google.com/ml-kit/vision/image-labeling), [ML Kit Prompt API](https://developers.google.com/ml-kit/genai/prompt/android).
- Dados e licenças: [MyFood (Zenodo)](https://zenodo.org/records/4041488), [Brazilian food images](https://data.mendeley.com/datasets/7n36jtcpv3/2), [Nutrition5k](https://github.com/google-research-datasets/Nutrition5k), [UECFoodPix](https://mm.cs.uec.ac.jp/uecfoodpix/), [FoodSeg103](https://github.com/LARC-CMU-SMU/FoodSeg103-Benchmark-v1), [Food-101](https://huggingface.co/datasets/ethz/food101/blob/main/README.md?code=true), [OFF nutrient extraction](https://openfoodfacts.github.io/robotoff/references/predictions/nutrient-extraction), [OFF Nutri-Score YOLO](https://huggingface.co/openfoodfacts/nutriscore-yolo), [termos da API Gemini](https://ai.google.dev/gemini-api/terms).
