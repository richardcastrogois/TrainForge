# OAuth Android e sessão — V1-011/012

Estado em22/10/2026: auth Go e Flutter implementados localmente, em validação. Fixtures criptográficas/PostgreSQL não comprovam login Google real. iOS continua no produto, sem teste nativo.

## Valores públicos conferidos com o autor

Projeto: bootcamp-treinos-ia, número975945820703. Capturas do autor confirmam cliente Android TrainForge, Web Bootcamp Treinos, público External e três contas em Test users. Não versionar e-mails dessas capturas.

Client ID Web de servidor: `975945820703-phranuo6urju23c43fb6n2102do767kl.apps.googleusercontent.com`.

| Variante | Pacote | SHA-1 | Estado OAuth |
|---|---|---|---|
| Debug | com.example.trainforge | 1E:93:4C:58:20:7C:D2:3B:A8:D8:EE:49:91:DA:80:56:78:DC:9E:1C | Pacote e fingerprint coincidem com captura do cliente existente |
| Release avaliação | com.example.trainforge | 24:EF:27:3C:82:50:DC:FE:15:8A:E6:45:42:BA:8D:D4:0F:02:17:6D | Cadastro separado solicitado ao autor; confirmação pendente |

SHA-256 debug: `01:96:DD:07:C2:35:76:D2:BA:2C:3E:8B:DC:EA:8D:03:4B:81:F7:8C:45:84:AC:E2:F4:16:A5:03:B4:EB:13:0F`.
SHA-256 release: `BF:A9:1D:87:92:CE:53:12:4A:77:7B:15:BF:46:50:C4:0A:B7:25:92:36:63:62:B6:A5:58:1F:21:1C:20:88:78`.

IDs/fingerprints são públicos. Client secret Web não é necessário para validar ID token. Não alterar origens JavaScript/redirects do legado por inferência da integração Android. Contas legadas não foram migradas nem vinculadas por e-mail.

Console: [clientes](https://console.cloud.google.com/auth/clients?project=bootcamp-treinos-ia), [público](https://console.cloud.google.com/auth/audience?project=bootcamp-treinos-ia). Clientes existentes exibem aviso de possível exclusão por inatividade e continuam visíveis. Validar login e conferir uso/aviso depois, sem afirmar resolução antecipada. [Política Google](https://support.google.com/cloud/answer/15549257).

## Ambientes e assinatura

Go: `TF_GOOGLE_SERVER_CLIENT_ID` exige um único client ID Web explícito. Vazio torna troca Google indisponível503. `.local/api.env` guarda configuração e conexão runtime; não imprimir.

Flutter: `GOOGLE_SERVER_CLIENT_ID` e `API_BASE_URL` via dart-define/arquivo local ignorado. HTTP só em debug para localhost/127.0.0.1/10.0.2.2/::1. Release exige HTTPS. Não segue redirects. `TF_ENV=production` recusa autenticação sem TLS e não confia em X-Forwarded-Proto. Terminação TLS/proxy confiável dependem da etapa de infraestrutura; servidor local não é staging.

Secure storage usa chave Go distinta do JWT Fastify. O par de tokens fica num único JSON sem nome/e-mail. O checkpoint não chama bootstrap/geradores legados com token Go. Mostra autenticação e lacunas dos demais domínios.

`tools/android_signing.py` criou chave RSA3072 local em `.local/android-signing/trainforge-evaluation.p12` e `android/key.properties`, ignorados. O helper recusa sobrescrever/rotacionar; não repetir nesta máquina. Preservar o material antes de limpeza/mudança de máquina. Perder a chave impede atualizar seus APKs. Não é assinatura de loja.

Gradle usa assinatura dedicada e recusa release sem configuração, sem fallback debug. Mesmo pacote com certificados distintos não permite atualização entre debug/release; não desinstalar apagando dados sem decisão do autor.

ACL de `android/key.properties` foi restringida à conta Windows atual e SYSTEM após autorização explícita. A primeira tentativa havia sido rejeitada pelo auto-review.

## Implementação e limites

- Biblioteca oficial `cloud.google.com/go/auth/credentials/idtoken v0.24.1`; certs Google fixos, cache, timeout5s, logs SDK descartados inclusive com env debug. RS256, assinatura, issuer normalizado, audience exata, exp, iat e sub válidos. E-mail verificado preserva regra do legado; chave sempre Google+issuer+sub. Nome pode ser vazio; imagem null nesta fatia.
- Tokens opacos aleatórios256bits, prefixos distintos, somente SHA-256 no DB. Access15min; refresh máximo30dias desde login, sem extensão deslizante; família por login/dispositivo.
- Refresh bloqueia família e relê consumo após lock. Reuso revoga toda a família, inclusive credenciais do vencedor concorrente; não afeta outra família. Resposta perdida pode exigir novo login Google; não repetir automaticamente o POSTrefresh.
- Flutter coordena renovação para401concorrentes, só um retry protegido. Offline/timeout/429/5xx preservam tokens;401confirmado invalida. Compare-and-replace serializado evita restaurar sessão antiga após logout/troca de conta. Logout offline requer repetir conectado.
- JSON estrito, body64KiB, IDtoken16KiB, erros sem eco, no-store, limite por peer IP (10/minlogin,60/minoutrasrotasauth), mapa limitado4096. Forwarded não altera IP/TLS. Limitador por processo; retenção/limpeza, limites distribuídos e autorização dos demais domínios continuam nas histórias seguintes.

## Teste real e retomada

Emulador existente TrainForge_Benchmark: Android35, GooglePlay,2GBRAM. Sem novo AVD, wipe, reset ou instalação Flutter. Conferir serial; `adb -s emulator-5554 reverse tcp:8082 tcp:8082`. API somente loopback.

1. DB V1 com migration00004; API local e Swagger com seis operações.
2. APKdebug com client ID conferido; verificar certificado/checksum; instalar sem uninstall.
3. Autor autentica manualmente numa conta de teste. Senha/2FA/consentimento só pelo autor. Não pedir tokens, capturar logcat integral ou tela de senha.
4. Confirmar conta real na tela, GETme200 e identidade persistida; reabrir confirma sessão.
5. Validar rede/retomada, refresh, logout e reentrada sem duplicar identidade. Expiração forçada exige recorte explícito da sessão e evidência antes de mudar estado real.
6. Registrar sem tokens/e-mail. Debug não comprova release: este exige OAuth próprio e HTTPS.

Depois orientar celular: opções de desenvolvedor, depuração USB, autorizar computador, serial ADB, reverse específico e instalação sem apagar dados.

`auth-local-verification.json`: fixtures RSA/JWKS, rejeições HTTP e concorrência PostgreSQL em base temporária removida, contagem de usuários V1 inalterada. Testes Flutter: `test/auth_security_test.dart` e `test/session_refresh_test.dart`. Nenhuma fixture comprova login Google real. Handoff traz estado do APK/emulador e pendências.

Fontes: [Google ID token](https://developers.google.com/identity/gsi/web/guides/verify-google-id-token), [SDK Go](https://docs.cloud.google.com/go/docs/reference/cloud.google.com/go/auth/latest/credentials/idtoken), [Flutter Android](https://pub.dev/packages/google_sign_in_android#integration).
