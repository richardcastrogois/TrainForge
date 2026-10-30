# Guia do projeto

Raiz:C:/dev/TrainForge/trainforge. O app usaFlutter; a API e o catálogo usamGo; os dados persistentes ficam no PostgreSQL local isolado. Fastify/Prisma são referências históricas, não serviços necessários para iniciar o sistema atual.

[Guia de aprendizado](docs/aprendizado/README.md) → [Operação e logs](docs/aprendizado/operacao-local.md) → [Diagramas](docs/diagramas/README.md).

NoPowerShell do VSCode:

~~~powershell
Set-Location C:/dev/TrainForge/trainforge
$tfPython = 'C:/Users/richa/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $tfPython tools/ambiente.py status
& $tfPython tools/ambiente.py start
~~~

Salve/cancele formulários antes de parar:

~~~powershell
& $tfPython tools/ambiente.py plan-stop
& $tfPython tools/ambiente.py stop
~~~

Esses comandos reutilizam a configuração existente. Não usar init, activate, wipe ou restore para abrir o app. Consulte o[guia completo](docs/aprendizado/operacao-local.md) para os efeitos, logs, cada serviço, modo de desenvolvimento e erros comuns.

[Handoff](docs/execucao/v1/handoff.md) é o estado vigente; [backlog](docs/execucao/v1/backlog.json) governa o que falta. Para entender por que há tantas pastas, veja[peças do projeto](docs/aprendizado/pecas-do-projeto.md).
