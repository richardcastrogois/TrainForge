# Handoff vigente — frontend completo fiel ao Figma

Atualizado em24/10/2026. Raiz **C:/dev/TrainForge/trainforge**. A prioridade mais recente do autor é **ajustar todo o frontend para ficar exatamente igual ao Figma antes de continuar novas funcionalidades**. Ler [plano visual](frontend-fidelidade-figma.md) e [inventário atual](frontend-figma-inventory.json). Não retomar uma nova história debackend por ignorar essa mudança.

## Checkpoint atual — Grafite e lima / rolagem

APKdebug0.2.1+12 instalado,90testesFlutter/analyze0issues. [Ajuste implementado](frontend-dark-scroll.md), [recibo](frontend-dark-scroll-verification.json), [APK atual](android-frontend-checkpoint.json). Autor escolheu terceira proposta e pediu rolagem conforme iOS27: superfícies neutras mais separadas e lima nos destaques; Android sem decoração de esticamento. Física e gesto de atualizar preservados; iOS padrãoFlutter mantido e testado porwidget, sem execução nativa iOS27. Não instalar GSAP/Motion, atualizar SDKs, pedir novoOAuth ou pesquisar novamente para esses ajustes. Figma permanece emquota. Conta/consumo reais preservados, sem novo consumo peloagente. Pontos07–12 continuam fora desta rodada.

Base anterior42bb676431cabe5228fbc82960a35878dd214260 publicada comCI40052687262 bem-sucedida. Conferir Git real para o incremento posterior. Push de incrementos validados continua autorizado; sem deploy.

## Checkpoint visual anterior — 23/10

Pedido mais recente: implementar os pontosfrontend01–06 antes dos07–12. [Etapa e critérios](frontend-etapa-01-06.md), [recibo integrado](frontend-stage01-verification.json), [APK atual](android-frontend-checkpoint.json).

**APKdebug0.2.0+11 instalado,85testesFlutter/analyze0issues.** ÍconeTF/nome/splash nativos, inicialização com preferência antes dasessão e restauração limitada/recuperável, Hoje com datas/semana e resumoGo reais, carregamentos/estados, transições/redução de movimento e tema claro/escuro/sistema persistido noaparelho. Aparência acessível noavatar → Preferências e naentrada semlogin. Preferência separada dascredenciais; nenhuma novaAPI/migration/dado deconsumo.

**Pontos01–06 concluídos no checkpointAndroid, conforme direção confirmada peloautor: marcaTF atual naabertura e dark derivado dessaidentidade.** Implementação e recibo conferidos. Contextos deaberturaA/B e dark completo nãoobtidos antes daquotaStarter; a decisão aprova a adaptação, sem alegar comparação exata dequadros nãoinspecionados. Demaisfamílias07–12 continuam fora destaetapa. iOS somente código/recursos preparados e verificados estruturalmente, sem build/execuçãoXcode.

Conta e1consumo humano real preservados; agente não digitou quantidade nem confirmou consumo. Sem reset nem novo consentimentoGoogle automatizado. Não apagar registro porinferência. Recursos API/banco/emulador locais ativos; autor não quer hospedagem agora.

Publicação anterior: base020 b066082,CI40007081568 passou; visual01 b9660d5a15c4e4b88797278fde75b13b405bddbd,CI40011701056 passou; visual02 49982c3c957212e86dcc6536c42b3baa79c6265f,CI40013327968 passou. Conferir Git real para o incremento01–06 posterior; push autorizado, nenhum deploy.

## Estado entregue

- Etapas01/02 concluídas:73metadados de movimento,439ativos excluídos,0programas/instruções/mídias/prática liberados. Não inventar conteúdo para preencher o visual.
- V1-011/012/013 concluídas no aceite local: GoogleAndroiddebug pessoal, identidade canônica, reabertura, rede sem perda de sessão, expiração natural/refresh, logout/reentrada; exportação e exclusão real explicitamente autorizada passaram. [Fechamento](auth-local-fechamento.md), [aceitehistórico](auth-real-android-verification.json). OAuthdebug/release e Web já conferidos; não pedir recriação declientes ou hospedagem.
- V1-014 concluída: biblioteca pública Go/Flutter com filtros/cursor/detalhe/versões/retirada/ETag e atribuições; somente consulta.
- V1-019 concluída no lote autorizado:6369referênciasCiqual/CoFID,2identidades conflitantes excluídas,3bases desconhecidas preservadas. Import/reimport/backuprestore históricos validados; não repetir coleta/importação/restore sem mudança concreta.
- **V1-020 concluída funcionalmente:** API Go0.5.1/25operações, migration00008, cadastro particular, consumo, histórico do dia/fuso, revisões/exclusão e subtotais rastreáveis. Flutterconectado às APIs. [Implementação](alimentacao-registro.md), [SQL/HTTPdescartável](nutrition-local-verification.json), [consumo real](nutrition-real-android-verification.json).
- Autor confirmou pessoalmente um consumo real e mostrou confirmação/histórico. Conferência só por contagens:1conta/1consumo ativo/0alimentos próprios; nenhum nome/e-mail/quantidade/alimento/horário/token do titular em recibosGit. Agente não criou refeição na base entregue e não está autorizado a apagar esse consumo por inferência.
- Cadastro próprio/ausências/ownership/concorrência/idempotência/edição/exclusão/limite/retirada/exportação/purge testados em banco temporário removido, com uma referência real já pesquisada copiada somente para a fixture. Isso não é novo loginGoogle nem aceite humano de todos os fluxos025.
- APKdebug histórico do020 **0.1.5+8**, gerado e instalado com preservação dos dados após conferir noAndroid a telaMinhaAlimentação,0editores/rascunhos e1registro persistido. A revisão automática bloqueou primeiro por receio de rascunho aberto; a nova conferência comprovou condição segura e a atualização passou. [Buildatual](android-nutrition-checkpoint.json). Reciboandroid-auth-checkpoint.json representa build0.1.3+4 histórica.

## Frontend — trabalho atual

A interface funcional deavaliação anterior **não reproduzia o Figma**. Autor contestou e pediu a mudança de prioridade. Não alegar frontend completo por haver APIs/DTOs ou um tema aplicado.

Figma vivo: arquivo bX6YjBBLIJgoo2MtiFLntl, página **0:1 · 01 · Produto interativo · v0.5**;401quadrostoplevel/398mobile com variantes/rascunhos/exemplos. Páginas126:2 e141:2 são arquivo. Não reaplicar geradoresv0.4 nem editar oFigma sem necessidade.

Leitura de design context com screenshots concluída para:
- Entrar23:735;
- Hoje25:1667;
- Alimentação25:1992;
- Porção104:1233.

Sessão conector be13df9a-20a4-47d5-ba30-e854be04613e, reutilizar enquanto válida. Skillfigma-design-to-code já lida; deve ser incluída em skillNames e screenshot do contexto é referência visual. Pedir novos contextos de famílias/estados, não implementar só de metadados ou dos SVGs históricos.

Checkpoint inicial histórico deidentidade: `lib/core/theme/trainforge_theme.dart` com tokensFigma, marcaTF, superfícies/botões/campos e tipografia inicial; entrada e cabeçalho deconta usam marca. **Fidelidade completa pendente.** O incremento visual01 agora distribuiInter eSVGs, conecta shell/barra inferior e as primeiras composições. Biblioteca/formulários/detalhes/privacidade e demais estados ainda exigem conversão visual; ver o checkpoint atual acima. AuthsóGoogle real; e-mail/Apple não foram simulados.

História021emdoing, com pontosfrontend01–06 concluídos no checkpointAndroid,07–12 ainda abertos; transversal a022/025 e demaisUI. Preservar domínio semWidgets/Dio, repositories/controllerinjetados e sessão coordenada. Não reativar AppShell legado que chamaFastify/geradores ou usa dados antigos. Atualizar inventário de fidelidade por família, com evidência visual por nó e estados320/390/textoampliado. Não marcar todas as variantes como rotas diferentes sem conferência.

## Cuidados do incremento

- Quantidade exige entrada explícita, g/ml e evidência medida/estimativa; cálculoGo usa big.Rat, versão/base/fator, sem densidade ou nutrientes inventados. Fonte/célula/limite originais preservados. Subtotais separados por coluna/método/unidade; ausência não é zero. Até100registros/dia para subtotalcompleto, histórico paginado1–20; acima dolimite não exibe totaltruncado.
- IdempotênciaUUID por titular/operação24h, lock porconta/revalidação desessão, revisãootimista e corpo/chave congelados em resposta incerta. Até100correções; exclusão continua permitida após esse limite. Tombstones/revisões privados até exclusão daconta; exportação/purge013 cobrem tudo.
- Runtime não tem escrita editorial ampla.00008 adiciona funçãoSECURITYDEFINER restrita a declaração particular, sem source_id e sem clínica, mais índice dohistórico. Migrations atuais00001–00008. Nenhuma tabela/coluna privada nova sem inventário013.
- Horários de resposta normalizados emUTC; Flutter exibe horário local e fuso informado separadamente. Cabeçalhos de nutrientes com quebras de linha são normalizados somente naexibição, sem alterar fonte/versão.
- Autor relatou teclado físico/virtual sementrada; campo habilitado/focado aceitou um dígitoADB temporário, removido sem consumo. TecladoAndroid reconectado/listaoriginal restaurada; autor confirmou que tecladonotebook voltou afuncionar. Não limpar app/emulador/contaGoogle para tratar isso. Captura temporária do rascunho deve ser removida, nuncacomitada.
- Dados demonstrativos doFigma não são dados doapp: não copiar calorias/refeições/treinos/doses/histórico/media semdireitos. Preservar idosos/cuidadores/casa/praça/academia e lacunas reais.
- AppDio continua sem URL/header/query/body/exceções emlogs; rede/429/5xx preservam sessão. Header deconta esperada impede formulário antigo ir para conta nova. Não imprimir storage, credenciais, SQLprivado ou XMLUIbruto.

## Verificação e publicação

85testesFlutter passaram nesta etapa, analyze0issues; visual02 histórico tinha70. Go testes/vet e integraçãoSQL/HTTP do020 passaram;76testesPython passaram nesta etapa (71anteriores +5recursos nativos); documentação derivada regenerada e verificada. Swagger é gerado por comentários/tipos, não editarJSON/YAML à mão. Graphify atualizado porASTsomente, HTMLexportado; semindexaçãosemântica dos dossiês.

Push dos incrementos validados aoGitHub autorizado em23/10. Conferir Git real.020/tema/documentação publicados em b066082 comCI40007081568 bem-sucedida; visual01 é o incremento posterior, sem deploy. Remoto https://github.com/richardcastrogois/TrainForge.git. Não fazerforcepush. Scriptsignorados.local/check_auth_stage.py echeck_publish.py verificam segredos/caminhos; stage explícito. Conferir CI doSHAreal, não inferir push peloVSCode.

## Ambiente preservado e comandos

API loopback8082, PostgreSQL17.5 local15432/trainforge_v1_dev e AVDTrainForge_Benchmark/emulator-5554 ativos. Instalações existentes Go1.27.3,Flutter3.41.4/Dart3.11.1,Swaggo1.16.6; não reinstalar/atualizar sem motivo. Credenciais/dados/chaves em.local eandroid/key.properties ignorados/ACL protegida; não regenerar chave release.

```powershell
cd C:\dev\TrainForge\trainforge
.\tools\avaliar-android.ps1 -Action status
# start só se necessário e após conferir ausência de rascunho aberto
.\tools\avaliar-android.ps1
# prepare compila sem substituir o app em uso
.\tools\avaliar-android.ps1 -Action prepare
./tools/go-api.ps1 test ./...
./tools/go-api.ps1 vet ./...
python tools/gerar_documentacao.py --write --check
python -m unittest discover -s tools -p "test_*.py"
```

Binários locais travam no sandbox deste host; comandos autorizados funcionam fora dele. Edições via ferramentaNodefuncionam; não executarADB/Flutter síncronos dentro doNodeREPLsandbox. Usarexec_command com require_escalated quando necessário. Não perder tempo repetindo essa investigação. FerramentasADB deQA devem guardarXMLemmemória, emitir somente allowlists/contagens e apagar o temporário remoto.

Semhospedagem/deploy/contratação/contato externo. Registro[opções deAPIs](../../conteudo/opcoes-apis-exercicios.md):gratuitasprimeiro, eventualcompraúnicaatéR$400depende de decisão específica. ReleaseHTTPS/iOS e capacidade demilhões não validados; não bloqueiam ofrontendlocal nem autorizam inventar cobertura.
