# APIs atuais

Gerado a partir de contracts/generated/swagger-v1.json (API 0.9.1).34 operações. Swagger local: http://127.0.0.1:8082/docs/index.html. ContratoHTTP não implica aceitação de conteúdo inexistente.

| Método | Rota | Área | Autorização |
|---|---|---|---|
| POST | /api/v1/auth/google | auth | Credencial específica do fluxo; não publicar o corpo |
| POST | /api/v1/auth/logout | auth | Credencial específica do fluxo; não publicar o corpo |
| POST | /api/v1/auth/refresh | auth | Credencial específica do fluxo; não publicar o corpo |
| GET | /api/v1/catalog/filters | catalog | Pública |
| GET | /api/v1/catalog/movements | catalog | Pública |
| GET | /api/v1/catalog/movements/{id} | catalog | Pública |
| GET | /api/v1/catalog/programs | catalog | Pública |
| GET | /api/v1/catalog/programs/{id} | catalog | Pública |
| GET | /api/v1/foods | nutrition | Pública |
| GET | /api/v1/foods/filters | nutrition | Pública |
| GET | /api/v1/foods/{id} | nutrition | Pública |
| GET | /api/v1/health/live | operation | Pública |
| GET | /api/v1/health/ready | operation | Pública |
| GET | /api/v1/me | auth | Bearer / titular |
| DELETE | /api/v1/me | privacy | Bearer / titular |
| POST | /api/v1/me/deletion-intent | privacy | Bearer / titular |
| GET | /api/v1/me/export | privacy | Bearer / titular |
| GET | /api/v1/me/food-entries | nutrition | Bearer / titular |
| POST | /api/v1/me/food-entries | nutrition | Bearer / titular |
| GET | /api/v1/me/food-entries/{id} | nutrition | Bearer / titular |
| DELETE | /api/v1/me/food-entries/{id} | nutrition | Bearer / titular |
| PATCH | /api/v1/me/food-entries/{id} | nutrition | Bearer / titular |
| GET | /api/v1/me/food-summary | nutrition | Bearer / titular |
| GET | /api/v1/me/foods | nutrition | Bearer / titular |
| POST | /api/v1/me/foods | nutrition | Bearer / titular |
| GET | /api/v1/me/meal-diary | meals | Bearer / titular |
| POST | /api/v1/me/meals | meals | Bearer / titular |
| GET | /api/v1/me/meals/{id} | meals | Bearer / titular |
| DELETE | /api/v1/me/meals/{id} | meals | Bearer / titular |
| PATCH | /api/v1/me/meals/{id} | meals | Bearer / titular |
| GET | /api/v1/me/training-configuration | training-configuration | Bearer / titular |
| PUT | /api/v1/me/training-configuration | training-configuration | Bearer / titular |
| GET | /api/v1/me/training-configuration/resources | training-configuration | Bearer / titular |
| GET | /api/v1/privacy | privacy | Pública |

## Ler uma chamada

Exemplo de consulta: Flutter GoFoodRepository → AppDio → GET foods → handlernutrition → consulta parametrizada → food_versions/fontes → JSON → tela.

Exemplo de escrita: pessoa confirma consumo → POST me/food-entries → sessão/titular/limites → transação/idempotência → food_entries e vínculo de refeição quando aplicável → resposta confirmada. A tabela não recebe requisições do celular diretamente.

As cinco rotas de catálogo passam pela API para o serviço separado. Foto, composição/execução de treino e master não ganham rotas prontas por aparecerem no planejamento.
