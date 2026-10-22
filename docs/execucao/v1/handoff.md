# Handoff vigente — encerramento solicitado em22/10/2026

**Ponto exato:** etapas01 e02/M1 concluídas; etapa03/M2 iniciou somente investigação da **V1-011 (autenticaçãoGoogle)**. Não há handlerGo de login, refresh ou catálogo, integração nova Flutter nem APKV1. O autor pediu encerrar esta rodada, registrar e commitar para o próximo chat; não continuar implementação nesta rodada.

Repositório: `C:/dev/TrainForge/trainforge`. O pai não é repo. Primeiro leia AGENTS, [plano macro](plano-macro.md), [escopo](escopo.md), [decisões do piloto](decisoes-piloto.md), [backlog](backlog.md) e os fechamentos abaixo. Atualização por IA exige evidência, sem marcar capacidade planejada como entregue.

## O que já foi feito

- **[Etapa01 encerrada](etapa-01-fechamento.md):** triagem dos512ativos completa;73metadados de consulta,439excluídos;0instruções/mídias/prática. DecisãoGo/fronteira documentada. É fechamento de triagem, não homologação clínica. N01–N46 permanecem encerradas nos seus recortes; não reabrir pesquisas por causa dessas exclusões.
- **[Etapa02/M1 concluída](etapa-02-fechamento.md):** histórias006–010; Go1.27.3portátil, servidor net/http+pgx, config/limites/timeouts/shutdown, duas rotas reais de saúde. Swagger2.0 por comentários/DTOs, recarga geração→build→restart comprovada e geração determinística. Três migrationsGoose aplicadas,73metadados importados e reimportados sem duplicar. Backup/restore real comparou contagens/hash; cinco invariantesSQL verificadas, fixtures revertidas e base temporária removida.
- Commit local da fundação: **`c23ace6 feat: establish isolated Go API foundation and reviewed catalog`**. O commit documental de encerramento seguinte contém estehandoff e o comparativo único deAPIs.
-42testesPython passaram; `go test ./...`, `go vet ./...`, build, Swaggercheck e testes de processoAPI/DB passaram. Evidências: [API conectada](api-connected-verification.json), [DB/restore](database-verification.json), [importação](catalog-import-verification.json). CI preparada, mas sem execução remota/publicação autorizada.

## De onde seguir no próximo chat

**V1-011 está `doing` somente por investigação.** `completionEvidence` permanece vazio. Na retomada autorizada:

1. Revisar [contratos](../../arquitetura/contratos-v1.md) e [camadas](../../arquitetura/camadas-go.md). Implementar validaçãoGoogle com assinatura, issuer, audience explícita, exp e subject; identidade por issuer+sub, sem vincular contas por e-mail. Ausência deOAuth/configuração deve ser estado indisponível, sem token/perfil fictício no runtime.
2. Biblioteca oficial investigada: [cloud.google.com/go/auth/credentials/idtoken v0.24.1](https://docs.cloud.google.com/go/docs/reference/cloud.google.com/go/auth/latest/credentials/idtoken), [fonte](https://github.com/googleapis/google-cloud-go/blob/auth/v0.24.1/auth/credentials/idtoken/validate.go), [regrasGoogle](https://developers.google.com/identity/gsi/web/guides/verify-google-id-token). Fonte verificada: Validate usa as chaves conhecidas e valida audiência quando não vazia/exp; a aplicação ainda precisa verificar issuer/sub. Nenhuma dependênciaGoogle foi mantida emgo.mod: a exploração foi removida para encerrar sem código incompleto.
3. Cliente atual: `lib/features/auth/data/auth_repository.dart` tem serverClientId público no código; sua presença não comprova configuraçãoAndroid debug/release. `auth_api.dart` usa `/mobile-auth/google` e `/mobile-auth/me`, retorno`token`. NovaAPI usa `/api/v1`/`accessToken`: não basta mudarbaseURL. Não houve loginGoogle real/validação doOAuth nesta rodada.
4. **Achado pendente de segurança:** `lib/core/http/app_dio.dart` registra query/body e responsebody; pode imprimir IDtoken/access/refresh e dados pessoais. Corrigir antes do próximo teste de login, mantendo só metadados seguros. `AuthRepository.isAuthenticated` apaga token em qualquer falha degetMe; diferenciar falha de rede de401 na integração. Essas correções foram identificadas, ainda não implementadas.
5. Depois011, seguir012 (rotação singleuse/família/logout/Flutter),013 (ownership/limites/dados),014–016 e021–022 conforme dependências dobacklog. Fixtures isoladas são permitidas em testes; não inserir usuários/treinos/históricos fictícios no DB entregue para aparentar jornada concluída.
6. Conteúdo de prática permanece bloqueado:73metadados não formam programa executável. Manter fonte/autoria/versão/requisitos e estado real poroperação. Não substituir exclusão por instruçãoIA. Disponibilidade de clipes pagos não homologa dose/progressão nem público.

## Estado local ao encerrar

- API/watcher de verificação encerrados; **clusterPostgreSQLV1 parado de forma segura** em22/10. `.local/pgdata`, credenciais e backup preservados porque serão reutilizados. Nenhuma base/volume legado removido.
- BináriosPostgreSQL17.5 existentes em `C:/Program Files/PostgreSQL/17/bin`, clusterV1localhost15432, DB`trainforge_v1_dev`, schema`trainforge_v1`. Não foi criado serviçoWindows. Serviço/bancos legados não acessados; suas contagens são desconhecidas.17.5 exige atualização de patch antes de staging/exposição externa.
- Go1.27.3 em `.tools/go/bin/go.exe`; caches/Swaggo em `.tools`; segredos/dados/dump em `.local`, todos ignorados. ZIPGo já instalado/verificado foi excluído; toolchain permaneceu. ACL de`.local` restrita ao usuário/SYSTEM. Não copiar segredos aoGit.
- Docker apresentou erro no gerenciadorInference/socket `dockerInference`; substituído pelo banco nativo. Sem reset deDocker/WSL/volumes, mudança devirtualização ou tentativa de apagar osocket.
- Flutter/globalGo/legado não foram trocados. Produto continuaAndroid+iOS; primeiro testeAPK seráAndroid. iOS não testado.

Comandos reproduzíveis usados nesta máquina:

```powershell
Set-Location C:/dev/TrainForge/trainforge
$tfPython = 'C:/Users/richa/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $tfPython tools/db_local.py start
./tools/go-api.ps1 test ./...
./tools/go-api.ps1 vet ./...
& $tfPython -m unittest discover -s tools -p 'test_*.py'
& $tfPython tools/gerar_documentacao.py --write --check
& $tfPython tools/dev_api.py
# API localhost8082; Swagger /docs/index.html. Ctrl+C para API/watcher.
& $tfPython tools/db_local.py stop
```

Helpers adicionais: `migrate_local.py` somente forward; `importar_catalogo_local.py --dry-run`/semflag; `verificar_banco_local.py` testa restore em base separada e exclui só a base que criou. Não reimportar/retestar por hábito se nenhum arquivo/modelo mudou. O smokeAPI é o teste específico da fundação com duas rotas; atualizar suas expectativas deliberadamente quando novos contratos forem implementados, sem falsificar a evidência histórica.

## Opções de conteúdo e orçamento — decisão nova

**[Registro único deAPIs/datasets/mídias](../../conteudo/opcoes-apis-exercicios.md)** incorpora todas as opções anteriores e as novas pistas: free-exercise-db, GymRatDataStash, hasaneyldrm, APINinjas, MuscleWiki, MoveKit e ExerciseAnimatic. Evidência primária/pendências/preços datados separados; nenhuma mídia nova baixada, integração contratada ou fornecedor homologado.

Direção atual: testar primeiro o que temos sem pagar e explorar gratuitas dentro de quotas/licenças. Se faltar, teto de avaliação futura **atéR$400**, preservando preferência por pagamento único; nenhuma compra/assinatura autorizada. O valorUS$19 anterior é histórico. Não pagar nem abrir nova frente ampla de pesquisa agora; aguardar lacunas do teste e direção do autor. Não contactar autores/BeFit/fornecedores.

Documentação de leitura: `docs/arquitetura/README.md`, Markdown/Mermaid sem painel/servidor. Atualizarbacklog/evidências/diário e regenerar derivados a cada história. Não publicar/push/deploy por inferência de commitlocal autorizado.
