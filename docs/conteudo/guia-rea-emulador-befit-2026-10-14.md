# Guia de preparacao: REA e teste Android sem celular

Data: 14/10/2026. Plano para o proximo chat, nao instalacao ja executada.
Ler primeiro [o handoff](handoff-befit-2026-10-14.md) e o AGENTS.md do projeto.
Objetivo principal: descobrir origem e disponibilidade do conteudo BeFit.
Objetivo separado: observar fluxos para propor complementos ao nosso Figma.

## Escopo e autorizacoes

O usuario pediu um guia para o outro chat instalar/configurar ferramentas e testar
sem celular. Este documento nao atesta instalacao, conexao MCP, compatibilidade do
computador ou autorizacao do titular do BeFit para engenharia reversa.

Preparar diagnostico e plano das instalacoes gratuitas necessarias. Apresentar
componentes, locais, downloads, efeitos e comandos antes de alterar o computador.
Confirmar o plano com o usuario e cumprir as permissoes do ambiente. Reutilizar
ferramentas existentes; nao reinstalar o que funciona. Nao assumir custo/licenca.
Mudancas de virtualizacao, recursos Windows, reboot, contas e termos exigem decisao
explicita. Nao desativar seguranca, Hyper-V, WSL ou Docker para fazer funcionar.

Os termos BeFit 7.3/10.3 vedam extracao automatizada, copia e engenharia reversa.
Conferir a versao vigente. Sem permissao ou outra base legitima esclarecida, nao
descompilar, instrumentar, interceptar trafego, extrair biblioteca ou automatizar
acesso ao BeFit. Continuar pesquisa publica e observacao normal permitida; propor
pedido de autorizacao se necessario. Instalar uma ferramenta nao libera seu alvo.
[Termos oficiais](https://appbefit.com/terms/).

Nao alterar Figma, app Flutter, APIs, banco, filas N15/N21 ou configuracao global
Git. Ha mudancas locais preexistentes. Nao commitar/push, copiar segredos ou publicar
APKs, gravacoes, logs ou ativos de terceiros no repositorio publico.

## 1. Inventario minimo, somente leitura

Conferir Windows/arquitetura, CPU, RAM, disco livre e virtualizacao; depois localizar
Node/npm, Java/JDK, Android Studio/SDK, adb, emulator e AVDs existentes. Verificar
se REA ja esta registrado e conectado antes de propor outra instalacao.
Nao ler arquivos de contas/credenciais para esse inventario.

Comandos iniciais, um por vez, somente se o executavel existir:

```powershell
node --version
npm --version
java -version
javac -version
```

A referencia Android Studio para Windows informa 16GB de RAM para Studio+Emulator
e 32GB recomendados. Verificar tambem CPU/GPU/disco na tabela atual; nao prometer
desempenho antes do inventario. Se nao couber, registrar limitacao e continuar
busca publica, sem substituir por celular real ou servico pago automaticamente.
[Instalacao e requisitos](https://developer.android.com/studio/install).

Separar ferramentas locais da pasta do app; nao adicionar dependencias npm,
package.json, lockfiles ou projetos Android ficticios ao TrainForge para o benchmark.

## 2. Conjunto de ferramentas

- REA e seu servidor MCP: https://github.com/morluto/rea.
- Android Studio/SDK, Platform-Tools (adb), Android Emulator e uma imagem AVD.
- VS Code pode servir como editor/terminal; nenhuma extensao e requisito deste plano.
- JDK/JADX: apenas para analise estatica autorizada, nao para executar a interface.
- Appium/UiAutomator2: opcional, somente se controle de UI automatizado for necessario
  e permitido. Nao instalar uma pilha extra antes de verificar a necessidade.
- Nao instalar Hopper, IDA, Ghidra, Frida, proxy TLS, root ou emuladores alternativos
  por padrao. Nao confundir analise nativa profunda com observacao de fluxos.

## 3. Configurar REA para o agente escolhido

REA documenta Node 22.x >=22.19, 24.x >=24.11 ou 26+; conferir a versao publicada.
Escolher somente o cliente efetivamente usado, inicialmente Codex, nao todos.
Primeiro resolver e registrar a versao publicada e examinar o plano:

```powershell
npm view rea-agents dist-tags.latest
npx rea-agents@latest setup --client codex --dry-run --json
```

O dry-run nao aplica a configuracao, mas npx pode baixar/executar o pacote: tratar
isso no plano. Depois da aprovacao, usar a mesma versao examinada, nao uma atualizacao
silenciosa entre plano e aplicacao. Comando de entrada documentado:

```powershell
npx rea-agents@latest setup --client codex
```

Registrar caminhos/backups apresentados, preservar outros MCPs e nao aprovar
instaladores opcionais desnecessarios. Reiniciar/reconectar o cliente conforme
orientacao; nao encerrar abruptamente trabalho do usuario.
Validar a configuracao com doctor na mesma versao:

```powershell
npx rea-agents@latest doctor --client codex --json
```

Verificar tambem ferramentas reais na sessao e carregar a skill instalada. Doctor
nao comprova conexao viva; skill sozinha nao instala MCP. Main e npm podem divergir.
Sem ferramentas, reparar apenas o erro concreto, nao instalar tudo outra vez.
[Instalacao REA](https://github.com/morluto/rea/blob/main/docs/installation.md).

## 4. Preparar o emulador

Preferir o SDK existente; se faltar, Android Studio oficial e o caminho de referencia.
No SDK Manager selecionar Platform-Tools, Emulator e imagem necessaria. Nao exigir
Android Studio para sempre: o emulador tambem pode ser operado pela linha de comando.

Criar um AVD dedicado pelo Device Manager. Na tela inicial: More Actions > Virtual
Device Manager; criar dispositivo Phone/Pixel com imagem Google Play se a loja for
necessaria. Google APIs sozinho nao significa Play Store. Escolher API compativel
com o alvo e ABI suportada; nao fixar ARM/x86_64 sem verificar host e aplicacao.
Nome sugerido: TrainForge_Benchmark, sem reutilizar/apagar AVD pessoal existente.
[Criacao de AVD](https://developer.android.com/studio/run/managing-avds).

No Windows, verificar aceleracao. A recomendacao oficial e WHPX. Se faltar suporte
BIOS/Windows, explicar efeito e solicitar intervencao antes de modificar/reiniciar;
nao contornar com desativacao de protecoes ou alteracao indiscriminada de hypervisor.
[Aceleracao](https://developer.android.com/studio/run/emulator-acceleration).

Localizar SDK no SDK Manager. O caminho em LOCALAPPDATA e candidato, nao certeza.
Exemplo PowerShell, executar apenas depois de confirmar o SDK:

```powershell
$sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$adb = Join-Path $sdk 'platform-tools\adb.exe'
$emulator = Join-Path $sdk 'emulator\emulator.exe'
Test-Path -LiteralPath $adb
Test-Path -LiteralPath $emulator
& $adb version
& $emulator -accel-check
& $emulator -list-avds
& $adb devices -l
```

Se o caminho diferir, ajustar as variaveis, nao reinstalar nem mudar PATH global.
Iniciar o AVD criado pelo Device Manager; CLI tambem e possivel. Ao iniciar helpers
em background com Start-Process, usar WindowStyle Hidden. Reservar janela visivel
ao emulador interativo que o usuario precisa observar/controlar.
[Linha de comando do emulador](https://developer.android.com/studio/run/emulator-commandline).

Depois de iniciado, selecionar o serial REAL de adb devices, nunca pressupor 5554:

```powershell
$serial = 'emulator-5554' # Substituir pelo serial realmente observado.
& $adb -s $serial get-state
& $adb -s $serial shell getprop sys.boot_completed
```

Gate: estado device, boot_completed=1 e tela de inicio efetivamente observada.
wait-for-device sozinho nao prova boot; limitar esperas e reportar falhas.
Usar sempre serial explicito; nao operar outros dispositivos eventualmente listados.
[ADB oficial](https://developer.android.com/tools/adb).

## 5. Validar REA com o emulador, sem presumir controle de UI

REA usa adb fornecido pelo operador; nao instala SDK/emulador nem inicia o AVD.
Configurar REA_ADB_PATH com o caminho validado, no ambiente do servidor MCP quando
necessario. Variavel somente no terminal nao se propaga a servidor ja iniciado.
Operacoes documentadas: inspect_adb_client, list_adb_devices, inspect_adb_device,
inspect_adb_display, inspect_adb_window e capture_adb_screen. Descobrir schemas
e disponibilidade na versao conectada; nao inventar parametros.

Gate: emulador correto identificado e screenshot real com dimensoes verificadas.
Nao considerar doctor verde ou arquivo PNG existente como teste funcional completo.
Essa integracao nao oferece taps/digitacao: nao prometer que REA navega sozinho.
[REA/ADB e limites](https://github.com/morluto/rea/blob/main/docs/adb-device-analysis.md).

Para automacao de interface autorizada, avaliar Appium + UiAutomator2 e cliente
compativel separadamente. O driver instala componentes de teste no AVD: documentar
essa mutacao e usar somente o AVD dedicado. Conferir requisitos atuais e validar:

```powershell
appium driver install uiautomator2
appium driver doctor uiautomator2
```

Esses comandos pressupõem Appium instalado pelo plano aprovado; nao executa-los
sem necessidade. Servidor somente local, sem opcoes insecure ou exposicao de rede.
Validar primeiro em APK de exemplo com licenca adequada, nunca usar acesso ao BeFit
como teste inicial de automacao ainda nao autorizada.
[Appium/UiAutomator2](https://appium.io/docs/en/latest/quickstart/uiauto2-driver/).

## 6. Obter e testar o aplicativo

Preferir distribuicao oficial do desenvolvedor/Play Store para app.befit da 3APPS.
Se login da loja for indispensavel, pedir ao usuario realiza-lo; nao ler senhas,
codigos ou tokens. Nao criar conta, aceitar termos ou iniciar assinatura/trial
automaticamente. Aptoide e o link de referencia, nao prova de assinatura original.
Nao recorrer a APK modificado, cracked ou espelhos aleatorios para contornar acesso.

Se for fornecido APK legitimo, conferir pacote, versao, assinatura, hash e compatibilidade
antes da instalacao. Pacotes split exigem conjunto compativel; nao tratar base.apk
como instalador universal, nao reassinar/reempacotar e nao inventar fonte oficial.
Nao exportar o APK da loja para analise sem esclarecer permissao de extracao.
Somente depois dos gates, instalar no AVD dedicado, sem sobrescrever app existente
ou conceder automaticamente todas as permissoes. Registre recusas/incompatibilidade.

Teste funcional permitido: abrir; observar onboarding sem dados pessoais desnecessarios;
localizar programa/exercicio; conferir instrucao; observar inicio, pausa/retorno e
historico quando acessiveis. Nao executar exercicio fisico como validacao clinica.
Registrar cada caso com precondicao, passos, esperado, observado, evidencia e limite.
Descrever campos e problemas resolvidos, nao transcrever o acervo para nosso catalogo.

Se termos impedirem bots, nao trocar REA por Appium/adb como contorno. Usar observacao
manual permitida/gravacoes fornecidas ou solicitar autorizacao. Se premium, antiemulador,
atestado de integridade ou login bloquearem, registrar o ponto, nao adulterar identidade.
App instalado, tela aberta e biblioteca liberada sao tres estados distintos.

## 7. Analise estatica: ramo condicionado, nao primeiro passo

So preparar analise de alvo proprio/licenciado/autorizado. A documentacao REA Android
requer JDK completo 17+ e JAR jadx-headless-mcp compativel/pinado com SHA256 conferido.
Java/JRE funcionando nao basta: verificar javac e jdk.compiler. Windows depende de
artefatos nativos correspondentes da versao; nao assumir que npm tem recursos de main.
JADX comum instalado nao equivale automaticamente a esse adaptador.
[REA Android](https://github.com/morluto/rea/blob/main/docs/android-analysis.md).

Com permissao documentada e ambiente provado em fixture, perguntas estreitas: existem
creditos/fornecedores identificaveis, que parte do conteudo e local e quais declaracoes
de funcionamento sao sustentadas? Nao interpretar CDN/Strapi como autoria; nao afirmar
recuperacao de programa/algoritmo de servidor. Nao copiar ativos para implementar.

## 8. Entrega e criterio de parada

Manter pesquisa publica avancando quando instalacao depender de usuario/restart.
Nao transformar preparacao do ambiente em semanas de investigacao de infraestrutura.
Encerrar cada pista sem nova evidencia; falha repetida so justifica outra tentativa
com causa ou entrada diferente. Materiais exclusivos/dependentes de resposta devem
ter pendencia clara, nao gerar mais buscas identicas.

Entregar status separado de instalacao, MCP conectado, emulador validado, teste de
fixture, acesso BeFit e achados. Matriz: fonte/fornecedor, vinculo demonstrado ou
hipotetico, programa versus movimento/midia, autoria, licenca, custo, utilidade APK,
pendencia e proxima acao. Nao contar homologacao por numero de arquivos/testes.

Registrar comandos, versoes, caminhos e resultados sem segredos. Capturas/logs/APKs
somente locais em pasta de pesquisa aprovada e ignorada pelo Git, com acesso minimo;
nao gerar bugreport integral ou baixar videos para obter algo que a UI ja informa.
Hashes para novos arquivos coletados, evidencias sempre datadas; nao sobrescrever
evidencia historica nem atribuir recibos locais a simples leitura web.

Somente propostas de complemento Figma, sem editar; N15-C continua aberta e N21 retida.
Este guia nao alterou ferramentas, emulador, app, fila ou corpus Graphify lib/.
Links tecnicos conferidos por leitura web em 14/10/2026; nao foram executados os comandos.
