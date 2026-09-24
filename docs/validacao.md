# Registro de validação — fase 1

Data: 09/09/2026. O objetivo foi reconstituir o estado do projeto e preparar documentação/design. **Análise estática aprovada não equivale a aplicativo testado em produção.**

## Evidências de execução

| Verificação | Local / comando | Resultado |
| --- | --- | --- |
| Análise Flutter | App: `flutter analyze --no-pub` | Passou: `No issues found!` |
| Tipagem API | API: `node node_modules/typescript/bin/tsc --noEmit` | Código de saída 0 |
| Tipagem web | Frontend: `node node_modules/typescript/bin/tsc --noEmit --incremental false` | Código de saída 0 |
| Schema Prisma | API: `node node_modules/prisma/build/index.js validate` | Schema válido; não aplica migrations nem consulta tabelas |
| Graphify | Extração estrutural + agrupamento dos três corpora | 42/33/53 arquivos; saídas detalhadas em [Graphify](graphify.md) |
| Integridade dos grafos finais | `graphify diagnose multigraph --graph <arquivo> --json` | Três grafos sem endpoints inválidos ou duplicações detectadas no estado exportado |
| Consulta de símbolo | `graphify explain features_auth_data_auth_repository_authrepository --graph graphify-out/graph.json` | Nó e nove conexões retornados |
| Figma de referência | Capturas dos seis nós indicados | Inspecionados; limites de nós/previews e licença registrados em [proposta visual](proposta-visual.md) |
| Figma novo | Editor na aba conectada do Comet; inspeção visual e de camadas | Seis telas preenchidas em 390 × 844, textos/vetores editáveis e arquivo favoritado; montagem concluída em 09/09/2026 |
| Prévia local | Navegação Hoje → Sessão → Evolução no navegador | Botões e avisos demonstrativos responderam; sem persistência de dados |
| Outras áreas do conceito | Planos, Atividade e Alimentação no navegador | Navegação e mensagens de demonstração verificadas |
| Artefatos visuais | Parse XML de sete SVGs e `node --check` no script da prévia | Passaram; limites horizontais dos textos conferidos nos seis frames pelo DOM |
| Documentação | Validador da skill em sete documentos principais e README do design | Sem erros e sem links locais quebrados; avisos heurísticos revistos abaixo |

As verificações de linguagem usaram as dependências já instaladas. Não houve instalação limpa para provar reprodução dos lockfiles. Flutter precisou de acesso ao SDK fora da raiz gravável; não houve mudança no código do SDK. Tentativas iniciais de wrappers pnpm/Flutter e uma consulta livre Graphify tiveram problemas de execução/permissão; foram usados os executáveis locais para os checks conclusivos acima.

O validador de documentação procura `TODO` sem delimitar palavra e sinaliza também palavras portuguesas como “todo/todos”. Seus avisos de possíveis placeholders foram falsos positivos. Também procura literalmente títulos sem acento como `visao geral` e termos como `mapeamento/gotchas`; os conteúdos correspondentes estão no guia, nas tabelas de contratos e nas seções de operação. A revisão não identificou lacunas de conteúdo decorrentes desses avisos. Isso não constitui uma auditoria completa de segredos.

## O que foi inspecionado

Os 42 arquivos Dart de `lib/`, configurações e manifests de plataforma, pubspec/lockfile, README e estrutura local; rotas, casos de uso, autenticação, geração, ambiente, Prisma e as cinco migrations da API; páginas/cliente HTTP/bootstrap/autenticação/configuração e histórico Git do frontend. Dependências geradas e diretórios de build não foram tratados como código autoral.

O Git da API e do frontend estava limpo durante a análise, nos commits `523f6d9` e `11407b3`, respectivamente. TrainForge não tinha repositório Git. O histórico confirma alterações mobile na API posteriores ao bootstrap inicial; por isso a pasta antiga não é apenas um retrato da imersão.

Os achados A01–A15 são deduzidos do código atual. O bloqueio de recorrência, descarte de bootstrap e ausência de consumo de refresh têm caminhos identificáveis. A corrida concorrente de refresh, comportamento sob múltiplas instâncias e índices do banco em execução exigem testes próprios: não foram reproduzidos como incidentes.

## Não executado

- Login Google real, leitura/escrita de contas ou dados de utilizadores.
- Inicialização da API conectada ao banco, teste HTTP integrado ou aplicação/reversão de migrations.
- Build release, assinatura, instalação em dispositivo, teste Android/iOS ou envio às lojas.
- Benchmark de desempenho/latência, teste offline e teste de concorrência em banco isolado.
- Auditoria de vulnerabilidades/CVEs, upgrade ou compatibilidade com versões futuras.
- Pesquisa profunda de APIs/fontes públicas, criação da skill global, commit/push ou deploy.

## Limite da entrega visual

A prévia, os SVGs e o Figma são artefatos de design com dados fictícios. Não exercitam o Flutter nem a API. O esboço online foi concluído pelo editor do Comet após o limite MCP Starter interromper a primeira tentativa. O canvas contém exatamente seis telas preenchidas e a inspeção de camadas confirmou texto editável. Componentes reutilizáveis, auto layout do conteúdo e conexões de protótipo ainda não foram criados.

Uma tentativa de reload para verificar persistência foi rejeitada pela revisão automática por possível perda de alterações não salvas; não foi executada. A evidência é a inspeção no editor aberto, sem teste de reabertura independente.

## Escopo das alterações

Foram adicionados documentação, índices Graphify e artefatos locais de conceito visual. README original e lógica do aplicativo foram preservados. Não foi movido código entre pastas, alterado schema/migration, modificado segredo, iniciado versionamento ou criado recurso de hospedagem/banco.

O servidor usado para verificar o conceito serve apenas `docs/`, em loopback, sem expor a raiz do projeto ou arquivos `.env`. É uma prévia temporária local; abrir `docs/design/preview.html` diretamente também funciona.

## Revisão documental e preparação de publicação — 24/09/2026

Visão R01–R18, pitch, etapas 0/01, conteúdo, critérios técnicos e roteiro futuro do Figma alinhados. Validador da skill `documentacao-projeto`: 32 documentos, sem erros/links locais quebrados. Avisos de palavras portuguesas/títulos heurísticos revistos, sem campos de entrega esquecidos. Os links para evidências brutas excluídas da publicação foram convertidos em referências explícitas a arquivos apenas locais.

Graphify consultado no início e atualizado ao encerrar o incremento documental: **0 alterados, 42 inalterados, 0 removidos** em `lib/`. Não há extração semântica dos documentos. Varredura dos arquivos candidatos a Git, sem imprimir valores: nenhum padrão de chave privada, token GitHub, chave AWS/Google, JWT literal ou URL de banco com credencial encontrado. Essa varredura é limitada por padrões e não certifica ausência universal de segredos.

Os dados brutos de pesquisa, caches, builds, logs, chaves e configurações de máquina permanecem locais; o primeiro versionamento inclui fonte Flutter existente, documentação, artefatos próprios de design e índices reutilizáveis. Sem alterações funcionais no app/API/banco e sem edição de Figma.

Análise estática da base antes do commit: `flutter analyze --no-pub` terminou com **No issues found!**. Foi necessário usar o SDK fora do sandbox; não houve upgrade de Flutter/dependências. A primeira tentativa restrita, sem saída útil, foi interrompida. Sem testes integrados de login, API, banco, sensores ou reconhecimento — não foram implementadas essas evoluções nesta entrega.

Revisão do conjunto inicial staged: **322 arquivos**, aproximadamente 3,9 MB de arquivos de trabalho, sem arquivos individuais acima de 1 MB. `git diff --cached --check` passou. A inspeção de credenciais usa padrões explícitos, não certificação de segurança do produto. Os riscos de logs/recorrência/autenticação do diagnóstico permanecem abertos.
