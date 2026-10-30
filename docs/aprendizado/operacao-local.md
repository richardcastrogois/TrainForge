# Operar o ambiente local

Estes comandos reutilizam a instalação e os dados já existentes neste notebook. Não instalam ferramentas, não importam conteúdo e não executam migrations. Execute no terminal PowerShell do VSCode.

## 1. Preparar o terminal

~~~powershell
Set-Location C:/dev/TrainForge/trainforge
$tfPython = 'C:/Users/richa/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $tfPython tools/ambiente.py status
~~~

O caminho explícito evita depender de outroPython noPATH. Essa variável vale apenas neste terminal. Em outro computador, os SDKs/configurações precisam de preparação própria.

Saída: banco15432, catálogo18083 eapi8082 devem estartrue; apkAtual indica se o arquivo corresponde às fontes. dispositivos lista oADB. False não apaga dados: mostra qual parte está parada/desatualizada.

## 2. Iniciar tudo

~~~powershell
& $tfPython tools/ambiente.py start
~~~

Ordem: banco existente → catálogo já provisionado →API →emuladorTrainForge_Benchmark →APK. Se necessário, o helper recompila odebug e instala com-r, preservando dados. Se já corresponder, não reinstala. Não aceita listener desconhecido como seu processo. LoginGoogle, quando necessário, é feito por você dentro do Android.

Primeira abertura/rebuild pode demorar. MensagemfinalPronto e status true comprovam prontidão técnica; não significam que treinos/fotos ainda pendentes foram implementados.

## 3. Ver os logs

Abra terminais separados para cada processo. Ctrl+C interrompe o acompanhamento doGet-Content; o serviço continua.

~~~powershell
Get-Content .local/android-evaluation/api.log -Tail 40 -Wait
Get-Content .local/catalog-evaluation/catalog.log -Tail 40 -Wait
Get-Content .local/postgres.log -Tail 40 -Wait
Get-Content .local/android-evaluation/emulator.log -Tail 40 -Wait
~~~

Execute uma linha por terminal, não as quatro de uma vez. API registra rota/status/duração/requestId com allowlist. Banco e ferramentas podem conter contexto interno; logs locais não devem ser publicados integralmente. Nunca copie api.env, owner.env, key.properties ou tokens para uma conversa/issue.

Para mensagens de execução do Flutter:

~~~powershell
& 'C:/Users/richa/flutter/bin/flutter.bat' --no-version-check logs -d emulator-5554
~~~

Esse comando acompanha o aparelho e pode incluir mensagensAndroid de outras bibliotecas. Use o serial mostrado emstatus se diferente. Ele não adiciona logs novos ao código. Para desenvolvimento comhot reload, após o ambiente ativo:

~~~powershell
& 'C:/Users/richa/flutter/bin/flutter.bat' --no-version-check run --debug -d emulator-5554 --dart-define-from-file=.local/flutter-auth.json
~~~

Não rode esse comando junto deprepare/analyze/test/generate: a geração concorrente muda fingerprints. Emflutter run: r fazhot reload, R reinicia oDart e q encerra o acompanhamento/app. Recompile quando mudar config nativa ou defines.

## 4. Navegar na API

- Swagger local: http://127.0.0.1:8082/docs/index.html
- Vida: http://127.0.0.1:8082/api/v1/health/live
- Prontidão: http://127.0.0.1:8082/api/v1/health/ready
- Referência alimentar: http://127.0.0.1:8082/api/v1/foods?limit=1

live indica processo; ready verifica dependências. GET consulta; POST/PUT/PATCH/DELETE podem gravar. Comece por consultas públicas. Não cole tokens nos exemplos ou faça exclusões para aprender sem conferir o alvo. A lista completa está em[APIs](../diagramas/apis.md).

## 5. Parar e voltar

Salve ou cancele formulários antes de parar. Se houver envio incerto, reconcilie antes; fechar não confirma um registro.

~~~powershell
& $tfPython tools/ambiente.py plan-stop
& $tfPython tools/ambiente.py stop
& $tfPython tools/ambiente.py status
~~~

plan-stop só mostra o plano. stop valida os registros antes de agir: sinaliza a API, depois catálogo, fecha somente oAVD registrado e o mesmo boot e para ocluster local. Celulares e processos de outros projetos não são encerrados. Se um serviço não parar, o banco é preservado e o comando falha. UmAVD aberto fora do registro pode precisar ser fechado manualmente pela janela.

Para voltar, execute start novamente. Parar preserva bancos, arquivos, conta e assinatura. Nunca use wipe-data, apague pgdata ou execute init para isso.

## 6. Cada serviço separadamente

| Peça | Comando | Observação |
|---|---|---|
| Banco | & $tfPython tools/db_local.py start | Só cluster15432 registrado |
| Banco, estado | & $tfPython tools/db_local.py status | Não consulta registros pessoais |
| Catálogo em segundo plano | & $tfPython tools/ambiente.py start-catalog | Reutiliza a base, cria registro de parada novo e inicia o leitor; veja catalog.log |
| API em primeiro plano | & $tfPython tools/dev_api.py | Apenas8082livre e banco/catálogo ativos; mostra build/logs; Ctrl+C encerra essa API |
| PrepararAPK | & $tfPython tools/avaliar_android.py prepare | Compila e confere assinatura; não instala |
| Emulador manual | & 'C:/Users/richa/AppData/Local/Android/sdk/emulator/emulator.exe' -avd TrainForge_Benchmark -no-snapshot-save | ReusaAVD; não abre outro se já houver um |
| Conectar/reusarAPK | & $tfPython tools/avaliar_android.py start --serial emulator-5554 | Exige dispositivo já conectado; não inicia catálogo por conta própria |

O modo em primeiro plano serve para estudar. Para iniciar/parar o conjunto com propriedade registrada, prefiraambiente.py. Não execute dois watchers para a mesma porta. Não useactivate/rollback/init/restore como comandos cotidianos; eles têm outro efeito.

## Quando algo falhar

Se a porta está ocupada, identifique seu processo; não execute taskkill em todos osGo/PostgreSQL. SeapkAtual=false, prepare fora de outra geração. SeGoogle exibir consentimento, conclua você mesmo. Se a leitura de preferência/sessão falhar, tente novamente sem limpar os dados. Use status e a mensagem curta antes de reinstalar qualquer coisa.

Os comandos status/plan-stop foram executados nesta entrega. start/stop foram testados com mocks de segurança; não se repetiu uma parada real nem consentimento apenas para escrever este guia.
