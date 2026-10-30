# Bancos e tabelas reais

Snapshot de 29/10/2026: somente metadados obtidos em transação READ ONLY; nenhuma linha pessoal consultada/publicada. Núcleo schema 13/30 tabelas; catálogo schema 2/4 tabelas. Nomes de tabelas repetidos pertencem a bases diferentes.

**Uma tabela não chama outra.** Código Go enviaSQL; JOIN combina leituras, FK valida referência e funções/triggers podem executar lógica no PostgreSQL. Chave primária identifica; UNIQUE restringe repetição. FK composta inclui todos os campos listados.

As tabelas de treino existem na fundação; isso não significa que adesão/execução/histórico estejam implementados ou tenham conteúdo liberado. As migrações são a fonte estrutural; o snapshot não autoriza gravar ou apagar nada.

## trainforge_v1_dev

### access_tokens

Credenciais de acesso emitidas e vínculo de sessão.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| token_hash | bytea | Sim |
| family_id | uuid | Sim |
| expires_at | timestamp with time zone | Sim |
| created_at | timestamp with time zone | Sim |

Restrições estruturais:

- FOREIGN KEY (family_id) REFERENCES trainforge_v1.auth_families(id)
- PRIMARY KEY (token_hash)

### account_deletion_intents

Confirmações temporárias para exclusão da conta.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| token_hash | bytea | Sim |
| user_id | uuid | Sim |
| family_id | uuid | Sim |
| expires_at | timestamp with time zone | Sim |
| created_at | timestamp with time zone | Sim |

Restrições estruturais:

- FOREIGN KEY (family_id, user_id) REFERENCES trainforge_v1.auth_families(id, user_id)
- PRIMARY KEY (token_hash)
- UNIQUE (user_id, family_id)

### account_erasures

Ledger mínimo para impedir reaparecimento de dados em restore.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| user_id | uuid | Sim |
| erased_at | timestamp with time zone | Sim |

Restrições estruturais:

- PRIMARY KEY (user_id)

### activity_events

Eventos de uma execução de atividade; fluxo completo pendente.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| id | uuid | Sim |
| session_id | uuid | Sim |
| user_id | uuid | Sim |
| event_type | text | Sim |
| occurred_at | timestamp with time zone | Sim |
| payload | jsonb | Sim |

Restrições estruturais:

- PRIMARY KEY (id)
- FOREIGN KEY (session_id, user_id) REFERENCES trainforge_v1.activity_sessions(id, user_id)

### activity_sessions

Estrutura de execução; não confundir com sessão de autenticação.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| id | uuid | Sim |
| occurrence_id | uuid | Sim |
| user_id | uuid | Sim |
| state | text | Sim |
| started_at | timestamp with time zone | Sim |
| ended_at | timestamp with time zone | Não |
| completed_at | timestamp with time zone | Não |

Restrições estruturais:

- UNIQUE (id, user_id)
- FOREIGN KEY (occurrence_id, user_id) REFERENCES trainforge_v1.schedule_occurrences(id, user_id)
- PRIMARY KEY (id)

### auth_families

Famílias de sessão; revogação conjunta e detecção de reuso.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| id | uuid | Sim |
| user_id | uuid | Sim |
| revoked_at | timestamp with time zone | Não |
| created_at | timestamp with time zone | Sim |

Restrições estruturais:

- UNIQUE (id, user_id)
- PRIMARY KEY (id)
- FOREIGN KEY (user_id) REFERENCES trainforge_v1.users(id)

### batch_content

Vínculo entre lote e versões de conteúdo.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| artifact_sha | text | Sim |
| asset_id | text | Sim |
| version_sha | text | Sim |

Restrições estruturais:

- FOREIGN KEY (artifact_sha) REFERENCES trainforge_v1.import_batches(artifact_sha)
- FOREIGN KEY (asset_id, version_sha) REFERENCES trainforge_v1.content_versions(asset_id, version_sha)
- PRIMARY KEY (artifact_sha, asset_id, version_sha)

### content_versions

Versões imutáveis dos tipos de conteúdo editorial.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| asset_id | text | Sim |
| version_sha | text | Sim |
| kind | text | Sim |
| source_id | text | Sim |
| title | text | Não |
| locale | text | Não |
| source_published_version | text | Não |
| allowed_operations | text[] | Sim |
| payload | jsonb | Sim |
| created_at | timestamp with time zone | Sim |

Restrições estruturais:

- UNIQUE (asset_id, version_sha, kind)
- PRIMARY KEY (asset_id, version_sha)
- FOREIGN KEY (source_id) REFERENCES trainforge_v1.sources(id)

### content_withdrawals

Retirada de conteúdo; presença histórica não libera uso.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| asset_id | text | Sim |
| version_sha | text | Sim |
| reason | text | Sim |
| withdrawn_at | timestamp with time zone | Sim |

Restrições estruturais:

- FOREIGN KEY (asset_id, version_sha) REFERENCES trainforge_v1.content_versions(asset_id, version_sha)
- PRIMARY KEY (asset_id, version_sha)

### enrollments

Estrutura de adesão do titular; V1-015 ainda não implementada.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| id | uuid | Sim |
| user_id | uuid | Sim |
| program_id | text | Sim |
| program_sha | text | Sim |
| status | text | Sim |
| options | jsonb | Sim |
| created_at | timestamp with time zone | Sim |
| program_kind | text | Sim |

Restrições estruturais:

- FOREIGN KEY (program_id, program_sha, program_kind) REFERENCES trainforge_v1.content_versions(asset_id, version_sha, kind)
- UNIQUE (id, user_id, program_id, program_sha)
- UNIQUE (id, user_id)
- PRIMARY KEY (id)
- FOREIGN KEY (program_id, program_sha) REFERENCES trainforge_v1.content_versions(asset_id, version_sha)
- FOREIGN KEY (user_id) REFERENCES trainforge_v1.users(id)

### food_batch_versions

Alimentos/versões associados a um lote de importação.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| artifact_sha | text | Sim |
| food_id | text | Sim |
| version_sha | text | Sim |

Restrições estruturais:

- FOREIGN KEY (artifact_sha) REFERENCES trainforge_v1.food_import_batches(artifact_sha)
- FOREIGN KEY (food_id, version_sha) REFERENCES trainforge_v1.food_versions(food_id, version_sha)
- PRIMARY KEY (artifact_sha, food_id, version_sha)

### food_entries

Consumos explicitamente confirmados e seus dados/cálculos versionados.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| id | uuid | Sim |
| user_id | uuid | Sim |
| food_id | text | Sim |
| food_sha | text | Sim |
| quantity | numeric | Sim |
| unit | text | Sim |
| occurred_at | timestamp with time zone | Sim |
| timezone | text | Sim |
| calculation | jsonb | Sim |
| deleted_at | timestamp with time zone | Não |
| created_at | timestamp with time zone | Sim |

Restrições estruturais:

- FOREIGN KEY (food_id, food_sha) REFERENCES trainforge_v1.food_versions(food_id, version_sha)
- PRIMARY KEY (id)
- FOREIGN KEY (user_id) REFERENCES trainforge_v1.users(id)
- UNIQUE (id, user_id)

### food_import_batches

Rastreabilidade dos lotes de composição alimentar.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| artifact_sha | text | Sim |
| bundle_id | text | Sim |
| manifest_sha | text | Sim |
| review_sha | text | Sim |
| imported_foods | integer | Sim |
| created_at | timestamp with time zone | Sim |

Restrições estruturais:

- PRIMARY KEY (artifact_sha)

### food_name_catalogs

Revisão do catálogo de nomes por idioma para cache coerente.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| locale | text | Sim |
| revision | bigint | Sim |

Restrições estruturais:

- PRIMARY KEY (locale)

### food_name_versions

Nomes editoriais revisados por idioma e versão; cobertura real ainda0.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| food_id | text | Sim |
| food_version_sha | text | Sim |
| locale | text | Sim |
| version_sha | text | Sim |
| name | text | Sim |
| aliases | text[] | Sim |
| payload | jsonb | Sim |
| created_at | timestamp with time zone | Sim |

Restrições estruturais:

- FOREIGN KEY (food_id, food_version_sha) REFERENCES trainforge_v1.food_versions(food_id, version_sha)
- PRIMARY KEY (food_id, food_version_sha, locale, version_sha)

### food_name_withdrawals

Retirada de uma versão traduzida; mantém rastreabilidade.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| food_id | text | Sim |
| food_version_sha | text | Sim |
| locale | text | Sim |
| version_sha | text | Sim |
| reason | text | Sim |
| withdrawn_at | timestamp with time zone | Sim |

Restrições estruturais:

- FOREIGN KEY (food_id, food_version_sha, locale, version_sha) REFERENCES trainforge_v1.food_name_versions(food_id, food_version_sha, locale, version_sha)
- PRIMARY KEY (food_id, food_version_sha, locale, version_sha)

### food_versions

Alimento/base/versão; público ou próprio conforme titularidade.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| food_id | text | Sim |
| version_sha | text | Sim |
| source_id | text | Não |
| source_food_id | text | Não |
| source_row_key | text | Não |
| owner_id | uuid | Não |
| name_original | text | Sim |
| name_pt | text | Não |
| preparation | text | Não |
| basis_quantity | numeric | Não |
| basis_unit | text | Não |
| nutrients | jsonb | Sim |
| provenance | jsonb | Sim |
| created_at | timestamp with time zone | Sim |
| source_published_version | text | Não |
| name_locale | text | Não |
| allowed_operations | text[] | Sim |

Restrições estruturais:

- FOREIGN KEY (source_id) REFERENCES trainforge_v1.sources(id)
- FOREIGN KEY (owner_id) REFERENCES trainforge_v1.users(id)
- PRIMARY KEY (food_id, version_sha)

### food_withdrawals

Versões alimentares retiradas do uso.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| food_id | text | Sim |
| version_sha | text | Sim |
| reason | text | Sim |
| withdrawn_at | timestamp with time zone | Sim |

Restrições estruturais:

- FOREIGN KEY (food_id, version_sha) REFERENCES trainforge_v1.food_versions(food_id, version_sha)
- PRIMARY KEY (food_id, version_sha)

### idempotency_records

Resultado de operações para reconciliar reenvios sem duplicação.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| user_id | uuid | Sim |
| operation | text | Sim |
| key_hash | bytea | Sim |
| request_hash | bytea | Sim |
| response_status | integer | Sim |
| response_body | jsonb | Não |
| expires_at | timestamp with time zone | Sim |

Restrições estruturais:

- PRIMARY KEY (user_id, operation, key_hash)
- FOREIGN KEY (user_id) REFERENCES trainforge_v1.users(id)

### import_batches

Rastreabilidade de lotes editoriais importados.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| artifact_sha | text | Sim |
| bundle_id | text | Sim |
| manifest_sha | text | Sim |
| imported_assets | integer | Sim |
| created_at | timestamp with time zone | Sim |

Restrições estruturais:

- PRIMARY KEY (artifact_sha)

### meal_items

Relação refeição/consumo sobre o mesmo registro, sem cópia de nutrientes.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| entry_id | uuid | Sim |
| user_id | uuid | Sim |
| meal_id | uuid | Sim |
| position | integer | Sim |

Restrições estruturais:

- FOREIGN KEY (entry_id, user_id) REFERENCES trainforge_v1.food_entries(id, user_id) ON DELETE CASCADE
- UNIQUE (meal_id, "position")
- FOREIGN KEY (meal_id, user_id) REFERENCES trainforge_v1.meals(id, user_id) ON DELETE CASCADE
- PRIMARY KEY (entry_id)

### meal_versions

Revisões de nome/horário e metadados da refeição.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| meal_id | uuid | Sim |
| user_id | uuid | Sim |
| revision | integer | Sim |
| title | text | Sim |
| occurred_at | timestamp with time zone | Sim |
| timezone | text | Sim |
| entry_ids | uuid[] | Sim |
| deleted | boolean | Sim |
| confirmed_at | timestamp with time zone | Sim |

Restrições estruturais:

- FOREIGN KEY (meal_id, user_id) REFERENCES trainforge_v1.meals(id, user_id) ON DELETE CASCADE
- PRIMARY KEY (meal_id, revision)

### meals

Agrupamento de consumos do titular por refeição.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| id | uuid | Sim |
| user_id | uuid | Sim |
| title | text | Sim |
| occurred_at | timestamp with time zone | Sim |
| timezone | text | Sim |
| revision | integer | Sim |
| deleted_at | timestamp with time zone | Não |
| created_at | timestamp with time zone | Sim |

Restrições estruturais:

- UNIQUE (id, user_id)
- PRIMARY KEY (id)
- FOREIGN KEY (user_id) REFERENCES trainforge_v1.users(id)

### program_items

Componentes de programa. Estrutura existente; zero programas reais liberados.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| program_id | text | Sim |
| program_sha | text | Sim |
| session_key | text | Sim |
| position | integer | Sim |
| movement_id | text | Sim |
| movement_sha | text | Sim |
| source_dose | jsonb | Não |
| program_kind | text | Sim |
| movement_kind | text | Sim |

Restrições estruturais:

- FOREIGN KEY (movement_id, movement_sha, movement_kind) REFERENCES trainforge_v1.content_versions(asset_id, version_sha, kind)
- FOREIGN KEY (program_id, program_sha, program_kind) REFERENCES trainforge_v1.content_versions(asset_id, version_sha, kind)
- FOREIGN KEY (program_id, program_sha, session_key) REFERENCES trainforge_v1.program_sessions(program_id, program_sha, session_key)
- FOREIGN KEY (movement_id, movement_sha) REFERENCES trainforge_v1.content_versions(asset_id, version_sha)
- PRIMARY KEY (program_id, program_sha, session_key, "position")
- FOREIGN KEY (program_id, program_sha) REFERENCES trainforge_v1.content_versions(asset_id, version_sha)

### program_sessions

Sessões previstas em versão de programa; sem jornada completa ativa.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| program_id | text | Sim |
| program_sha | text | Sim |
| program_kind | text | Sim |
| session_key | text | Sim |
| source_metadata | jsonb | Sim |

Restrições estruturais:

- PRIMARY KEY (program_id, program_sha, session_key)
- FOREIGN KEY (program_id, program_sha, program_kind) REFERENCES trainforge_v1.content_versions(asset_id, version_sha, kind)

### refresh_tokens

Material de renovação protegido conforme implementação; não expor em logs.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| token_hash | bytea | Sim |
| family_id | uuid | Sim |
| expires_at | timestamp with time zone | Sim |
| consumed_at | timestamp with time zone | Não |
| created_at | timestamp with time zone | Sim |

Restrições estruturais:

- FOREIGN KEY (family_id) REFERENCES trainforge_v1.auth_families(id)
- PRIMARY KEY (token_hash)

### schedule_occurrences

Ocorrências de agenda; jornada depende de seleção/execução.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| id | uuid | Sim |
| user_id | uuid | Sim |
| enrollment_id | uuid | Sim |
| source_session_key | text | Sim |
| planned_for | timestamp with time zone | Sim |
| timezone | text | Sim |
| program_id | text | Sim |
| program_sha | text | Sim |

Restrições estruturais:

- FOREIGN KEY (program_id, program_sha, source_session_key) REFERENCES trainforge_v1.program_sessions(program_id, program_sha, session_key)
- FOREIGN KEY (enrollment_id, user_id, program_id, program_sha) REFERENCES trainforge_v1.enrollments(id, user_id, program_id, program_sha)
- UNIQUE (enrollment_id, planned_for, source_session_key)
- FOREIGN KEY (enrollment_id, user_id) REFERENCES trainforge_v1.enrollments(id, user_id)
- UNIQUE (id, user_id)
- PRIMARY KEY (id)

### sources

Identificação da fonte editorial e seus dados de origem.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| id | text | Sim |
| name | text | Sim |
| publisher | text | Não |
| urls | jsonb | Sim |
| created_at | timestamp with time zone | Sim |

Restrições estruturais:

- PRIMARY KEY (id)

### training_configuration_versions

Revisões privadas da configuração que a pessoa confirmou.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| user_id | uuid | Sim |
| revision | integer | Sim |
| configuration | jsonb | Sim |
| confirmed_at | timestamp with time zone | Sim |

Restrições estruturais:

- PRIMARY KEY (user_id, revision)
- FOREIGN KEY (user_id) REFERENCES trainforge_v1.users(id)

### users

Identidade estável do usuário. Não guardar senha Google.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| id | uuid | Sim |
| provider | text | Sim |
| issuer | text | Sim |
| subject | text | Sim |
| display_name | text | Não |
| email | text | Não |
| created_at | timestamp with time zone | Sim |

Restrições estruturais:

- PRIMARY KEY (id)
- UNIQUE (provider, issuer, subject)

## trainforge_catalog_dev

### catalog_releases

Publicações imutáveis e autoridade atual do catálogo separado.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| revision | bigint | Sim |
| digest | text | Sim |
| previous_digest | text | Sim |
| package_digest | text | Sim |
| published_at | timestamp with time zone | Sim |

Restrições estruturais:

- PRIMARY KEY (revision)

### content_versions

Versões imutáveis dos tipos de conteúdo editorial.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| asset_id | text | Sim |
| version_sha | text | Sim |
| kind | text | Sim |
| source_id | text | Sim |
| title | text | Não |
| locale | text | Não |
| source_published_version | text | Não |
| allowed_operations | text[] | Sim |
| payload | jsonb | Sim |
| created_at | timestamp with time zone | Sim |

Restrições estruturais:

- PRIMARY KEY (asset_id, version_sha)
- FOREIGN KEY (source_id) REFERENCES trainforge_v1.sources(id)

### content_withdrawals

Retirada de conteúdo; presença histórica não libera uso.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| asset_id | text | Sim |
| version_sha | text | Sim |
| reason | text | Sim |
| withdrawn_at | timestamp with time zone | Sim |

Restrições estruturais:

- FOREIGN KEY (asset_id, version_sha) REFERENCES trainforge_v1.content_versions(asset_id, version_sha)
- PRIMARY KEY (asset_id, version_sha)

### sources

Identificação da fonte editorial e seus dados de origem.

| Coluna | TipoPostgreSQL | NOT NULL |
|---|---|---|
| id | text | Sim |
| name | text | Sim |
| publisher | text | Não |
| urls | jsonb | Sim |
| created_at | timestamp with time zone | Sim |

Restrições estruturais:

- PRIMARY KEY (id)

## Quem acessa estas tabelas?

| Módulo | Acesso |
|---|---|
| auth | Conta, famílias, access e refresh; transações em internal/auth/postgres.go |
| privacy | Exportação, confirmação/exclusão e ledger; funções e restore controlados |
| nutrition | Busca/versões/alimentos próprios/consumos e refeições; titular obrigatório nas rotas privadas |
| trainingconfig | FunçõesSQL para configuração privada, revisão e idempotência; runtime sem escrita direta livre |
| catálogo | Leitor do banco público separado; credencial sem acesso ao núcleo privado |
| importadores/migradores | Operações administrativas com credenciais próprias; não são endpoints do APK |

Os diagramas11–15 mostram pares de tabelas comFK em setas da dependente para a referenciada. Não mostram ordem deINSERT nem prescrição de treino.
