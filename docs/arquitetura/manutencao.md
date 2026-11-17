# Manter arquitetura, contratos e diagramas

Os guias são arquivos locais e versionados. Abra [a arquitetura](README.md) no editor/GitHub ou [os mapas](diagramas/index.html) no navegador; leitura não inicia servidor. Os seis guias de arquitetura são manuais, e os detalhes repetitivos são gerados das fontes abaixo.

| Informação | Fonte canônica | Derivado |
|---|---|---|
| Implementação Flutter/Go/SQL | `lib`, `services/api`, migrations | `inventario-atual.json`, `gerado/referencia.md` |
| Contrato HTTP | Comentários e DTOs Go | Swagger JSON/YAML, pacote Go de Swagger e `diagramas/apis.md` |
| Estado das histórias | `docs/execucao/v1/backlog.json` | `docs/execucao/v1/backlog.md` |
| Intenção/achados | `plano.json`, `achados.json`, decisões e histórias | Entradas auditáveis do inventário; o gerador não conclui trabalho |
| Mapas revisados | `diagramas/mapas.json` | 15 SVGs, `trainforge.drawio` com 15 páginas, README e index HTML |
| Banco observado | `diagramas/schema-publico.json`, apenas metadados | `diagramas/banco.md` documenta colunas/restrições; testes conferem cobertura/FKs |
| Backend anterior | `referencias/backend-fastify.json` | Snapshot histórico com revisão/hashes/links; não descreve o Go atual |
| Estrutura Dart detalhada | `graphify-out/graph.json` | Consulta e HTML Graphify; escopo AST de `lib/` |

## Alterar e conferir

Atualize primeiro a fonte responsável e os guias afetados; depois gere e revise os derivados. Os comandos abaixo não iniciam app/API/banco nem acessam registros privados:

```powershell
python tools/gerar_documentacao.py --write --check
python tools/gerar_diagramas.py
python tools/gerar_diagramas.py --check
python -m unittest discover -s tools -p test_documentacao.py
python -m unittest discover -s tools -p test_diagramas.py
```

O primeiro gerador mantém apenas inventário JSON, referência técnica e backlog MD. Não sobrescreve README ou outros guias manuais. Os mapas e índices são reprodutíveis; não editar SVG/draw.io/índices diretamente, pois a próxima geração usa `mapas.json`. Abra `trainforge.drawio` no draw.io Desktop ou extensão VS Code `hediet.vscode-drawio`, com uma página por assunto. Nenhuma instalação ou envio externo é necessário para ler SVGs.

Se o schema mudar, obter snapshot somente de metadados em transação read-only, revisar tabelas/FKs e atualizar banco/mapas; não exportar linhas de usuário. O snapshot não é prova de que um clone novo aplicou migrations. O gerador valida as fontes declaradas dos mapas e recusa SVG/XML divergente; testes conferem as 30 tabelas do núcleo e quatro do catálogo.

## Swagger e recarga Go

Swaggo **1.16.6** gera `services/api/internal/swaggerdocs/docs.go` e `contracts/generated/swagger-v1.json/.yaml`; o catálogo possui geração própria. Paths, DTOs, erros, paginação, unidades e permissões devem realizar o contrato revisado. Anotação `@Security` não implementa autenticação.

```powershell
python tools/gerar_swagger.py --write
python tools/gerar_swagger.py --check
python tools/gerar_catalogo_m1_swagger.py --check
```

As ferramentas reutilizam a instalação existente. Em clone novo, instalar explicitamente com `go install github.com/swaggo/swag/cmd/swag@v1.16.6` quando necessário; a ferramenta verifica o módulo com `go version -m`, pois o rótulo CLI dessa tag imprime 1.16.4. A geração usa diretório temporário e nome fixo do pacote, sem depender do caminho do clone.

`dev_api.py` observa Go/go.mod/go.sum, ignora derivados e executa geração → build → restart; build falho preserva o processo anterior. Salvar comentário ou recarregar o navegador isoladamente não executa Swaggo. O watcher não aplica migration. Swagger local, com a API iniciada: `http://127.0.0.1:8082/docs/index.html`. A [operação diária](../aprendizado/operacao-local.md) usa o helper do ambiente, sem init/activate/restore.

Flutter mantém DTOs explícitos; nenhum gerador Dart foi adotado. Adotar um futuramente requer comprovar compatibilidade com Swagger 2 e contratos reais. Exemplos devem ser anônimos; não embutir tokens, corpos privados ou credenciais na UI/documentação.

## CI e portabilidade

`.github/workflows/documentacao.yml` regenera, testa e verifica deriva. Em PR não recebe credencial de escrita. Em push/dispatch confiável da branch padrão, um job separado recebe o artefato e versiona somente derivados permitidos; não executa scripts de PR com escrita, não faz force-push nem contorna proteção de branch. Falha de push é explícita.

A geração usa Python/biblioteca padrão e não depende do clone externo Fastify, caminhos absolutos, mtime ou timestamp variável. A suíte documental valida XML/SVG, páginas e referências dos mapas, e a CI também confere Swagger/Go. Execuções anteriores têm [recibo](../execucao/v1/publicacao-ci-verification.json); isso não prova que a execução de um commit novo já ocorreu.

Atualizar o snapshot externo é uma operação histórica explícita, não parte da geração diária:

```powershell
python tools/gerar_documentacao.py --capture-backend C:/caminho/do/backend --write
```

Esse comando exige repositório limpo, captura revisão/metadados e não lê `.env`, tráfego ou banco. Não executá-lo para manter o Go. O Graphify usa atualização AST incremental de `lib/`, code-only/no-cluster; Go/SQL ficam nos mapas, fontes e Swagger. [Detalhes Graphify](../graphify.md).

Import não é trace; construtor não prova clique; rota compatível não prova DTO/login; anotação não prova registro; tabela existente não entrega jornada; hash não libera direito ou comprova revisão humana. Evidências runtime e conclusão das histórias ficam nos seus recibos, backlog e handoff.


## Correções de CI em17/11/2026

O catálogo gera Swagger somente a partir dos diretórios públicos, mantendo a recusa de rotas/DTOs privados. Testes Go com `-json` têm stdout separado de stderr: downloads de cache frio não são eventos JSON e nunca são publicados como evidência. O parser continua estrito.

O SDK mínimo e a imagem de build foram atualizados paraGo 1.27.4, por digest oficial, após o achado [GO-2026-6859](https://pkg.go.dev/vuln/GO-2026-6859) no primeiro CI pós-push. Não houve alteração de contrato HTTP, schema ou dados do produto.
