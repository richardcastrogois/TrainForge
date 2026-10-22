# API Go do TrainForge

Monólito modular em construção. Consulte [o fechamento da fundação](../../docs/execucao/v1/etapa-02-fechamento.md), [camadas](../../docs/arquitetura/camadas-go.md) e [contrato gerado](../../contracts/generated/swagger-v1.json).

Pré-requisitos: Go1.27.3, Python3, Swaggo1.16.6; PostgreSQL17 para desenvolvimento local. Este clone usa uma cópia Go portátil ignorada e os binários PostgreSQL previamente instalados. Clones novos não instalam ferramentas automaticamente.

Na raiz do repositório:

```powershell
python tools/db_local.py init   # somente primeira criação do cluster isolado
python tools/db_local.py start
python tools/migrate_local.py
python tools/db_local.py grant-runtime
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

API localhost8082; DB localhost15432. Somente health/live e health/ready foram implementados na fundação. O catálogo está no DB, sem endpoint/ensino/prática. Swagger local: `/docs/index.html`. Não alterar a URL Flutter para este serviço antes de adaptar os contratos.

Go não é garantia de escala: pool limitado, consultas/índices, autorização, timeouts e carga real serão validados por fatia. PostgreSQL17.5 local exige atualização de patch antes de exposição externa.
