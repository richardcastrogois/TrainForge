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

CódigoGo0.6.0 mantém25operações e acrescenta leitura opcional de nomes/aliases porlocale e revisão, com cursor/ETag coerentes. Último ambiente humano avaliado continuaGo0.5.1/migration8.00009/00010foram validadas somente em banco descartável, sem aplicação à base entregue. Flutter/APK15 ainda usa o contrato original. Publicação humana e integração cliente continuam pendentes;0nomes traduzidos publicados. [Contrato](../../docs/arquitetura/contratos-v1.md).

Ensaio dirigido quando o código mudar:python tools/verificar_nomes_alimentares.py. Banco temporário comSQL/HTTP, guardas de alvo, dados e estado do cluster preservados; semGoogle/consumo humano. [Recibo atual](../../docs/execucao/v1/food-names-read-verification.json).

Go não é garantia de escala: pool limitado, consultas/índices, autorização, timeouts e carga real serão validados por fatia. PostgreSQL17.5 local exige atualização de patch antes de exposição externa.

Privacidade: [implementação e limites](../../docs/execucao/v1/privacidade-013.md). Manutenção manual: python tools/manter_privacidade_local.py (prévia; --apply aplica um lote). Restore separado: python tools/aplicar_exclusoes_restore.py --target-database trainforge_v1_privacy_restore_<12hex> (prévia; --apply sanitiza sem promover). Usar os comandos Python a partir da raiz. Credenciais administrativas continuam fora do runtime/Git.
