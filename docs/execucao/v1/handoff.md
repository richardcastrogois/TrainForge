# Handoff vigente — TrainForge

Atualizado em **19/11/2026 (tarde, BRT)**. Checkout `C:/dev/TrainForge/trainforge`. Objetivo do dia: APK v0.1 público para a feira (link + QR code), API hospedada e apresentação da etapa 02.

## Fluxo pedido pelo autor

Pendências tratadas **uma por vez**; ao fechar cada uma: commit/push quando houver mudança (sem coautor Claude), `python tools/gerar_documentacao.py --write --check`, diagramas se o produto mudou e `python tools/atualizar_graphify.py --write`. Stage explícito por path, nunca `git add .`; gitleaks no staged antes de commitar.

| # | Pendência | Estado |
|---|---|---|
| 1 | APK release | **Concluída**: 0.5.0+30 assinado e verificado (abaixo) |
| 2 | Importar pacote Brasil + Portugal no Neon | Pendente (aguarda ok do autor) |
| 3 | Publicar pacotes no GitHub Releases (`catalog-packs-v1`) | Pendente (upload pelo autor no navegador) |
| 4 | Commitar tela de pacotes + manifest do pacote Brasil | Pendente |
| 5 | Google: `TF_GOOGLE_SERVER_CLIENT_ID` na Vercel e teste de login | Pendente |
| 6 | Licença proprietária + Termos/Privacidade | Pendente; ressalvas: repositório público, dados de terceiros (ODbL/CC-BY-SA) e Termos/Privacidade |

## Arquitetura de distribuição (19/11)

- **API**: `https://trainforge-api.vercel.app` (Vercel Hobby, projeto `trainforge-api`, região gru1, root `services/api`, deploy a cada push em `main`). Entrada `services/api/api/index.go` → pacote público `serverless` → `internal/app` (mesma montagem de rotas do servidor `cmd/api`). `vercel.json` reescreve tudo para `/api/index`. Proxy confiável `127.0.0.1/32`; o edge da Vercel substitui `X-Forwarded-*`.
- **Banco**: Neon gratuito, organização `org-rapid-leaf-05707803` (não é a org Neon×Vercel do autor; os 4 bancos dele não foram tocados), projeto `trainforge` (`fragrant-recipe-20177567`), região sa-east-1, database `trainforge_v1_prod`, 16 migrations. Papéis: `trainforge_owner` (dono/migrações), `trainforge_runtime` (grants de `tools/db_permissions.py`) e `trainforge_api` (login da API, membro de `trainforge_runtime`). Conexões só em `.local/neon.env` e na variável sensível `TF_DATABASE_URL` da Vercel.
- **Conteúdo no Neon**: 73 itens de exercícios (`import-content`) e pacote alimentar **Brasil** ativo (57.326 alimentos, artefato `04a6bf39…ee9a`). `import-food` legado falhou ("food review evidence changed", evidências compactadas); não necessário com o catálogo novo. Importadores só aceitam o Neon com `TF_HOSTED_TARGET=neon`, host `*.neon.tech`, TLS e database `trainforge_v1_prod`.
- **Catálogo alimentar**: `tools/food_catalog_slim.py --pack br|br-pt` recorta o catálogo completo assinado (`.local/food-catalog/full-assets` + `distribution/catalog.sqlite`) em pacotes regionais assinados com a mesma chave: genéricos (TACO, Ciqual, CoFID, USDA Foundation/SR Legacy/FNDDS) + produtos Open Food Facts do(s) país(es).

| Pacote | Alimentos | Gzip/ZIP | Instalado | Onde |
|---|---|---|---|---|
| `br` | 57.326 | 41 MB | 103 MB | Embutido no APK; ativo no Neon |
| `br-pt` | 78.262 | 52 MB | 129 MB | Download opcional (GitHub Releases) |
| completo | 6.702.350 | 3,2 GB | 8,8 GB | Só local (`.local/food-catalog/full-assets`) |

ZIPs prontos para upload em `build/catalog-packs/` (gitignored). O app baixa de `AppConfig.catalogPacksUrl` (padrão `…/releases/download/catalog-packs-v1/`) e importa com a verificação de assinatura já existente; o repositório precisa continuar público para esse download.

## APK release (pendência 1, concluída)

`build/app/outputs/flutter-apk/app-release.apk`: **0.5.0+30**, 135.738.207 bytes (129,5 MB, 3 ABIs), SHA `bf00d761cb2a…`, certificado de release `BF:A9:1D…` (o mesmo registrado no Google), `allowBackup=false`, sem debuggable/cleartext, catálogo Brasil verificado dentro do APK. Recibo: `.local/android-release/artifact.json`. Não instalado nem publicado.

- JDK: **Temurin 21.0.13 LTS** (Gradle 8.14 não roda em Java 25). Exportar `JAVA_HOME="C:\Program Files\Eclipse Adoptium\jdk-21.0.13.9-hotspot"` em shells abertos antes da instalação.
- Correções: `GeneratedPluginRegistrant.java` (gerado, ignorado) estava com o plugin de teste do build debug; movido para `.local/android-release/`, e o Flutter regenerou a versão release. `tools/preparar_release_android.py` resolve os recursos XML encurtados no release (`res/xml/backup_rules.xml` → `res/Qq.xml`) pela tabela do `aapt2`.
- Validação: `flutter analyze` 0 problemas e **372 testes Flutter**; `go test ./...` completo; gitleaks sem achados nos commits.
- Comando: `python tools/preparar_release_android.py --config .local/android-release/release-config.json --certificate-sha256 BFA91D8792CE53124A777B15BF4650C40AB72592366362B6A5581F211C208878`.

## Preservação e limites

`.local` contém bancos, chaves (catálogo, assinatura Android), `neon.env` e backups: nunca publicar nem imprimir. Preservar dados reais locais (consumo, refeição 20 g de teste, configuração 047). Postgres local tem o catálogo global ativo (6.702.350, [recibo](food-catalog-local-import.json)); não confundir com o Neon, que tem só o pacote Brasil. Treino continua com 73 metadados de consulta e zero programa/instrução/dose/mídia liberados. Mídias MoveKit aguardam compra (plano do Codex em `docs/conteudo/`, ainda não versionado). iOS não validado nativamente.

[Registro por etapa](food-offline-progress.json) · [Escopo](escopo.md) · [Implementação](implementacao.md) · [Validação/entrega](validacao-e-entrega.md) · [Operação local](../../aprendizado/operacao-local.md) · [Histórico](../../historico/README.md)
