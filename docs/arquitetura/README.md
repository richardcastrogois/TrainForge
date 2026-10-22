# Arquitetura do TrainForge — comece aqui

> Gerado de código e registros versionados por `tools/gerar_documentacao.py`. Não editar este arquivo à mão. Revisão das entradas: `9147d3cd1695ebc5`.

**Leia este arquivo e os links abaixo no GitHub ou no editor. Não é necessário iniciar Python, Go, API, banco ou servidor para consultar.** Os diagramas Mermaid são texto versionado e renderizado pelo GitHub.

## O que existe e o que é proposta

| Área | Evidência e limite |
| --- | --- |
| Flutter neste clone | 43 arquivos Dart; análise estática, sem teste runtime |
| Backend Fastify externo | Referência auditada em 2026-10-21, commit `523f6d9609be`; 29 rotas extraídas. O clone não contém esse código |
| Go neste clone | 16 arquivos Go de aplicação; 7 registros net/http detectados |
| Produto | Android e iOS; primeiro desenvolvimento/teste em Android |
| Conteúdo | Pesquisa concluída nos recortes; publicação/prática/direitos continuam por item |

## Mapa atual: estrutura e correspondências

```mermaid
flowchart LR
    node0["Telas e widgets (13 arquivos)"]
    node1["Repositories Flutter (7 arquivos)"]
    node2["HTTP Dio (8 arquivos)"]
    node3["Modelos Dart (9 arquivos)"]
    node4["Fastify: referência externa versionada"]
    node2 -->|"importação estática"| node3
    node1 -->|"importação estática"| node2
    node1 -->|"importação estática"| node3
    node0 -->|"importação estática"| node3
    node0 -->|"importação estática"| node1
    node2 -->|"12 métodos e paths compatíveis"| node4
```

Setas de importação não são traces. Correspondência HTTP não confirma autenticação, DTO completo ou resposta em execução.

## Arquitetura proposta: ainda a implementar

```mermaid
flowchart LR
    node0["Pessoa"]
    node1["Telas Flutter"]
    node2["ViewModels / controllers"]
    node3["Repositories / DTOs"]
    node4["Cliente Dio / sessão"]
    node5["Módulo auth Go"]
    node6["Módulo catalog Go"]
    node7["Módulo activity Go"]
    node8["Módulo nutrition Go"]
    node9["PostgreSQL"]
    node10["Manifestos revisados"]
    node11["Importador Go"]
    node12["Mídia autorizada / referência"]
    node13["Logs / métricas / traces"]
    node14["Google Identity"]
    node0 -->|"Ações e dados confirmados"| node1
    node1 -->|"Comando tipado"| node2
    node2 -->|"Método de domínio"| node3
    node3 -->|"DTO versionado"| node4
    node4 -->|"POST /api/v1/auth/google, refresh, logout"| node5
    node5 -->|"Verificar assinatura e claims"| node14
    node5 -->|"Consulta / transação"| node9
    node4 -->|"GET /api/v1/catalog/programs/{id}"| node6
    node4 -->|"POST enrollments / sessions / events; GET summary/history"| node7
    node4 -->|"GET/POST foods; POST food-entries"| node8
    node6 -->|"SELECT projetado e paginado"| node9
    node7 -->|"Transação por ocorrência"| node9
    node8 -->|"Leitura / transação privada"| node9
    node10 -->|"Arquivo validado"| node11
    node11 -->|"Transação idempotente"| node9
    node6 -->|"URL de ativo autorizado ou referência"| node12
    node5 -->|"Telemetria redigida"| node13
    node7 -->|"Telemetria redigida"| node13
```

A proposta Go não vira código atual por estar no desenho. Detalhes, camadas e limites de capacidade estão nos documentos revisados.

## Explorar por assunto

- [Telas, destinos e jornadas](gerado/telas-e-fluxos.md)
- [Quem chama quem, entradas e respostas](gerado/chamadas-http.md)
- [Modelos e relações do banco](gerado/banco.md)
- [Go: comentários, registros e especificação](gerado/go-e-swagger.md)
- [Progresso, dependências e tarefas](gerado/progresso.md)

- [Camadas do backend Go](camadas-go.md)
- [Como a documentação se atualiza](documentacao-dinamica.md)
- [Swagger por comentários](swagger-go.md)
- [Arquitetura proposta e decisões](arquitetura-alvo.md)
- [Diagnóstico e achados](diagnostico-atual.md)
- [Plano macro da V1](../execucao/v1/plano-macro.md)
