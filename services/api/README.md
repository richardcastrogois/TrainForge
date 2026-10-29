# API Go do TrainForge

Monólito modular em construção. Consulte [o fechamento da fundação](../../docs/execucao/v1/etapa-02-fechamento.md), [camadas](../../docs/arquitetura/camadas-go.md) e [contrato gerado](../../contracts/generated/swagger-v1.json).

## Estado vigente — 29/10/2026

Go0.8.1 /34 operações. Readiness confere objetos/privilégios do runtime com falha genérica; não lê registros de usuários. Suíte comum/vet/Swagger passaram; teste SQL de prontidão aprovado em40813092631/9124a85 com quatro negativos/recuperação. CI de migrations/refeições/privacidade0.8.0 já aprovado. [Escopo](../../docs/execucao/v1/ci-sql-verification.json). Configuração047 foi validada com dados humanos; refeições045 têm gravação atômica, diário/detalhe, metadados versionados e exclusão integral, com SQL/HTTP e privacidade/restore verificados em bases descartáveis. [Estado, semântica e pendências](../../docs/execucao/v1/refeicoes-045.md). O comando `python tools/verificar_refeicoes_local.py`, na raiz, cria e remove somente bases descartáveis, compara hashes dos dados entregues e preserva o estado do cluster. Fixtures não validam refeição real nem login Google.

O banco local está no schema13/30tabelas, com grants restritos e [ativação com checkpoint e comparação](../../docs/execucao/v1/meal-grouping-local-activation.json). Cliente Flutter integrado no APK debug0.4.3+25; leitura nativa preservou o consumo real anterior sem agrupamento inventado. Seleção particular e edição de metadados na UI implementadas. Aceite de consumo real/correção/exclusão e foto042 continuam pendentes; criação/consulta humana observada foi confirmada como teste de navegação. Não repetir migrations, SQL ou restore sem mudança pertinente. Não há programa, instrução, dose ou mídia liberados para prática. Os parágrafos de versões anteriores abaixo são checkpoints históricos.

Pré-requisitos: Go1.27.3, Python3, Swaggo1.16.6; PostgreSQL17 para desenvolvimento local. Este clone usa uma cópia Go portátil ignorada e os binários PostgreSQL previamente instalados. Clones novos não instalam ferramentas automaticamente.

Na raiz do repositório:

```powershell
python tools/db_local.py init   # apenas clone novo; este ambiente já existe
python tools/db_local.py start
python tools/migrate_local.py
python tools/db_local.py grant-runtime
 # Importações já validadas neste clone; repetir somente se o artefato mudar.
python tools/importar_catalogo_local.py --dry-run
python tools/importar_catalogo_local.py
python tools/dev_api.py
# Ctrl+C encerra a API; python tools/db_local.py stop encerra só o cluster V1.
```

`init` cria credenciais aleatórias em `.local` ignorada; o runtime não recebe credencial de migration. Reimportar o mesmo artefato é idempotente. Não copiar `.local` para o Git ou outro dispositivo.

```powershell
./tools/go-api.ps1 test ./...
./tools/go-api.ps1 vet ./...
python tools/verificar_api_local.py
python tools/verificar_banco_local.py
```

API localhost8082; DB localhost15432. Go0.5.1 entrega25operações:saúde, autenticação/sessão, catálogo de73metadados, consulta de6369referências alimentares, cadastro particular, consumo/revisão/exclusão/histórico/subtotais, política/exportação/exclusão de conta. Migrations00001–00008 aplicadas; GoogleAndroiddebug/sessão/privacidade reais já validados. [Fechamento](../../docs/execucao/v1/auth-local-fechamento.md). Não repetir login/importação/restore por hábito. Sem programa/dose/mídia aprovada para prática. Swagger local:/docs/index.html. [APK](../../docs/execucao/v1/avaliacao-android.md).

CódigoGo0.6.1 mantém25operações e leitura de nomes/aliases porlocale/revisão, com cursor/ETag coerentes. ClienteFlutter integrado eAPK0.3.6+19 instalado, com ensaio Android de idiomas. Schema11/26tabelas locais:9–11 autorizadas e aplicadas após SQLdescartável, com dados preservados e leituraHTTPreal nos4idiomas. Nenhum nome revisado publicado.00011marca idioma particular não declarado comound. Ferramenta editorial e cobertura real entregues; projeção de nomes no histórico/detalhe e aplicação de pacote humano aprovado continuam pendentes. [Integração](../../docs/execucao/v1/frontend-food-names-verification.json).

Operação local: cmd/food-names e internal/foodnamesops. Default check-publish valida arquivos sem banco; publicação/retirada exigem confirmação do pacote e referência humana verificada, com papel migrator local. Coverage usa read-only e runtime. Não autentica revisores nem prova direitos; não executado com conteúdo real. [Procedimento e limites](../../docs/conteudo/nomes-alimentares-revisados.md).

Ensaio dirigido quando o código mudar:python tools/verificar_nomes_alimentares.py. Banco temporário comSQL/HTTP, guardas de alvo, dados e estado do cluster preservados; semGoogle/consumo humano. [Recibo atual](../../docs/execucao/v1/food-names-operations-verification.json).

Go não é garantia de escala: pool limitado, consultas/índices, autorização, timeouts e carga real serão validados por fatia. PostgreSQL17.5 local exige atualização de patch antes de exposição externa.

Privacidade: [implementação e limites](../../docs/execucao/v1/privacidade-013.md). Manutenção manual: python tools/manter_privacidade_local.py (prévia; --apply aplica um lote). Restore separado: python tools/aplicar_exclusoes_restore.py --target-database trainforge_v1_privacy_restore_<12hex> (prévia; --apply sanitiza sem promover). Usar os comandos Python a partir da raiz. Credenciais administrativas continuam fora do runtime/Git.

## Imagem para avaliação noCI

Dockerfile multi-stage e contexto por allowlist geram runtime scratch com UID/GID65532, CA pública e tzdata embutido. [Run40819933235](https://github.com/richardcastrogois/TrainForge/actions/runs/40819933235) aprovou build/smoke somente no runner; [recibo](../../docs/execucao/v1/api-image-verification.json) contém commit, versão, imageID, SHA256 do arquivo e limites. Artefato retido sete dias, sem registry push ou deploy. Não executamos Docker no notebook nem copiamos dados de avaliação. TLS/banco/Google e entregaAPK têm gates próprios; a imagem não contém migrations ou credenciais.

## Prova isolada de catálogoM1

`cmd/catalog` e `cmd/catalog-migrate` são aditivos e restritos ao banco descartável próprio da prova. Não são o caminho doAPK ou uma migration da avaliação. Papéis e comandos separados, cinco rotas públicas existentes e duas de saúde; [plano e limites](../../docs/arquitetura/reavaliacao-microservicos-2026-10-29.md), [contrato gerado](../../contracts/generated/catalog-m1.swagger.json) e [evidência](../../docs/execucao/v1/catalog-m1-verification.json). Fixtures SQL/processo somente noCI dedicado; não reutilizar o helper de banco real ou rodar migrations do monólito nessa projeção.
