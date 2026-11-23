# Teste ao vivo no celular por Wi-Fi

Objetivo: eu (ou o agente) mudo o código no PC e a tela do celular atualiza em 1–2 s (hot reload), sem gerar, baixar e instalar APK a cada ajuste. Serve para o redesenho visual; desempenho e o teste final continuam no APK release.

## Como funciona

- O PC instala no celular a **versão de desenvolvimento** (debug) pela depuração por Wi-Fi do Android (11 ou mais).
- Ela é **assinada com a mesma chave da versão oficial** (`android/key.properties`, fora do Git). Assim instala por cima sem apagar os dados e o login Google continua funcionando, porque o Google confere a assinatura do app.
- Ela usa a **mesma API e as mesmas configurações públicas** da versão oficial (`.local/android-release/release-config.json`). O que você registrar é real, na sua conta.
- O agente tira print do celular pelo próprio PC (`adb exec-out screencap`): não precisa mandar fotos.

## Passo 1 — no celular (só na primeira vez)

1. **Ativar as opções do desenvolvedor:** Configurações → Sobre o telefone → tocar 7 vezes em **Número da versão** (em alguns aparelhos fica em "Informações do software"). Confirmar com o PIN.
2. **Ativar a depuração por Wi-Fi:** Configurações → Sistema → **Opções do desenvolvedor** → **Depuração por Wi-Fi** → ativar. O celular e o PC precisam estar **na mesma rede Wi-Fi**.
3. Tocar no nome **Depuração por Wi-Fi** (não no botão) para abrir a tela com o **endereço IP e porta** (ex.: `192.168.0.15:41235`).
4. Tocar em **Parear dispositivo com código de pareamento**: aparece outro endereço (com outra porta) e um código de 6 dígitos. Deixe essa tela aberta.

## Passo 2 — no PC (só na primeira vez)

No PowerShell, com o endereço e a porta **da tela de pareamento**:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" pair 192.168.0.15:37099
```

Digite o código de 6 dígitos quando pedir. Depois, com o endereço e a porta **da tela principal** da depuração por Wi-Fi:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" connect 192.168.0.15:41235
```

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
```

O celular deve aparecer como `device`. Nas próximas vezes basta o `connect` (a porta muda quando a depuração é desligada e ligada de novo; confira na tela).

## Passo 3 — o agente prepara e inicia (pedir: "inicia o teste ao vivo")

1. Uma vez: no `android/app/build.gradle.kts`, o tipo `debug` passa a usar a mesma assinatura do release quando `key.properties` existir (sem a chave, continua a assinatura de debug padrão). Não muda o APK oficial.
2. Iniciar no celular:

   ```powershell
   flutter run -d 192.168.0.15:41235 --dart-define-from-file=.local/android-release/release-config.json
   ```

3. A cada mudança no código o agente aplica o hot reload (`r`) ou o hot restart (`R`, quando muda estado inicial); a tela do celular atualiza sozinha. Você comenta o que vê.

## Limites

- PC ligado, sem dormir, e na mesma rede; se a conexão cair, repetir o `connect`.
- A versão de desenvolvimento é mais lenta e mostra uma faixa "DEBUG"; não serve para medir desempenho.
- Ao terminar, instalar de novo a versão oficial pelo link (por cima) para voltar ao app normal.
- Mudanças em código nativo (Kotlin, manifesto, plugins novos) exigem parar e rodar o `flutter run` de novo; hot reload vale para as telas em Dart.
