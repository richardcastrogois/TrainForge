# Swagger gerado por comentários e tipos Go

Decisão do autor em **21/10/2026**: documentar handlers com comentários e DTOs Go; gerar a especificação e disponibilizar Swagger UI no futuro serviço. Não manter um YAML manual como fonte concorrente.

## Escolha inicial e compatibilidade

Preparação com **Swaggo v1.16.6**, versão identificada e fixada, em vez de instalar `@latest`. O fluxo documentado dessa versão gera **Swagger2.0 / OpenAPI2.0**. Isso não deve ser chamado de OpenAPI3. A linha2 tem releases com sufixoRC; uma mudança de formato/versão precisa de teste com os contratos e o cliente Dart, não de troca automática. Fontes: [release fixada](https://github.com/swaggo/swag/releases/tag/v1.16.6), [README dessa versão](https://github.com/swaggo/swag/blob/v1.16.6/README.md), [releases](https://github.com/swaggo/swag/releases).

Swagger UI é a interface de leitura/teste; Swagger/OpenAPI é a especificação. O objetivo é a atualização por comentários, não exigir uma família específica de framework. A integração `net/http` pode usar [http-swagger](https://github.com/swaggo/http-swagger), com versão a fixar em V1-008 após o teste da primeira rota.

## Fonte e derivados

```text
Handler Go + comentários @Router/@Param/@Success/@Failure
                    + structs de request/response
                              ↓ Swaggo
services/api/internal/swaggerdocs/docs.go   (gerado, importado pela API)
contracts/generated/swagger-v1.json        (gerado, portátil para ferramentas)
contracts/generated/swagger-v1.yaml        (gerado, não editar)
                              ↓
Swagger UI da API + validação de contrato/cliente + documentação do repositório
```

O contrato é pensado/revisado antes de implementar o comportamento e consumir no Flutter. A geração code-first não autoriza inventar response a partir de implementação acidental: os handlers/DTOs/comentários devem realizar o contrato revisado. Campos, paginação, erro, permissão, unidades e exemplos pertencem à mesma revisão.

Exemplo **de anotação proposta, não endpoint já existente**:

```go
// ListPrograms lista as versões que permitem o uso solicitado.
// @Summary Listar programas do catálogo
// @Tags catalog
// @Produce json
// @Param limit query int false "Quantidade máxima de itens"
// @Success 200 {object} ListProgramsResponse
// @Failure 401 {object} Problem
// @Security BearerAuth
// @Router /api/v1/catalog/programs [get]
```

`ListProgramsResponse` e `Problem` serão structs reais do serviço; o exemplo não cria mock nem conteúdo de runtime. O padrão proposto usa paths completos em `@Router` e basePath raiz, evitando duplicar `/api/v1`. Em V1-008 conferir que o schema descreve os corpos/status reais, inclusive erros de aplicação, e não apenas as anotações.

## Automação preparada e trabalho futuro

`tools/gerar_swagger.py --write` gera em diretório temporário e distribui somente os três derivados definidos; `--check` regenera e falha se divergir. A ferramenta não instala dependências e exige `swag --version` compatível. Se `services/api/go.mod` não existe, informa **PENDENTE V1-008** sem gerar serviço ou spec fictícios.

Depois de implementar a base Go e revisar os pré-requisitos:

```powershell
# Instalação futura explícita da ferramenta de desenvolvimento:
go install github.com/swaggo/swag/cmd/swag@v1.16.6

# Com o serviço/DTOs/comentários já existentes:
python tools/gerar_swagger.py --write
python tools/gerar_swagger.py --check
```

No desenvolvimento do Go, o comando de recarga deve executar **gerar Swagger → compilar → reiniciar API** ao salvar `.go`; excluir `internal/swaggerdocs` e arquivos gerados da observação para evitar loop. Configurar essa sequência no watcher escolhido/reutilizado faz parte de V1-008. Apenas salvar comentário, atualizar a aba ou adicionar `go:generate` não executa o gerador sozinho.

Na CI do serviço, gerar e comparar os três arquivos com a ferramenta fixada, testar DTOs/handlers e conferir registros de rota antes de gerar o cliente Dart. O workflow documental atual extrai arquivos Go/spec quando eles existirem; ele não finge que já foi validado um backend ausente.

## Segurança e evidência

Anotação `@Security` documenta autenticação; não implementa middleware ou autorização por recurso. Exemplos devem ser contratuais e anônimos, sem tokens/dados físicos reais. Swagger UI interativo deve ter exposição/configuração deliberadas por ambiente, sem segredo embutido ou credencial persistente. Testar rotação, isolamento, idempotência e limites continua obrigatório. Interface atualizada não prova API segura ou capaz de atender uma carga.

O [mapa Go gerado](gerado/go-e-swagger.md) separa anotações, registros literais e operações encontradas na especificação. Hoje a ausência do serviço é mostrada explicitamente.
