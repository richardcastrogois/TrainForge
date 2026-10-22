# Etapa02 / M1 — fundação local concluída

Concluída na continuação de21–22/10/2026. Histórias006–010: API Go real, Swagger por comentários, modelo/migrations, cluster separado, importação e recuperação ensaiados. A etapa não entrega login, cliente Flutter integrado, prática ou APK.

## Resultado observado

| Verificação | Resultado |
|---|---|
| Processo Go sem DB | live200, ready503; [smoke negativo](api-smoke.json) |
| Processo com runtime PostgreSQL | live200, ready200, SwaggerUI200; [teste conectado](api-connected-verification.json) |
| Salvar anotação | gerou Swagger, compilou e reiniciou; versão alterada observada porHTTP e depois restaurada; processo encerrado |
| Migrations |00001core,00002FKs por tipo,00003sessões prescritas; forward com Goose; rerun sem novas migrations |
| Importação | dry run73; primeiro insert73; reimportações0novos/73inalterados; [recibo](catalog-import-verification.json) |
| Recuperação | dump real restaurado noutra base; contagens e hash dos registros iguais; [relatório](database-verification.json) |
| Integridade | cinco invariantes SQL rejeitadas como esperado; fixtures revertidas e base de restore removida |
| Dados entregues |73metadados de movimentos,1fonte,0usuários/adesões/sessões/consumos;0instruções/mídias/prática aprovadas |

Go1.27.3 portátil em `.tools/go`, módulos/checksums em `services/api/go.mod`/`go.sum`; Swaggo1.16.6. A tag imprime rótuloCLI1.16.4: a ferramenta confere o módulo compilado, não o rótulo. PackageName fixo garante geração determinística. Swagger2.0 real contém somente as duas rotas de saúde nessa entrega. Nenhum gerador Dart adotado; sua compatibilidade será verificada antes da integração do cliente.

## Banco isolado e comandos

Reutilizados binários PostgreSQL17.5 previamente instalados em `C:/Program Files/PostgreSQL/17/bin`. Novo cluster em `.local/pgdata`, localhost15432, banco `trainforge_v1_dev`, schema `trainforge_v1`. Nenhum serviço Windows criado, senha global trocada ou banco legado acessado. Docker falhou no gerenciador de inferência/socket `dockerInference`; sua configuração e volumes não foram alterados.

```powershell
# Na raiz do clone. Python3 necessário; instalação não é automática.
python tools/db_local.py init          # primeira criação, não é reset
python tools/db_local.py start
python tools/migrate_local.py
python tools/db_local.py grant-runtime
python tools/importar_catalogo_local.py --dry-run
python tools/importar_catalogo_local.py
python tools/dev_api.py
# Ctrl+C encerra watcher e API.
python tools/db_local.py stop          # encerra só o cluster deste clone
```

API em localhost8082; Swagger em `http://127.0.0.1:8082/docs/index.html`. Watcher executa geração→build→restart e preserva o processo anterior se build falhar. Não roda migration ao salvar. A documentação de arquitetura permanece Markdown/Mermaid sem servidor de leitura.

Configuração `.local/api.env` contém apenas a conexão runtime, não a credencial migrator. Papéis sem superuser: runtime lê editorial, faz CRUD privado e não cria schema/tabela; migrator é dono somente do banco V1. Credenciais, cluster, dump e dados preparados ficam ignorados; ACL local restrita ao usuário/SYSTEM. Fonte e versão são preservadas por ativo, sem assumir que versãohash é uma versão publicada pelo autor.

## Testes e reversibilidade

```powershell
./tools/go-api.ps1 test ./...
./tools/go-api.ps1 vet ./...
python tools/verificar_api_local.py
python tools/verificar_banco_local.py
python tools/revisar_conteudo_local.py --check
python tools/fechar_triagem_piloto.py --check
python tools/gerar_documentacao.py --write --check
python -m unittest discover -s tools -p "test_*.py"
```

`verificar_banco_local.py` gera `.local/backups/trainforge-v1-post-content.dump`, recusa sobrescrever base de restore já existente, restaura em `trainforge_v1_restore_20261021`, compara contagens/hash, testa restrições dentro de transação revertida e exclui somente essa base que criou. Backup foi retido por continuar necessário ao desenvolvimento. Não há comando down/reset.

Retirada editorial é lógica: migrator insere asset_id+version_sha+motivo em `content_withdrawals` sob transação, mantendo versão e relações históricas; não apagar em cascata para desfazer importação. Endpoint/listagem respeitará essa retirada na014. Nenhuma retirada foi inventada no catálogo real.

## Limites e próxima etapa

PostgreSQL17 é uma linha suportada, mas o patch17.5 está defasado: [17.11 era o patch corrente na verificação](https://www.postgresql.org/support/versioning/). Uso deste cluster é desenvolvimento local; atualizar antes de staging/exposição externa. Sem alegação de carga para milhares de usuários: baseline de carga/segurança ainda está nas etapas posteriores.

Go é único migrador do schema novo. Dados/contagens do banco legado são desconhecidos e não são presumidos vazios. Migração desses dados ficou fora deste incremento isolado; inventário com acesso específico, mapeamento e ensaio são gates antes de qualquer futura migração real. Não há dualwrite nem corte do Flutter paraGo.

A CI foi preparada para Go/testes/vet/build e deriva Swagger; execução remota ainda depende de publicação autorizada. V1-003 continua transversal. A próxima história é011: validar token real Google e identidade por issuer+sub, seguida de012/013. Treinos executáveis continuam bloqueados pelos usos excluídos na etapa01; não liberar prática por haver catálogo noDB.
