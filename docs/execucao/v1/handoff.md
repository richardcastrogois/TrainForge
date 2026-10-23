# Handoff vigente — APK0.1.3+4, catálogo/alimentos reais e login Google debug e privacidade validados; gates release pendentes

Atualizado em23/10/2026. Raiz correta: `C:/dev/TrainForge/trainforge`. **Primeiro abrir [avaliação Android](avaliacao-android.md)**: `.\tools\avaliar-android.ps1` inicia o ambiente existente e abre o app. Autor retornou ao notebook e fez loginGoogle consentido. Não automatizar senha/2FA/consentimento. Reentrada na mesma conta e exclusãoTrainForge explicitamente autorizada foram concluídas. ContaGoogle preservada, app reaberto naentrada; catálogos preservados.

## Validação consentida em23/10 — estado mais recente

LoginGoogle real Androiddebug concluído pessoalmente pelo autor. Uma identidadeGoogle canônica persistida, GETme200 e conta conectada; nenhum e-mail/token/subject registrado nas evidências. Reabertura preservou sessão. Falha temporária somente noADB reverse8082 preservou conta e contagens; mapping restaurado emfinally, reconexão200.

Access expirou naturalmente, sem alterarDB: consulta401→refresh→retry200, consumo de refresh0→1 e mesma identidade, acesso renovado válido. Logout pelo botão retornou204 e tela deentrada,0famílias/acessos ativos. Autor reentrou pessoalmente, mesma identidade/1usuário e nova família, sem duplicar conta.

Exportação no app: Conta/Sessões próprias,semcredenciais; seis demais seções vazias com200. Clipboard não usado, exportação/XML bruto não retidos. Titular autorizou explicitamente excluir somente a contaTrainForge deavaliação. Fluxo normal daUI executado após verificar mesmaidentidade: leitura dos limites, intenção temporária, frase exata, DELETE200 e confirmação.0contas/famílias/access/refresh/intenções/dados privados na base corrente,1registro mínimoUUID/data correspondente ao titular. ContaGoogle não alterada.73metadados/6369alimentos e hashes das linhas editoriais preservados.

App reaberto naentrada sem requisição deautenticação, evidenciando limpeza/retomada sem conta residual. [Recibo real](auth-real-android-verification.json). API/emulador/DB permanecem ativos para o autor; recibo deparada anterior é histórico. Nenhuma mudança de código/APK/Graphify ou nova fixture necessária. Gate restante: HTTPS/testeAPKrelease e validações próprias de plataforma; não fechar011/013 nem iniciar outraV1 indevidamente.

CadastroOAuthrelease confirmado em23/10 por captura doautor, com tipo/pacote/SHA1 correspondentes ao certificado local. [Evidência](oauth-release-verification.json). O clientWeb existente permanece noFlutter/Go; não há troca de configuração necessária. Registro não comprova uso/loginAPKrelease.

## Direção autorizada em23/10

Autor autorizou atualizar Graphify, commitar e enviar os incrementos validados aoGitHub; essa autorização substitui a restrição anterior a push. Deploy/compra/contato externo continuam sem autorização. Graphify reconferido:0alterados/55inalterados,705nós/901arestas; artefatos já atuais, sem reindexação semântica ou instalação.

V1-013 implementada/validada tecnicamente: autorização/titularidade, limites por instância, exportação própria, exclusão confirmada, manutenção limitada e gate de restore, com contratosGo/Flutter. Continua doing: loginGoogle debug real passou; OAuthrelease confirmado; HTTPS/testeAPKrelease ainda pendem; fluxo privado real concluído. Não iniciar outraV1 antes desse aceite. Requisito de escala é objetivo: capacidade de milhões simultâneos não está comprovada sem carga e infraestrutura dimensionada.

## Trabalho autônomo enquanto autor está fora

**V1-019 concluída para o lote alimentar autorizado.** [Importação real](alimentacao-importacao.md):6369registros (3484Ciqual/2885CoFID),2identidadesdo código13-669excluídas,3basesBTMdesconhecidas mantidas. Preflight6371identidades/1069660células preservado como histórico candidato; revisão específica porfonte e projeção final separadas.

Goimportador verifica operação/atribuição/hash/cabeçalho/estado/decimal/base/grupo, limita paths/tamanhos e grava transacionalmente com idempotência/imutabilidade. Migration00005aditiva aplicada; runtime não pode escrever editorial. Reimportação0novos/6369inalterados. Backupnovo restaurado em DBseparada, comparando contagem/hash de todas as tabelas; alvo removido. Checkpoint anterior mantido sem alegar teste de restore dele. Recibos food-review-verification.json, food-import-fixtures-verification.json e food-import-verification.json.

Permissões são específicas de consulta/composição/escala fiel de dados, sem clínica, dieta, porção caseira ou mídia. Outras20famílias continuam inventariadas sem aprovação porherança. API deconsulta e Flutteralimentar entregues como preparação parcial020/025: busca/fonte/cursor/detalhe/ETag, nomes/colunas originais, nutrientes com estados/bases/créditos, sem cálculo/consumo. Consulta alimentar entregue inicialmente emGo0.3.0/14operações; estado atualGo0.4.0/18operações eAPK0.1.3+4. [Consulta alimentar](alimentacao-consulta.md), food-read-verification.json. Migration00006só adiciona índices;00007 adiciona ciclo deprivacidade. Backup alimentar histórico validado até00005; após restore aplicar migrations atuais e gate de exclusões antes de liberar acesso. Não repetir export/import/restore sem mudança concreta.

V1-013 tem implementação independente pronta, com aceite privado real concluído;011/HTTPS e testeAPKrelease ainda pendentes. Não iniciar020 nem outra história funcional antes de concluir esses gates. Manter gates deaceite e a cobertura completa do produto.

## Estado Git e entregas

Push expressamente autorizado em23/10. Os seis commits antes locais e o registro3170c50 foram enviados ao origin/main e oSHAremoto conferido. [CI real bem-sucedida39952064880](https://github.com/richardcastrogois/TrainForge/actions/runs/39952064880); generate e version-generated concluídos, derivados já correspondentes às entradas. V1-003 concluída com [evidência](publicacao-ci-verification.json). Implementação013 publicada em4b922abd32db6c8f7ec806438d1969f49086e44d; [CI01339963554285](https://github.com/richardcastrogois/TrainForge/actions/runs/39963554285) passou (71testesPython,Go/Swagger/Mermaid). Conferir Git real antes de editar. A lista doVSCode por si só não confirma commit/push.

Etapas01/02 concluídas:73metadados de consulta importados,439excluídos e0prática/instrução/mídia liberadas. V1-014 concluída como leitura de catálogo e019como importação alimentarGo/DB; V1-011 continua doing/completionEvidence vazio. V1-012/021/022 têm preparação parcial, sem fechamento das dependências ou aceite integrado. V1-003 concluída quanto aos critérios documentais/remotos.

## Implementação local real

- AppDio registra somente eventos fixos/status/categoria, sem corpos, URL/query/headers ou exceções. Secure storage falho interrompe requisição; sem redirects de credenciais. Rede/timeout/429/5xx preservam sessão;401 confirmado invalida. Compare-and-replace/clear serializados evitam respostas antigas apagarem/restaurarem outra sessão.
- Go usa biblioteca Google oficialv0.24.1: assinaturaRS256, certsGoogle fixos, issuer canônico, audienceWeb explícita, exp/iat/sub e e-mail verificado. IdentidadeGoogle+issuer+sub, nunca associação automática por e-mail. Tokenmalformado/null rejeitado antes do parserSDK. Configuração ausente503; logsSDK descartados.
- Sessão opaca256bits com SHA256 noDB, access15min e refreshmáximo30dias desde login. Migration00004 aplicada, Go único migrador/escritor do novo schema. Refreshsingleuse atômico por família, reuso revoga tambémaccess/vencedorconcorrente; logoutidempotente por dispositivo. Sem dualwrite nem migração de contas legadas.
- Flutter usa contratosGo e chave securestorage distinta do Fastify. AuthController/SessionRepository injetados, restauração com uma consulta de identidade, botões ocupados, cancelamento/configuração/erros seguros e retry de logout correto. Não chama bootstrap/geradoresFastify.
- Biblioteca anônima e autenticada com73metadados reais: busca/filtros/paginação, tipos movimento/programa separados, fontes/autoria/contribuições/licenças/versões/requisitos.0programas permanece vazio. API nega retirada/grant ausente mesmo diante deETag; cache revalidado. Nunca entrega texto instrucional/dose/mídia. [Fechamento014](catalogo-consulta.md).
- Alimentos públicos:6369referências, fontes/atribuição no detalhe, valores exatos, ausência/traço/limite distintos,3bases desconhecidas sem escala.128páginasHTTP conferidas, campos dos detalhes comparados aoDB, nenhuma conta/refeição criada. Testes descartáveis confirmam titularidade/grant/retirada antes deETag. V1-020/025 continuam todo com preparação registrada, completionEvidence vazio.
- APKdebug0.1.3+4 gerado, assinatura e hash conferidos, instalado semuninstall, aberto e inspecionado no AVDAndroid35GooglePlay. [Recibo](android-auth-checkpoint.json) agora representa a mesma build produzida/instalada. Backup/transferência de dadosAndroid excluem arquivos/tokens inclusive transferência entreplataformas; iOS nativo não testado.
- CertificadoRSA3072release local dedicado preservado em.local/android-signing/trainforge-evaluation.p12; android/key.properties ignorado, ACL restrita à contaWindows/SYSTEM após autorização explícita. Gradle recusa fallbackdebug. Não regenerar/rotacionar/apagar/comitar chaves.
- OAuthdebug/Web conferidos por capturas do autor: projeto bootcamp-treinos-ia/975945820703, pacote/SHAdebug coincidem, públicoExternal com3Testusers. ClientOAuthAndroidrelease criado pelo autor e confirmado porprint em23/10; pacote/SHA1 conferem comcertificado local, ver oauth-release-verification.json. AvisosGoogledeinatividade sem resolução comprovada. [GuiaOAuth](oauth-android.md).

## V1-013 — implementação pronta para aceite

[Estado e matriz de acesso](privacidade-013.md). Política pública e ações privadas Go/Flutter, sem leitura porIDdeoutro titular. Exportação paginada por8seções, JSONcopiado exato sem arredondamento; exclusão exige sessãoTrainForge deaté15min (não prova nova senha/MFA), challenge de5min e frase exata. Purge atômico revoga todas as sessões, mantém apenasUUID/data no registro de exclusões e preserva outros titulares/editorial. Cache e limpeza local condicionais impedem resposta antiga apagar outra sessão.

Migration00007 aplicada noDBisolado; runtime segue sem escrita editorial ampla. Fixture descartável validou ownership/cursor, rollback, corrida refresh/delete, nonce/família/expiração/clockDB e privilégios. Backup de fixture antigo foi restaurado em alvo separado:1conta reaparecida→0 após aplicar registro atual, outro titular/editorial preservados, reaplicação idempotente. Alvos/dump descartáveis removidos;0contas criadas/excluídas na base entregue.

Manutenção manual com prévia padrão; wrapper de restore recusa alvo real/ausente/conectado e nunca promove. Backups históricos preservados, sem promessa de expiração automática. Limites por instância:1024conexões/128requisições concorrentes,rate limiter limitado/particionado,proxy explicitamente confiável,timeouts/pool. Não equivale a capacidade medida para milhões. [ProvaSQL/restore](privacy-local-verification.json), [HTTPatual](privacy-http-verification.json).

## Evidência e limites

- Go test/vet passaram.48testesFlutter passaram e analyze semissues; cobrem logs/refresh, controllerauth, respostas antigas, estadosvazios, retirada, linksHTTPS e layout320x568 comtexto2x. Leitor de tela físico e iOS não validados.
- [CatálogoSQL/HTTP](catalog-read-verification.json): DBfixture descartável removida, filtros/cursor/versões/retirada/ETag e sem escritaeditorialruntime; loteHTTP real exatamente73IDs, atribuições/condições presentes, zero prática/programas, hash/contagemsemalteração.
- [Authtransacional](auth-local-verification.json): identidade/concorrência/rotação/reuso/expiração/logout em DBtemporária; nenhuma fixture entregue. [HTTPatual](auth-http-verification.json): ready200/me401/Googleinválido401/refreshinválido401/logout204, Swagger11operações nesse recibo histórico; estado atual18operações/Go0.4.0 comprovado por privacy-http-verification.json.
- Inspeção visual da biblioteca e detalhe no emulador confirmou autoria/licença e consulta explícita. Capturas públicas ficam ignoradas em.local, sem conta/e-mail/tokens. Nenhum link de fornecedor foi aberto pelo agente.
- GraphifyFlutter atualizado apenasporAST:59arquivos,783nós/1001arestas;7arquivos novos/alterados de013/auth, HTMLexportado. Sem extraçãosemântica/reclusterização; backup em.local/graphify-backup-20261023-privacy.
- LoginGoogle real **Androiddebug validado em23/10**; release/HTTPS seguem sem validação, portanto011 não foi encerrada. Nenhum usuário foi inventado. Prática, adesões, atividade/histórico, cadastro alimentar/consumo, HTTPSrelease, infraestrutura e iOS seguem pendentes.

## Próximo passo do autor e do agente

1. LoginGoogle debug, sessão/refresh/logout/reentrada e exclusão privados reais passaram; não repetir sem mudança relevante. A contaTrainForge foi excluída por autorização explícita. Entrar novamente criaria uma nova contaTrainForge; Google permanece intacto.
2. CadastroOAuthAndroidrelease confirmado em23/10, pacote com.example.trainforge e SHA1 24:EF:27:3C:82:50:DC:FE:15:8A:E6:45:42:BA:8D:D4:0F:02:17:6D. Não pedir que o autor recrie o cliente. Falta definir proposta de ambienteHTTPS deavaliação; pergunta ao autor sobre hospedagem existente/opção gratuita está pendente, sem autorização de deploy. [GuiaOAuth](oauth-android.md). Debug já validado não comprova release; APIHTTPS/release/iOS continuam gates próprios.
3. Não fazer deploy/criar cobrança/alterar segurança da máquina ou contratar para contornar gates. Após evidência dos critérios/dependências, fechar011/012/013 e só então iniciar próximaV1.
4. Celular vem depois, com serialADB explícito, depuraçãoUSB e instalação preservando dados. Manter Android+iOS e todos os cenários da [matriz](matriz-cenarios.md).

## Ambiente e operação

Helper `tools/avaliar-android.ps1`: start/prepare/status/stop. Reutiliza instalações/AVD/banco, confere source/config/APKhash e certificado, recusa porta desconhecida, não executa migrations/import/reset. Estado/pids/stopfiles locais são ignorados; parada confere clone/stopfile/AVD/bootID e encerra só recursos iniciados por ele. API/emulador/cluster foram parados ao fim da avaliação deprivacidade; dados/credenciais/APK preservados. Resultado da partida/parada final em [recibooperacional](android-environment-verification.json).

Go1.27.3 portátil, Swaggo1.16.6, Flutter3.41.4/Dart3.11.1, PostgreSQL17.5 existentes. url_launcher6.3.3 adicionado para abertura voluntária dos linksHTTPS de atribuição, além da bibliotecaGoogle do incremento anterior. Sem instalaçãoFlutter/AVD ou upgrade amplo. AtualizarpatchPostgreSQL antes de staging/exposição. Binários locais travam no sandbox deste host; fora dele os comandos autorizados funcionam. Não repetir investigação nem testes históricos de restore/import sem mudança que justifique.

```powershell
cd C:\dev\TrainForge\trainforge
.\tools\avaliar-android.ps1
.\tools\avaliar-android.ps1 -Action status
.\tools\avaliar-android.ps1 -Action stop
# Conforme alteração relevante, não repetir tudo sem motivo:
./tools/go-api.ps1 test ./...
./tools/go-api.ps1 vet ./...
python tools/verificar_catalogo_local.py
python tools/gerar_documentacao.py --write --check
python -m unittest discover -s tools -p "test_*.py"
```

[Registroúnico deopções](../../conteudo/opcoes-apis-exercicios.md): gratuitasprimeiro, eventualcompraúnicaatéR$400depende da decisão doautor. Semnova pesquisaampla, integração paga, compra, contatoexterno oudeploy. Commit/push dos incrementos validados autorizados em23/10.
