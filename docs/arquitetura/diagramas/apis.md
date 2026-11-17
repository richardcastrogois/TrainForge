# APIs atuais

> Gerado por `tools/gerar_diagramas.py` de `contracts/generated/swagger-v1.json`; não editar à mão.

API **0.10.0**, **38 operações**. [Contrato completo](../../../contracts/generated/swagger-v1.json) · [Modelo e regras](../modelo-e-contratos.md) · [Arquitetura](../README.md).

Com a API iniciada, Swagger local: `http://127.0.0.1:8082/docs/index.html`. Operação documentada não implica aceite funcional ou prática autorizada.

| Método | Rota | Área | Autorização |
|---|---|---|---|
| POST | /api/v1/auth/google | auth | Credencial do fluxo; ver contrato |
| POST | /api/v1/auth/logout | auth | Credencial do fluxo; ver contrato |
| POST | /api/v1/auth/refresh | auth | Credencial do fluxo; ver contrato |
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
| DELETE | /api/v1/me | privacy | Bearer / titular |
| GET | /api/v1/me | auth | Bearer / titular |
| GET | /api/v1/me/activity | activity | Bearer / titular |
| POST | /api/v1/me/activity-sessions | activity | Bearer / titular |
| GET | /api/v1/me/activity-sessions/{id} | activity | Bearer / titular |
| POST | /api/v1/me/activity-sessions/{id}/commands | activity | Bearer / titular |
| POST | /api/v1/me/deletion-intent | privacy | Bearer / titular |
| GET | /api/v1/me/export | privacy | Bearer / titular |
| GET | /api/v1/me/food-entries | nutrition | Bearer / titular |
| POST | /api/v1/me/food-entries | nutrition | Bearer / titular |
| DELETE | /api/v1/me/food-entries/{id} | nutrition | Bearer / titular |
| GET | /api/v1/me/food-entries/{id} | nutrition | Bearer / titular |
| PATCH | /api/v1/me/food-entries/{id} | nutrition | Bearer / titular |
| GET | /api/v1/me/food-summary | nutrition | Bearer / titular |
| GET | /api/v1/me/foods | nutrition | Bearer / titular |
| POST | /api/v1/me/foods | nutrition | Bearer / titular |
| GET | /api/v1/me/meal-diary | meals | Bearer / titular |
| POST | /api/v1/me/meals | meals | Bearer / titular |
| DELETE | /api/v1/me/meals/{id} | meals | Bearer / titular |
| GET | /api/v1/me/meals/{id} | meals | Bearer / titular |
| PATCH | /api/v1/me/meals/{id} | meals | Bearer / titular |
| GET | /api/v1/me/training-configuration | training-configuration | Bearer / titular |
| PUT | /api/v1/me/training-configuration | training-configuration | Bearer / titular |
| GET | /api/v1/me/training-configuration/resources | training-configuration | Bearer / titular |
| GET | /api/v1/privacy | privacy | Pública |

## Ler uma chamada

Consulta: tela → repository Flutter → AppDio → handler Go → consulta parametrizada → JSON → tela. Escrita: revisão da pessoa → requisição privada → sessão/titular/revisão → transação/idempotência → resposta confirmada. O celular não consulta tabelas diretamente.

As cinco leituras do catálogo passam pela API para o processo separado. Execução usa ocorrências e eventos reais; seleção/adesão, conteúdo, agenda, foto e master conservam critérios próprios. [Camadas e fluxos](../camadas-e-fluxos.md).
