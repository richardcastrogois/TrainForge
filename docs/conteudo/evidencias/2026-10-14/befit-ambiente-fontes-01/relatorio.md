# BeFit e REA: diagnóstico, fontes e plano para aprovação

Data: 14/10/2026, America/Sao_Paulo. Etapa executada: leitura, inventário e pesquisa pública. Instalações e alterações de configuração ainda não aprovadas/aplicadas.

## Resultado desta etapa

O Windows tem CPU/RAM compatíveis e o Emulator confirma WHPX utilizável. SDK, ADB, Emulator e três imagens Google Play já existem. Reutilizá-los evita instalar Android Studio ou baixar imagens novamente. Não há AVD enumerado no ambiente consultado. O bloqueio para criar/iniciar um AVD é espaço: C: tinha 2,6 GiB livres na consulta CIM e 2,35 GiB na consulta posterior. Nenhuma limpeza, remoção ou movimentação foi realizada.

REA não está registrado no config Codex consultado nem disponível como ferramenta nesta sessão. A skill `reverse-engineer-anything` não existe nos dois diretórios pessoais candidatos verificados. A versão npm resolvida é 6.5.0; somente metadados foram recebidos, nenhum tarball executado.

Fornecedor externo de exercícios, instruções, vídeos ou programas BeFit: **não identificado com comprovação**. A informação pública descreve equipe editorial/revisão e catálogo, mas não estabelece a origem de cada ativo ou concede reutilização.

## Ambiente observado

| Componente | Resultado real | Decisão |
| --- | --- | --- |
| Windows | Windows 11 Home Single Language, 64 bits, build 26200 | Usar Windows nativo |
| CPU | Intel i7-13650HX, 14 núcleos/20 processadores lógicos | Compatível em princípio |
| RAM | 31,7 GiB total; 7,7 GiB disponível no instante consultado | Evitar muitas aplicações simultâneas no primeiro boot |
| GPU | NVIDIA RTX 3050 6GB Laptop GPU e Intel UHD Graphics | Modelo identificado; VRAM efetiva não validada pelo campo CIM AdapterRAM |
| Disco | Somente C: como disco local fixo; 2,35 GiB livres na última consulta | Não criar AVD com essa margem |
| Hypervisor | HypervisorPresent=true; `emulator -accel-check` retorna 0/WHPX instalado e utilizável | Sem mudança de BIOS ou recursos Windows prevista |
| Node/npm ativos | Node 24.14.0; npm 11.5.2 | Atendem engines npm REA 6.5.0; não atualizar |
| Registro de Node instalado | Registro Windows anuncia 22.13.1, divergente do executável ativo em C:/nvm4w/nodejs | Usar versão efetivamente executada, não a entrada histórica do registro |
| Java/JDK | java e javac 23.0.2; C:/Program Files/Java/jdk-23 | Reutilizável se necessário; não necessário para REA/ADB básico |
| SDK | C:/Users/richa/AppData/Local/Android/Sdk | Caminho confirmado pelo local.properties e executáveis; não usar LOCALAPPDATA virtualizado do sandbox |
| ADB | 1.0.41 / Platform-Tools 35.0.2-12147458 | Consulta de versão passou; dispositivos ainda não enumerados |
| Emulator | 35.3.11.0, gfxstream | Versão e aceleração passaram; boot ainda não testado |
| Imagens | API 33/rev.9, API 34/rev.14, API 35/rev.9; google_apis_playstore/x86_64 | Propor reutilizar API 35; presença confirmada, integridade/boot ainda pendentes |
| AVD | `-list-avds` não listou nomes; diretório pessoal padrão ausente | Criar um novo dedicado após aprovação e espaço |
| Android CLI Tools | cmdline-tools/tools ausentes no SDK | Instalar somente Command-Line Tools |
| Android Studio | Não encontrado no caminho padrão nem registros de desinstalação consultados | Não necessário no plano mínimo; isso não exclui cópia portátil em outro local |
| VS Code | Presente, registro 1.141.1 | Pode ser terminal; nenhuma extensão proposta |
| REA | Sem seção rea no config consultado; zero ferramentas REA anunciadas ao agente | Instalar/configurar somente cliente Codex |

Os flags CIM de virtualização da CPU vieram false com hypervisor ativo. Isso não demonstra BIOS desativada: o teste operacional do Emulator confirmou WHPX utilizável. Não alterar BIOS por esses flags.

`Get-WindowsOptionalFeature` exigiu elevação administrativa e não retornou estado. Não é necessário repetir ou elevar administrativamente esse comando: o teste de aceleração resolveu a questão prática. A primeira consulta CIM no sandbox falhou por acesso indisponível; seus campos nulos/zeros não são recursos do computador. Nova consulta de leitura fora do sandbox recebeu os dados acima. Um comando inicial tinha erro de sintaxe PowerShell e foi corrigido; não produziu evidência de hardware. Uma sequência de versões no sandbox parou após Node/npm e foi interrompida; Java foi validado por execução separada no host.

## Plano mínimo gratuito para confirmar

### A. REA no Codex

Origem: [repositório oficial](https://github.com/morluto/rea) e [metadados npm 6.5.0](https://registry.npmjs.org/rea-agents/6.5.0). Tarball publicado: `https://registry.npmjs.org/rea-agents/-/rea-agents-6.5.0.tgz`. Licença do pacote: MIT. Tamanho descompactado do pacote principal: 25.564.765 bytes; dependências e cache são adicionais, total ainda não medido. Reservar até 500 MiB como orçamento inicial de trabalho, não estimativa comprovada; parar se ultrapassar.

Integridade publicada npm: `sha512-C6BG7LyrAdR74mSjertM6PrxJkcNZ2bfQNOJornPo9erDEp2tyPRVYPnV5Yodr+1RqewCQla68WulXlVnveD+A==`. Ainda não comparada a tarball local.

Caminhos propostos, fora da pasta do app/repositório:

- Pacote: `C:/dev/rea-tools/node_modules/rea-agents`.
- Cache dedicado: `C:/dev/rea-tools/npm-cache`.
- Config existente a preservar: `C:/Users/richa/.codex/config.toml`.
- Skill correspondente: destino pessoal exato a conferir no dry-run, dentre os roots Codex/shared aplicáveis; não presumir localização antes da prévia.

Efeitos: baixar/executar pacote de terceiro, criar pasta de ferramentas/cache, posteriormente adicionar servidor stdio REA e skill pessoal ao cliente Codex. A configuração pessoal pode disponibilizar REA em outros chats Codex. Preservar outros servidores e backups. O npm declara `frida` como dependência opcional: usar `--omit=optional` para não instalar essa dependência. Não instalar provedores nativos extras nesta etapa.

Comandos propostos, **ainda não executados**:

```powershell
npm install --prefix C:\dev\rea-tools --cache C:\dev\rea-tools\npm-cache --omit=optional --save-exact rea-agents@6.5.0
& 'C:\nvm4w\nodejs\node.exe' 'C:\dev\rea-tools\node_modules\rea-agents\scripts\rea.mjs' setup --client codex --dry-run --json
```

A aprovação do download/dry-run não aplica automaticamente mudanças fora dos caminhos e efeitos apresentados. Conferir a prévia real; apresentar qualquer diferença relevante antes de aplicar. Se aprovado o registro apresentado, usar o mesmo launcher/versão para setup do cliente Codex e `doctor --client codex --json`. Configurar `REA_ADB_PATH=C:/Users/richa/AppData/Local/Android/Sdk/platform-tools/adb.exe` no ambiente do servidor MCP. Não alterar PATH global. Não registrar VS Code como segundo cliente.

Reconectar/reabrir o Codex conforme instrução do setup, com intervenção do usuário. Aceite: ferramentas efetivamente anunciadas nesta sessão e chamada real a `inspect_adb_client` retornando o ADB confirmado. Doctor e skill isolados não fecham a etapa. Usar os schemas reais do servidor, não parâmetros supostos de main. [Setup e limites](https://github.com/morluto/rea/blob/main/docs/installation.md).

### B. Android CLI e um AVD

Propor executar somente depois de haver pelo menos **12 GiB livres** em C:. Esse é um gate conservador deste plano, considerando AVD novo, arquivos de dados e margem do Windows; não é requisito oficial fixo para essa combinação. Se optar por Android Studio completo, a documentação oficial indica 16 GB de espaço mínimo para Studio+Emulator e 32 GB recomendados. [Requisitos oficiais](https://developer.android.com/studio/install).

Download: [Android Command-Line Tools, Windows](https://developer.android.com/studio#command-tools), `commandlinetools-win-15859902_latest.zip`, tamanho anunciado 155,7 MB. SHA256 publicado: `90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a`. Não baixado nem hash local conferido.

Destino do ZIP proposto: `C:/dev/rea-tools/downloads/`; extrair para `C:/Users/richa/AppData/Local/Android/Sdk/cmdline-tools/15859902/`, sem sobrescrever SDK existente. O identificador da pasta é uma escolha local para o pacote de build 15859902; não comprova revisão sdkmanager. Confirmar a revisão em source.properties após extração.

Efeitos: cerca de 156 MB de download e tamanho extraído a medir; acrescenta sdkmanager/avdmanager. Não atualizar todos os pacotes. Reutilizar ADB, Emulator e imagem API35 já instalados. Se avdmanager pedir download inesperado, parar e esclarecer compatibilidade/integridade; não reinstalar toda a pilha.

Intervenção de termos, quando chegar à etapa aprovada: abrir página oficial > descer até **Command line tools only** > clicar **commandlinetools-win-15859902_latest.zip** > ler contrato > usuário decidir sobre **I have read and agree...** > clicar **Download Android Command Line Tools for Windows**. Não aceitar termos por conta do usuário ou responder `y` em lote a licenças. Nada disso foi clicado nesta etapa.

AVD proposto: `TrainForge_Benchmark`, imagem `system-images;android-35;google_apis_playstore;x86_64`, perfil Phone/Pixel compatível obtido da lista real de avdmanager. Destino dedicado: `C:/dev/rea-tools/avd/TrainForge_Benchmark.avd`. Começar com 2 núcleos e 2 GiB RAM; ajustar somente após observar boot/desempenho. Dados do AVD ocuparão espaço adicional; não mover/apagar imagens existentes. Compatibilidade específica do BeFit será decidida pela Play Store/execução real, não presumida pela ABI do host.

Aceite: serial real em `adb devices -l`, estado device, `sys.boot_completed=1`, launcher efetivamente visto e captura real com dimensões. Esperas de boot serão limitadas; persistir log mínimo e ponto de falha. Não iniciar AVD com os atuais 2,35 GiB livres. Nenhuma limpeza automática incluída no plano.

### C. Teste permitido antes do BeFit

Primeiro alvo: o AVD novo sem contas pessoais e suas telas de launcher/Configurações Android. Exercitar identificação do dispositivo, display/window e screenshot; observar abertura/retorno manual. Não envolve desmontar BeFit, biblioteca ou contas de terceiros. Se for necessário testar instalação de um APK de exemplo, selecionar uma release oficial do [ApiDemos](https://github.com/appium/android-apidemos), conferir hash/manifest/assinatura e licenças antes de instalar; [licença declarada Apache 2.0](https://github.com/appium/android-apidemos/blob/master/LICENSE). APK não escolhido/baixado nesta etapa.

REA não é controlador genérico de taps/digitação. O guia ADB documenta inspeção/captura e lançamento de apps/atividades, além de operações que modificam o dispositivo; usar apenas o subconjunto necessário. Avaliar Appium/UiAutomator2 só se teste de UI automatizado autorizado trouxer necessidade concreta. Não instalado nem necessário para o teste inicial manual. [REA/ADB](https://github.com/morluto/rea/blob/main/docs/adb-device-analysis.md).

## BeFit: fontes, conteúdo e direitos

As evidências abaixo são **leituras web**, sem corpos locais/recibos HTTP/hash de fontes. Não foram obtidos vídeos, APK ou programa completo. Busca pública focada em créditos/fornecedores não trouxe vínculo externo comprovado; nenhuma coleta automática de acervo ou API privada foi feita.

| Camada | Fonte e evidência | Autoria/origem | Direitos/custo | Utilidade e pendência |
| --- | --- | --- | --- | --- |
| Movimentos | [Biblioteca pública](https://appbefit.com/exercises/), seções de filtros/tabelas: nomes, grupos musculares, ambientes, níveis e equipamentos | Equipe indicada pela marca; origem individual não declarada nessa página | Consulta pública não é licença de importação | Referência de classificação; não aprovar conteúdo/cobertura cuidador/idoso/praça |
| Instruções | Mesma página descreve guias de execução e oferece orientação editorial geral | [Experts](https://appbefit.com/experts/) identifica Antonio Brandão e Ednardo Ribeiro; Ednardo é descrito como revisor do algoritmo/conteúdo | Qualificações são declarações da empresa, não consulta a registro; direitos por texto pendentes | Não atribuir cada guia a esses autores sem crédito específico; guia editorial não substitui programa completo |
| Vídeos/mídia | Biblioteca anuncia vídeo por exercício; tentativa de abrir o link público Push-Ups falhou na ferramenta web | Produtor, filmagem/animação e licenciante não identificados | Nenhuma licença ou preço de reutilização encontrado; termos restringem cópia | Nenhum vídeo efetivamente observado ou recebido; não concluir fornecedor pelo estilo/CDN/CMS |
| Programas completos | [Special Workouts Library](https://appbefit.com/special-workouts-library/) distingue planos contínuos de sessões avulsas; [Play Store](https://play.google.com/store/apps/details?id=app.befit) anuncia biblioteca e personalização | Curadoria/equipe anunciadas; fornecedor externo e autoria por programa não identificados | Loja descreve acesso integral ligado à assinatura; preço local não consultado; nenhum trial/pagamento iniciado | Nenhuma sequência integral, progressão ou instrução de programa recebida; anunciar catálogo não prova acervo importável |

A página Experts atribui produção a uma equipe. Essa declaração não demonstra que todos os ativos sejam produzidos internamente, que não existam fornecedores, ou que a mesma licença cubra todos os materiais. Os termos 10.1 reivindicam direitos, mas titularidade declarada também não prova cadeia de produção/licenciamento. Não há comprovação de uso de wger, Gym Visual ou MuscleWiki pelo BeFit.

[Termos BeFit](https://appbefit.com/terms/) relidos: 7.3 restringe bots/acesso/extração automatizada e 10.3 restringe engenharia reversa e cópia. A preparação REA não autoriza aplicar essas operações ao app. Até esclarecer permissão/base legítima: sem decompilação, instrumentação, interceptação, exportação de APK/acervo ou automação do BeFit. Testes normais manuais limitados ao acesso autorizado, sem contornar premium/login/integridade/emulador.

Distribuição legítima localizada: página oficial Google Play para `app.befit`, também ligada pelo site. Nenhum APK foi instalado. Depois dos gates, usuário fará eventual login da loja e decidirá termos/permissões; não criar conta, conceder todas as permissões ou iniciar trial automaticamente. Se Play Store não disponibilizar o app para o AVD, registrar incompatibilidade; não recorrer a APK modificado/espelho como contorno.

### Alternativas: sem vínculo demonstrado com BeFit

wger já tem amostras locais e registro EX01 em `docs/conteudo/fontes.json`, datado 23/09. Reutilizar esse corpus, sem nova coleta: exercício/tradução/mídia têm direitos próprios e não são programas completos aprovados. Consulta web atual ao site da API retornou desafio Anubis; não repetida/contornada. MuscleWiki EX06 estava incompatível com custo zero no registro local de 23/09; preços/direitos atuais não revalidados, portanto não recomendada aquisição. Página de licença Gym Visual tentada não foi acessível; nenhum preço/grant/material confirmado. Essas referências não são fornecedores descobertos do BeFit.

### Próxima pista e critério de parada

Encerrar novas buscas amplas dessa rodada. Retomar somente com crédito real observado no acesso permitido, documento público novo ou resposta oficial. Uma resposta é necessária para esclarecer se os ativos são próprios/licenciados e se há fonte pública ou cessão gratuita compatível com TrainForge.

Contato oficial encontrado na Play Store: `contact@appbefit.com`. Rascunho para revisão, **não enviado**:

> Olá, equipe BeFit. Estamos pesquisando fontes de conteúdo para o projeto TrainForge e não pretendemos copiar o acervo do BeFit. Poderiam esclarecer se os movimentos, instruções, vídeos e programas da biblioteca são produzidos pela 3APPS ou licenciados de terceiros? Se houver fornecedores ou materiais públicos, podem indicar seus nomes e páginas oficiais? Existe conteúdo com permissão gratuita para uso em outro aplicativo, incluindo português e consulta offline? Também gostaríamos de saber quais formas de observação manual em emulador e pesquisa técnica vocês autorizam, sem extração, cópia ou contorno de restrições. Obrigado.

Enviar requer autorização específica para esse destinatário/texto. Permissões Gmail anteriores para CG02/03/05 não se aplicam. Nenhum contato enviado, conta criada ou monitoramento agendado.

## Fluxos e preservação do projeto

Zero fluxos runtime BeFit observados. Marketing de biblioteca/histórico não é teste. Quando acesso manual permitido existir, casos: escolher plano/sessão, entender exercício, iniciar/pausar/retomar e consultar histórico, cada um com pré-condição, passos, observado e limite. Comparar então com `docs/design/fluxos-v04.md` e `ajustes-visao-integrada.md`, propondo solução própria. Não há proposta baseada em runtime nesta etapa.

Cuidadores para si, idosos, casa e praça permanecem requisitos distintos. BeFit geral não os comprova e também não prova ausência dessas categorias. Não alterar dose/variante/supervisão, transferir efeito de programa a gesto ou preencher autoria/direitos por IA.

Fila relida: activeItem CG-02, activeQuestion CG02-MATERIAL, oito perguntas pendentes; somente CG-01 consta em closedItems da sequência executável. N15-C parcial, N21 retida. Nenhuma fila foi alterada.

Graphify consultado localmente: 470 nós/607 arestas; vizinhança de workout_day_detail localizada. Não contém evidência de origem BeFit/REA. Conferência final pela API local `detect_incremental(Path("lib"))`: 0 novos/alterados, 42 inalterados, 0 removidos, 0 erros de caminhada. Saídas preservadas; nenhuma extração semântica/reindexação de documentos ou referências. JSON ambiente.json validado por ConvertFrom-Json; flags de instalação/conexão/boot/BeFit permanecem pendentes ou false, coerentes com a etapa. Mudanças locais preexistentes preservadas; 17 arquivos rastreados modificados antes deste relatório. Este incremento acrescenta apenas relatório e resumo JSON nesta pasta. Sem código/Figma/banco/config global Git/commit/push.

## Entrega por etapa

| Etapa | Estado em 14/10 | Gate restante |
| --- | --- | --- |
| Diagnóstico | Concluído com limites explicitados | Espaço para AVD |
| Ambiente instalado | SDK/ADB/Emulator/JDK/Node preexistentes e parcialmente verificados | Aprovar somente ferramentas faltantes |
| REA/MCP | Ausente; versão publicada identificada | Download/dry-run aprovado, configuração revisada e conexão real |
| Emulador | Executável/aceleração verificados; AVD/boot não testados | Espaço, aprovação, criação e tela observada |
| Teste permitido | Planejado; zero testes de dispositivo realizados | Executar em AVD dedicado primeiro |
| BeFit | Distribuição legítima localizada; app não executado | Acesso da loja e permissões; sem contorno |
| Conteúdo encontrado | Informação editorial/metadados públicos; zero vídeos ou programas completos recebidos | Fonte externa ainda não identificada |
| Fluxos/Figma | Zero observações runtime; nenhuma edição | Observação manual permitida e comparação posterior |

Confirmação solicitada ao usuário: escolher aprovação A (REA/download e prévia), B (CLI/AVD após espaço e termos), ou ambas. Aplicação do registro MCP somente dentro da prévia revisada/aprovada. Limpeza de disco, aceites de termos, contato com BeFit e automação/engenharia reversa não estão incluídos automaticamente.
