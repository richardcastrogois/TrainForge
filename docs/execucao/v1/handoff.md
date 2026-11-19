# Handoff vigente — TrainForge

Atualizado em **18/11/2026, 23:35 BRT** (Claude assumiu a frente alimentar após o Codex parar, a pedido do autor). Checkout `C:/dev/TrainForge/trainforge`. Ponto de retomada da alimentação offline; implementação autorizada, sem refinamentos novos.

[Registro por etapa](food-offline-progress.json): atualizar ao terminar cada etapa. Nenhum worker ou observador ativo: 53824, 70624, 77620 e 68876 terminaram.

## Fluxo atual pedido pelo autor

**Finalizar alimentação sem buildAPK agora e sem commitar ajustes de inicialização/intro/logo/splash/ícones.** Build e testes Android conjuntos ficam para depois. Commit alimentar, quando houver, por paths/hunks próprios, nunca `git add .`. HEAD continua aa0142d.

## Ponto exato

**V1-019.** Concluído e verificado em 18–19/11:

- Compactação estrutural (`tools/food_catalog_compact.py`): 8.820.420.608 bytes, SHA `fa60453e…f7f6da`, 6.702.350 foods com hash de células idêntico, 6.340.572 barcodes, FK ok, 14 fontes. Versão de conteúdo inalterada `042e99d9…98c0562`.
- Pacote assinado: `assets/food_catalog/catalog.sqlite.gz` **3.231.875.230 bytes**, artefato `08abd86fa9abd2d4e3e92d326c5f6bf398c334613aebaae272d3678b9503207c`; `compact_bundle_verified` e `python tools/food_catalog_build.py --verify` exit0. `distribution/catalog-update.zip` (ZIP32 STORED, só manifesto+gzip, testzip ok).
- Exports: verificação Go `--operation verify` aprovada (6.702.350 linhas, 0 gravações) após corrigir só validadores de catálogo para 84 linhas OFF reais (controles C0/C1 e U+0000 em nomes, nome 1.141 runas, rótulo 380, quantidades 95/169 caracteres). Entrada pessoal continua estrita; porções longas não são selecionáveis. Staging Postgres troca U+0000 por U+FFFD e guarda o original exato em base64 na anotação. [Recibo](food-catalog-exports-verification.json), tentativa 4.
- Exports arquivados por `food_catalog_publish.py --confirm` em `.local/food-catalog/exports/08abd86f…207c/` (13 fontes + manifest, sem internet/SQL).

- Catálogo global importado e **ativo** no Postgres local (19/11): 6.702.350 versões vinculadas, release `active`, 32 tabelas não-catálogo idênticas e todas as linhas de catálogo preexistentes preservadas (6.369 versões legadas), banco 37,7 GB, cluster deixado parado. A comparação final do 1º recibo estourou o timeout de 35 s do psql; concluída via `importar_catalogo_alimentar_local.py --verify-from-checkpoint` (checkpoint pré-importação restaurado em banco descartável, removido depois). [Recibo](food-catalog-local-import.json).

**Próxima ação:** `gerar_documentacao.py --write --check` (2 derivados divergiam) e commit isolado só da alimentação, sem as alterações de inicialização/logo/splash. APK, teste nativo integrado e aceite humano continuam pendentes.

Artefatos a preservar:

| Caminho | Papel |
|---|---|
| `.local/food-catalog/raw/` | TACO/USDA/OFF originais completos e recibos; não baixar novamente |
| `.local/food-catalog/distribution/catalog.sqlite` | Banco compacto assinado (8,82 GB), fonte do gzip |
| `.local/food-catalog/distribution/baseline-manifest.json`/`baseline-trust.json` | Manifesto do layout antigo (banco removido com autorização em 19/11) |
| `.local/food-catalog/distribution/catalog-update.zip` | ZIP de atualização assinado |
| `assets/food_catalog/` | Gzip/manifest/trust do APK |
| `.local/food-catalog/exports/08abd86f…/` | Exportações públicas imutáveis por artefato; manter hashes/licenças e oferta ODbL |
| `.local/food-catalog/go-exports-scan-20261119/` | Diagnóstico antes/depois da varredura completa |
| `.local/food-catalog/signing/` | Chave privada, nunca publicar |

Removido com autorização do autor em 19/11: `distribution/catalog-uncompact.sqlite.gz` (5,56 GB, layout antigo inviável, regenerável do baseline).
Retirados somente derivados antigos para liberar espaço: `recovery/catalog-interrupted.sqlite` e `build/usda-stage.sqlite`, após baselinecompleto/integridade/assinatura. A cópia Fluttertestde5,56GB também foi removida; o gzipbaseline foi movido deassets sem duplicação. Não usar o antigo resumeCSV: o trabalho atual parte do rawnormalizado completo. Nenhum banco particular ou arquivo de autoria do Claude foi apagado.

A conferência anterior confirmou OFF: **4.916.182 linhas de entrada / 4.570.308 registros com código e nome**; legado: **6.369**; TACO: **597**. USDA: **2.125.085 linhas brutas**; 2.125.076 têm nome aproveitável, com9 exclusões explícitas. O esperado corrigido é6.702.350 alimentos no total; só anunciar a contagem final após verify. Disco livre observado: cerca de **11,1 GB**; não criar novas cópias de bancos grandes. Remover apenas derivados redundantes depois de verificar o pacote final, com alvo absoluto conferido; preservar dados pessoais, fontes e uma cópia final íntegra.

## Decisões que não precisam ser perguntadas de novo

- TACO + USDA completo + OFF global, conservando Ciqual/CoFID: todos os registros aproveitáveis, sem redução arbitrária a amostra ou apenas Brasil.
- Catálogo no APK e busca/barcode offline; nenhuma API de fornecedor durante o uso. Primeiro login online; depois dados alimentares privados duráveis e sincronização pela API Go própria, permitida pelo autor.
- Porções somente quando peso/volume e condição forem documentados ou informados pela pessoa. Não inventar peso de colher/lata nem densidade para converter g/ml. Ausente não vira zero.
- Open Food Facts/ODbL aceito. Créditos em Fontes e transparência e oferta das bases derivadas por fonte; referências sozinhas não encerram a obrigação de disponibilizar os dados.
- Contribuições opcionais com consentimento CC0 explícito, campos/fotos revisados, sem peso ou histórico particular no export público. Mantenedor aprova antes de publicação. Sem cadastro, compra ou hospedagem nova por inferência.
- Snapshots e cálculos históricos imutáveis. Algoritmo canônico novo é explícito; legado não é recalculado.

## Implementado e validado

Código em integração: **Flutter 0.5.0+30 / API 0.11.0 (51operações) / migrations 14–16**. A base pessoal foi ativada de13 para16 com backup novo,38tabelas, as30preexistentes inalteradas e8novas vazias. A importação global ainda não ocorreu. [Recibo da ativação](food-offline-local-activation.json). Não confundir código/migration existente com serviço atualizado ou catálogo ativo.

| Recorte | Resultado e evidência |
|---|---|
| Flutter completo | **358 testes passaram**, análise 0 erros; `.local/food-offline-client-20261118/final-full.stdout.jsonl`. O recibo conserva357 anteriores/42 dirigidos; após correção pontual do total no manifesto,16 testes dirigidos e análise0 passaram, sem repetir a suíte inteira |
| Flutter dirigido depois dos últimos ajustes | **42 testes passaram**, análise 0 erros; [recibo cliente](food-offline-client-verification-20261118.json), com hashes e separação dos dois recortes |
| SQL real em banco descartável | **Schema 16**, sync, contribuições, refeições, staging/ativação de catálogo, privacidade e readiness; dados entregues inalterados e banco descartável removido. [Recibo SQL](offline-nutrition-sql-verification.json), 18/11 13:50 UTC |
| Backend | `go test ./...` e `go vet ./...` passaram antes do último ajuste de distribuição; depois dele `go test ./internal/publiccatalog ./internal/platform/httpapi` passou |
| Ferramentas | **211 testes Python passaram**; catálogo passou22 dirigidos incluindo reparo dos membros gzip. APK10/release8/arquivamento4/Android9/inventário5 também aprovados. Novas ferramentas depois desse recorte precisam de verificação própria |

Capacidades: catálogo SQLite/FTS4 com início TACO, fontes pelo manifesto assinado, GTIN e leitor ML Kit embarcado; SQLCipher por conta, chave no armazenamento seguro, outbox durável/FIFO, confirmação com paridade de cálculo, conflitos e tombstones; lock persistente após 401 conhecido e limpeza na exclusão; porções pessoais; contribuições/fotos cifradas e retirada; atualização gzip/ZIP assinado e confiança presa ao APK; créditos/ODbL em configurações.

Backend: `/me/nutrition/sync` e `/changes`, ledger independente do replay antigo de 24h, contribuições e mídia sanitizada, CLI de revisão; catálogo por staging e ativação exata. Distribuição pública com Range/hash e rota versionada `/api/v1/food-catalog/exports/{artifactSHA256}/{file}`. `tools/food_catalog_publish.py` verifica assinatura e exportações antes de mover os arquivos públicos para `exports/{sha}/`, sem SQL ou internet; permite manter versões antigas disponíveis. Cliente de release verifica o catálogo **dentro do APK final**, tamanhos/tipos assinados e SQLCipher por ABI.

## Próximos passos, nesta ordem

1. **Concluir a recuperação.** Conferir processo pelo comando, não só PID, e ler os dois logs atuais. Corrigir a contagem USDA e testar a correção com fixture. A retomada existente reinspeciona prefixos e reaproveita stage/SQLite; não normaliza tudo novamente. Se não houver processo ativo e a falha estiver corrigida:

   ```powershell
   Set-Location C:/dev/TrainForge/trainforge
   python -u tools/food_catalog_resume.py 1> .local/food-catalog/resume-next.log 2> .local/food-catalog/resume-next-errors.log
   ```

   Registrar esses novos logs no handoff se o comando for usado. Nunca rodar dois geradores. Se `recovered_catalog_complete` já constar e faltar apenas empacotamento, usar `python -u tools/food_catalog_package.py`, em vez de reingerir.

2. **Conferir produção.** `python tools/food_catalog_build.py --verify` deve passar sem fixture, fontes faltantes ou redução silenciosa. Resultado final esperado: `assets/food_catalog/{catalog.sqlite.gz,manifest.json,trust.json}`; SQLite bruto e `catalog-update.zip` ficam em `.local/food-catalog/distribution/`. O banco bruto supera 4 GiB: nunca incluí-lo diretamente no APK. ZIP de atualização tem exatamente manifesto + gzip, ZIP_STORED. Conferir cobertura, hashes, licenças dos exports e tamanho real antes de anunciar pronto.

3. **Congelar fontes e validar Android.** Não rodar Flutter/analyze/gen-l10n em paralelo a `prepare`. Executar a suíte completa final uma vez após os ajustes e compilar com `python tools/avaliar_android.py prepare`; ele só gera/confere debug e não instala. Verificar `python tools/verificar_catalogo_apk.py --apk build/app/outputs/flutter-apk/app-debug.apk` e inventário nativo. `integration_test/food_offline_native_test.dart` já existe, nunca executado: testa catálogo real, arroz TACO, barcode, EAN gerado localmente/ML Kit, SQLCipher, fila/reabertura/isolamento/lock/exclusão de conta sintética, sem HTTP/Google. Comando após selecionar **AVD descartável**:

   ```powershell
   & C:/Users/richa/flutter/bin/flutter.bat test integration_test/food_offline_native_test.dart -d SERIAL_DO_AVD_DESCARTAVEL --no-pub
   ```

   O `TrainForge_Benchmark` existente tem **6 GiB**, insuficiente para a base expandida. Não redimensionar, limpar nem apagar esse AVD. Nenhum aparelho físico foi usado nesta rodada. Um AVD descartável foi criado nesta rodada: `TrainForge_Food_Offline_Test_20261118`, em `.local/avd/`, partição24GiB. Ainda não foi iniciado; registro em `.local/food-offline-native/runtime.json`. Reutilizar esse alvo, sem criar outro. O teste reabre banco; não simula morte do processo nem substitui câmera física/TalkBack/iOS.

4. **Preparar ativação do servidor com preservação.** Antes de distribuir APK/update, o mesmo manifesto/versões precisa estar ativo no Go. Migrations14–16 já foram aplicadas com backup/comparação e readiness real; não reaplicar nem recriar banco. Falta importar/ativar o catálogo exato, preservando registros, sem repetir Google/configuração ou excluir refeições. `cmd/import-food-catalog` começa por `--operation verify`, depois stage/activate com SHA explícito e papel migrator local validado. Não imprimir conexão. Arquivar exports com `python tools/food_catalog_publish.py --confirm SHA_DO_ARTEFATO` e usar `--exports C:/dev/TrainForge/trainforge/.local/food-catalog/exports/SHA_DO_ARTEFATO` no importador (o CLI Go executa em services/api). Servir somente release ativa; conservar exports/manifests antigos. Medir disco antes da importação PostgreSQL de milhões de registros.

5. **Fechar documentação e checks.** Swagger já inclui as novas rotas públicas e paths /api/v1/me corretos; conferir se os fontes mudarem. Executar `python tools/gerar_documentacao.py --write --check`, diagramas e Graphify AST incremental `python tools/atualizar_graphify.py --write`; suíte Python final e checks adequados. Graphify já foi atualizado18/11:109Dart,4.713nós,5.443arestas,26arquivos reextraídos,0rede/LLM. Swagger0.11.0/51operações gerado/conferido; manter derivados alinhados se surgir nova correção. Atualizar este handoff e backlog com evidências reais. Não fazer novo rebuild semântico da raiz nem repetir pesquisa.

6. **Revisão final e distribuição.** Commit/push estão autorizados pelo contexto do projeto, com stage explícito e scanner de segredos sobre todo intervalo/blobs/ZIPs, sem force-push. Nenhum commit/push desta implementação foi realizado ainda. APK por link requer endpoint HTTPS real e OAuth/certificado release corretos. `tools/preparar_release_android.py` existe, mas não há configuração pública de produção validada ou release gerado nesta rodada. Não publicar debug como release nem declarar a V1 inteira pronta.

## Preservação e limites

Backlog atual: **18 done / 8 doing / 23 todo**, próxima `V1-019`. A ativação13→16 não inseriu catálogo global ou registros particulares; API/PG ficaram parados como antes. A história foi reaberta para o escopo global autorizado; a conclusão anterior Ciqual/CoFID continua como evidência histórica. V1-026 continua doing: alimentação offline não encerra offline de atividade.

Preservar uma conta, consumos reais e a refeição 20g declarada teste pelo autor, além da configuração047 revisão 2/14:00. Não reclassificar por inferência nem repetir instalações/login. API/catálogo/PG devem ser observados pelos helpers; não usar migrations/import/restore como startup cotidiano. `.local` contém bancos, chaves e backups privados; nunca publicar.

Treino permanece com **73 metadados de consulta, 439 ativos excluídos e zero programa/instrução/dose/mídia liberados para prática**. V1-015/016/017/023 e demais gates conservam seus critérios. Último APK anterior gerado: 0.4.7+29, não instalado; último instalado documentado: 0.4.6+28. O APK 0.5.0+30 ainda não foi gerado, instalado ou publicado. iOS não foi validado nativamente no Windows.

[Escopo](escopo.md) · [Implementação por domínio](implementacao.md) · [Validação/entrega](validacao-e-entrega.md) · [Operação local](../../aprendizado/operacao-local.md) · [Histórico](../../historico/README.md). Checkpoint anterior e CI de 17/11 permanecem nos recibos datados; não sobrescrevê-los como novos ensaios.
