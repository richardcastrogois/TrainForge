# Android e REA validados; BeFit instalado legitimamente

Data: 14/10/2026, America/Sao_Paulo. Este é o estado posterior aos relatórios `befit-ambiente-fontes-01` e `befit-rea-instalacao-02`, que permanecem como snapshots históricos.

## Resultado por etapa

| Etapa | Resultado efetivamente observado | Limite |
| --- | --- | --- |
| Ferramentas Android | Command-Line Tools 22.0 instaladas no SDK existente; ADB 35.0.2 e Emulator 35.3.11 reutilizados | Sem atualização geral do SDK |
| REA no agente | Ferramentas disponíveis neste chat; chamada MCP real a inspect_adb_client passou | Não é apenas skill/doctor ou cliente de teste externo |
| AVD | TrainForge_Benchmark, Pixel 5, Android 15/API35, imagem Google Play x86_64 existente | Boot de um dispositivo virtual, não teste do app TrainForge |
| Boot | Serial observado emulator-5554; device; sys.boot_completed=1; nome do AVD confirmado | Serial deve ser redescoberto em futuras execuções |
| Tela | Launcher e Settings visualizados; 1080x2340, 440 dpi | Capturas pontuais, sem gravação contínua |
| Alvo permitido | Configurações Android abriram via REA; retorno ao launcher via comando ADB direto confirmado | REA não fornece controle genérico de taps/digitação |
| Loja | Usuário realizou login manual; Google Play abriu a página oficial app.befit | Nenhuma senha/código capturado, solicitado ou armazenado pelo agente |
| BeFit | Versão 1.1.37/código141 instalada; installer_package_name=com.android.vending | Interface do BeFit não foi aberta/testada; APK não exportado |
| Conteúdo | Nenhum vídeo/programa integral obtido; fornecedor externo ainda não comprovado | Marketing/instalação não fecham autoria, instruções ou direitos |

## Instalação Android

O usuário baixou o ZIP oficial após as instruções de leitura da licença e informou que havia instalado. A imagem enviada mostrava o ZIP aberto no Explorer. O agente concluiu a instalação já autorizada, sem aceitar automaticamente nova tela de termos/licenças.

- Original preservado: `C:/Users/richa/Downloads/commandlinetools-win-15859902_latest.zip`.
- Tamanho real: 155.655.386 bytes.
- SHA256 real igual ao anunciado na página oficial: `90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a`.
- Destino: `C:/Users/richa/AppData/Local/Android/Sdk/cmdline-tools/15859902/`.
- source.properties: Pkg.Revision=22.0; Pkg.Path=cmdline-tools;22.0. O nome da pasta representa o build do ZIP, não a revisão SDK.
- Extração em staging separado, validação de caminhos, movimento somente para destino novo; SDK/imagens preexistentes preservados.
- Java 23.0.2 reutilizado via JAVA_HOME do processo, sem alteração global de ambiente.

sdkmanager --version e --list_installed passaram. Os executáveis agora informam depreciação em favor de Android CLI. A documentação oficial confirma a depreciação e informa que `android emulator` ainda está desabilitado no Windows; foi usado o avdmanager existente/documentado, sem instalar outra pilha. Fontes: [avdmanager](https://developer.android.com/tools/avdmanager), [Android CLI](https://developer.android.com/tools/agents/android-cli).

Listagem/criação reportaram devices.xml ausentes nas imagens API33/34/35. Não ocultar esses avisos: o perfil Pixel 5 embutido estava disponível; a criação retornou exit0 e o boot/Play Store passaram. Não repetir downloads para corrigir aviso sem efeito demonstrado. A imagem API35 contém system.img, vendor.img, kernel e ramdisk e é reconhecida pelo SDK. Não foi declarado hash integral dessa imagem.

## AVD e primeiro boot

Criado sem --force ou substituição:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Java\jdk-23'
'no' | & 'C:\Users\richa\AppData\Local\Android\Sdk\cmdline-tools\15859902\bin\avdmanager.bat' create avd --name TrainForge_Benchmark --package 'system-images;android-35;google_apis_playstore;x86_64' --device pixel_5 --path 'C:\dev\rea-tools\avd\TrainForge_Benchmark.avd'
```

Configuração dedicada ajustada antes do primeiro boot: identidade/nome TrainForge_Benchmark, 2 núcleos, 2048 MiB RAM, GPU auto, indicador de Play Store correspondente à imagem Google Play, caminho de dados no AVD. Backup da configuração recém-gerada conservado em config.ini.before-first-boot. Essas mudanças não mascaram emulador: REA observou ro.kernel.qemu=1 e ro.build.characteristics=emulator; ro.debuggable=0.

Launcher: Emulator existente com `-avd TrainForge_Benchmark -memory 2048 -cores 2 -no-snapshot -no-boot-anim -gpu auto`. Janela interativa visível; sem alteração de BIOS/WHPX/Hyper-V/segurança. WHPX estava utilizável na verificação anterior. Nome do AVD confirmado pelo console `adb -s emulator-5554 emu avd name`.

Esperas de boot: rodada de até 40 segundos com timeout de 5 segundos por comando ADB, sem wait-for-device indefinido. Boot completou nessa rodada. Logs possuem avisos CPUID/.ini; não impediram os gates reais. Não foi aberto acesso gRPC sem autenticação. Logs locais em `C:/dev/rea-tools/evidence/emulator-firstboot.{stdout,stderr}.log`; não ler/compartilhar chaves de sessão indicadas nos logs.

Espaço livre observado: 90,96 GiB antes da instalação/boot; 85,48 GiB após testes. Variação do disco inteiro não é medição exclusiva do consumo do AVD. Imagem Android: release15/API35/buildAE3A.240806.036, patch2024-09-05, ABIs declaradas x86_64/arm64-v8a. Isso não prova suporte futuro de qualquer APK; o pacote BeFit instalou neste ambiente.

## Casos de teste realizados

| Caso | Pré-condição/passos | Esperado | Observado/evidência |
| --- | --- | --- | --- |
| T01 REA/ADB | Registro aplicado e cliente reconectado; inspect_adb_client pelo agente | ADB selecionado e versão real | Passou, REA_ADB_PATH e35.0.2; ev_09a47e95e9749f12dacb0d524c3f7c655ec06693a6212420e1febf3c658e0fd3 |
| T02 boot | AVD novo; lançamento; get-state/getprop/nome | device, boot1 e AVD correto | Passou, emulator-5554/TrainForge_Benchmark |
| T03 tela | Device online; inspect_adb_device/display/window/capture | Identidade, resolução e launcher efetivo | Android15,1080x2340/440dpi, NexusLauncher; PNG visualizado |
| T04 Settings | Launcher; start_adb_app com.android.settings; captura | Settings em foco e tela legível | Statusok, SettingsHomepageActivity, PNG visualizado |
| T05 retorno | Settings; ADB shell input keyevent KEYCODE_HOME; inspect_adb_window | Launcher em foco | Passou; ação executada por ADB direto, não tool de taps REA |
| T06 loja | Abrir Google Play sem conta | Explicitar dependência de login | Tela Sign in observada; usuário fez login manual e confirmou conclusão |
| T07 distribuição | Abrir market://details?id=app.befit na Google Play; conferir listing e Install | App oficial instalável sem compra | Nome BeFit: Gym & Home Workout Plan/3APPS SOLUTIONS; Install gratuito; depois Open/Uninstall observados |
| T08 instalação | Gerenciador Android, inspect_adb_package | Versão e instalador registrados | app.befit 1.1.37/code141, com.android.vending; ev_43b83d51a18f0fe4dc5145733bc0bdb1cef26cbd5ffde5b52dcb8794ce72c04b |

T07 selecionou Install pela UI da loja com um comando ADB de toque baseado na captura observada, somente no AVD dedicado. Não automatizou a interface/acervo BeFit, não iniciou trial ou compra, não concedeu permissões runtime em lote. A loja foi usada como distribuição legítima, sem espelho/extração de APK. O pacote solicita23 permissões segundo a projeção do gerenciador; isso não significa23 permissões concedidas pelo agente. Assinatura/hash do APK não foram exportados ou auditados separadamente; a instalação foi realizada pela loja oficial e pelo Android.

Uma verificação extra por `cmd package get-install-source` retornou Unknown command no Android15; não repetida. O campo installer_package_name da chamada REA já comprova o instalador registrado. Horários de instalação devolvidos pelo Android foram preservados como valores do dispositivo, sem apresentá-los como relógio America/Sao_Paulo confirmado.

## Evidências locais

JSON integral de chamadas REA antes do login: `../raw/rea-android-03/rea-evidencias.json`. Loja/distribuição: `../raw/rea-android-03/rea-store.json`. Diretório raw já coberto pelo ignore Git da data. Capturas originais permanecem fora do repositório em `C:/dev/rea-tools/evidence/`:

| Captura | Pasta | SHA256 |
| --- | --- | --- |
| Launcher | screen-firstboot/screen.png | f4558adb323758c27ac461f1933b023861a22074423224c05a50f9730177790c |
| Settings | screen-settings/screen.png | cdcb2f54fe690502f584ab2ac3063631ecf59aa257c8847e983f95bdc2ad418a |
| Google Play Sign in, antes da credencial | screen-play-entry/screen.png | 072f0bf90455822f15b370207c591d1649e5cfe71771302b81cd3ed4ce97b44b |
| Listing BeFit na loja | screen-befit-store/screen.png | 23e5fe4de63854de9dda4d1305b33726f885589090e1984003350b6f1fde2937 |
| Instalação concluída | screen-befit-install-progress/screen.png | 22e701ae5bee6bb4fe497df5d3d023e61c7595dd25f644cbb640d95da8c7de43 |

Nenhuma captura/inspeção de tela durante a entrada de senha/códigos. Nenhum bugreport, banco privado, APK puxado, vídeo baixado ou tráfego interceptado.

## Conteúdo e critérios de parada

Matriz da pesquisa pública anterior permanece válida nos limites daquela leitura; novos testes de ambiente/loja não descobrem autoria externa:

| Camada | Fonte disponível | Autoria/origem demonstrada | Direitos/custo/utilidade |
| --- | --- | --- | --- |
| Movimentos | appbefit.com/exercises: classificação/nomes públicos | Equipe geral anunciada, sem fornecedor por item | Referência de organização; não catálogo importável aprovado |
| Instruções | Guias anunciados e orientação editorial pública | Experts identifica Antonio Brandão/Ednardo Ribeiro; vínculo por guia não comprovado | Texto por ativo/tradução/offline sem grant; qualificação não auditada em registro |
| Mídia | Vídeos anunciados e imagens promocionais da loja | Produtor/estúdio/licenciante não identificado | Nenhum vídeo recebido/licenciado; hospedagem/estilo não provam autoria |
| Programas | Special Workouts Library anuncia planos e sessões; app instalado | Curadoria/personalização anunciadas, sem fonte integral identificada | Acesso integral anunciado com assinatura; nenhum programa recebido/liberado |

Zero novos programas úteis aprovados para TrainForge. Nenhum vínculo comprovado com wger/Gym Visual/MuscleWiki. Não contar instalação ou número de testes como avanço de conteúdo executável. A biblioteca geral não resolve requisitos específicos de cuidadores para si, idosos, casa e praça.

Termos BeFit 7.3/10.3 continuam como restrição observada. A instalação não autoriza decompilação, instrumentação, extração ou automação da plataforma. O agente não abriu a UI BeFit. Próximos caminhos: uso manual permitido pelo usuário para identificar créditos/help; fonte pública nova; ou solicitação oficial de esclarecimento/permissão. Rascunho não enviado no relatório01. Não repetir buscas amplas/URLs falhas sem pista nova, nem enviar contato sem autorização específica.

## Retomada e preservação

Guia humano: `docs/conteudo/retomada-rea-android-befit-2026-10-14.md`. AVD ficou na página Google Play do BeFit, com Open disponível, para o usuário abrir manualmente quando retornar. Não foi criada automação recorrente ou tarefa futura.

Figma/código/banco/fila não alterados. N15-C parcial e N21 retida. Os fluxos BeFit continuam sem observação runtime; as telas da loja são publicidade, não funcionamento confirmado. Comparação futura somente após uso manual permitido, contra fluxos-v04/ajustes-visao-integrada. Graphify cobre lib/, não esta pesquisa; não reindexar referências nem documentos semanticamente.

Conferência final: ambos os JSON de evidência parsearam; as cinco capturas tiveram hashes comparados integralmente com os valores REA; raw ignorado pelo Git; diff rastreado em lib/test/pubspec vazio. API Graphify detect_incremental:0novos/alterados,42inalterados,0removidos,0erros. Saídas preservadas, sem extração semântica. Resultados em validacoes.json; validação documental não é aprovação clínica, jurídica ou de conteúdo BeFit.
