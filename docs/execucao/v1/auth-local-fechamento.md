# Autenticação, sessão e privacidade — aceite do checkpoint local

Conferido em23/10/2026. O autor reafirmou que quer avaliar no emulador e não quer hospedagem agora. O pedido anterior de escolher hospedagem foi uma antecipação indevida do agente; não é pré-requisito do desenvolvimento/teste local.

Este fechamento cobre V1-011/012/013 no ambiente local autorizado. Não representa conclusão de toda aM2, do aplicativoV1, de iOS ou da distribuiçãorelease. Os critérios de segurança permanecem: HTTPS fora do desenvolvimento, certificado adequado e validação real antes de exposição/distribuição.

## Critérios e evidências

| História / critério | Resultado e evidência |
|---|---|
|011: credencialGoogle verificada, identidade issuer+sub e sem associação por e-mail | SDK oficial/testes criptográficos e SQL em auth-local-verification.json; loginGoogle Android consentido, conta única e reentrada real em auth-real-android-verification.json |
|011: OAuthdebug/release, IDs públicos e segredos separados | Cadastrodebug e cadastrorelease com pacote/SHAconferidos, oauth-release-verification.json; WebserverClientId preservado, chaves/segredos ignorados |
|011: HTTPS fora do desenvolvimento | FlutterAppConfig só permiteHTTPloopback emdebug; manifestrelease sem cleartext; APIproduction exigeTLSouproxy explicitamente confiável. Rejeição426/spoof coberta por auth/handler_test.go e httpapi/network_test.go. Não há endpoint externo nem testeAPKrelease alegado |
|012: refreshhash/rotação/reuso/família | SQLconcorrente, replayrevoga família e preserva outra, testes em internal/auth/postgres_test.go e auth-local-verification.json |
|012: cliente serializa, preserva rede e revoga logout |48testesFlutter docheckpoint; falha temporária/reabertura reais preservaram sessão, expiração natural→refresh0/1→retry200, logout204 e reentrada na mesma identidade, auth-real-android-verification.json |
|013: titularidade/limites/proxy | Matriz em privacidade-013.md; testesBOLA/cursor/corpo/spoof/limites e privilégios/rollback em privacy-local-verification.json |
|013: exportação/exclusão/retenção/restore | Oito seções próprias consultadas e exclusão explicitamente autorizada noapp real;0contas/sessões/intenções,1registro mínimo e hashes editoriais preservados. Restore deconta previamente excluída e manutenção emfixturesdescartáveis já passaram; limitações debackups explicadas |

Recibos anteriores defixtures continuam dizendo realGoogleLoginValidated=false porque descrevem aqueles testes, não ologinposterior. A evidência real é separada. Nenhuma fixture entrou na base entregue; a única contaGoogle real foi criada porconsentimento e excluída porautorização explícita.

## Gates posteriores preservados

-031/032/033: hospedagem, orçamento, stagingHTTPS, deploy e pipeline deimplantação dependem de autorização/critério próprios. Não pesquisar/provisionar agora porinércia.
-034/035/036: buildrelease assinada, endpointHTTPS, instalação/atualização e jornada dedistribuição ainda não validados. OAuthrelease cadastrado não comprova loginAPKrelease.
-038 eposteriores: iOS nativo/macOS/Xcode/Keychain/OAuth exigem validação própria; Android+iOS continuam no produto.
-015/016:0programas/prática/instrução/mídia liberados; não inventar conteúdo para fechar aceite.
-020/025: cadastroalimentar/consumo ainda não implementados. Consulta6369referências já disponível.

## Teste local disponível agora

API127.0.0.1:8082, cluster isolado15432 e APKdebug0.1.3+4 noAVDexistente. Biblioteca e alimentos independem de login. A biblioteca foi aberta e confirmou73movimentos/0programas. Hospedagem e outra configuraçãoGoogle não são necessárias para explorar essas telas.

[Handoff](handoff.md) e [guia de avaliação](avaliacao-android.md). Não repetir login, instalações, coleta/importação/restore ou Graphify sem mudança relevante.
