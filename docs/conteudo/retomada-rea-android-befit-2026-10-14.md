# Retomada rápida: REA, emulador Android e BeFit

**Atualizacao04:** [BeFit observado e decisao sobre os treinos](evidencias/2026-10-14/befit-fluxos-treinos-04/relatorio.md). O usuario rejeitou contato com BeFit. O agente abriu o app e observou apresentacao e primeira pergunta; aguarda decisao sobre Termos/Privacidade e perfil ficticio antes de continuar. Biblioteca/player ainda nao testados. Tese ReViEEW conferida em24paginas visuais eSI2: grade24, nove fichas/27variantes e partes da sessao localizadas; cotejo/direitos finais pendentes. O texto abaixo preserva o checkpoint03 anterior a abertura. N15-C aberta/N21 retida; sem app/Figma/banco.

Estado em14/10/2026. [Relatório/evidências desta etapa](evidencias/2026-10-14/befit-android-validado-03/relatorio.md). Este documento substitui o status de instalação dos relatórios01/02, preservando seus diagnósticos históricos.

## O que está pronto

- REA6.5.0 instalado em C:/dev/rea-tools; registro Codex, skill correspondente e REA_ADB_PATH aplicados.
- Conexão real pelo agente validada, além do teste stdio externo anterior.
- SDK/ADB/Emulator existentes reutilizados; Command-Line Tools22.0 instaladas com ZIP oficial/hash conferido.
- AVD TrainForge_Benchmark (Pixel5/Android15/API35/Google Play) criado e validado em launcher/Configurações.
- Login Google Play feito manualmente pelo usuário.
- BeFit app.befit1.1.37/code141 instalado pela Google Play; não aberto ou automatizado pelo agente.

Android SDK/ADB/Emulator serão reutilizáveis para desenvolver/testar o TrainForge Flutter. REA é adicional de pesquisa e não dependência do app. Não foi instalado Android Studio, Appium, JADX ou extensão nova de VS Code.

## Quando voltar ao notebook

Se a janela do celular virtual estiver aberta, ela deve estar na página BeFit da Play Store. Confira **BeFit: Gym & Home Workout Plan**, **3APPS SOLUTIONS**, e clique manualmente **Open/Abrir** somente se quiser seguir com uso normal permitido. Instalação não comprova startup/biblioteca liberada.

Se houver termos/permissões, leia e decida. Não iniciar assinatura/trial para liberar a pesquisa automaticamente. Se exigir login BeFit, faça-o pessoalmente apenas se optar por isso; não envie senha/código ao chat. Se houver incompatibilidade/proteção/premium, registrar o ponto e continuar pesquisa independente, sem contorno.

Para pesquisar origem: procure manualmente **About/Sobre**, **Help/Ajuda**, **Credits/Créditos**, detalhes de autoria e links oficiais, caso essas entradas existam. Esses nomes são alvos de procura, não menus BeFit já observados. Traga nomes/links/créditos, sem transcrever ou copiar biblioteca. A seguir separar movimento, instrução, vídeo e programa completo; autoria da equipe ou nome de CDN/CMS não comprova fornecedor de cada ativo.

## Abrir o emulador novamente

No VS Code: **Terminal > New Terminal/Novo Terminal**, selecionar PowerShell. Ou **Iniciar > PowerShell**. Nenhuma extensão necessária.

Se o AVD já estiver aberto, use a janela existente. Caso esteja fechado:

```powershell
Start-Process -FilePath 'C:\Users\richa\AppData\Local\Android\Sdk\emulator\emulator.exe' -ArgumentList @('-avd','TrainForge_Benchmark','-memory','2048','-cores','2','-no-snapshot','-no-boot-anim','-gpu','auto') -WindowStyle Normal
```

É o comando de lançamento usado no teste; futuras execuções podem depender do estado atual do Windows. Não apagar dados nem criar outro AVD para recuperar este.

Conferência rápida:

```powershell
& 'C:\Users\richa\AppData\Local\Android\Sdk\platform-tools\adb.exe' devices -l
```

Use o serial realmente listado. No teste desta etapa foi emulator-5554; ele pode mudar. Antes de operar, confirmar nome:

```powershell
& 'C:\Users\richa\AppData\Local\Android\Sdk\platform-tools\adb.exe' -s 'SERIAL_OBSERVADO' emu avd name
& 'C:\Users\richa\AppData\Local\Android\Sdk\platform-tools\adb.exe' -s 'SERIAL_OBSERVADO' shell getprop sys.boot_completed
```

Troque SERIAL_OBSERVADO pelo valor real. Nome esperado TrainForge_Benchmark; boot esperado1. Em offline/erro, guardar a linha final e o log do boot; não reinstalar tudo.

## REA no Codex

Depois de reabrir o Codex, o agente deve encontrar ferramentas mcp__rea e executar inspect_adb_client. Não rodar setup de novo quando o registro estiver alinhado. Caminho de registro: C:/Users/richa/.codex/config.toml; backup: config.toml.rea.backup; skill: C:/Users/richa/.agents/skills/reverse-engineer-anything.

Diagnóstico pontual, somente se houver falha real:

```powershell
& 'C:\nvm4w\nodejs\node.exe' 'C:\dev\rea-tools\node_modules\rea-agents\scripts\rea.mjs' doctor --client codex --json
```

Doctor não prova conexão do chat. Provedores Ghidra/IDA/JADX ausentes não impedem REA/ADB. REA pode inspecionar/capturar e iniciar apps/atividades; não presumir controle genérico de cliques/digitação. Appium só entra com necessidade concreta e permissão do alvo.

## O que continua pendente

1. **Origem do conteúdo:** fornecedor externo ainda não comprovado; zero vídeos/programas integrais recebidos ou licenciados. Ler matriz do relatório01/03; não repetir busca ampla sem pista nova.
2. **Permissões BeFit:** termos vedam automação/extração/engenharia reversa. Instalação/conta não concedem autorização técnica ou direitos de reutilização. Observação manual permitida e fonte pública nova podem avançar; eventual contato precisa de autorização específica. Rascunho oficial não enviado no relatório01.
3. **Fluxos/Figma:** zero testes runtime BeFit pelo agente. Marketing não comprova funcionamento. Depois de uso permitido, comparar com docs/design/fluxos-v04.md e ajustes-visao-integrada.md, propondo experiência própria.
4. **Conteúdo TrainForge:** manter autoria profissional, adequação, instrução fiel, supervisão exigida e direitos por ativo. Cuidadores para si, idosos, casa e praça continuam recortes próprios. N15-C parcial e N21 retida; nada publicado/liberado por esta instalação.

Nenhum código, banco, Figma, fila, commit ou push alterado. Capturas/APK não foram publicados; capturas de teste permanecem locais, e os registros raw estão ignorados pelo Git. Não capturar senha/códigos nem ler credenciais de conta em diagnóstico.
