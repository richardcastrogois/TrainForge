# Resultado posterior — N39 encerrada para pesquisa condicionada

O ensaio autorizado foi executado: cinco fotos públicas e dois controles sintéticos, em CPU, com entrada conferida e sem conexão de rede do processo de inferência. O peso e as 26 dependências temporárias foram removidos imediatamente após o último teste; **1.348.849.875 bytes eliminados**, diretório ausente verificado.

Pizza, prato de queijos e cheesecake coincidiram nas três fotos específicas. Caldo verde recebeu “ramen” (score0,7164), cadeira recebeu “gnocchi” e preto sintético recebeu “breakfast burrito” (0,7450). Os scores não são confiança calibrada. O resultado seleciona somente **hipóteses alimentares com confirmação/correção humana obrigatória**, mantendo pessoa e autor explícitos; não aprova reconhecimento automático português, quantidade, alergénios ou nutrição individual.

A ordem16/17 foi conferida com metadados task_templates e com as duas fotos: preservar o config testado. Duas fotos iniciais retornaram429 e continuam ausentes; a quinta foto é suplemento declarado de outro arquivo, sem repetir os objetos bloqueados. O simulador documental de confirmação passou14verificações sobre saídas reais; não é teste da UI ou de idosos/cuidadores.

[Audi­toria do fechamento](auditoria-fechamento.json), [ensaio inicial](resultado-ensaio-local.json), [suplementar](resultado-ensaio-suplementar.json), [decodificação](decodificacao-16-17.json), [confirmação](confirmacao-conferida.json), [downloads temporários](aquisicao-temporaria.json), [dependências](dependencias-ensaio.json), [limpeza](limpeza-ensaio.json). Os blocos seguintes registram o levantamento anterior ao teste; estados ali abertos/aguardando autorização são históricos. Pesquisa concluída não equivale à oferta aprovada; publicação e app continuam falsos.

# N39 — alimentos por fotografia

**Continua aberta; N40 não iniciada.** Foram ampliados o contrato de entrada, a avaliação publicada, as alternativas e os direitos. Ainda não houve inferência, instalação de framework, download de peso ou foto. O fechamento exige resolver a avaliação do caminho escolhido; encontrar um modelo alimentar não demonstra que ele atende ao TrainForge.

## Entregas desta continuação

- [Contrato específico](contrato-classificacao.json): entrada, saída, confiança, confirmação/correção e pessoa da refeição, com os quatro contextos separados.
- [Auditoria reproduzível](avaliacao-publicada.json), gerada por [analisador offline](analisar-n39.py): confere corpos, taxonomias, resultados publicados e um adaptador de entrada com matrizes sintéticas. **Não executa modelo.**
- [Novas fontes e percurso](fontes-e-seguimento.json): quatro famílias novas; comparação inicial preservada em [fontes-e-comparacao.json](fontes-e-comparacao.json).
- [Plano gratuito do ambiente](ambiente-plano.md), com caminhos, origens, efeitos e limite de disco; confirmação apresentada no chat e ainda sem resposta.
- [Lote proposto](lote-ensaio-proposto.json): seis arquivos públicos identificados por metadados, autoria e direitos individuais. Nenhuma imagem recebida ou visualmente aceita como anotação de teste.

## Modelo alimentar e contrato

[nateraw/food](https://huggingface.co/nateraw/food), PR213, é um ViT ajustado para Food101, com Apache 2.0 declarada. A revisão fixada é `8991abd49ea01ebf502aeda51d4f12a59c603e01`. O inventário informa peso de **343.584.369 bytes** e SHA-256; ele não foi baixado. Há 101 nomes de pratos. Resultados públicos repetem acurácia 0,891287 e perda 0,450064, sem contagem explícita de avaliação, predições por foto ou calibração. Velocidade arredondada não permite afirmar o n exato. Isso não é certeza individual nem teste português.

O código oficial Transformers v4.8.1 esclarece o caminho legado: resize direto 224×224 bilinear, conversão dos inteiros para 0–1 e normalização por média/desvio 0,5, em canais primeiro. O ensaio sintético conferiu formato, valores, tipo e rejeição explícita de cinzento. Não reproduziu o treino nem a inferência. A versão do config e a versão dev citada pelo cartão não são prova da transformação efetivamente usada em todo treinamento.

O mapa inverso concorda após converter seus IDs textuais para inteiros. Há, porém, diferença documental: no [loader publicado](https://huggingface.co/datasets/nateraw/food101/blob/66550ec/food101.py), classes 16/17 são cheesecake/cheese_plate; no config do modelo, cheese_plate/cheesecake. O script atual não comprova a revisão usada no treino. Não mudar a taxonomia silenciosamente; incluir ambos os alimentos no ensaio e resolver a proveniência/decodificação.

Não há classe explícita desconhecido ou não-alimento. Não foi escolhido limiar de confiança. A proposta exige confirmação humana em todos os casos, permite “nenhuma destas” e entrada manual. Pratos mistos, preparo português, ingredientes ocultos, alergénicos e porções não são capacidades comprovadas deste classificador.

## Alternativas e avaliação independente de instalação

PR216 é a [conversão ONNX de Swin-Food101](https://huggingface.co/onnx-community/swin-finetuned-food101-ONNX), derivada de aspis/Microsoft, mantida pela onnx-community. API, cartão e configurações da revisão `e5e50bfc6425aa546f3b4421ca8bd79d0dd610b8` foram recebidos. Os nomes das 101 classes coincidem, mas o pré-processamento usa bicúbica e média/desvio ImageNet diferentes. As duas entradas de acurácia do cartão são auto-relatadas; não comprovam equivalência entre variantes quantizadas. Não foi instalado ou executado.

O percurso por uma [aplicação aberta, NutriLens](https://github.com/thejusdutt/nutrilens), PR217, levou a relatórios e anotações publicados pelo mantenedor Thejus Dutt. São evidência dele, sem reprodução nossa. A tabela de calibração recompõe aproximadamente ECE 0,01532, mas pertence à fusão com parâmetros específicos, não ao Swin sozinho ou ao nateraw. O relatório de 39 fotos tem 53/66 acertos de pratos nas linhas exibidas, cerca de 80,30%, diferente da manchete 80,6%; a causa não foi estabelecida. Há ainda diferença entre 2.523 amostras informadas e o nominal 25×101=2.525. Não corrigimos os documentos originais. Faixas de nutrientes são estimativas visuais; não equivalem a pesagens ou validação clínica. Fotos do benchmark não foram obtidas.

PR218 registra a [licença primária dos pesos MobileCLIP](https://github.com/apple-aiml-research/ml-mobileclip/blob/main/LICENSE_MODELS): apesar de o software ter MIT, os pesos recebidos como referência têm concessão de pesquisa não comercial que exclui desenvolvimento de produto e uso comercial. A MIT da aplicação não libera a fusão inteira. Não selecionar esse caminho como solução pronta para TrainForge.

O [estudo DailyFood](https://arxiv.org/abs/2403.07403), PR215, acrescenta evidência sobre transferência de refeições curadas para pratos cotidianos. Não testa este modelo nem culinária portuguesa. O README dos autores aponta pastas de dados sem grant explícito; não foram abertas ou baixadas fotos. Ele é referência metodológica, não pacote de conteúdo livre.

## Direitos e caminhos que continuam distintos

Food101/PR211 tem 101 classes e imagens de Foodspotting. O aviso de direitos foi localizado no **loader histórico ethz/food101**, pai do commit [e06acf2](https://huggingface.co/datasets/ethz/food101/commit/e06acf2a88084f04bce4d4a525165d68e0a36c38), recebido nesta continuação. O loader nateraw atual não contém esse aviso. Corrige-se a atribuição anterior que o localizava diretamente no script nateraw: o cabeçalho Apache deste último licencia código, não suas fotografias. Não houve download de imagens Food101 ou conclusão jurídica sobre todos os pesos derivados.

Nutrition5k/PR212 continua como dataset com CC BY 4.0 e anotações de pratos de cafetarias específicas, não reconhecedor entregue ou prova de equivalência a uma foto RGB portuguesa. LogMeal/PR214 permanece alternativa paga após trial, sem conta, token, imagem enviada ou contratação. Nenhum destes fornecedores foi associado ao BeFit.

A família Commons/MI01 já existia e foi reutilizada, sem duplicar o catálogo. Os seis metadados escolhidos incluem pizza, cheesecake, prato de queijos, bacalhau à Brás, caldo verde e cadeira. Há imagens desfocadas, pequenas ou com autoria presumida no histórico; registrar isso antes do uso. Uma miniatura não tem o mesmo hash do original. Nenhuma foto foi incorporada ao produto e o lote pequeno não demonstrará generalização populacional.

## Pessoas, ambientes e pendências

O [contrato](contrato-classificacao.json) separa pessoa da refeição, quem fotografa e quem relata. O cuidador comendo para si é o próprio participante; registrar para o assistido exige indicação explícita. Prato compartilhado não determina quem consumiu ou quanto. Casa, academia e praça têm condições de captura distintas, não exigem GPS e mantêm alternativa manual. OCR, barcode, massa e consumo não foram antecipados como capacidades desta N.

A [lista de pendências](criterios-e-pendencias.json) mantém os gates abertos. O [plano](ambiente-plano.md) propõe Python existente, ambiente CPU isolado em `C:\dev\TrainForge\.research-runtime\n39`, até 5 GB de disco e modelo fixado, sem CUDA ou mudanças globais. A exigência de confirmação vem do pedido inicial do usuário para apresentar instalações, downloads, caminhos e efeitos antes de instalar. A pergunta está pendente; silêncio não autoriza.

N15 permanece pausada e aberta. N40–N46 não foram iniciadas nesta continuação. A fila antiga também preserva N18-I/N19-I/N20-I pendentes e N21 não iniciada; não há fundamento para declarar “todas deram certo, exceto N15”. Não fechar ou reduzir critérios para avançar a numeração. App, Figma, banco, contas e contatos permanecem sem mudanças nesta N.

## Verificações locais

A auditoria específica passou em 52 verificações, incluindo 32 hashes de corpos originais. A [conferência deste seguimento](verificacoes-seguimento.json) passou em 155 verificações e 51 links locais. São conferências de documentação/entrada sintética, não inferência, uso real ou aprovação clínica. O índice histórico tem 770 chamadas/638 HTTP 200/716 hashes e o catálogo 288 famílias. O Graphify incremental de lib/ informou 0 alterados/42 inalterados/0 removidos, com saídas preservadas e sem indexar semanticamente a pesquisa. Estado Git dos caminhos funcionais vazio e diff --check sem erros; amostras dos corpos locais estão ignoradas pelo Git.
