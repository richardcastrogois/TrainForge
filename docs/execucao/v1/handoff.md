# Handoff vigente — TrainForge

Atualizado em **29/10/2026**. Repositório: **C:/dev/TrainForge/trainforge**.

**Trabalho retomado pelo autor em29/10.** Sua nova solicitação revoga a parada anterior. Git inicialmente limpo em3f94bb3; helper29/10 informou apiReady:false, apkCurrent:true e nenhum dispositivo conectado. Não iniciar recursos ou repetir aceite por hábito.

**Arquitetura:** o autor escolheu detalhar microserviços por etapas. [Plano concreto M0–M4](../../arquitetura/reavaliacao-microservicos-2026-10-29.md). A primeira prova proposta é o catálogo público, com processo/banco descartáveis próprios e cinco rotas compatíveis. A configuração047 ainda consulta conteúdo no SQL. A pergunta de autorização da prova M1 está pendente; não implementar essa mudança arquitetural ou migrar a avaliação por inferência. Continuar trabalho independente de segurança e qualidade.

## Próxima ação

Ler AGENTS.md, este handoff, backlog.json, plano-macro.md e etapa-02-fechamento.md. Conferir Git/arquivos antes de alterar; não repetir instalações, pesquisas, importações, restore ou Google sem mudança pertinente.

**V1-047 encerrada funcionalmente em 27/10. Próxima história: V1-015, pelas dependências.** O autor criou, revisou e confirmou a rotina real; o agente reabriu as quatro etapas e o resumo e conferiu com SQL somente de leitura. Depois o autor autorizou uma correção específica de horário. A UI/API gerou a revisão 2, recuperada ao fechar e reabrir com um novo controlador. A comparação SQL comprovou que somente o campo autorizado mudou, preservando a revisão 1 e sua data, os demais campos, a conta, o consumo e o catálogo. Não houve terceira versão, extração de credenciais do aparelho ou novo login Google. [Fechamento por critério](training-configuration-047-fechamento.json), [teste humano](training-configuration-human-verification.json).

O último checkpoint047 ficou em Planos. O autor confirmou que havia salvado e saído. APK25 instalado com dados preservados; navegação nativa conferiu biblioteca/retorno e metadados preenchidos sem gravar. Tela final no diário, sem formulário; reler antes de agir. Banco/API/emulador mantidos. Não repetir a validação da V1-047 sem mudança pertinente. Seu aceite funcional não encerra o frontend inteiro.

**Refinamento de clareza continua pendente:** o usuário considerou fuso e hora pouco didáticos e pediu primeiro testar, depois corrigir o frontend. A [fonte frontend](frontend-fidelidade-figma.md) registra fuso do aparelho, separação da hora, ajuda e hierarquia de ações. A origem da rejeição do identificador IANA não foi comprovada. O controle de rolagem e texto pelo Windows foi inconsistente no ensaio; a recuperação final foi conferida pela semântica do Android. Não atribuir isso à rolagem do app sem investigação.

Continuar a V1-015, com V1-014, V1-013 e V1-047 concluídas. A ausência de conteúdo aprovado continua impedindo prática. Não inventar programas, doses, instruções ou mídia nem liberar elegibilidade por preencher a rotina. Se um aceite exigir conteúdo humano indisponível, registrar e continuar o trabalho independente, como a V1-045. Manter responsabilidades separadas e segurança desde já; capacidade de milhões exige medição de carga.

## Trabalho independente045 já iniciado

**28/10: SQL/HTTP, Flutter, seleção particular e edição de metadados integrados.** API0.8.0/34operações, schema13/30tabelas. APKdebug0.4.3+25 instalado/hash/assinatura conferidos após o autor salvar/sair; dados incluindo grupos/vínculos/versões preservados. [Estado](refeicoes-045.md), [complemento atual](meal-grouping-edit-client-verification.json), [cliente anterior](meal-grouping-client-verification.json), [SQL/HTTP/restore](meal-grouping-sql-verification.json), [ativação](meal-grouping-local-activation.json).

Preparar item não grava consumo; revisão confirma todo o grupo atomicamente. Duas visões compartilham IDs/totais da API; legado permanece sem agrupamento. Metadados têm revisão/corpo/chave congelados em envio incerto, conflito/24h sem nova intenção; correção não envia itens/quantidades. Conta/geração descartam respostas antigas. Rascunho com alteração só de data também avisa antes de sair.

248 testes completos antes do refinamento de descoberta; 37 dirigidos depois, análise limpa. 591 mensagens/idioma; layout de metadados320px/texto2x nos quatro idiomas e dois temas. Sem repetir SQL/restore/Google, pois este complemento usa os contratos existentes.

**Feedback humano:** o autor pesquisou um nome comum no seletor particular e não encontrou. APK25 esclarece “Alimentos que cadastrei” e oferece biblioteca diretamente, com cancelamento preservando busca/rascunho. Base continua sem nomes alimentares revisados em português; não inventar tradução. Prints posteriores mostraram criação/reabertura no diário/detalhe. Autor confirmou: foi apenas teste de navegação. Há1conta/2consumos/6369versões/2revisões047/1refeição; destes, somente o consumo anterior tem aceite real. Nenhum dado de negócio foi escrito/excluído pelo agente; preservar o teste até ação do titular.

045 continua doing: aceite real de refeição/correção/exclusão, foto042 e seu ciclo pendentes. Nativo de edição em refeição real não foi executado; teste automatizado isolado não o substitui. Outbox026 tem critérios próprios. Treinos015/016 continuam sem conteúdo humano aprovado para prática e sem implementação de adesão. Continuar trabalho independente sem fingir conclusão.

## Último checkpoint do app e ambiente —28/10 (histórico)

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


## Complemento independente de qualidade032

Job Flutter acrescentado com SDK oficial3.41.4/revisão imutável e lockfile, deriva l10n, análise, suíte e cobertura no runner. Primeira execução remota Flutter40690557153 aprovada para02e596b; SDK, lockfile, l10n, análise, testes/cobertura e artefato conferidos. Go/docs40690557360 também aprovado para o mesmo commit. [Escopo e limites](qualidade-ci.md), [recibo](ci-flutter-verification.json). Não encerra032/028 nem SQL em CI/Sonar/carga. Sem instalar ferramentas no notebook, assinar ou publicar APK.


## Próxima retomada após a parada solicitada

APKdebug0.4.3+25 instalado, API0.8.0/34operações e schema13/30tabelas. Helper confirmou apiReady/apkCurrent e emulator-5554. Última UI observada: diário, sem formulário. Preservados1conta, consumo real anterior, refeição/consumo humano de teste e2revisões047. Não apagar o teste por inferência nem classificá-lo como consumo real.

Graphify conferido novamente:0Dart alterados/116inalterados,4254nós/4998arestas, HTML exportado semLLM. Não havia mudança de contrato Go neste encerramento; Swagger existente permanece válido.

045 precisa de aceite real/correção/exclusão e foto042;015/016 têm bloqueio editorial e implementação pendente. Depois, foto/refeições/análise046, offline026, auditoria/master/observabilidade/carga e entrega seguem dependências. CI Flutter já executou; migrations/SQL noCI, Sonar e imagem/artefatos de entrega ainda faltam. Nenhuma refatoração de grants ou runner SQL provisório ficou em aberto.

A [explicação da arquitetura atual](../../arquitetura/camadas-go.md) registra por que usamos monólito modular, o papel do main, a transação de refeições e os critérios para eventual extração. Não prometer milhões nem migração automática para microserviços.


## Estado da fonte e CI —29/10

Fonte Go0.8.1, 34 operações; o diagnóstico HTTP foi acrescentado sem alterar os contratos. O APK instalado continua debug0.4.3+25. Nenhuma API, banco, emulador, conta ou registro de avaliação foi iniciado ou alterado nesta rodada. O helper inicial indicava API indisponível e nenhum dispositivo; reler o estado antes de agir.

- **SQL ampliado aprovado:** run40817964419/3169bea, job123263441423; oito suítes, 12 testes principais e 21 eventosPASS com subtestes, sem skips aceitos. Schema13, reexecução e limpeza das bases descartáveis conferidos nos logs. [Recibo](ci-sql-verification.json). O primeiro ensaio falhou por exigir referência do wrapper local; o teste original foi preservado e o CI usa entrada sintética explícita. Não é aceite humano nem novo login Google.
- **Prontidão:** objetos/grants/funções, rejeição de papel privilegiado e quatro negativos com recuperação executados no CI; nenhuma migration nova. O adaptador usa metadados e devolve503 genérico.
- **AuditoriaGo:** scanner oficial v1.9.0 aprovado em Linux/Windows para8331426 e3169bea, com zero vulnerabilidades conhecidas alcançáveis detectadas naquele recorte. [Recibo](go-vulnerability-verification.json). O diagnóstico HTTP0c0c531 também passou em40818474380, com logs Linux/Windows conferidos.
- **HTTP029 parcial:** requestId gerado pelo servidor, método categorizado, padrão de rota, status, duração e bytes. Sem URL/query/valores deID, corpos, credenciais, IP ou identidade. SuíteGo comum e vet passaram; pipeline0c0c531 aprovado: Go/docs40818474388, SQL40818474391 e scanner40818474380. [Recibo](http-observability-verification.json). Não entrega correlaçãoFlutter, pool/SQL, métricas/traces, retenção ou alertas.

Dump/restore em CI, imagem sem root, artefatos de entrega, Sonar, carga e auditoria integral continuam pendentes.032/028/029 não estão encerradas. Não repetir aceites, testes nativos ou instalações sem mudança pertinente. O Graphify continua116Dart/4254nós/4998arestas, sem alteração Dart nesta rodada; os mapasGo foram regenerados.

## Segredos no histórico — pendência real

Run40815286943/9b712b0 falhou com87candidatos; redaction sintético passou e nenhum valor bruto foi publicado. Revisão desses candidatos:79falsos positivos, duas ocorrências de URL externa assinada expirada em03/10 e seis ocorrências de URL externa com token sem validade comprovada. Nenhuma credencial do TrainForge identificada nesses87; isso não prova ausência geral de segredos.

Sete campos em seis evidências atuais foram sanitizados, preservando localizador, documentos/hashes e observações históricas. [Comparação semântica](research-url-sanitization.json), [recibo](git-secret-verification.json). O histórico antigo permanece e o gate segue pendente. Não imprimir diff bruto das linhas antigas, reexecutar os tokens, contatar fornecedores, rotacionar credenciais ou reescrever o Git automaticamente. Nenhuma exceção ampla foi criada para tornar o pipeline verde.

## Imagem não root aprovada emCI —29/10

[Run40819933235](https://github.com/richardcastrogois/TrainForge/actions/runs/40819933235)/83b799f, job123269780675, passou build e smoke. Runtime scratch, UID/GID65532, filesystem somente leitura, capabilities removidas e sem elevação, rede interna sem portas publicadas. Produção recusouHTTP simples; modo de teste respondeu live200 e ready503 sem banco. SIGTERM e limpeza dos recursos passaram. [Recibo com imageID/SHA256](api-image-verification.json).

Imagem Linux/amd64 e metadata no artefato12874570734, retido até05/11. Não houve Docker local, registry push, deploy ou acesso aos dados de avaliação. Não comprova TLS público, login real, fluxo de negócio, auditoria da imagem, rebuild idêntico, carga ou releaseAPK. As duas primeiras falhas depreflight/rede e suas correções estão preservadas no recibo/diário; não repetir esses ensaios por hábito.

## Próxima retomada: pendências preservadas

1. Aguardar a resposta da pergunta já enviada sobre a prova isoladaM1. O plano tem os donos candidatos das30tabelas e os acoplamentosSQL: sources também atende alimentos, treinos têmFKs editoriais e idempotência precisa de dono por comando. Não executar cutover ou mexer nos dados reais por inferência.
2. Trabalho independente possível: dump/restore e gate de exclusões noCI, auditoria028 restante, métricas/pool/retention029 e próximos critérios032. Não declarar032 encerrada pela imagem; seu gate028 e demais critérios continuam abertos.
3. Histórico de segredos ainda pendente, sem supressão ampla ou reescrita autorizada. Não reexecutar tokens externos para tentar validá-los.
4. Treinos015/016 e prática continuam sem programas/instruções/doses/mídias aprovados.045 tem aceite humano/foto pendentes;042/046/026 e demais jornadas seguem o backlog. Não preencher lacunas com fixtures no produto.

Commits/push autorizados. API/DB/APK de avaliação preservados; conferir estado somente quando necessário. Sem nova pesquisa ampla de fornecedores, compra, hospedagem ou deploy.
