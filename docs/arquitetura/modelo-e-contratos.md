# Modelo e contratos

Referência consolidada em **16/11/2026**. A API Go **0.10.0** expõe **38 operações**; núcleo schema **13 / 30 tabelas**, catálogo schema **2 / 4 tabelas**. As migrations usam Goose e a persistência usa pgx/SQL, sem ORM. [APIs extraídas do Swagger](diagramas/apis.md) · [Tabelas, colunas e restrições](diagramas/banco.md) · [Fontes de código](gerado/referencia.md).

## Identidade, versões e titularidade

| Conceito | Regra |
|---|---|
| Usuário e sessão | Identidade estável por provedor/issuer/sub; famílias por dispositivo, hashes de tokens, rotação e revogação. Não exigir uma sessão única para toda a conta |
| Fonte e conteúdo | Origem, autoria, permissões e evidência acompanham ativo/versão. `source_published_version` permanece ausente quando a fonte não a informa; hash local não vira versão publicada pelo autor |
| Movimento, instrução e mídia | São expressões diferentes. Público, ambiente, apoio, idioma, revisão e direito de exibir/redistribuir permanecem por versão |
| Programa e prescrição | Programa/coleção identificados explicitamente; sessão e item conservam ordem, referência exata e dose da fonte. Gesto isolado não herda eficácia de um programa |
| Adesão, ocorrência e execução | Adesão aponta para versão; ocorrência identifica data/fuso e sessão prescrita; execução registra apenas eventos realmente confirmados |
| Alimentação | Catálogo editorial e cadastro particular têm origens distintas; consumo conserva alimento/versão, preparo, base, quantidade e fatores usados |
| Pessoa assistida | Relação/autorização futura explícita; cuidador praticando nas próprias pausas continua sendo o titular |

IDs são opacos; queries privadas sempre usam o titular autenticado. Timestamps usam UTC com fuso explícito para interpretar a data local; não derivar o dia da agenda pelo relógio do servidor. Revisão editorial, revisão de registro e revisão de metadados são conceitos separados.

## Treino: estrutura e dose

`content_versions` distingue movimentos, instruções, mídia, programas e coleções por `kind`; `batch_content` liga versões ao manifesto. `program_sessions` usa programa+versão+session_key; `program_items` referencia sessão e versão do movimento. As FKs de `schedule_occurrences` comprovam adesão e sessão daquela versão.

Dose prescrita, timer e quantidade realizada são separados. Campos tipados podem representar séries, repetições, duração, sustentação, distância, lado, descanso, tempo e intensidade conforme a fonte. Ausência permanece `null`; zero só representa valor real válido. Não inventar dose para preencher estrutura nem transformar oito variantes ReViEEW em circuito novo. N15 preserva onze componentes de cuidadores; ES2019-DOM-01 preserva cinco movimentos de idosos em casa como pacote próprio.

O SQL ensaiado rejeita duas execuções abertas na mesma ocorrência, evento de outro titular, movimento usado como programa, conclusão sem datas finais e ocorrência sem sessão prescrita. O motor atual registra início, medida, pausa, retomada, parcial, conclusão e cancelamento, com journal/revisão/replay duráveis. Sem programa/ocorrência reais liberados, a lista vazia é correta. [Execução e evidências](../execucao/v1/implementacao.md#atividade).

Histórico conserva a versão editorial usada. Retirada pode impedir novo uso; visibilidade histórica ainda deve respeitar direitos/retenção. Alterar agenda ou composição não reescreve eventos passados. Nenhum tempo ou repetição é inferido de uma pausa ou de aplicativo fechado.

## Configuração privada V1-047

`training_configuration_versions` guarda titular, revisão, configuração e confirmação; PK(user_id, revision), versões imutáveis, sem DML direto do runtime. `save_training_configuration` revalida sessão, trava titular, confere revisão/recursos e grava versão+idempotência na mesma transação. A view de recursos é editorial; a rota autenticada não transforma referência em posse ou elegibilidade.

| Elemento | Contrato |
|---|---|
| GET configuração | Versão privada ou `current:null`; rótulos/indisponibilidade de recurso ficam fora do snapshot |
| PUT configuração | `revision` esperada, `reviewed:true`, configuração completa e chave UUID por intenção; nova versão = esperada + 1; sem userId no corpo |
| Recursos | Busca original até 100 runes, limite 1–20 e cursor vinculado a conta/busca/limite; identidade fonte+equipamento |
| Campos | 1–3 ambientes; recursos declarados (1–32 referências), nenhum ou desconhecidos; personal/caregiver_break; fuso UTC/IANA/offset; 1–28 disponibilidades, weekday 1–7, minutos 1–1440 e horário HH:MM/null |
| Escrita | JSON estrito UTF-8 até 16 KiB, sem chaves duplicadas; revisão otimista e replay de 24h. Mesmo corpo/chave pode recuperar versão anterior, inclusive após retirada de recurso |
| Acesso/erros | Bearer/sessão viva, no-store, limite por conta; guarda X-TrainForge-Account só confere igualdade. Erros 400/401/409/413/415/429/503, sem valores privados ou SQL |
| Cliente | Etapas curtas, revisão e guarda de saída; rascunho em memória, corpo/chave congelados em resposta incerta; conflito oferece recarga; conta/geração invalidam respostas antigas |

Configuração é declaração de rotina, sem diagnóstico, prescrição ou autorização de prática. Exportação/exclusão/restore incluem versões. A revisão humana 2 foi recuperada no aceite funcional; não criar outra por hábito. [Especificação e evidências](../execucao/v1/implementacao.md).

## Alimentos e cálculo

`food_versions` distingue fonte editorial e titular particular por CHECK exclusivo. Base por 100g/100ml, unidades, preparação e ausência de nutrientes são explícitas. Decimais/limites usam strings exatas e estados tipados; fatores/denominadores FA não somam métodos alternativos. Dados desconhecidos não viram zero.

O lote importado contém 6.369 referências (3.484 Ciqual e 2.885 CoFID); duas identidades conflitantes ficaram fora e três bases desconhecidas foram preservadas. Runtime só lê conteúdo editorial; o importador autorizado é escritor próprio. Cadastro particular não vira catálogo público nem revisão profissional. Busca da conta não expõe cadastros alheios. [Importação](../execucao/v1/implementacao.md) · [Registro/cálculo](../execucao/v1/implementacao.md).

## Refeições V1-045

`meals` guarda metadados atuais/tombstone; `meal_items` referencia os mesmos `food_entries` por titular, com vínculo único por consumo e posição; `meal_versions` conserva revisões e identidades, sem copiar nutrientes. Não houve backfill de registros antigos. As visões por refeição e alimento leem os mesmos consumos.

| Operação/regra | Contrato |
|---|---|
| POST refeições | Título opcional 0–80, occurredAt/timezone, reviewed:true e 1–32 novos EntryInput completos com revisão 0; grupo/consumos/cálculo/replay atômicos; não recebe IDs antigos para vínculo implícito |
| Diário | date/timezone obrigatórios, locale opcional; entries únicos, grupos por entryIds, ungroupedEntryIds, totais e complete; limite 100 e otherActiveItems explicam itens fora do recorte |
| Detalhe | Titular, metadados e itens originais incluindo tombstones; alheio 404; locale afeta só foodDisplay |
| PATCH | Revisão esperada, reviewed:true e metadados; nova versão do grupo, sem mudar tempos/quantidades individuais |
| DELETE | Revisão esperada, reviewed:true; desativa o grupo e os consumos ainda ativos atomicamente |
| Escrita | Bearer e sessão revalidada em SQL; chave UUID estável, replay 24h, JSON estrito até 64 KiB, datas com microssegundos; no-store; 400/401/404/409/413/415/429/503 |
| Replay posterior | Confere resultado atual; correção/exclusão gera conflito quando necessário, sem recriar consumos nem reapresentar uma refeição antiga |
| Privacidade | Exportação inclui grupos/itens/versões; exclusão de conta e ledger/restore removem os três conjuntos |

Correção/exclusão individual continua no consumo. Metadados da refeição têm revisão independente. Remover um item preserva os demais e o grupo; grupo sem itens ativos permanece no detalhe e não cria consumo fictício. Runtime tem SELECT/EXECUTE nas novas tabelas. Foto e fila durável mantêm critérios próprios. O lançamento de 20g foi declarado teste de navegação pelo autor; não reclassificar nem apagar por inferência. [Detalhes e aceite ainda aberto](../execucao/v1/implementacao.md).

## Nomes, idiomas e projeções de leitura

`food_name_versions` referencia alimento+versão exatos; guarda idioma, hash, nome, até 16 aliases, autor/data, licença/atribuição e hashes das evidências. `food_name_withdrawals` conserva a retirada imutável. `food_name_catalogs` mantém revisão por pt-BR/pt-PT/en/es, incrementada por publicação/retirada; repetição idempotente não aumenta revisão.

Publicação rejeita alvo privado, idioma inválido, JSON ambíguo/campos extras, aliases duplicados e controles invisíveis. O pacote exige evidências com bytes/hash correspondentes e confirmação operacional. Hash/booleano não autenticam revisão humana nem comprovam licença. Não existe endpoint editorial público; cobertura real publicada permanece **0/6.369 por idioma**. Nomes de apresentação da UI (73 movimentos/31 variantes) não são traduções editoriais profissionais.

A leitura escolhe a última versão antes de considerar retirada, sem ressuscitar nome anterior. locale opcional mantém o contrato original quando ausente; nameCatalog/namesVersion/cursor/ETag vinculam revisão e idioma. Mudança de revisão retorna 409 para reiniciar a paginação. Nome/alias nunca muda ID, preparo, base, nutrientes ou hash original. A migration 00011 só usa `und` para novos nomes particulares sem idioma declarado; não reescreve snapshots antigos. [Operação editorial](../conteudo/evidencias-para-integracao.md#nomes-alimentares).

Leitura privada de consumo exige titular/sessão viva; ativo alheio/excluído é 404, credencial inválida/revogada é 401, resposta no-store. `EntryFoodDisplay`/`NameCatalog` são DTOs opcionais, fora de calculation, exportação e replay de escrita. A transação privada termina antes da consulta pública em lote/repeatable-read; pool de uma conexão foi ensaiado. Cliente confere conta/geração/idioma/revisão, sem traduzir nomes particulares. [Evidência de leitura localizada](../execucao/v1/food-names-consumption-verification.json).

## Exclusão, restore e mudanças futuras

`account_deletion_intents` usa nonce com hash, titular/família e expiração. A exclusão confirmada revalida sessão e limpa o inventário privado; `account_erasures` conserva só UUID/data, sem FK, nome, e-mail ou token. Restore separado/offline aplica exclusões atuais e revalida o corte antes de promoção. O CLI não promove automaticamente. [Privacidade](../execucao/v1/implementacao.md).

Migrations pequenas forward e papéis migrator/runtime separados mantêm um escritor por domínio. Backups exigem restauração conferida em alvo separado. Ativações 9–11, 12 e 13 tiveram autorização/checkpoints e comparação de dados nos [recibos de nomes](../execucao/v1/food-names-local-activation.json), [configuração](../execucao/v1/training-configuration-local-activation.json) e [refeições](../execucao/v1/meal-grouping-local-activation.json); isso não manda reaplicar migrations ao iniciar o ambiente. Eventual migração do legado exige inventário, mapeamento (`completeAt` → `completedAt`) e ensaio próprio.

Continuam planejados: fila privada durável com idempotência/conflitos e recuperação após matar processo; exclusão coordenada de foto/miniatura/fila sem recriação; master autenticado com permissão explícita, revogável e auditável. Não inferir poder por e-mail/GitHub. [Decisões do produto](../execucao/v1/escopo.md) · [Critérios de segurança](seguranca-operacao.md).
