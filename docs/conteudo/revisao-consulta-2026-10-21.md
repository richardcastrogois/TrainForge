> Estado vigente desta continuação: [fechamento da etapa01](../execucao/v1/etapa-01-fechamento.md). Triagem512concluída,73metadados/439excluídos,0ensino/prática; V1-002/005fechadas, V1-007emexecução. Registros de revisão parcial abaixo são históricos.

# Revisão do primeiro lote de consulta — 21/10/2026

Continuação de V1-005 dentro da etapa01. A revisão documental foi feita pelo agente Codex, com essa identidade registrada. Não foi atribuída a um profissional inexistente nem equivale a homologação clínica, teste no aplicativo ou entrega de APK.

## Resultado utilizável

- **73 entradas de catálogo wger**: nomes originais, IDs, equipamento e grupos musculares conforme os snapshots. Nomes sem português continuam no idioma original; não houve tradução inventada.
- **2 textos portugueses para consulta**: Flexão de Punho com Barra (`wger:translations:2138`) e Supino com halteres (`wger:translations:2789`). Textos existentes preservados, com créditos, licença, fonte e registro das alterações da projeção. Sem nova dose ou programa.
- **0 liberações de prática guiada e 0 mídias liberadas** nesta revisão. A ausência de liberação não declara que toda mídia seja proibida: falta a conferência do ativo/variante e da entrega concreta.
- Os outros **437 ativos** permanecem fora deste lote. A fila conserva os motivos/pendências por ativo. Não somar registros textuais e movimentos como programas completos.

O [manifesto de consulta](../../content/manifests/pilot-approved.json) registra somente os metadados das decisões. O [registro de revisão](../../content/manifests/pilot-review-decisions.json) prende cada decisão ao hash integral do ativo candidato; um candidato novo ou alterado não ganha autorização por herdar a fonte. Os textos completos continuam fora do Git, em `content/local/editorial-v1-reviewed.json`.

O nome `pilot-approved` refere-se exclusivamente às operações listadas. `runtimeSeed:false`, `practiceApproved:0` e `appDeliveryVerified:false` são explícitos. Não importar todo `content/local/` nem habilitar execução apenas por encontrar a palavra approved.

## Conferência dos seis textos portugueses

| ID da tradução | Resultado | Motivo/limite |
|---|---|---|
|2138|Consulta documental|Preparação, movimento e retorno existentes preservados; sem dose ou elegibilidade nova|
|2789|Consulta documental|Posição, subida e retorno existentes preservados; sem dose ou elegibilidade nova|
|2847|Revisão técnico-editorial pendente|Conferir formulação sobre antebraços/sustentação, cabeça e variante antes de ensinar; não corrigir por inferência|
|2888|Instrução retida|Trechos sem sentido na redação; não apresentar como ensino nem completar com IA|
|2775|Instrução retida|Texto descreve benefícios/anatomia da máquina, sem preparação, ajuste, execução e retorno|
|2794|Variante pendente|Título português fala em círculos; corpo e demais nomes descrevem balanço frente/trás. Movimento1670 também retido|

O movimento1022 mantém o bloqueio anterior por traduções semanticamente divergentes. Não foi corrigido escolhendo silenciosamente uma tradução. Os nomes dos movimentos91/1654 podem compor o catálogo, mas seus textos portugueses2888/2775 não entram como instrução liberada.

## Direitos e entrega

A licença foi conferida no objeto do snapshot, separando movimento e tradução. A documentação primária do wger distingue dados Creative Commons do software AGPL. Os códigos legais [CC BY-SA4](https://creativecommons.org/licenses/by-sa/4.0/legalcode.en) e [CC BY-SA3](https://creativecommons.org/licenses/by-sa/3.0/legalcode) foram abertos para conferir as condições; não se aplicou uma licença genérica do site a todos os objetos.

Cada decisão guarda título, criadores/contribuidores fornecidos, fonte, ponteiro, licença e alterações; nomes selecionados de traduções guardam crédito/licença próprios. A implementação deverá conservar avisos e créditos, identificar alterações, cumprir ShareAlike quando aplicável e não acrescentar restrições ao material licenciado. Não há alegação de endosso. O código do TrainForge e o conteúdo externo continuam identificados separadamente; esta revisão não é uma conclusão jurídica geral sobre qualquer integração futura.

As condições ainda precisam ser verificadas na API/UI/APK. Os testes desta rodada verificam a seleção e a rejeição de operações fora da revisão; não simulam que a interface já exibe créditos ou que a versão já foi distribuída.

## Ajuste de fidelidade do contrato

Vinte ativos dos dossiês guardavam mapas de exceções em `rights.label`, enquanto o schema exige texto ou ausência. A preparação agora conserva esses mapas em `sourceRightsFacts` e deixa a etiqueta desconhecida como `null`. Nenhuma informação foi descartada e o mapa não foi convertido em uma licença uniforme. O validador rejeita esse desvio de tipo; há caso de regressão isolado.

## Conferir e reconstruir

```powershell
python tools/preparar_conteudo_local.py --check
python tools/revisar_conteudo_local.py --write --check
python tools/auditar_conteudo_local.py
python tools/gerar_documentacao.py --write --check
python -m unittest discover -s tools -p "test_*.py"
```

As decisões são explícitas e versionadas. Se mudar o hash do lote, o comando de revisão para e exige conferir as decisões; não reaplica uma aprovação genérica a conteúdo novo. Fontes locais ausentes em outro clone não são substituídas por downloads automáticos. Nenhuma fixture dos testes entra nos arquivos preparados.

## O que falta para fechar a revisão de uso

V1-005 continua em andamento: conferir os34componentes documentais, expressão final autorizada/instrução suficiente, variantes e requisitos de uso/apoio; verificar mídias já referenciadas quando forem selecionadas. Materiais sem cobertura continuam excluídos, com lacuna visível. Não inventar um profissional obrigatório para todo exercício geral, nem remover aquele efetivamente exigido pela fonte. Não reabrir todas asN ou contactar autores.

Os dados alimentares completos já preparados permanecem candidatos para a história019; identidade, bases de cálculo e localização continuam explícitas. Importação depende também de banco isolado010. A revisão parcial de consulta não fecha006/019, não implementa Go e não gera APK. O contrato permite que o desenvolvimento posterior use o catálogo autorizado enquanto os demais materiais conservam seus estados reais.

Validação final executada:37testes locais passaram; auditoria de512ativos/1.069.660células e checks de preparação/revisão passaram; documentação regenerada/conferida e `git diff --check` sem erro. Não são testes clínicos, daAPIoudoAPK.
