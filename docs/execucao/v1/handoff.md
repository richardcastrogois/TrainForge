# Handoff vigente — TrainForge

Atualizado em **28/10/2026**. Repositório: **C:/dev/TrainForge/trainforge**.

## Próxima ação

Ler AGENTS.md, este handoff, backlog.json, plano-macro.md e etapa-02-fechamento.md. Conferir Git/arquivos antes de alterar; não repetir instalações, pesquisas, importações, restore ou Google sem mudança pertinente.

**V1-047 encerrada funcionalmente em 27/10. Próxima história: V1-015, pelas dependências.** O autor criou, revisou e confirmou a rotina real; o agente reabriu as quatro etapas e o resumo e conferiu com SQL somente de leitura. Depois o autor autorizou uma correção específica de horário. A UI/API gerou a revisão 2, recuperada ao fechar e reabrir com um novo controlador. A comparação SQL comprovou que somente o campo autorizado mudou, preservando a revisão 1 e sua data, os demais campos, a conta, o consumo e o catálogo. Não houve terceira versão, extração de credenciais do aparelho ou novo login Google. [Fechamento por critério](training-configuration-047-fechamento.json), [teste humano](training-configuration-human-verification.json).

O último checkpoint047 ficou em Planos. O autor está usando a busca/formulário do APK24; não automatizar navegação nem atualizar enquanto isso. APK25 preparado com clareza de busca, ainda não instalado. Banco/API/emulador mantidos. Não repetir a validação da V1-047 sem mudança pertinente. Seu aceite funcional não encerra o frontend inteiro.

**Refinamento de clareza continua pendente:** o usuário considerou fuso e hora pouco didáticos e pediu primeiro testar, depois corrigir o frontend. A [fonte frontend](frontend-fidelidade-figma.md) registra fuso do aparelho, separação da hora, ajuda e hierarquia de ações. A origem da rejeição do identificador IANA não foi comprovada. O controle de rolagem e texto pelo Windows foi inconsistente no ensaio; a recuperação final foi conferida pela semântica do Android. Não atribuir isso à rolagem do app sem investigação.

Continuar a V1-015, com V1-014, V1-013 e V1-047 concluídas. A ausência de conteúdo aprovado continua impedindo prática. Não inventar programas, doses, instruções ou mídia nem liberar elegibilidade por preencher a rotina. Se um aceite exigir conteúdo humano indisponível, registrar e continuar o trabalho independente, como a V1-045. Manter responsabilidades separadas e segurança desde já; capacidade de milhões exige medição de carga.

## Trabalho independente045 já iniciado

**28/10: SQL/HTTP, Flutter, seleção particular e edição de metadados integrados.** API0.8.0/34operações, schema13/30tabelas. APKdebug0.4.2+24 instalado/hash/assinatura conferidos; **0.4.3+25 preparado, não instalado**, para preservar a busca/formulário em uso pelo autor. [Estado](refeicoes-045.md), [complemento atual](meal-grouping-edit-client-verification.json), [cliente anterior](meal-grouping-client-verification.json), [SQL/HTTP/restore](meal-grouping-sql-verification.json), [ativação](meal-grouping-local-activation.json).

Preparar item não grava consumo; revisão confirma todo o grupo atomicamente. Duas visões compartilham IDs/totais da API; legado permanece sem agrupamento. Metadados têm revisão/corpo/chave congelados em envio incerto, conflito/24h sem nova intenção; correção não envia itens/quantidades. Conta/geração descartam respostas antigas. Rascunho com alteração só de data também avisa antes de sair.

248 testes completos antes do refinamento de descoberta; 37 dirigidos depois, análise limpa. 591 mensagens/idioma; layout de metadados320px/texto2x nos quatro idiomas e dois temas. Sem repetir SQL/restore/Google, pois este complemento usa os contratos existentes.

**Feedback humano:** o autor pesquisou um nome comum no seletor particular e não encontrou. APK25 esclarece “Alimentos que cadastrei” e oferece biblioteca diretamente, com cancelamento preservando busca/rascunho. Base continua sem nomes alimentares revisados em português; não inventar tradução. Prints posteriores mostraram criação/reabertura no diário/detalhe. Autor confirmou: foi apenas teste de navegação. Há1conta/2consumos/6369versões/2revisões047/1refeição; destes, somente o consumo anterior tem aceite real. Nenhum dado de negócio foi escrito/excluído pelo agente; preservar o teste até ação do titular.

045 continua doing: aceite real de refeição/correção/exclusão, foto042 e seu ciclo pendentes. Nativo de edição em refeição real não foi executado; teste automatizado isolado não o substitui. Outbox026 tem critérios próprios. Treinos015/016 continuam sem conteúdo humano aprovado para prática e sem implementação de adesão. Continuar trabalho independente sem fingir conclusão.

## Estado validado e ambiente

- **Go0.8.0 /34operações**, Swagger gerado e servido localmente conferido. Cinco rotas de refeições integradas com migration13 aplicada localmente. Novas rotas GET/PUT /api/v1/me/training-configuration e GET …/resources. Domínio/aplicação, PostgreSQL, handler e Flutter separados. [Contrato](../../arquitetura/contratos-v1.md).
- **Schema13 /30tabelas** aplicado em trainforge_v1_dev,127.0.0.1:15432. [Ativação045](meal-grouping-local-activation.json): dump completo local anterior à13 e comparação preservaram os dados; esse checkpoint específico ainda não foi restaurado. O mecanismo de dump/restore/exclusão foi ensaiado separadamente em bases descartáveis. A [ativação histórica da12](training-configuration-local-activation.json) usou checkpoint somente de schema e comparação, quando ainda não havia configuração. Não repetir os ativadores nem tratar checkpoint como restauração validada.
- [SQL047](training-configuration-sql-verification.json): criação/leitura/alteração/replay/conflito concorrente, fontes/retirada, duas contas, credencial revogada, exportação/exclusão e DML direto bloqueado em base descartável removida. Novos negativos SQL diretos recusamreview:false,titular forjado,medida física e fusoLocal. [Privacidade/restore](training-configuration-privacy-verification.json): ledger reaplicado em outra base, configuração apagada não ressuscita; outra conta/editorial preservados. Não repetir sem mudança pertinente.
- Flutter atual: 591 mensagens/idioma em pt-BR/pt-PT/en/es; 248 testes completos antes da clareza de busca e 37 dirigidos depois, análise sem issues. [Complemento045](meal-grouping-edit-client-verification.json). O [checkpoint047](training-configuration-client-verification.json) tinha 555 mensagens e 213 testes. Suíte comum Go e vet passaram; SQL foi executado separadamente, não inferido dos skips. Testes não significam cobertura total, Sonar, CIFlutter/SQL ou carga concluídos.
- **Checkpoint047 anterior: APKdebug0.4.0+22**, SHA25687de38a82f978fbc81a7d8b802e701b56cf6221df984bcb394860638c32d90cb, assinatura debug conferida. AVDTrainForge_Benchmark/emulator-5554/Android15/1080x2340. [Ensaio nativo inicial](training-configuration-native-verification.json): sessão existente, entrada pela conta, GETausência e opções desmarcadas. Depois o autor confirmou a rotina real, autorizou edição específica e a revisão2 foi recuperada; [evidência atual](training-configuration-human-verification.json). Não houve novo consentimentoGoogle nem resposta de rotina inventada.
- API127.0.0.1:8082, PostgreSQL15432 e emulador ativos após o helper. tools/avaliar_android.py status confere estado/fingerprint. Watcher anterior foi parado pelo própriostopfile antes da implementação; o novo foi iniciado depois da migration/testes.18082 permanece encerrada. Não precisa hospedar para testar localmente.
- Native iniciou com preferência efetivamente guardada **light/pt-BR**, confirmada por leitura somente das duas chaves não secretas. Códigos fixos do processo mostraramread_appearance_timeout/read_locale_timeout; a tela observada é compatível com os valores guardados. Os códigos não provam sozinhos que a resposta tardia foi aplicada. Nenhuma preferência foi gravada pelo agente neste incremento. Não afirmar que a escolha anterior dark ainda é a preferência vigente.
- Graphify atual **116 Dart /4254 nós /4998 arestas**, AST incremental + HTML sem LLM/semântica/clusterização. Complemento: 10 alterados/106 inalterados e depois 6/110, sem removidos. Backups em .local/graphify-backup-20261028-meal-edit; 5 ARB não interpretados. Go/SQL estão em Swagger/mapas.

## Decisão do rascunho e integração047

Autor escolheu **avisar antes de descartar**, sem rascunho durável. Respostas ficam em memória durante etapas/retorno/idioma; saída alterada oferece continuar ou descartar. AndroidBack volta uma etapa. Corpo/chave/conta congelados durante resposta incerta; retry confirma mesma intenção. Conflito preserva respostas e oferece recarregar versão guardada com confirmação antes do descarte. Conta diferente invalida estado/respostas e remove rota.

Sem local/contexto/recurso/dia/tempo predefinido como fato. Unknown difere de none. Fuso começa no desvio observado do aparelho, revisável paraUTC/IANA/offset; desvio fixo não acompanhaDST. Horário não fixo énull; tempo disponível não é dose. Recursos têm identidade composta fonte/equipamento e nomes originais; rótulos emlote/retirados ficam fora do snapshot.

Banco guarda somente configuração completa revisada, versões e resultado idempotente24h. Runtime sóSELECT/EXECUTE restrito para essa tabela, semDML direto; versão imutável. Configuração incluída no inventário/exportação/exclusão/ledger/restore antes da ativação. Leitura inicial falha não habilita salvar formulário vazio sobre versão existente.

## Entrega048 preservada e limites editoriais

Biblioteca, detalhe público, seleção/formulário, histórico e detalhe/correção usam nomes revisados por identidade/versão/idioma. foodDisplay fica fora decalculation e não altera snapshot/cálculo/nutrientes/corpos/chaves/replay. Consultas emlote, cursores porconta/filtro/idioma/revisão e retirada semreviver versão antiga já validados; não repetir sem mudança pertinente. Idioma segue aparelho por padrão, escolha manual opcional. Timeout não grava padrão e resposta tardia não substitui intenção mais recente.

Cobertura real de nomes **0/6369 por idioma**, revisão0: Ciqual2025/3484 e CoFID2021/2885. [Ferramenta editorial](../../conteudo/nomes-alimentares-revisados.md) existe, mas hash/confirmação não provam revisão/licença/identidade. Publicação real exige pacote humano/direitos. Não criar traduções para retirar fallback.048done refere-se àUI disponível/capacidade editorial; futuras jornadas usam a infraestrutura existente.

## Decisões do produto preservadas

[Trilha por área](trilha-implementacao.md) e [Q1–Q6](decisoes-piloto.md). Ambos os caminhos de treino; configuração completa em etapas curtas/revisão antes da busca; trocas compatíveis e dias/horários; retomar ou parcial sem conclusão automática. Cuidador pratica para si nas pausas, sem paciente obrigatório. Idosos, cuidadores, casa, praça/parque e academia, Android/iOS permanecem.

Foto propõe candidatos editáveis e usuário informa quantidade. Visões por refeição/alimento; histórico visual/análise/dicas revisadas juntos naV1, sem diagnóstico de diário incompleto. Fotos recuperáveis pela conta com cache; excluir refeição exclui foto. Offline026 exige fila durável privada, conflitos/idempotência e exclusão sem recriar dados; memória de envio incerto não fecha026.042/044/045/046 têm critérios próprios.

Exclusão própria pelo titular; master049todo com identidade estável verificada, concessão/revogação e auditoria. Não inferir master por e-mail/GitHub. Todos os cenários da matriz permanecem; participantes de usabilidade não confirmados. Emulador primeiro e Android físico orientado depois.

73metadados de movimento,439ativos excluídos e zero programas/doses/instruções/mídias/prática aprovados. Sem conteúdo, nutrientes, fatos físicos ou adequação clínica inventados.011/012/013 têm GoogleAndroiddebug real histórico validado; não repetir esse consentimento. HTTPS/release/iOS têm gates próprios. Frontend021 foi fundação, não produto inteiro concluído.

## Operação, documentação e Git

Commit/push de incrementos validados autorizados; sem hospedagem/deploy/recurso cloud, compra/assinatura/integração paga ou contato externo. [Opções deAPI](../../conteudo/opcoes-apis-exercicios.md): gratuitas primeiro; compra única eventual atéR$400 depende de decisão específica. Sem nova pesquisa ampla. TF/Inter/Grafite-lima aprovados; Android semesticar. CotaStarterFigma esgotada, semnova chamada/contorno/compra; abrir noPC não remove limite.

Credenciais/assinatura/logs/XML/capturas privadas/backups fora doGit. Acesso à janela autorizado, mas controleWindows inconsistente; UIAutomator/screencap fornecem evidência Android. Exigir snapshotnovo/dispositivo explícito, nunca usarXMLantigo após dumpfalhar. Não automatizarGoogle.

Atualizar backlogJSON/contratos/diagramas/diário/handoff; gerar docs e testar. Swagger vem dos tipos/comentáriosGo. Não executar analyze/gen-l10n/test junto ao prepare; SDKs instalados. Não prometer certificação de segurança ou escala por contagens/testes.
