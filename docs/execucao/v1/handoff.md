# Handoff vigente — APK0.1.2+3, catálogo/alimentos reais e aceite Google pendente

Atualizado em22/10/2026. Raiz correta: `C:/dev/TrainForge/trainforge`. **Primeiro abrir [avaliação Android](avaliacao-android.md)**: `.\tools\avaliar-android.ps1` inicia o ambiente existente e abre o app. Autor está fora do notebook; não aguardar intervenção para revisão técnica nem tentar senha/2FA/consentimento.

## Trabalho autônomo enquanto autor está fora

**V1-019 concluída para o lote alimentar autorizado.** [Importação real](alimentacao-importacao.md):6369registros (3484Ciqual/2885CoFID),2identidadesdo código13-669excluídas,3basesBTMdesconhecidas mantidas. Preflight6371identidades/1069660células preservado como histórico candidato; revisão específica porfonte e projeção final separadas.

Goimportador verifica operação/atribuição/hash/cabeçalho/estado/decimal/base/grupo, limita paths/tamanhos e grava transacionalmente com idempotência/imutabilidade. Migration00005aditiva aplicada; runtime não pode escrever editorial. Reimportação0novos/6369inalterados. Backupnovo restaurado em DBseparada, comparando contagem/hash de todas as tabelas; alvo removido. Checkpoint anterior mantido sem alegar teste de restore dele. Recibos food-review-verification.json, food-import-fixtures-verification.json e food-import-verification.json.

Permissões são específicas de consulta/composição/escala fiel de dados, sem clínica, dieta, porção caseira ou mídia. Outras20famílias continuam inventariadas sem aprovação porherança. API deconsulta e Flutteralimentar entregues como preparação parcial020/025: busca/fonte/cursor/detalhe/ETag, nomes/colunas originais, nutrientes com estados/bases/créditos, sem cálculo/consumo. SwaggerGo0.3.0 com14operações; APK0.1.2+3. [Consulta alimentar](alimentacao-consulta.md), food-read-verification.json. Migration00006só adiciona índices; backup validado até00005, aplicar00006 após restauração. Não repetir export/import/restore sem mudança concreta.

Próxima dependência funcional éV1-013 antes de020;011ainda exigeGooglemanual. Preparação técnica de contratos/testes pode continuar sem concluir histórias dependentes ou inventar contas/requisitos. Manter gates deaceite e a cobertura completa do produto.

## Estado Git e entregas

O remoto main foi consultado e continuava em `90e746e2cdf35c5ff0788cd3441e269b1748f533`. Os incrementos `1765708` (logs/sessão) e `6d3f3a4` (auth/checkpoint) foram commits locais; os incrementos desta continuação também devem ser locais. Não houve push. A lista de mudanças no VSCode não significa envio ao remoto nem confirmação pendente dos commits já feitos. Nova conferência ls-remote em22/10 manteve90e746e; sempush. Conferir Git real antes da próxima edição.

Etapas01/02 concluídas:73metadados de consulta importados,439excluídos e0prática/instrução/mídia liberadas. V1-014 concluída como leitura de catálogo e019como importação alimentarGo/DB; V1-011 continua doing/completionEvidence vazio. V1-012/021/022 têm preparação parcial, sem fechamento das dependências ou aceite integrado. V1-003 continua transversal/publicação remota pendente.

## Implementação local real

- AppDio registra somente eventos fixos/status/categoria, sem corpos, URL/query/headers ou exceções. Secure storage falho interrompe requisição; sem redirects de credenciais. Rede/timeout/429/5xx preservam sessão;401 confirmado invalida. Compare-and-replace/clear serializados evitam respostas antigas apagarem/restaurarem outra sessão.
- Go usa biblioteca Google oficialv0.24.1: assinaturaRS256, certsGoogle fixos, issuer canônico, audienceWeb explícita, exp/iat/sub e e-mail verificado. IdentidadeGoogle+issuer+sub, nunca associação automática por e-mail. Tokenmalformado/null rejeitado antes do parserSDK. Configuração ausente503; logsSDK descartados.
- Sessão opaca256bits com SHA256 noDB, access15min e refreshmáximo30dias desde login. Migration00004 aplicada, Go único migrador/escritor do novo schema. Refreshsingleuse atômico por família, reuso revoga tambémaccess/vencedorconcorrente; logoutidempotente por dispositivo. Sem dualwrite nem migração de contas legadas.
- Flutter usa contratosGo e chave securestorage distinta do Fastify. AuthController/SessionRepository injetados, restauração com uma consulta de identidade, botões ocupados, cancelamento/configuração/erros seguros e retry de logout correto. Não chama bootstrap/geradoresFastify.
- Biblioteca anônima e autenticada com73metadados reais: busca/filtros/paginação, tipos movimento/programa separados, fontes/autoria/contribuições/licenças/versões/requisitos.0programas permanece vazio. API nega retirada/grant ausente mesmo diante deETag; cache revalidado. Nunca entrega texto instrucional/dose/mídia. [Fechamento014](catalogo-consulta.md).
- Alimentos públicos:6369referências, fontes/atribuição no detalhe, valores exatos, ausência/traço/limite distintos,3bases desconhecidas sem escala.128páginasHTTP conferidas, campos dos detalhes comparados aoDB, nenhuma conta/refeição criada. Testes descartáveis confirmam titularidade/grant/retirada antes deETag. V1-020/025 continuam todo com preparação registrada, completionEvidence vazio.
- APKdebug0.1.2+3 gerado, assinatura e hash conferidos, instalado semuninstall, aberto e inspecionado no AVDAndroid35GooglePlay. [Recibo](android-auth-checkpoint.json) agora representa a mesma build produzida/instalada. Backup/transferência de dadosAndroid excluem arquivos/tokens inclusive transferência entreplataformas; iOS nativo não testado.
- CertificadoRSA3072release local dedicado preservado em.local/android-signing/trainforge-evaluation.p12; android/key.properties ignorado, ACL restrita à contaWindows/SYSTEM após autorização explícita. Gradle recusa fallbackdebug. Não regenerar/rotacionar/apagar/comitar chaves.
- OAuthdebug/Web conferidos por capturas do autor: projeto bootcamp-treinos-ia/975945820703, pacote/SHAdebug coincidem, públicoExternal com3Testusers. ClientOAuthrelease ainda não criado. AvisosGoogledeinatividade sem resolução comprovada. [GuiaOAuth](oauth-android.md).

## Evidência e limites

- Go test/vet passaram.32testesFlutter passaram e analyze semissues; cobrem logs/refresh, controllerauth, respostas antigas, estadosvazios, retirada, linksHTTPS e layout320x568 comtexto2x. Leitor de tela físico e iOS não validados.
- [CatálogoSQL/HTTP](catalog-read-verification.json): DBfixture descartável removida, filtros/cursor/versões/retirada/ETag e sem escritaeditorialruntime; loteHTTP real exatamente73IDs, atribuições/condições presentes, zero prática/programas, hash/contagemsemalteração.
- [Authtransacional](auth-local-verification.json): identidade/concorrência/rotação/reuso/expiração/logout em DBtemporária; nenhuma fixture entregue. [HTTPatual](auth-http-verification.json): ready200/me401/Googleinválido401/refreshinválido401/logout204, Swagger11operações nesse recibo histórico; estado atual14operações comprovado por food-read-verification.json.
- Inspeção visual da biblioteca e detalhe no emulador confirmou autoria/licença e consulta explícita. Capturas públicas ficam ignoradas em.local, sem conta/e-mail/tokens. Nenhum link de fornecedor foi aberto pelo agente.
- GraphifyFlutter atualizado apenasporAST:55arquivos,705nós/901arestas;7arquivos na primeira passagem alimentar, depois só os ajustes efetivos; HTMLexportado. Sem extraçãosemântica/reclusterização; backups em.local/graphify-backup-20261022*.
- LoginGoogle **real ainda não validado**; fixture/negativosHTTP/APKaberto não encerram011. Nenhum usuário foi inventado. Prática, adesões, atividade/histórico, cadastro alimentar/consumo, HTTPSrelease, infraestrutura e iOS seguem pendentes.

## Próximo passo do autor e do agente

1. Autor retorna ao notebook e executa o comando do [guia](avaliacao-android.md); biblioteca e alimentos independem deGoogle.
2. Autor faz entradaGoogle pessoalmente numa Testuser. Não capturar tela de senha/logcatintegral; confirmar tela Conta conectada, GETme200 e somente relações/contagens/hash noDB, sem exporidentidade. Depois reabertura/rede/refresh/logout/reentrada reais.
3. Autor cria clienteAndroidrelease separado com pacote com.example.trainforge e SHA1 `24:EF:27:3C:82:50:DC:FE:15:8A:E6:45:42:BA:8D:D4:0F:02:17:6D`. Debug pode ser validado antes. HTTPS/testerelease são gates próprios; não publicar para contorná-los.
4. Só fechar011/012quando critérios reais passarem. Avançar próximas histórias pelas dependências;014não libera016sem instrução/mídia revisada nem022sem015/021. Preservar todos os públicos/ambientes e lacunas da [matriz](matriz-cenarios.md).
5. Celular vem depois, com serialADB explícito, depuraçãoUSB e instalação sem apagar dados. ProdutoAndroid+iOS, não reduzir escopo à plataforma desta máquina.

## Ambiente e operação

Helper `tools/avaliar-android.ps1`: start/prepare/status/stop. Reutiliza instalações/AVD/banco, confere source/config/APKhash e certificado, recusa porta desconhecida, não executa migrations/import/reset. Estado/pids/stopfiles locais são ignorados; parada confere clone/stopfile/AVD/bootID e encerra só recursos iniciados por ele. API/emulador/cluster foram parados ao fim da consulta alimentar; dados/credenciais/APK preservados. Resultado da partida/parada final em [recibooperacional](android-environment-verification.json).

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

[Registroúnico deopções](../../conteudo/opcoes-apis-exercicios.md): gratuitasprimeiro, eventualcompraúnicaatéR$400depende da decisão doautor. Semnova pesquisaampla, integração paga, compra, contatoexterno, push, deploy oupublicação.
