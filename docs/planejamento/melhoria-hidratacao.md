# Melhoria: registro de hidratação

Estado em 27/11/2026: **parcial** — cartão com 200 ml/500 ml, total do dia e desfazer, na Alimentação e no "+" (`hydration_card.dart`); meta, referência, outras bebidas e lembretes continuam pendentes das decisões abaixo. Antes, em 23/11: não implementado. Hoje o app só mostra o cartão "Hidratação — registro de água ainda não disponível" (`lib/shared/widgets/product_overviews.dart`). O visual final entra no redesenho geral; este documento define o funcionamento.

## Objetivo

Registrar a água bebida no dia com um toque, ver o total do dia e, se a pessoa quiser, uma meta que ela mesma define. Público principal: pessoas mais velhas e leigas, que sentem menos sede e esquecem de beber; o registro precisa ser mais rápido que o de comida.

## Decisão de arquitetura proposta

**Reaproveitar o registro de consumo com o alimento "Água" do catálogo**, em vez de criar uma tabela e uma API novas.

- O catálogo instalado já tem "Água" (`Water, tap`, USDA FNDDS, base 100 g; é também uma das 370 classes de foto e voz).
- Cada copo vira um registro de consumo comum: sincroniza pela fila offline, aparece no diário, entra na exportação e na exclusão de dados sem mudar o inventário de privacidade nem as migrações.
- **Unidade:** o registro guarda gramas, porque é a base da fonte; a tela mostra mililitros pela relação física da água, **1 ml ≈ 1 g** (densidade ~1 g/ml na temperatura ambiente). A conversão vale só para água e fica escrita no código e na tela de detalhes.
- **Total do dia:** soma dos registros cujo `foodId` é o da água, no fuso do dia já usado pelo diário. Se a versão do alimento mudar no catálogo, a busca é pelo `foodId`, não pela versão.
- Alternativa adiada: um registro próprio de líquidos (água, café, chá, suco) em ml, com tabela e operação novas na API Go, migração e atualização do inventário de privacidade. Só vale a pena se o autor decidir contar outras bebidas.

## Funcionamento

1. **Cartão Hidratação** (Hoje e Alimentação): total do dia em ml e em copos, e três botões grandes: **+ 1 copo (200 ml)**, **+ 1 garrafa (500 ml)** e **Outra quantidade**. Os volumes aparecem escritos no botão; não é uma medida inferida.
2. **Desfazer:** depois de cada toque, "Desfazer" por alguns segundos (apaga o registro recém-criado pela operação de exclusão já existente).
3. **Meta opcional:** desligada por padrão. A pessoa pode escolher a própria meta em ml. A tela mostra uma referência com a fonte (EFSA 2010: ingestão adequada de água total de 2,0 L/dia para mulheres e 2,5 L/dia para homens, somando bebidas e alimentos; **conferir a fonte primária antes de exibir**) e o aviso: "Quem tem problema no coração ou nos rins pode ter limite de líquidos: siga a orientação do seu médico." O app não calcula meta pelo peso nem prescreve.
4. **Voz e foto:** "um copo de água" já cai em "Água" pelo tradutor de voz; com a quantidade pela voz (item já aprovado), "copo de água" pode abrir com 200 ml preenchidos para conferir.
5. **Lembretes (fase 2, opcional, desligados por padrão):** notificação local em horários escolhidos pela pessoa. Exige a permissão de notificações (Android 13+), um plugin de agendamento e a declaração no Data safety; decidir junto com o redesenho.

## Etapas de implementação

1. Domínio: localizar o alimento água no catálogo instalado (pelo `foodId` das classes de foto), somar o dia e criar o registro rápido com quantidade em g a partir de ml.
2. Cartão com os três botões, total, desfazer e estados (carregando, offline pendente, catálogo sem água → cartão explica e some o botão).
3. Meta opcional nas configurações, com referência e aviso.
4. Textos em pt, en e es; testes de unidade (soma, fuso, versão trocada), de tela (toque, desfazer, sem catálogo) e da fila offline.
5. Atualizar Data safety (sem dado novo além do consumo), documentação, graphify e diagramas.

Estimativa: 3 a 4 horas sem os lembretes; o visual fica para o redesenho.

## Decisões do autor

- Contar só água ou também café, chá e suco?
- Volumes dos botões: 200 ml e 500 ml servem?
- Mostrar a referência da EFSA ou só a meta escolhida pela pessoa?
- Lembretes na primeira versão ou depois?
