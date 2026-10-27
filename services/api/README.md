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

CódigoGo0.6.1 mantém25operações e leitura de nomes/aliases porlocale/revisão, com cursor/ETag coerentes. ClienteFlutter integrado eAPK0.3.3+16 preparado,não instalado. Schema11/26tabelas locais:9–11 autorizadas e aplicadas após SQLdescartável, com dados preservados e leituraHTTPreal nos4idiomas. Nenhum nome revisado publicado.00011marca idioma particular não declarado comound. Ferramenta editorial e cobertura real entregues; aceites nativos e aplicação de pacote humano aprovado continuam pendentes. [Integração](../../docs/execucao/v1/frontend-food-names-verification.json).

Operação local: cmd/food-names e internal/foodnamesops. Default check-publish valida arquivos sem banco; publicação/retirada exigem confirmação do pacote e referência humana verificada, com papel migrator local. Coverage usa read-only e runtime. Não autentica revisores nem prova direitos; não executado com conteúdo real. [Procedimento e limites](../../docs/conteudo/nomes-alimentares-revisados.md).

Ensaio dirigido quando o código mudar:python tools/verificar_nomes_alimentares.py. Banco temporário comSQL/HTTP, guardas de alvo, dados e estado do cluster preservados; semGoogle/consumo humano. [Recibo atual](../../docs/execucao/v1/food-names-operations-verification.json).

Go não é garantia de escala: pool limitado, consultas/índices, autorização, timeouts e carga real serão validados por fatia. PostgreSQL17.5 local exige atualização de patch antes de exposição externa.

Privacidade: [implementação e limites](../../docs/execucao/v1/privacidade-013.md). Manutenção manual: python tools/manter_privacidade_local.py (prévia; --apply aplica um lote). Restore separado: python tools/aplicar_exclusoes_restore.py --target-database trainforge_v1_privacy_restore_<12hex> (prévia; --apply sanitiza sem promover). Usar os comandos Python a partir da raiz. Credenciais administrativas continuam fora do runtime/Git.
