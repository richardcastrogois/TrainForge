# Como opero o ambiente local

Estes comandos reutilizam as ferramentas e os dados já provisionados neste notebook. Execute no PowerShell, na raiz do checkout. O guia descreve a operação existente; sua leitura ou atualização não inicia serviços, não reinstala o APK e não repete o login Google.

## Abrir o terminal e entender o estado

```powershell
Set-Location C:/dev/TrainForge/trainforge
$tfPython = 'C:/Users/richa/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $tfPython tools/ambiente.py status
```

O caminho explícito evita depender de outro Python no `PATH`. A variável vale apenas nesse terminal. Outro computador precisa de provisionamento e configuração próprios; estes comandos não são um instalador portátil.

| Campo de status | Como interpreto |
|---|---|
| `banco15432` | O PostgreSQL local está escutando na porta 15432 |
| `catalogo18083` | O catálogo separado responde à verificação de prontidão |
| `api8082` | A API principal responde à sua verificação de prontidão |
| `apkAtual` | O APK preparado corresponde às fontes/configuração esperadas pelo helper |
| `dispositivos` | Dispositivos conectados ao ADB; usar o serial observado |

`false` informa uma parte parada ou desatualizada; não apaga dados. Um APK atual no disco não comprova que essa versão está instalada. O estado de uma execução antiga não substitui o `status` de agora.

## Iniciar e voltar ao app

```powershell
& $tfPython tools/ambiente.py start
```

O helper reutiliza o banco e o catálogo já provisionados, inicia API e o AVD `TrainForge_Benchmark`, prepara/reusa o APK e abre o aplicativo. Se necessário, recompila o debug e instala com `-r`, preservando dados; se já corresponder, evita reinstalação. Antes de aceitar processos existentes, confere os registros de propriedade do ambiente.

Prepare-se para a primeira abertura ou recompilação demorar. A mensagem final e os checks de prontidão comprovam o ambiente técnico, não o aceite de todas as jornadas. Se aparecer consentimento Google, a interação é feita por você no Android; não é uma etapa obrigatória a repetir a cada início.

Antes de uma atualização do APK ou parada, observe a tela. Salve ou cancele formulários. Se um envio estiver incerto, consulte/reconcilie o resultado: sair da tela não desfaz uma requisição já enviada.

## Acompanhar os logs

Abra um terminal por comando. `Ctrl+C` interrompe o acompanhamento de `Get-Content`; o serviço continua.

```powershell
Get-Content .local/android-evaluation/api.log -Tail 40 -Wait
```

```powershell
Get-Content .local/catalog-evaluation/catalog.log -Tail 40 -Wait
```

```powershell
Get-Content .local/postgres.log -Tail 40 -Wait
```

```powershell
Get-Content .local/android-evaluation/emulator.log -Tail 40 -Wait
```

A API registra rota, status, duração e `requestId` com campos permitidos. Ao investigar, comece pela ação, horário e mensagem curta; não publique logs integrais. Nunca copie `api.env`, `owner.env`, `key.properties`, tokens ou backups para uma conversa ou issue.

Para mensagens do Flutter no dispositivo:

```powershell
& 'C:/Users/richa/flutter/bin/flutter.bat' --no-version-check logs -d emulator-5554
```

Troque `emulator-5554` pelo serial informado em `status`. A saída pode conter mensagens Android de bibliotecas; o comando não adiciona novos logs ao código.

Para desenvolver com hot reload, depois de o ambiente estar ativo:

```powershell
& 'C:/Users/richa/flutter/bin/flutter.bat' --no-version-check run --debug -d emulator-5554 --dart-define-from-file=.local/flutter-auth.json
```

Em `flutter run`, `r` faz hot reload, `R` reinicia Dart e `q` encerra o acompanhamento/app. Alterações nativas e de defines exigem recompilação. Não executar `run`, geração de idiomas, analyze ou testes em paralelo a `avaliar_android.py prepare`: a geração concorrente pode mudar o fingerprint do APK.

## Consultar a API para aprender

| Endereço local | O que mostra |
|---|---|
| `http://127.0.0.1:8082/docs/index.html` | Swagger UI, com o contrato gerado |
| `http://127.0.0.1:8082/api/v1/health/live` | Processo vivo |
| `http://127.0.0.1:8082/api/v1/health/ready` | Prontidão e dependências |
| `http://127.0.0.1:8082/api/v1/catalog/movements?limit=1` | Uma consulta pública de metadados |
| `http://127.0.0.1:8082/api/v1/foods?limit=1` | Uma consulta pública de referência alimentar |

O ambiente precisa estar ativo para esses endereços responderem. GET consulta; POST/PUT/PATCH/DELETE podem gravar. Comece pelo GET público e siga o [rastro de uma ação](fluxo-de-uma-acao.md). O [mapa de APIs](../arquitetura/diagramas/apis.md) concentra a lista. Não cole tokens em exemplos compartilhados nem execute exclusões para estudar sem decidir o alvo.

## Parar preservando os registros

```powershell
& $tfPython tools/ambiente.py plan-stop
& $tfPython tools/ambiente.py stop
& $tfPython tools/ambiente.py status
```

`plan-stop` mostra o plano, sem encerrar. `stop` valida os registros de propriedade, sinaliza API e catálogo, fecha somente o AVD registrado no mesmo boot e encerra o cluster local. Telefones e processos de outros projetos não são alvos. Se um serviço não parar ou voltar a escutar, o helper preserva o banco e falha. Um AVD aberto fora do registro pode precisar ser fechado pela própria janela.

Para voltar, execute `start`. Parar não apaga bancos, conta, arquivos nem assinatura. Não usar `wipe-data`, apagar `pgdata`, rodar `init` ou restaurar backup para abrir o app no dia seguinte.

## Entender o que permanece salvo

| Lugar | O que permanece | Limite |
|---|---|---|
| PostgreSQL local | Registros confirmados, conta, revisões, sessões e eventos persistidos | Parar o serviço não exclui a base; confirmação depende do servidor |
| Armazenamento do app/AVD | Preferências e dados locais conforme sua implementação | Não confundir fechar janela com apagar dados do AVD |
| Memória Flutter | Rascunhos e intenções incertas que o cliente conserva em memória | Matar o processo pode perdê-los; não há fila offline durável geral |
| `.local/` | Configuração privada, bancos, assinatura, logs e backups | Ignorado no Git; não é material público de apresentação |
| `build/` | APKs e artefatos de compilação | Recriação não recupera automaticamente um checkpoint antigo com seu hash |

A existência de um evento confirmado no servidor é diferente de uma intenção ainda não confirmada no aparelho. Reabrir uma sessão pode consultar fatos persistidos; isso não comprova recuperação durável de todo rascunho.

## Usar uma peça separadamente

Os comandos abaixo têm efeitos diferentes. Para iniciar/parar o conjunto com propriedade registrada, prefira `ambiente.py`.

| Peça | Comando no mesmo terminal preparado | Efeito |
|---|---|---|
| Banco | `& $tfPython tools/db_local.py start` | Inicia somente o cluster registrado em 15432 |
| Estado do banco | `& $tfPython tools/db_local.py status` | Consulta o estado técnico, sem listar dados pessoais |
| Catálogo | `& $tfPython tools/ambiente.py start-catalog` | Reutiliza a base existente e cria novo registro de parada do leitor |
| API em primeiro plano | `& $tfPython tools/dev_api.py` | Exige 8082 livre e dependências ativas; mostra build/logs; `Ctrl+C` encerra essa API |
| Preparar APK | `& $tfPython tools/avaliar_android.py prepare` | Compila e confere assinatura; não instala |
| Reusar dispositivo | `& $tfPython tools/avaliar_android.py start --serial emulator-5554` | Exige dispositivo conectado; não inicia o catálogo por conta própria |

Emulador manual, somente se não houver um AVD já aberto:

```powershell
& 'C:/Users/richa/AppData/Local/Android/sdk/emulator/emulator.exe' -avd TrainForge_Benchmark -no-snapshot-save
```

Não executar dois watchers na mesma porta. `init`, `activate`, migrations, rollback e restore têm outras finalidades; não são a rotina de início. Testes SQL, importações e recuperação também têm alvos e pré-condições próprios, documentados na [manutenção técnica](../arquitetura/manutencao.md).

## Se algo falhar

| Sinal | Primeiro passo |
|---|---|
| Porta ocupada | Identificar o processo e seu registro; não encerrar todos os Go/PostgreSQL |
| `apkAtual=false` | Preparar fora de outra geração; conferir se a tela pode ser atualizada sem perder formulário |
| Consentimento Google | Interagir no Android quando necessário; não limpar dados para forçar login |
| Falha de preferência/sessão | Tentar novamente e ler a mensagem; não apagar credenciais por falha de rede |
| Resposta de escrita incerta | Preservar a intenção/chave e consultar o resultado antes de uma nova decisão |
| Prática indisponível/lista vazia | Conferir conteúdo aprovado e dependências; não criar fixture na base entregue |

Os helpers e seus testes são a fonte do comportamento descrito. A documentação não repete instalações, restore, login ou parada real só para atualizar exemplos. O último estado observado e os resultados de cada incremento ficam no [handoff](../execucao/v1/handoff.md).
