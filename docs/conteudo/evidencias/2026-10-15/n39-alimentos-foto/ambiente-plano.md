**Resultado posterior:** autorização direta recebida. Ensaio executado, CPU4threads, ambiente isolado de1.348.849.875bytes removido após uso. Ver [resultados](resultado-ensaio-local.json), [suplemento](resultado-ensaio-suplementar.json) e [limpeza](limpeza-ensaio.json). O plano e a espera anteriores abaixo permanecem históricos.

# Plano gratuito do ensaio N39 — executado e removido

O objetivo é executar um classificador **alimentar específico**, observar erros e correções e separar isso da avaliação publicada pelos autores. A N39 continua aberta. Este plano não instala o app nem modifica Android, REA, Figma ou banco.

## Ambiente existente e efeito previsto

Conferência local de 15/10: Windows 11 Home Single Language 10.0.26200, Intel i7-13650HX, AMD64/64 bits, 14 núcleos e 20 processadores lógicos; Python bundled 3.12.14. Havia 16,31 GiB de RAM física e 125,56 GiB livres em C: no instante da leitura. Valores variáveis. Não foi encontrado runtime ML nos pacotes Python/Node bundled inspecionados; a busca leve de arquivos em C:/dev e cache não é inventário exaustivo de todo o computador.

Reutilizar o Python atual. Criar apenas `C:\dev\TrainForge\.research-runtime\n39`, fora do checkout `trainforge`, com ambiente virtual, cache, modelo e resultados temporários em subpastas. A proposta reserva **até 5 GB de disco** no total; não é promessa de consumo exato. Usar CPU, com limite inicial de quatro threads. Não instalar CUDA, drivers, serviços, extensões, alterar PATH global ou solicitar reinício. Memória e tempo reais só serão conhecidos durante o ensaio; interromper se houver pressão anormal.

## Downloads propostos

| Item | Origem conferida | Tamanho/efeito conhecido |
| --- | --- | --- |
| PyTorch CPU 2.13.0, wheel cp312/win_amd64 | [Índice CPU oficial](https://download.pytorch.org/whl/cpu/torch/), recibo local | Wheel observada no índice; hash anunciado a8b450c1e58e5800e5b4691dac412f8d2d65a1dc3298166f91596603a3531e6f. O wheel Windows PyPI mede 122.057.313 bytes, mas **não é medição do wheel CPU específico**. Conferir tamanho efetivo antes de baixá-lo. |
| Transformers 4.57.6 | [Metadados PyPI](https://pypi.org/pypi/transformers/4.57.6/json) | Wheel 11.993.498 bytes; Python >=3.9. Escolha 4.x para ensaio legado, não alegação de versão mais nova. |
| Dependências de ambos e Pillow/NumPy se não reutilizáveis com isolamento | PyPI/distribuidores oficiais, resolvidas antes da instalação | Incluem tokenizer, Hub, safetensors e bibliotecas matemáticas/utilitárias. Registrar versões, hashes, licenças e tamanho total antes de executar; não instalar extras de áudio, treino, torchvision ou torchaudio sem necessidade. |
| Peso nateraw/food, revisão fixada | [Inventário primário do modelo](https://huggingface.co/api/models/nateraw/food/tree/8991abd49ea01ebf502aeda51d4f12a59c603e01) | **343.584.369 bytes**; SHA-256 anunciado 33d6b7d44c0bb524fbb6f6d3b7d1f7c8d7c703b58882bf2a845355d9411f566d. Não recebido. Modelo declara Apache 2.0; isso não libera imagens Food101. |
| Config/card/pré-processador | Já recebidos e com hashes locais | Reutilizar; não baixar todo o repo, training_args.bin ou logs de treinamento. |
| Pequeno lote de fotos de ensaio | Somente fonte com licença explícita e atribuição por arquivo, após seleção | Não usar fotos do usuário, dos cuidadores ou do assistido; não importar a coleção Food101 nem supor licença comercial de um mirror. A seleção/anotação ainda não está pronta. |

Documentação oficial: [CPU e ambiente virtual](https://huggingface.co/docs/transformers/v4.57.1/en/installation), [versões PyTorch](https://pytorch.org/get-started/previous-versions/). Os metadados dos pacotes estão nos recibos `n39-*-package-metadata`. Licenças de componentes transitivos serão preservadas, sem resumir tudo a uma licença única do framework.

## Execução proposta após aprovação

1. Resolver o inventário e tamanho de dependências dentro do limite aprovado, revisar procedência e criar ambiente isolado.
2. Conferir importação/CPU e registrar as versões efetivas. Compatibilidade de metadados não é sucesso de execução.
3. Baixar somente o peso selecionado, com limite de tamanho e hash conferido. Carregar como pesos com `weights_only=True`; não permitir código remoto, auto instalação, conversão remota ou execução de training_args.bin.
4. Carregar config e peso locais, sem rede no ensaio. Comparar entrada moderna ao contrato legado e conferir os dois rótulos cuja ordem difere do loader publicado.
5. Fixar lote pequeno antes de observar saídas: comidas cobertas, casos portugueses/mistos com anotação explícita e controles sem comida. Registrar direitos, hipóteses top-k, erros e tempo. Separar rótulo humano, ingrediente e nome da classe. Não tratar conjunto pequeno como validação populacional.
6. Verificar a política proposta de confirmar/corrigir/nenhum destes e identidade da refeição; não preencher gramas, consumo, alérgenos ou metas.
7. Registrar se o caminho atende ou falha em cada critério. Instalar ou obter alguma predição não fecha automaticamente a N39.

## Confirmação pendente

A pergunta foi apresentada no chat com caminho, gratuidade e limite de disco. Nenhuma resposta foi recebida até a elaboração deste plano. O silêncio não será tratado como autorização.

A necessidade vem do pedido direto do usuário: “Apresente o plano de instalações gratuitas, caminhos, downloads e efeitos para minha confirmação. Depois execute as partes aprovadas”. A aprovação anterior tratava de REA/Android; não se presume aprovação de um framework ML novo. Não há bloqueio de aprovação automática nesta etapa e nenhuma skill está impondo confirmação adicional.
