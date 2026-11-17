# Execução de treino — persistência, API e tela própria

Estado em **16/11/2026: motor, persistência/API e interface implementados; V1-017 e V1-023 em andamento**. Conteúdo e aceite real continuam pendentes.

Direção atual do autor: aplicativo Android/iOS, implementação própria sobre Flutter/Go/PostgreSQL, um problema por vez. Sem web e sem alteração em alimentação neste incremento. Não foi copiado código, programa, tradução ou mídia do openGym. Não foram adicionados pacotes ou ativos externos.

## O que este incremento resolve

O módulo `services/api/internal/activity/session.go` implementa um agregado puro e imutável de execução. Recebe referências exatas de programa, versão, sessão prescrita e ocorrência. Mantém o horário original, os alvos e os registros realizados separados.

| Ação | Regra |
|---|---|
| Iniciar | Identidades, versões, relógio e prescrição explícitos; nenhuma série realizada é preenchida por padrão |
| Registrar série | Somente iniciado; slot e número devem existir na prescrição; modo repetições ou duração; resultado desconhecido é recusado, zero informado é preservado |
| Pausar | Somente iniciado; abre intervalo de pausa |
| Retomar | Somente pausado; fecha intervalo sem deslocar o início original |
| Concluir | Confirmação explícita e todos os slots/séries registrados; atingir a meta não é requisito para preservar o resultado realmente informado |
| Encerrar parcial | Confirmação explícita; preserva os registros existentes e as séries ainda sem registro |
| Cancelar | Confirmação explícita; não apaga fatos já registrados |

Tempo decorrido, saída de tela, inatividade e fim de timer não executam ações. Encerrar enquanto pausado fecha a pausa no horário do encerramento. Duração ativa é a linha do tempo integral menos pausas, sem perder precisão ao arredondar cada evento individualmente.

Cada comando possui UUID e revisão esperada. O mesmo UUID/corpo é identificado antes da revisão/estado terminal; não duplica séries ou duração. UUID reutilizado com outro corpo conflita. Estados terminais não aceitam comandos novos. O limite técnico de comandos reserva um encerramento final, para nunca deixar uma sessão presa aberta.

## Contrato preparado para o Flutter

`trainforge.activity-session/1` contém: identidade da sessão/titular/ocorrência; referência de programa/versão/sessão; estado/revisão; início/último evento/fim; duração ativa; itens e alvos; séries realizadas; intervalos de pausa. Instantes do snapshot são UTC, com precisão máxima de microssegundos. Posição corresponde ao slot do programa; número da série começa em 1.

O resultado de comando distingue `appliedRevision` da revisão do `snapshot` atual. Um replay de comando antigo não deve substituir um estado mais recente. A projeção Flutter bloqueia identidade/titular incorretos, mudanças na prescrição e reescrita de fatos confirmados; ignora respostas antigas e apaga seu estado ao invalidar o contexto da conta.

O relógio de exibição é somente estimativa. O descanso usa um instante final explicitamente escolhido e calcula o restante ao voltar do segundo plano; não existe prescrição automática de descanso.

Os limites de tamanho/tempo/quantidade do contrato são barreiras técnicas, não recomendações de prática. Carga opcional em kg é decimal textual; ausência não é convertida em zero. O registro não calcula progressão, deload, gasto energético, aptidão ou dose futura.

## Persistência e autorização

`ActivityStore` usa pgx/v5 e as tabelas já existentes `activity_sessions`, `activity_events` e `idempotency_records`. Não há nova migration nem novos grants. Cada transação revalida a credencial viva e trava titular/família e ocorrência/sessão; segue a ordem do bloqueio da projeção do catálogo antes do titular. Duas contas não compartilham comandos nem resultados.

O evento inicial conserva prescrição, nomes vinculados à versão e instante original. Eventos posteriores conservam comando, horário atribuído pelo servidor e hash do corpo. A leitura reconstitui e valida o agregado, os recibos e a correspondência com a ocorrência e o estado SQL. Uma UUID de comando é vinculada ao titular; continua deduplicando depois que o cache de resposta expira. O reenvio responde com a revisão originalmente aplicada e o snapshot atual. Uma ocorrência não admite nova sessão após o encerramento. Excluir os dados não permite recriar a sessão por reenvio do comando.

Iniciar, retomar e registrar exigem programa e movimentos exatos, operações `catalog_metadata` e `guided_practice` liberadas, revisão humana indicada, instrução e segurança revisadas, ausência de retirada e projeção do catálogo válida. Não são interpretadas doses de terceiros. `source_dose` deve declarar o contrato próprio `trainforge.activity-prescription/1`, modo e lista explícita de alvos. Não há dose padrão.

Pausar e encerrar preservam fatos mesmo se a prática foi retirada. Concluir continua exigindo todos os registros e confirmação. Retirada ou falha do serviço de catálogo impede nova prática; não apaga o histórico.

## HTTP e Flutter

API **0.10.0 / 38 operações**; quatro operações novas privadas:

| Método | Rota | Resultado |
|---|---|---|
| GET | `/api/v1/me/activity` | Próximas ocorrências e sessões recentes; até 32 de cada, com `complete` explícito |
| GET | `/api/v1/me/activity-sessions/{id}` | Snapshot, título, nomes por versão e disponibilidade atual |
| POST | `/api/v1/me/activity-sessions` | Inicia uma ocorrência existente; `occurrenceId` e `Idempotency-Key` UUID |
| POST | `/api/v1/me/activity-sessions/{id}/commands` | Revisão esperada, ação, confirmação e série realizada opcional; mesma chave em reenvios |

O servidor atribui o instante da ação. O cliente não escolhe titular nem horário histórico. JSON duplicado, campos desconhecidos, aliases de caixa, parâmetros inesperados e corpo excessivo são recusados. Respostas privadas usam `no-store`; erros não incluem registros nem credenciais.

A composição cria `GoActivityRepository` somente ao abrir a aba **Atividade**. `ActivityPage` reutiliza a mesma superfície para lista, sessão aberta, pausa e encerramento; não adiciona uma página para cada estado nem altera as cinco abas existentes. Voltar à lista e trocar de aba não concluem a sessão. A conta controla toda resposta aceita e invalida o estado antigo ao sair ou trocar de titular.

Alvos e realizado aparecem separados. Entradas de realizado começam vazias; repetições ou duração em segundos, carga opcional decimal em kg. Zero explícito é aceito. Carga e duração decimais não usam ponto flutuante para confirmar medidas. Parcial, conclusão e cancelamento têm diálogo de confirmação. O tempo estimado exibido não grava desempenho.

Uma falha incerta de escrita conserva corpo, revisão e UUID **somente na memória do processo**. Retentar usa a mesma intenção por até 24 horas monotônicas. Conflito ou prazo vencido exige consultar o servidor antes de nova decisão. Feed incompleto não prova ausência de sessão. Não há fila offline durável; matar o processo perde a intenção não confirmada, embora os fatos já confirmados possam ser consultados novamente no servidor.

## Limites que permanecem abertos

- Não existem programas/instruções/doses/mídias aprovados para prática no lote entregue. A aba mostra estado vazio/indisponibilidade; nenhum treino foi criado para contornar essa ausência. Fixtures só existem no banco descartável e nos testes.
- Seleção/adesão, agenda e composição de rotina continuam nas V1-015/016. Esta API executa ocorrências existentes; não cria prescrições nem ocorrências.
- Player/instrução e mídia, correção de série confirmada e modos distância/cardio ainda não foram implementados.
- Não houve compra, cópia AGPL, nova atribuição externa de mídia ou alteração de alimentos. Créditos do catálogo já existente continuam preservados.
- Recuperação de intenção após matar processo, fila offline privada, sincronização e testes nativos completos têm seus próprios critérios (V1-023/026). Interface testada com fixtures não constitui prática real aprovada.

## Verificação

Testes Go do agregado cobrem transições, parcial, pausas, confirmação, repetição, conflitos, imutabilidade, zero versus ausência, limites, fuso e precisão. Testes Flutter cobrem contrato, estados, cronologia, prescrições/fatos imutáveis, respostas atrasadas, invalidação por conta e deadline. A validação usa somente código e fixtures; não inicia o ambiente nem grava dados privados.

Primeira fundação: Go comum/vet, 283 testes Flutter e 127 Python aprovados naquele checkpoint. [Recibo histórico](activity-session-foundation-verification.json).

Persistência/API: [verificação SQL/HTTP em banco descartável](activity-session-sql-verification.json). O helper compara hashes de todas as tabelas entregues antes/depois, migra somente o descartável, executa testes selecionados sem aceitar skips e remove a base temporária. Cobre ciclo real SQL, corrida, reenvio após TTL, autorização viva, isolamento entre contas, retirada, exportação e exclusão. As flags editoriais dos testes são sintéticas, não publicação humana.

Comandos de verificação: `python tools/verificar_atividade_local.py` (cluster próprio já ativo); `tools/go-api.ps1 test ./...`; `tools/go-api.ps1 vet ./...`; `flutter test --no-pub`; `flutter analyze --no-pub`; suíte Python e geradores documentais. Resultados finais e limites ficam no handoff e no recibo de integração deste incremento.

Resultado final:337testes Flutter aprovados, análise sem problemas; Go comum/vet;138Python e15documentais após regeneração. APKdebug0.4.7+29 compilado e assinatura/hash/fontes conferidos, sem instalação ou publicação. [Recibo completo de integração](activity-session-integration-verification.json). A base entregue não foi migrada nem recebeu fixtures; o cluster próprio voltou ao estado parado inicial.

Próxima unidade funcional: definir/publicar o primeiro programa próprio com instruções, doses e revisão humana verificáveis; então implementar seleção/adesão e agenda, ligar a ocorrência real à execução e testar o ciclo em Android. Mídia comprada e distribuição por link são etapas posteriores com autorização/configuração próprias. Não marcar 015/016/017/023 como concluídas antes desses critérios.
