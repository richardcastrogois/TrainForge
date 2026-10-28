# V1-045 — refeições e alimentos sobre os mesmos registros

Estado em **28/10/2026: doing, SQL/HTTP, cliente Flutter e leitura Android integrados**. Go0.8.0/34operações; schema13/30tabelas aplicado localmente com checkpoint e comparação das linhas anteriores; APKdebug0.4.3+25 instalado/hash conferido após o autor salvar/sair; dados preservados. Nenhuma refeição real foi criada pelo agente. O consumo humano anterior permaneceu intacto e sem agrupamento nas duas visões. [SQL/HTTP/restore](meal-grouping-sql-verification.json), [ativação](meal-grouping-local-activation.json), [cliente e leitura nativa](meal-grouping-client-verification.json). 045 permanece aberta por aceite real/correção/exclusão e fotos042. O autor criou e reabriu uma refeição de teste de navegação; confirmou que não era consumo real. [Complemento](meal-grouping-edit-client-verification.json).

## Cliente e checkpoint Android — 28/10

MealRepository/GoNutritionRepository validam conta antes e depois da resposta, identidade/versão, cobertura única dos consumos, revisão e confirmação do corpo enviado. MealDiaryController descarta respostas antigas de dia, idioma ou conta. MealDraftController conserva alimentos/quantidades e revisão explícita; falha incerta congela corpo e chave. Conflito ou expiração monotônica da janela24h exige conferir histórico, sem transformar retry em novo consumo. Estado continua somente em memória, sem fechar026.

NutritionPage mantém o histórico avulso paginado e abre Refeições e alimentos. Essa página alterna duas visões sobre o mesmo diário, indica os registros antigos sem refeição e reutiliza NutritionTotalsCard, sem cálculo no cliente. MealDraftPage prepara quantidades por item com EntryFormPage em modo local: adicionar ao rascunho não chama saveEntry. Somente a revisão final envia o grupo inteiro. A data escolhida inicia o rascunho e os itens; depois da confirmação a consulta volta ao dia do primeiro consumo, incluindo grupos que cruzam dias. O detalhe abre o fluxo existente de correção/exclusão individual e distingue exclusão da refeição inteira.

Teste completo da integração:231casos. Ajuste final de data:26casos dirigidos de cliente/UI/nutrição passaram, com análise limpa. Layout de rascunho vazio/diário de um item em320px/texto2x nos quatro idiomas e dois temas. Isso não substitui usabilidade com idosos/cuidadores nem execução nativa iOS. Captura Android conferida em light/pt-BR; sessão anterior restaurada, nenhum novo consentimentoGoogle. Nome/quantidade/unidade do consumo real conferidos contra o banco sem alterá-los.

Seleção particular e UI de metadados agora implementadas: controlador privado existente reutiliza busca/paginação por conta, preparo continua sem gravação e PATCH envia somente nome/instante/fuso/revisão/revisão humana. Retry preserva corpo/chave/revisão;400/404/413/415/429 exigem nova revisão,409/24h exigem conferir histórico. Correção só do nome preserva o fuso salvo.248 testes completos antes do refinamento;37 dirigidos depois, análise limpa. APK25 esclarece a busca particular e permite abrir a biblioteca sem perder rascunho; cancelar preserva a consulta. Ainda falta aceite real de criação/reabertura/correção/exclusão pelo titular; os prints do autor comprovam criação/consulta de um teste de navegação. Foto/reconhecimento/armazenamento e sua exclusão continuam042; fila offline durável026. Nenhuma dessas lacunas foi preenchida com fixture, imagem ou nutriente inventado.

## Incremento SQL e HTTP — 28/10

meals_commands.go separa os comandos e sua validação. MealStore em meals_postgres.go implementa as portas de criação e diário, detalhe privado e correção/exclusão de grupo. Reutiliza a transação autenticada e o cálculo source-rational-v1 da020. Grupo e 1–32 consumos novos são confirmados na mesma transação, incluindo resposta idempotente. Falha em qualquer item desfaz tudo. Quantidades numericamente equivalentes conservam seu significado; o contrato de refeição aceita precisão de microssegundos, que é preservada pelo PostgreSQL.

Migration13 acrescenta meals, meal_items e meal_versions, sem backfill de consumos. Cada vínculo tem FK composta de titular, identidade de consumo única e posição no grupo. Runtime só recebe SELECT e funções restritas de confirmação/exclusão, que revalidam a sessão viva e travam o titular; não recebe DML direto nessas tabelas. Metadados de grupo são versionados; os cálculos e as revisões dos consumos continuam independentes.

GET /api/v1/me/meal-diary recebe date/timezone e locale opcional. Retorna até100 consumos, uma única lista de identidades, grupos por referência e registros sem agrupamento. Incompletude e itens da mesma refeição fora do recorte ficam explícitos. Nomes revisados usam até duas consultas em lote no mesmo snapshot editorial, sem mudar cálculo ou mutação. POST /api/v1/me/meals confirma a refeição; GET/PATCH/DELETE /api/v1/me/meals/{id} consultam, corrigem metadados ou excluem o grupo inteiro.

Corrigir metadados não desloca os horários individuais nem muda quantidades. Corrigir/excluir um item usa as rotas existentes e aparece nas duas visões; não apaga os demais itens. Excluir o grupo torna seus consumos restantes inativos na mesma transação. Reenvio de criação depois de alteração/exclusão retorna conflito, sem recriar registros. A retenção idempotente atual é24h; isso ainda não é a outbox durável da026. Uma refeição sem itens ativos preserva seus metadados no detalhe; não aparece no recorte diário baseado em consumos.

Exportação inclui meals/mealItems/mealVersions. Exclusão confirmada da conta remove grupos, vínculos e versões; o gate de restore reaplica o ledger antes de liberar qualquer recuperação. Novas seções retornam vazio antes da migration13, mantendo o banco12 utilizável. Testes descartáveis cobriram duas contas, rollback do segundo item, concorrência/replay, limites/dias diferentes, edição/exclusão de item e grupo, HTTP nos quatro idiomas, rejeições e dump/restore com outra conta preservada. Fixtures não são refeição real nem login Google.

Cliente, ativação local e APK foram entregues no checkpoint acima; o aceite de uma nova refeição real continua pendente. Foto042 e exclusão de mídia continuam pendentes; nenhuma foto foi enviada ou adicionada por esta implementação.

## Decisões que governam a implementação

Q2 pede agrupar por refeição e oferecer também visão por alimento. Q4 exige exclusão da refeição com foto/miniaturas e distingue excluir um item de excluir o grupo. Foto042propõe candidatos; alimento/versão e quantidade por item são confirmados pelo titular, sem peso/nutriente inferido. Histórico/análise/dicas046 usa os registros confirmados, sem diagnóstico de diário incompleto.

O grupo não é prescrição, receita, prova de consumo ou cópia dos nutrientes. Cada consumo continua com seuID,foodId/foodVersion,quantidade,unidade,data/fuso,cálculo exato e revisões. Correção existente recusa trocar a identidade/versão alimentar; agrupamento deve preservar essa regra.

## Modelo de leitura implementado

| Elemento interno | Finalidade e invariantes |
|---|---|
| MealMetadata | IDopaco, título informado opcional0–80caracteres semcontrole/espaço externo, data/fuso declarados, revisão positiva e quantidade total de itens ativos. Título vazio não vira “café/almoço/jantar” por inferência |
| MealMembership | Relação explícita EntryID→MealID. Cada registro pertence no máximo a uma refeição. Não inferir vínculo por proximidade de horário/nome/foto |
| MealDaySource | Porta de um snapshot autorizado:entries,meals,memberships ecomplete explícitos. Coleçõesnil e vínculos sem alvo são erro; arrays vazios representam ausência conhecida |
| MealDiary | Entries contém cada consumo uma vez; grupos e semagrupamento referenciamIDs, permitindo duas apresentações sem persistir outro consumo |
| MealGroup.Totals | Reutiliza totals da020sobre os itens incluídos neste recorte. Não soma o subtotal do grupo novamente ao total diário |
| OtherActiveItems | Itens ativos da refeição fora deste recorte. Pode incluir outro dia e truncamento; não alegar que o subtotal visível é a refeição inteira |
| Complete | Limite atual100consumos, alinhado ao resumo existente. Snapshot incompleto não exibe totais nutricionais como completos; não transforma ausência emzero |
| Dia e fuso | As duas visões selecionam pelo occurredAt de cada consumo e o fuso consultado, com limites semiabertos/DST da020. Horário da refeição é metadado; uma refeição pode atravessar meia-noite |

meals.go aplica invariantes, ordena por data/ID e monta projeção independente do snapshot de origem. Preserva nomes/unidades/quantidades/fracões/desconhecidos. meals_service.go recebe ator autenticado fora de dados de cliente, valida formato/contexto/cancelamento e delega à portaMealDayRepository; erro interno vira indisponibilidade. **Validação sintática do ator não autentica nem comprova ownershipSQL.** O adaptador revalida a credencial viva e consulta exclusivamente o titular na transação protegida pelo lock da conta.

```mermaid
flowchart LR
    rows["Consumos existentes: um ID por registro"] --> projection["Snapshot privado autorizado"]
    links["Vínculos explícitos de refeição"] --> projection
    projection --> shared["Entries: identidade e cálculo únicos"]
    shared --> byFood["Visão por alimento"]
    shared --> byMeal["Visão por refeição: referências aos IDs"]
    byMeal --> subtotal["Subtotal do recorte: totals020"]
    shared --> day["Total diário calculado uma vez"]
    legacy["Sem vínculo informado"] --> ungrouped["Sem agrupamento, sem nome inventado"]
```

## Caso de criação revisada — domínio/aplicação

meals_create.go define NewMealCommand e MealCreateService. Title opcional é declaração do titular; OccurredAt/Timezone do grupo são explícitos, reviewed precisa sertrue e items contém1–32EntryInput completos com revisão0.32é limite técnico, não recomendação alimentar. Campos/quantidade/unidade/evidência/versão e tempo por item reutilizam020; itens iguais confirmados não são mesclados automaticamente. Não recebeIDs de consumos antigos para agrupá-los porinferência.

MealCreateRepository é implementado por MealStore: **todos os itens e grupo na mesma transação**, com sessão viva/titular, versões/cálculos da020 e chave idempotente. A aplicação valida antes de chamar e confere retorno completo, IDs únicos, algoritmo, versão, quantidades, evidência, revisões e tempos equivalentes, sem rótulo inventado. O recibo SQL/HTTP acima comprova o adaptador em base descartável; não representa criação real na conta.

## Plano original e situação após o incremento SQL

1. Escritor atômico de criação, comandos de metadados/exclusão e idempotência implementados e testados. Não agrupar automaticamente o legado nem simular transação com gravações sequenciais no Flutter.
2. Migration13 criada, validada em descartável e ativada com checkpoint/comparação. Não alterar foodId/versão ou sobrescrever o snapshot alimentar.
3. Correção/exclusão de consumo aparece no grupo; revisão do consumo é independente da revisão dos metadados. Exclusão do grupo e reenvios tardios testados. Remoção de foto depende da042; não manter foto acessível como revisão.
4. Inventário/exportação/exclusão/restore e privilégios implementados e testados em descartável. Não usar dados reais como fixture.
5. Handlers/Swagger e repository/controller/Flutter implementados no recorte descrito acima; complementos de seleção/edição e aceite ainda pendentes. Duas visões devem compartilhar o estado e preservar erros, revisão, rascunho, conta e quatro idiomas. Conferir formulário antes de atualizar o APK.
6. Aceite real de refeição por seu titular e teste das duas visões semduplicar consumo. Fotos042 e dicas046 têm implementação/validação próprias; esta fundação não as entrega.

[Recibo de testes e limites](meal-grouping-foundation-verification.json). Fixtures do domínio não comprovam persistência, autorizaçãoSQL, refeição criada ou jornada disponível noAPK.
