# API Go do TrainForge

Monólito modular em construção. Consulte [o fechamento da fundação](../../docs/execucao/v1/etapa-02-fechamento.md), [camadas](../../docs/arquitetura/camadas-go.md) e [contrato gerado](../../contracts/generated/swagger-v1.json).

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

A00009(nomes/aliases revisados) foi validada somente em banco descartável. Modelo e persistência existem, mas não há publicação operacional/contratoHTTP/busca localizada integrado. Não enviar locale àAPI atual. Nenhum nome traduzido foi publicado. Para repetir somente esse ensaio quando a implementação mudar:python tools/verificar_nomes_alimentares.py. O helper usa banco temporário, preserva dados e o estado inicial do cluster; não usa Google nem histórico real. [Recibo](../../docs/execucao/v1/food-names-foundation-verification.json).

Go não é garantia de escala: pool limitado, consultas/índices, autorização, timeouts e carga real serão validados por fatia. PostgreSQL17.5 local exige atualização de patch antes de exposição externa.

Privacidade: [implementação e limites](../../docs/execucao/v1/privacidade-013.md). Manutenção manual: python tools/manter_privacidade_local.py (prévia; --apply aplica um lote). Restore separado: python tools/aplicar_exclusoes_restore.py --target-database trainforge_v1_privacy_restore_<12hex> (prévia; --apply sanitiza sem promover). Usar os comandos Python a partir da raiz. Credenciais administrativas continuam fora do runtime/Git.
