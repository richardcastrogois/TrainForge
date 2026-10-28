# Progresso e dependências

> Gerado de código e registros versionados por `tools/gerar_documentacao.py`. Não editar este arquivo à mão. Revisão das entradas: `02f82d50940a80dc`.

**18/49 histórias concluídas**, em 12 épicos. Próxima história: **V1-047**. Status vem do backlog revisado, não da existência de arquivo ou de um desenho.

| Épico | Objetivo | Histórias | Concluídas |
| --- | --- | --- | --- |
| EP01 | Recorte verificável e governança | 3 | 3 |
| EP02 | Conteúdo, autoria e direitos | 3 | 3 |
| EP03 | Fundação Go, contratos e banco | 4 | 4 |
| EP04 | Identidade, privacidade e acesso | 4 | 3 |
| EP05 | Biblioteca humana e API de catálogo | 5 | 1 |
| EP06 | Atividade e alimentação registradas de verdade | 7 | 2 |
| EP07 | Flutter e experiência da V1 | 8 | 2 |
| EP08 | Segurança, desempenho e observabilidade | 3 | 0 |
| EP09 | Infraestrutura, CI e implantação | 3 | 0 |
| EP10 | APK e primeiro teste acompanhado | 4 | 0 |
| EP11 | iOS e distribuição nas lojas | 2 | 0 |
| EP12 | Visão integral após o primeiro piloto | 3 | 0 |

## Dependências por história

### EP01 — Recorte verificável e governança

```mermaid
flowchart LR
    node0["V1-001"]
    node1["V1-002"]
    node2["V1-003"]
    node0 -->|"requer"| node1
```

| História | Status | Entrega | Depende de |
| --- | --- | --- | --- |
| V1-001 | done | Mapear conteúdo e cenários do APK de avaliação | nenhuma |
| V1-002 | done | Aceitar a decisão Go e definir a fronteira de migração | V1-001 |
| V1-003 | done | Manter documentação arquitetural dinâmica no repositório | nenhuma |
### EP02 — Conteúdo, autoria e direitos

```mermaid
flowchart LR
    node0["V1-001 (pré-requisito externo ao épico)"]
    node1["V1-004"]
    node2["V1-005"]
    node3["V1-006"]
    node4["V1-010 (pré-requisito externo ao épico)"]
    node0 -->|"requer"| node1
    node1 -->|"requer"| node2
    node2 -->|"requer"| node3
    node4 -->|"requer"| node3
```

| História | Status | Entrega | Depende de |
| --- | --- | --- | --- |
| V1-004 | done | Criar contrato editorial dos quatro tipos de conteúdo | V1-001 |
| V1-005 | done | Revisar o lote real para o uso do piloto | V1-004 |
| V1-006 | done | Importar conteúdo de forma idempotente e auditável | V1-005, V1-010 |
### EP03 — Fundação Go, contratos e banco

```mermaid
flowchart LR
    node0["V1-002 (pré-requisito externo ao épico)"]
    node1["V1-004 (pré-requisito externo ao épico)"]
    node2["V1-007"]
    node3["V1-008"]
    node4["V1-009"]
    node5["V1-010"]
    node0 -->|"requer"| node2
    node1 -->|"requer"| node3
    node2 -->|"requer"| node3
    node1 -->|"requer"| node4
    node2 -->|"requer"| node4
    node4 -->|"requer"| node5
```

| História | Status | Entrega | Depende de |
| --- | --- | --- | --- |
| V1-007 | done | Criar o esqueleto do monólito modular Go | V1-002 |
| V1-008 | done | Gerar Swagger dos comentários e DTOs Go antes do cliente | V1-004, V1-007 |
| V1-009 | done | Modelar conteúdo versionado, adesão e ocorrências | V1-004, V1-007 |
| V1-010 | done | Criar migrations e testar backup/restauração | V1-009 |
### EP04 — Identidade, privacidade e acesso

```mermaid
flowchart LR
    node0["V1-008 (pré-requisito externo ao épico)"]
    node1["V1-009 (pré-requisito externo ao épico)"]
    node2["V1-010 (pré-requisito externo ao épico)"]
    node3["V1-011"]
    node4["V1-012"]
    node5["V1-013"]
    node6["V1-017 (pré-requisito externo ao épico)"]
    node7["V1-020 (pré-requisito externo ao épico)"]
    node8["V1-021 (pré-requisito externo ao épico)"]
    node9["V1-042 (pré-requisito externo ao épico)"]
    node10["V1-045 (pré-requisito externo ao épico)"]
    node11["V1-049"]
    node0 -->|"requer"| node3
    node2 -->|"requer"| node3
    node3 -->|"requer"| node4
    node3 -->|"requer"| node5
    node1 -->|"requer"| node5
    node4 -->|"requer"| node11
    node5 -->|"requer"| node11
    node6 -->|"requer"| node11
    node7 -->|"requer"| node11
    node8 -->|"requer"| node11
    node9 -->|"requer"| node11
    node10 -->|"requer"| node11
```

| História | Status | Entrega | Depende de |
| --- | --- | --- | --- |
| V1-011 | done | Autenticar Google no novo serviço | V1-008, V1-010 |
| V1-012 | done | Rotacionar e revogar refresh tokens | V1-011 |
| V1-013 | done | Aplicar autorização, limites e ciclo dos dados | V1-011, V1-009 |
| V1-049 | todo | Autorizar exclusão própria e exceção master auditada | V1-012, V1-013, V1-017, V1-020, V1-021, V1-042, V1-045 |
### EP05 — Biblioteca humana e API de catálogo

```mermaid
flowchart LR
    node0["V1-006 (pré-requisito externo ao épico)"]
    node1["V1-008 (pré-requisito externo ao épico)"]
    node2["V1-012 (pré-requisito externo ao épico)"]
    node3["V1-013 (pré-requisito externo ao épico)"]
    node4["V1-014"]
    node5["V1-015"]
    node6["V1-016"]
    node7["V1-021 (pré-requisito externo ao épico)"]
    node8["V1-044"]
    node9["V1-047"]
    node10["V1-048 (pré-requisito externo ao épico)"]
    node0 -->|"requer"| node4
    node1 -->|"requer"| node4
    node1 -->|"requer"| node9
    node2 -->|"requer"| node9
    node3 -->|"requer"| node9
    node7 -->|"requer"| node9
    node10 -->|"requer"| node9
    node4 -->|"requer"| node5
    node3 -->|"requer"| node5
    node9 -->|"requer"| node5
    node4 -->|"requer"| node6
    node5 -->|"requer"| node8
    node6 -->|"requer"| node8
    node7 -->|"requer"| node8
```

| História | Status | Entrega | Depende de |
| --- | --- | --- | --- |
| V1-014 | done | Servir catálogo, versão e requisitos de uso | V1-006, V1-008 |
| V1-047 | doing | Persistir configuração completa antes da seleção de treino | V1-008, V1-012, V1-013, V1-021, V1-048 |
| V1-015 | todo | Criar adesão sem geração de treino | V1-014, V1-013, V1-047 |
| V1-016 | todo | Expor instrução acessível e mídia com direitos | V1-014 |
| V1-044 | todo | Compor treino com regras humanas revisadas | V1-015, V1-016, V1-021 |
### EP06 — Atividade e alimentação registradas de verdade

```mermaid
flowchart LR
    node0["V1-004 (pré-requisito externo ao épico)"]
    node1["V1-008 (pré-requisito externo ao épico)"]
    node2["V1-010 (pré-requisito externo ao épico)"]
    node3["V1-012 (pré-requisito externo ao épico)"]
    node4["V1-013 (pré-requisito externo ao épico)"]
    node5["V1-015 (pré-requisito externo ao épico)"]
    node6["V1-017"]
    node7["V1-018"]
    node8["V1-019"]
    node9["V1-020"]
    node10["V1-021 (pré-requisito externo ao épico)"]
    node11["V1-025 (pré-requisito externo ao épico)"]
    node12["V1-042"]
    node13["V1-045"]
    node14["V1-046"]
    node5 -->|"requer"| node6
    node3 -->|"requer"| node6
    node6 -->|"requer"| node7
    node0 -->|"requer"| node8
    node2 -->|"requer"| node8
    node8 -->|"requer"| node9
    node4 -->|"requer"| node9
    node1 -->|"requer"| node9
    node4 -->|"requer"| node12
    node9 -->|"requer"| node12
    node11 -->|"requer"| node12
    node13 -->|"requer"| node12
    node9 -->|"requer"| node13
    node10 -->|"requer"| node13
    node13 -->|"requer"| node14
    node9 -->|"requer"| node14
    node10 -->|"requer"| node14
```

| História | Status | Entrega | Depende de |
| --- | --- | --- | --- |
| V1-017 | todo | Executar ocorrências idempotentes de atividade | V1-015, V1-012 |
| V1-018 | todo | Consultar histórico e resumo com origem das métricas | V1-017 |
| V1-019 | done | Validar e importar o lote alimentar | V1-004, V1-010 |
| V1-020 | done | Pesquisar e cadastrar alimento próprio e registrar consumo | V1-019, V1-013, V1-008 |
| V1-042 | todo | Reconhecer alimentos por foto com revisão e quantidade informada | V1-013, V1-020, V1-025, V1-045 |
| V1-045 | todo | Organizar registros por refeição e por alimento | V1-020, V1-021 |
| V1-046 | todo | Entregar histórico visual, análise nutricional e dicas revisadas | V1-045, V1-020, V1-021 |
### EP07 — Flutter e experiência da V1

```mermaid
flowchart LR
    node0["V1-008 (pré-requisito externo ao épico)"]
    node1["V1-012 (pré-requisito externo ao épico)"]
    node2["V1-013 (pré-requisito externo ao épico)"]
    node3["V1-014 (pré-requisito externo ao épico)"]
    node4["V1-015 (pré-requisito externo ao épico)"]
    node5["V1-016 (pré-requisito externo ao épico)"]
    node6["V1-017 (pré-requisito externo ao épico)"]
    node7["V1-018 (pré-requisito externo ao épico)"]
    node8["V1-020 (pré-requisito externo ao épico)"]
    node9["V1-021"]
    node10["V1-022"]
    node11["V1-023"]
    node12["V1-024"]
    node13["V1-025"]
    node14["V1-026"]
    node15["V1-027"]
    node16["V1-048"]
    node0 -->|"requer"| node9
    node1 -->|"requer"| node9
    node3 -->|"requer"| node10
    node4 -->|"requer"| node10
    node9 -->|"requer"| node10
    node5 -->|"requer"| node11
    node6 -->|"requer"| node11
    node10 -->|"requer"| node11
    node7 -->|"requer"| node12
    node9 -->|"requer"| node12
    node2 -->|"requer"| node12
    node8 -->|"requer"| node13
    node9 -->|"requer"| node13
    node16 -->|"requer"| node13
    node11 -->|"requer"| node14
    node13 -->|"requer"| node14
    node8 -->|"requer"| node16
    node9 -->|"requer"| node16
    node10 -->|"requer"| node15
    node12 -->|"requer"| node15
    node13 -->|"requer"| node15
    node16 -->|"requer"| node15
```

| História | Status | Entrega | Depende de |
| --- | --- | --- | --- |
| V1-021 | done | Organizar configuração, composição e estado | V1-008, V1-012 |
| V1-022 | todo | Implementar entrada e biblioteca com conteúdo real | V1-014, V1-015, V1-021 |
| V1-023 | todo | Implementar sessão e recuperação de interrupção | V1-016, V1-017, V1-022 |
| V1-024 | todo | Implementar Hoje, histórico e perfil | V1-018, V1-021, V1-013 |
| V1-025 | todo | Implementar busca, cadastro próprio e registro alimentar no Flutter | V1-020, V1-021, V1-048 |
| V1-026 | todo | Tratar offline e sincronização sem fingir sucesso | V1-023, V1-025 |
| V1-048 | done | Localizar interface e nomes alimentares com revisão | V1-020, V1-021 |
| V1-027 | todo | Validar acessibilidade e paridade de contratos Android/iOS | V1-022, V1-024, V1-025, V1-048 |
### EP08 — Segurança, desempenho e observabilidade

```mermaid
flowchart LR
    node0["V1-007 (pré-requisito externo ao épico)"]
    node1["V1-013 (pré-requisito externo ao épico)"]
    node2["V1-014 (pré-requisito externo ao épico)"]
    node3["V1-018 (pré-requisito externo ao épico)"]
    node4["V1-020 (pré-requisito externo ao épico)"]
    node5["V1-021 (pré-requisito externo ao épico)"]
    node6["V1-028"]
    node7["V1-029"]
    node8["V1-030"]
    node1 -->|"requer"| node6
    node5 -->|"requer"| node6
    node0 -->|"requer"| node7
    node3 -->|"requer"| node7
    node2 -->|"requer"| node8
    node3 -->|"requer"| node8
    node4 -->|"requer"| node8
    node7 -->|"requer"| node8
```

| História | Status | Entrega | Depende de |
| --- | --- | --- | --- |
| V1-028 | todo | Auditar dependências, segredos e superfície de ataque | V1-013, V1-021 |
| V1-029 | todo | Instrumentar requisições, consultas e falhas | V1-007, V1-018 |
| V1-030 | todo | Medir consultas e carga representativa | V1-014, V1-018, V1-020, V1-029 |
### EP09 — Infraestrutura, CI e implantação

```mermaid
flowchart LR
    node0["V1-006 (pré-requisito externo ao épico)"]
    node1["V1-007 (pré-requisito externo ao épico)"]
    node2["V1-008 (pré-requisito externo ao épico)"]
    node3["V1-010 (pré-requisito externo ao épico)"]
    node4["V1-020 (pré-requisito externo ao épico)"]
    node5["V1-028 (pré-requisito externo ao épico)"]
    node6["V1-029 (pré-requisito externo ao épico)"]
    node7["V1-031"]
    node8["V1-032"]
    node9["V1-033"]
    node1 -->|"requer"| node7
    node3 -->|"requer"| node7
    node2 -->|"requer"| node8
    node5 -->|"requer"| node8
    node7 -->|"requer"| node9
    node8 -->|"requer"| node9
    node0 -->|"requer"| node9
    node4 -->|"requer"| node9
    node6 -->|"requer"| node9
```

| História | Status | Entrega | Depende de |
| --- | --- | --- | --- |
| V1-031 | todo | Escolher hospedagem e orçamento do piloto | V1-007, V1-010 |
| V1-032 | todo | Construir pipeline e artefatos reproduzíveis | V1-008, V1-028 |
| V1-033 | todo | Implantar staging e conferir restauração | V1-031, V1-032, V1-006, V1-020, V1-029 |
### EP10 — APK e primeiro teste acompanhado

```mermaid
flowchart LR
    node0["V1-021 (pré-requisito externo ao épico)"]
    node1["V1-023 (pré-requisito externo ao épico)"]
    node2["V1-024 (pré-requisito externo ao épico)"]
    node3["V1-025 (pré-requisito externo ao épico)"]
    node4["V1-026 (pré-requisito externo ao épico)"]
    node5["V1-027 (pré-requisito externo ao épico)"]
    node6["V1-030 (pré-requisito externo ao épico)"]
    node7["V1-032 (pré-requisito externo ao épico)"]
    node8["V1-033 (pré-requisito externo ao épico)"]
    node9["V1-034"]
    node10["V1-035"]
    node11["V1-036"]
    node12["V1-037"]
    node13["V1-042 (pré-requisito externo ao épico)"]
    node14["V1-044 (pré-requisito externo ao épico)"]
    node15["V1-045 (pré-requisito externo ao épico)"]
    node16["V1-046 (pré-requisito externo ao épico)"]
    node17["V1-047 (pré-requisito externo ao épico)"]
    node18["V1-048 (pré-requisito externo ao épico)"]
    node19["V1-049 (pré-requisito externo ao épico)"]
    node0 -->|"requer"| node9
    node7 -->|"requer"| node9
    node1 -->|"requer"| node10
    node2 -->|"requer"| node10
    node3 -->|"requer"| node10
    node4 -->|"requer"| node10
    node5 -->|"requer"| node10
    node6 -->|"requer"| node10
    node8 -->|"requer"| node10
    node9 -->|"requer"| node10
    node13 -->|"requer"| node10
    node14 -->|"requer"| node10
    node15 -->|"requer"| node10
    node16 -->|"requer"| node10
    node17 -->|"requer"| node10
    node18 -->|"requer"| node10
    node19 -->|"requer"| node10
    node10 -->|"requer"| node11
    node11 -->|"requer"| node12
```

| História | Status | Entrega | Depende de |
| --- | --- | --- | --- |
| V1-034 | todo | Preparar identidade e assinatura Android | V1-021, V1-032 |
| V1-035 | todo | Validar a jornada completa da V1 | V1-023, V1-024, V1-025, V1-026, V1-027, V1-030, V1-033, V1-034, V1-042, V1-044, V1-045, V1-046, V1-047, V1-048, V1-049 |
| V1-036 | todo | Gerar e disponibilizar APK à esposa | V1-035 |
| V1-037 | todo | Encerrar piloto e priorizar correções | V1-036 |
### EP11 — iOS e distribuição nas lojas

```mermaid
flowchart LR
    node0["V1-027 (pré-requisito externo ao épico)"]
    node1["V1-035 (pré-requisito externo ao épico)"]
    node2["V1-037 (pré-requisito externo ao épico)"]
    node3["V1-038"]
    node4["V1-039"]
    node0 -->|"requer"| node3
    node1 -->|"requer"| node3
    node3 -->|"requer"| node4
    node2 -->|"requer"| node4
```

| História | Status | Entrega | Depende de |
| --- | --- | --- | --- |
| V1-038 | todo | Compilar e testar no ecossistema iOS | V1-027, V1-035 |
| V1-039 | todo | Preparar TestFlight, Play e políticas de publicação | V1-038, V1-037 |
### EP12 — Visão integral após o primeiro piloto

```mermaid
flowchart LR
    node0["V1-013 (pré-requisito externo ao épico)"]
    node1["V1-037 (pré-requisito externo ao épico)"]
    node2["V1-038 (pré-requisito externo ao épico)"]
    node3["V1-040"]
    node4["V1-041"]
    node5["V1-043"]
    node1 -->|"requer"| node3
    node1 -->|"requer"| node4
    node2 -->|"requer"| node4
    node1 -->|"requer"| node5
    node0 -->|"requer"| node5
```

| História | Status | Entrega | Depende de |
| --- | --- | --- | --- |
| V1-040 | todo | Ampliar modalidades, programas e personalização humana | V1-037 |
| V1-041 | todo | Adicionar sensores, GPS e integrações | V1-037, V1-038 |
| V1-043 | todo | Desenvolver acompanhamento e alimentação avançados | V1-037, V1-013 |

[Backlog completo: aceite, tarefas, subtarefas e testes](../../execucao/v1/backlog.md) · [Voltar ao mapa](../README.md)
