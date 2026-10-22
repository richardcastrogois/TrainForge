# Handoff vigente — V1-011 em validação Android

Atualizado em22/10/2026. Repositório correto: `C:/dev/TrainForge/trainforge`. Retomada autorizada pelo autor; não aplicar a antiga instrução de encerrar antes de implementar.

**Ponto exato:** auth Go e integração Flutter implementadas localmente. APK debug gerado, instalado e aberto no emulador existente. Login Google real ainda aguarda conclusão manual do autor; OAuth release dedicado ainda não cadastrado. **V1-011 permanece doing, completionEvidence vazio.** Não concluir com fixtures. V1-012 tem implementação preparatória servidor/cliente coberta por testes isolados; não foi encerrada nem teve suas dependências ignoradas.

## Confirmado nesta retomada

- Git inicial limpo em90e746e, após fundaçãoc23ace6. Primeiro incremento validado: `1765708 fix: protect auth logs and retain sessions on network failures`.
- AppDio sem corpo/query/headers/URL/exceções nos logs; só eventos fixos/status/categoria. Falha de secure storage interrompe requisição. Sem redirecionamento de credenciais a outra origem. Exceção bruta não aparece na tela de login nem no handler global Flutter.
- Google oficialv0.24.1, RS256 e assinatura por certsGoogle fixos; issuer, audienceWeb explícita, exp/iat/sub e e-mail verificado. IdentidadeGoogle+issuer canônico+sub, nunca e-mail. JSONnull malformado é rejeitado antes do parserSDK. Configuração ausente=503.
- Sessão opaca com aleatoriedade256bits, hashesSHA256 noDB, access15min e refresh máximo30dias desde login. Migration00004 aditiva aplicada ao clusterV1 e privilégios runtime concedidos. Go continua único escritor/migrador desse schema.
- Refresh/rotação atômicos porfamília, singleuse, reuso revoga família incluindoaccess; logout idempotente por dispositivo. TestePostgreSQL concorrente passou em base descartável separada, removida depois. Usuários fictícios não foram inseridos na base entregue.
- Flutter usa `/api/v1/auth/google`, refresh/logout e `/api/v1/me`; par de tokens numa chave securestorage específicaGo. Refresh compartilhado entre401concorrentes, retryúnico, falhastransitórias preservam sessão. Compare-and-replace/limpezacondicional impedem respostas antigas de apagar/restaurar outra sessão.
- Entrada atual é checkpoint de autenticação com perfilreal e lacunas. Não chama bootstrap/geradoresFastify nem apresenta os módulos legados como integrados. CatálogoHTTP, atividade/histórico/alimentação continuam pendentes.
- OAuth debug e Web conferidos pelas capturas do autor: projeto bootcamp-treinos-ia/975945820703; pacote com.example.trainforge e SHA1debug coincidem. PúblicoExternal com três contasTestusers. Existem avisosGoogledeinatividade, ainda sem resolução comprovada. [GuiaOAuth](oauth-android.md). Não versionar e-mails/capturas.
- CertificadoRSA3072 release local dedicado criado e preservado; Gradle não usa debug como fallbackrelease. `.local/android-signing/trainforge-evaluation.p12` e `android/key.properties` ignorados. ACLdoproperties restringida à contaWindows/SYSTEM após autorização explícita, resolvendo o bloqueio inicial do auto-review. Não gerar de novo, rotacionar, apagar ou comitar os segredos.

## Validação realizada

- 12testesFlutter passaram; analyze completo semissues. A mudança final de limpezacondicional passou e gerou novoAPK; não foi reinstalado durante o loginmanual. [ReciboAPK](android-auth-checkpoint.json) distingue o hash instalado do recompilado.
- `go test ./...` e `go vet ./...` passaram; testesnovos de chavesGoogleindisponíveis/audience explícita também passaram. FixturesRSA/JWKS são locais; não são loginGoogle real.
- [Testestransacionais](auth-local-verification.json): loginconcorrente com identidadeúnica, e-mailigual/subdistinto semvincular, expiração, reusorefreshconcorrente, logout e isolamentodefamílias. Basetemporária removida, contagemusuáriosV1inalterada.
- [ProcessoHTTP real](auth-http-verification.json): ready200, meanônimo401, Googleinválido401, refreshinválido401, logoutinválido204; Swagger6operações. Essas sondas não criam usuários.
- Swagger gerado por comentários/DTOs; mapas/registros/backlog regenerados;42testesPython passaram. Evidências históricas da etapa02 não foram sobrescritas nem restore/importação repetidos.
- APKinicial: `build/app/outputs/flutter-apk/app-debug.apk`, SHA256 `1388E962D9B0B8C81BE8CFDE394EB503E4EDE030D11EE6325AD370607B0EBA94`; instalado comadbinstall-r e aberto semuninstall. Não éAPKrelease nem jornada completa.

## Intervenção aguardada e próximo passo

1. Autor toca Entrar comGoogle noemulador e autentica manualmente numa contaTestuser. Se não houvercontaGoogle, ele faz a entrada; senha/2FA/consentimento não são coletados poragente/chat. Não capturar logcatintegral ou tela de senha. Confirmar tela Conta conectada e conferir somente contagens/relações/hash noDB, sem divulgar dados pessoais.
2. Autor ainda não criou clienteOAuthrelease. NoConsole→Clientes→Criarcliente→Android: pacote com.example.trainforge, SHA1 `24:EF:27:3C:82:50:DC:FE:15:8A:E6:45:42:BA:8D:D4:0F:02:17:6D`; preservar clientedebug. Não exigirclientsecret.
3. Validar reabertura/rede/retomada, logout/reentrada reais; incluir expiração/refresh com recorte explícito da sessão se necessário. Instalar oAPK recompilado após o fluxoGoogle terminar; certificado/debug já conferido, hash no recibo. Atualizar evidências. Só depois avaliar011done, sem mascarar pendênciasrelease/HTTPS.
4. Não avançar históriasdependentes como prontas enquanto011não fechar. Trabalho independente de documentação/revisão/configuração pode continuar. Produto Android+iOS; iOS não testado e exigeOAuth/Keychain/Xcode próprios.

## Estado local e comandos

**APIwatcher ativo** nesta rodada: processo criado por `tools/dev_api.py --stop-file .local/auth-checkpoint.stop`, localhost8082. **ClusterV1 ativo**, localhost15432, `.local/pgdata`, DBtrainforge_v1_dev. EmuladorTrainForge_Benchmark/Android35GooglePlay ativo, serialobservadoemulator-5554; reverse8082→8082. Não encerrar durante login manual; ao finalizar validar estado real antes de atualizar esta seção.

Go1.27.3, Swaggo1.16.6, Flutter3.41.4/Dart3.11.1 existentes foram reutilizados. A única nova dependência de runtime foi a bibliotecaGoogle necessária e seus transitivos. Emulador já existia emC:/dev/rea-tools/avd; semnovoAVD/reset. BináriosPostgreSQL17.5 existentes; atualizarpatch antes de staging/exposição. Execuçãosandbox de binários ficou travada semoutput; ferramentas locais funcionaram fora do sandbox apósaprovação. Não repetir a investigação desse comportamento.

```powershell
Set-Location C:/dev/TrainForge/trainforge
$tfPython = 'C:/Users/richa/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $tfPython tools/db_local.py start
# Usar watcher existente; não abrir segundo processo na mesma porta.
# Se estiver parado: & $tfPython tools/dev_api.py
./tools/go-api.ps1 test ./...
./tools/go-api.ps1 vet ./...
& $tfPython tools/verificar_auth_local.py # só para mudançasauth; DBtemporária própria
& $tfPython tools/verificar_auth_http.py # exigeAPIlocalativa; sondasnegativas
& $tfPython tools/gerar_documentacao.py --write --check
# Builddebug usa .local/flutter-auth.json existente, somenteIDs públicos+URLlocal:
flutter build apk --debug --no-pub --dart-define-from-file=.local/flutter-auth.json
# Conferir serial antes de operar:
adb -s emulator-5554 reverse tcp:8082 tcp:8082
# Para parar somenteAPIwatcher desta rodada: criar .local/auth-checkpoint.stop
# Para parar somenteclusterV1 apósencerrarAPI: & $tfPython tools/db_local.py stop
```

## Limites preservados

Etapas01/02 concluídas:73metadados,439excluídos,0prática/instrução/mídiaaprovada; importaçãoidempotente/restore já comprovados. Nada foi fabricado para login ou catálogo. Idosos, cuidadores, casa, praça/parque e academia permanecem na cobertura.

[OpçõesdeAPIs](../../conteudo/opcoes-apis-exercicios.md) permanece registroúnico: gratuitasprimeiro, eventualcompraúnicaatéR$400 depende da decisão doautor. Semnova pesquisaampla, integraçãopaga, compra, contatoexterno, push, deploy oupublicação nesta retomada.
