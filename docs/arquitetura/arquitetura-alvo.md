# Arquitetura atual e reavaliação de execução

**29/10/2026:** Go0.8.1/34operações e schema13/30tabelas estão implementados como um processo modular. O autor esclareceu que sua preferência era microserviços e pediu investigação antes de escolher o rumo. A escolha Go permanece; o autor escolheu detalhar microserviços por etapas. A primeira prova de catálogoM1 foi implementada e aprovada emCI40860200717/ff8c8bb, sem cutover ou migração de dados reais. [Comparação aplicada, domínios e sequência para decisão](reavaliacao-microservicos-2026-10-29.md). Microserviços não exigem Kubernetes ou hospedagem. Não iniciar migração ampla nem assumir aprovação definitiva do monólito.

## Registro histórico da proposta21/10

**Proposta de 21/10/2026; implementação ainda não iniciada.** Recomendação: Flutter compartilhado Android/iOS, **API Go como monólito modular** e PostgreSQL. Um processo de API, módulos internos por domínio e um banco com transações. A migração atende à direção do autor e à revisão de domínio necessária; não é uma correção automática de desempenho.

| Caminho | Vantagem | Custo e condição |
|---|---|---|
| Evoluir Fastify | Chegar mais rápido ao primeiro fluxo; autenticação e sessões já existem | Modelo editorial e cliente ainda precisam mudar; mantém stack atual |
| Go modular, recomendado | Uma base alinhada ao objetivo técnico do autor, fronteiras e operação explícitas | Reconstruir auth/contratos, migrations e testes; primeiro provar uma fatia ponta a ponta |
| Microserviços/Kubernetes agora | Nenhum ganho demonstrado para o piloto | Mais deploys, rede, consistência, observabilidade e custo sem carga medida |

`V1-002` confirma a decisão e fronteira antes de criar o serviço. Backend legado permanece referência e possibilidade de recuperação. Não haverá dual write. O novo serviço usará banco de teste separado; o destino de qualquer dado real antigo será inventariado antes de importar. Uma ferramenta será dona das migrations por schema; Prisma e Go não disputarão a evolução das mesmas tabelas.

## Organização a implementar

```text
trainforge/
  lib/
    app/                     # composição, navegação e bootstrap
    core/                    # config, HTTP, sessão, falhas, armazenamento
    features/<feature>/
      data/                  # services HTTP/local, DTOs, repository impl
      domain/                # modelos/regras quando necessários
      presentation/          # pages, widgets, controllers/viewmodels
    shared/                  # componentes usados em mais de uma feature
  services/api/             # FUTURO, não existe como backend pronto
    cmd/api/
    cmd/import-content/
    internal/
      auth/
      catalog/
      activity/
      nutrition/
      platform/              # config, postgres, HTTP, logs
    migrations/
  contracts/generated/     # FUTURO Swagger JSON/YAML gerado por comentários Go
  content/manifests/         # FUTUROS lotes revisados; não payload sem licença
  docs/
  tools/                    # painel e validações documentais existentes
```

No Go, organizar cada módulo por responsabilidade real (handler/service/store/model quando existir motivo). Não criar interface, adapter e use case para cada operação trivial. `cmd` faz composição; `internal` limita importações externas. Preferência inicial por `net/http`, `pgx`, SQL explícito e uma ferramenta de migrations escolhida/verificada em `V1-002/007`; novas dependências exigem justificativa e versão suportada. Não instalar framework para copiar um diagrama.

Fronteiras detalhadas em [camadas Go](camadas-go.md): HTTP/DTO → aplicação → domínio e interfaces necessárias; PostgreSQL implementa persistência, com composição em `cmd`. [Swagger](swagger-go.md) será gerado dos comentários/DTOs, com recarga no desenvolvimento e conferência de divergência na CI. O [mapa do repositório](README.md) distingue código, referência externa e intenção planejada sem painel local.

No Flutter, manter a separação por feature. ViewModel/controller conduz estado e comandos; repository fornece domínio e coordena cache/HTTP; widgets apresentam e navegam. Usar composição e ferramentas existentes antes de introduzir BLoC/Riverpod/get_it somente por convenção. Repository não deve ser instanciado dentro de cada página. Camada de domínio adicional é útil onde há regra de unidade, sessão ou sincronização; não precisa existir como camada vazia em toda feature. [Recomendações oficiais Flutter](https://docs.flutter.dev/app-architecture/recommendations) e [organização de módulos Go](https://go.dev/doc/modules/layout) sustentam estas escolhas, adaptadas ao projeto.

## Fluxo de dados

Fonte pesquisada → manifesto revisado por ativo → importador idempotente → PostgreSQL → Go/OpenAPI → Dio/DTO → repository → ViewModel → tela. Ação confirmada do usuário percorre o sentido inverso e só vira histórico com persistência e estado conhecidos. Isso é consumo de conteúdo pesquisado mesmo com carga versionada no nosso banco; não exige chamar o fornecedor a cada toque.

Conteúdo público autorizado pode receber cache e ETag por versão. Informações privadas têm autorização por recurso, cache por conta e política de invalidação. Vídeos/fotos só entram se houver direitos daquele ativo; se não houver, o produto mostra a disponibilidade real. Object storage/CDN será contratado somente quando existir ativo que o justifique.

## Android e iOS

Domínio, regras, contratos e maioria da UI serão compartilhados. Identidade nativa, OAuth, secure storage, permissões, GPS/sensores, lifecycle, acessibilidade e distribuição terão validação própria. Android vem primeiro para desenvolvimento e APK da esposa. iOS continua no plano desde o início; build/release exige macOS e Xcode, como descreve a [documentação Flutter](https://docs.flutter.dev/deployment/ios). Windows não valida isso por possuir `ios/`.

## Escala: hipótese a medir

Flutter executa no aparelho; capacidade da API depende da mistura de chamadas, consultas, pool, latência, volume de dados e infraestrutura. O [caso oficial do Nubank](https://flutter.dev/showcase/nubank) é referência de organização multiplataforma, adoção e ferramentas; não demonstra que a arquitetura do TrainForge atende milhões nem que Nubank usa Go no backend.

Começar com paginação, consultas projetadas/indexadas, limites, ETag, métricas e backups. Medir staging antes de cache distribuído, fila ou réplica. Escalar instâncias stateless e conexões dentro dos limites reais do banco; extrair um módulo apenas quando houver necessidade de implantação, carga ou responsabilidade independente comprovada. Metas propostas e resultado medido ficam separados em `V1-030`.
