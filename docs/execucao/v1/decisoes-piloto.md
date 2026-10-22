> Atualização22/10: gratuitas primeiro; teto futuro de avaliação **R$400**, preservando preferência por compra única. Sem compra/assinatura autorizada. [Comparativo único](../../conteudo/opcoes-apis-exercicios.md). Referências anteriores aUS$19 abaixo são históricas.

# Direção do APK de avaliação

Respostas diretas do autor em **21/10/2026**, posteriores ao planejamento inicial. Este registro ajusta o objetivo do piloto; não comprova implementação, aprovação de conteúdo ou teste do APK.

## Objetivo e cobertura

O autor e sua esposa querem avaliar o aplicativo como um todo com o APK em mãos, percorrendo os cenários um de cada vez. O propósito é descobrir cedo o que corresponde à visão, o que precisa mudar e o que falta. Não limitar a avaliação a uma jornada pequena escolhida por conveniência, nem esperar o produto inteiro pronto para permitir feedback.

A matriz de avaliação cobre os requisitos R01–R18, os módulos de treino e alimentação, casa, praça/parque, academia, idosos e cuidadores. Cada cenário deve registrar capacidade implementada e verificável, conteúdo disponível, limites, lacunas e próxima ação. Uma capacidade ainda não implementada pode aparecer como pendência explícita; não deve aparentar funcionamento nem produzir dados simulados. A ordem técnica de implementação por dependências permanece necessária.

APKs de avaliação são incrementais: cada entrega informa versão, cenários realmente testáveis, pendências e roteiro. O aceite integral da V1 continua distinto da avaliação de uma versão intermediária. Android é a plataforma inicial; Android e iOS continuam como produto.

## Exercícios, equipamentos e autonomia

- Avaliar o conteúdo já pesquisado em toda a cobertura prevista, preservando origem, autoria, versão, público, dose e limites. Importar por lotes técnicos verificáveis não reduz o escopo a uma amostra arbitrária.
- Em casa, oferecer opções genéricas compatíveis com os recursos declarados pelo usuário e os requisitos documentados de cada material. Não presumir equipamentos nem inventar substituições de gesto, carga ou dose.
- Em academia, máquinas comuns orientam a busca, mas a disponibilidade de um aparelho ou a equivalência entre variantes deve ser confirmada. Praça/parque mantém seu recorte próprio.
- O objetivo de produto é ensinar a execução e permitir autonomia. Priorizar materiais que sustentem uso autônomo. Uma foto ou vídeo não elimina acompanhamento exigido pela fonte; conteúdo com essa exigência mantém o motivo de restrição na avaliação.
- Cuidador praticante e pessoa assistida permanecem separados. A exploração de uma tela não comprova elegibilidade para executar o conteúdo apresentado.

## Instruções e mídia

Usar o que existir e tiver uso permitido por ativo: foto e vídeo juntos quando ambos estiverem disponíveis; apenas foto ou apenas vídeo quando essa for a cobertura. A ausência de mídia não exclui automaticamente o registro do catálogo.

Quando não houver foto/vídeo, apresentar **“Foto/vídeo indisponível no momento”**; quando faltar instrução, apresentar **“Instrução indisponível no momento”**. A falta de instrução e a falta de mídia são estados distintos. Texto existente não deve desaparecer só porque falta vídeo. Não preencher a lacuna com material inventado, conteúdo copiado sem direitos ou promessa de orientação que não existe.

Registro sem instrução suficiente pode ser consultado quando seus metadados puderem ser exibidos; não fica automaticamente liberado como prática guiada. As lacunas devem alimentar a lista de refinamentos/pesquisas direcionadas após o teste.

## Alimentação

O autor quer uma base ampla oriunda da pesquisa, para avaliar o que existe e o que melhorar. Não escolher poucos alimentos como cobertura definitiva do piloto. Inventariar as fontes existentes e importar todos os registros utilizáveis e permitidos, por versões e lotes técnicos, com contagens de entrada, duplicados, rejeições e pendências por motivo.

A experiência deve permitir **digitar para buscar na base**, selecionar alimento/preparo e informar quantidade. Deve também permitir **cadastrar um alimento novo informado pelo usuário**, sem depender de cadastro manual para tudo. Esse cadastro é dado real fornecido pelo usuário, distinto do catálogo editorial pesquisado; não se torna fonte verificada nem público por inferência. Compartilhamento/moderação de cadastros não foi decidido nesta resposta.

Nutrientes, porção, unidade e preparo conservam sua origem. Dados não informados permanecem ausentes e afetam a completude do cálculo; não estimar valores, criar receitas/dietas ou preencher nutrientes com zero para concluir o formulário.

## Custo de conteúdo: decisão do autor

Resposta recebida em21/10/2026: avaliar também opções pagas, desde que o pagamento seja **único** e o valor **razoavelmente baixo**. Apresentar as condições para decisão do autor antes de qualquer contratação. Esclarecimento posterior do autor em21/10: os valores apresentados são altos; cerca deUS$19 em pagamento único seria uma possibilidade, e os demais valores apresentados são inviáveis. Usar esse valor como referência de limite aproximado para a pesquisa, sem presumir aprovação de compra, impostos ou conversão cambial.

Para cada opção paga, registrar fornecedor, preço/moeda/data, cobrança única ou recorrente, duração da licença, conteúdo incluído, uso comercial, armazenamento/cache/CDN, adaptação/tradução, atribuição, atualizações, restrições, impostos/conversão ainda não confirmados e lacunas. Despesas de hospedagem/tráfego são separadas da licença. Assinaturas e créditos que exigem recompras não atendem automaticamente ao requisito de compra única.

A autorização é para pesquisar e apresentar condições, sem compra, contratação, criação de conta ou contato por inferência. Fontes gratuitas continuam elegíveis conforme suas permissões. Gratuito para consultar não comprova direito de incorporar conteúdo no APK. A decisão comercial específica de cada fornecedor permanece pendente até o autor aceitar uma proposta concreta.

Nova pista do autor: ExerciseDB OSS/completo, wger, WorkoutX e pacotes de marketplace. A [verificação de fornecedores](../../conteudo/opcoes-apis-exercicios.md) registra fontes oficiais, diferenças de licença e candidatos com pagamento único. Não atribuir o mesmo fornecedor a ExerciseDB.dev/AscendAPI e ExerciseDB.io.

## Consequência para V1-001

A entrega passa a exigir manifesto de candidatos com cobertura da pesquisa e matriz de cenários do APK, incluindo alimentação e lacunas de instrução/mídia. As decisões foram convertidas em [manifesto documental de candidatos](../../../content/manifests/pilot-candidates.json) e [matriz de cenários](matriz-cenarios.md). O manifesto cobre331famílias,46recortesN e34componentes selecionados com referências e estados, sem importar/liberar conteúdo. Caminhos, ponteiros, hashes, contagens e limites conferidos por `python tools/validar_manifesto_piloto.py`; resultado em [verificação](verificacao-manifesto.json). V1-001 concluída apenas no escopo de candidatos/cenários. As revisões por ativo e a implementação seguem histórias próprias; não repetir as N nem gerar conteúdo.
