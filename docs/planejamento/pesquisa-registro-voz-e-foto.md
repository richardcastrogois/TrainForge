# Pesquisa: registrar refeição por voz e por foto, sem custo de tokens

Registrada em **20/11/2026** a pedido do autor. É uma **pesquisa planejada**: nada abaixo foi testado, medido ou instalado. As ferramentas citadas são candidatas a avaliar; versões, licenças e qualidade em português precisam ser conferidas nas fontes oficiais antes de qualquer decisão.

## Objetivo

Registrar uma refeição falando, como em "comi hoje arroz, feijão e batata", ou fotografando o prato. O processamento deve ser gratuito, de código aberto e de preferência no próprio celular, sem LLM paga nem cobrança por token. Os valores nutricionais vêm do catálogo próprio que o app já tem: SQLite com FTS4, pacote Brasil com 57.326 alimentos.

## Restrições do produto que a pesquisa precisa respeitar

- **A pessoa confirma antes de gravar.** Pela decisão Q2 e pelas regras do [escopo](../execucao/v1/escopo.md), foto e voz **sugerem** candidatos editáveis. A pessoa informa ou confirma a quantidade e salva. O pedido de "enviar automaticamente" vira **preencher automaticamente a tela de registro**: o envio ao servidor continua sendo o fluxo atual, com fila offline e sincronização (V1-025/V1-026).
- Quantidade não dita fica **desconhecida**. O app não inventa uma porção padrão em silêncio: pode sugerir uma porção declarada no catálogo, marcada como sugestão.
- Não incorporar código AGPL, como o Ultralytics YOLO, nem modelos ou datasets com licença só de pesquisa ou desconhecida.
- Áudio e foto são dados pessoais. Processar no aparelho. Nada sai para terceiros sem consentimento explícito. O áudio é descartado depois da transcrição, a menos que a pessoa escolha guardá-lo.

## Parte A: voz → texto → alimentos → refeição

### A1. Transcrição (voz para texto) em pt-BR

| Candidato | Onde roda | O que medir |
|---|---|---|
| Reconhecimento nativo do Android (`SpeechRecognizer`, modo offline com pacote de idioma), via plugin Flutter `speech_to_text` | No aparelho, sem custo | Funciona offline em pt-BR nos celulares-alvo? Depende dos serviços Google? Comportamento no iOS (Speech framework) |
| Vosk (modelo pequeno pt) | No aparelho | Tamanho do modelo, acerto em nomes de alimentos, integração Flutter (plugin ou FFI) |
| whisper.cpp (modelos tiny/base/small) | No aparelho ou num PC/servidor próprio | Latência em Android de entrada, tamanho (dezenas a centenas de MB), acerto em pt-BR |
| sherpa-onnx (modelos Whisper/Zipformer) | No aparelho | Existe pacote Flutter? Desempenho e tamanho |

Critérios: taxa de acerto em frases reais de refeição, gravadas pelo autor e pela piloto, com consentimento. Também latência, aumento do APK, funcionamento sem internet, licença do código **e** do modelo, e acessibilidade para idosos (fala mais lenta, sotaque, ruído).

Hipótese inicial a confirmar: o reconhecimento nativo é o mais leve, porque não aumenta o APK. Um modelo embutido (Vosk ou Whisper) só entra se o nativo falhar offline ou em qualidade.

### A2. Extração de alimentos e quantidades (sem LLM)

Regras locais em Dart, testáveis por unidade:

1. **Normalização**: minúsculas, remoção de acentos só para comparação e de expressões de enchimento ("comi hoje", "no almoço", "também").
2. **Refeição e data**: palavras-chave ("café da manhã", "almoço", "jantar", "lanche", "ontem", "hoje"). Na falta delas, usar a hora atual como sugestão.
3. **Divisão em itens**: separar por vírgula, " e ", " com ", " mais ", com cuidado para não quebrar nomes compostos ("arroz e feijão" pode ser um prato do catálogo). Testar as duas leituras contra o catálogo.
4. **Quantidade e unidade**: números escritos e falados ("duas", "meia", "100 gramas", "uma colher de sopa", "um prato", "uma concha"), com um léxico de unidades caseiras mapeado para as porções declaradas no catálogo.
5. **Correspondência com o catálogo**: busca FTS4 que já existe, mais similaridade aproximada (trigramas ou Levenshtein) para erros de transcrição. Priorizar genéricos (TACO) em termos simples como "arroz" e "feijão", e mostrar os 3 a 5 melhores candidatos.
6. **Sinônimos regionais**: tabela versionada ("macaxeira/aipim/mandioca", "jerimum/abóbora"), cultivada com as correções que as pessoas fazem.

A pesquisa compara essa abordagem de regras com NLP leve de código aberto (spaCy pt com modelo pequeno, num servidor próprio) **só se** as regras não bastarem. A preferência é ficar inteiro em Dart, no aparelho.

### A3. Confirmação e registro

Tela de revisão com um item por linha: alimento sugerido (trocável), quantidade (editável, vazia quando não foi dita) e refeição/horário. Ao confirmar, usa o mesmo caminho do registro manual: paridade de cálculo, fila durável e sincronização já testadas.

### A4. Entregáveis da pesquisa

- Tabela comparativa A1, com medições reais em 2 aparelhos Android (de entrada e o do autor).
- Conjunto de 30 a 50 frases de teste, com o resultado esperado (alimento e quantidade), versionado em `test/`.
- Protótipo de extração com taxa de acerto medida nesse conjunto.
- Decisão registrada: qual motor de transcrição, tamanho adicionado ao APK, limites conhecidos.

## Parte B: foto → alimentos (complementa a V1-042)

A V1-042 já existe no backlog ("Reconhecer alimentos por foto com revisão e quantidade informada"). Esta pesquisa define **como** fazer de graça e no aparelho.

| Caminho | Uso | O que verificar |
|---|---|---|
| ML Kit Image Labeling (Google, no aparelho) | Rótulos genéricos ("Food", "Rice"?) | Granularidade insuficiente para pratos brasileiros? Gratuito e offline |
| Classificador de alimentos em TFLite/LiteRT (modelos treinados em Food-101 e similares) | Prato ou alimento único | **Licença do dataset e do modelo** (o Food-101 vem de imagens de terceiros), cobertura de comida brasileira, tamanho |
| Detecção de vários itens no prato (YOLO, RT-DETR, MobileNet-SSD) | "Arroz + feijão + bife" na mesma foto | Evitar Ultralytics (AGPL). Avaliar alternativas Apache/MIT e se há dataset brasileiro com licença aberta |
| OCR de rótulo nutricional (ML Kit Text Recognition, no aparelho) | Produto embalado sem código de barras no catálogo | Extrair a tabela nutricional para um **alimento pessoal**, com revisão |
| Código de barras (já existe, `mobile_scanner`) | Produtos embalados | Corrigir a falha do teste nativo amplo com EAN sintético antes de ampliar |
| Foto + voz | Fotografa e diz "arroz, feijão, frango" | Usar a voz para desambiguar o que a imagem sugere. Provavelmente o caminho de melhor custo e benefício |

A foto **nunca** estima peso sozinha: a quantidade continua sendo informada pela pessoa. Treinar um modelo próprio com fotos de pratos brasileiros fica como hipótese futura, que dependeria de coletar imagens com consentimento e direitos claros.

Entregáveis: comparativo com licenças conferidas, protótipo do caminho escolhido e taxa de acerto num conjunto pequeno de fotos próprias, sem usar fotos de terceiros.

## Ordem sugerida

1. Voz com reconhecimento nativo, extração por regras e tela de revisão. É o mais barato e reaproveita o catálogo e o registro existentes.
2. OCR de rótulo e correção do scanner EAN.
3. Foto de prato, de preferência combinada com voz.

## Relação com o backlog

- Voz: proposta de **nova história** em EP06/EP07, com dependência de V1-025 (registro alimentar) e V1-045 (refeições). Ainda não criada no `backlog.json`; criar quando o autor aprovar o escopo.
- Foto: dentro da **V1-042**, sem mudar os critérios existentes.
