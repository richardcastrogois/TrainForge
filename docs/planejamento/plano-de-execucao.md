# Plano de execução

Data: 17/09/2026. Proposta; a aprovação de uma etapa não aprova automaticamente decisões das próximas. O foco imediato continua sendo definir o produto e o Figma, não programar o aplicativo.

## Check-in das etapas

Atualizado em 24/09/2026. Marcar `[x]` somente após executar e registrar evidências; propostas não contam como execução. Registrar data, resultado e pendências em cada encerramento. O pedido do autor torna este check-in obrigatório nos próximos incrementos.

- [x] **Etapa 0 — Base confiável:** inventário/preservação em 22/09; alinhamento documental R01–R18 em 24/09. [Evidência e limites](etapa-00-base.md). Nova conferência visual fica para a próxima intervenção no Figma.
- [ ] **Etapa 01 — Conteúdo e viabilidade: aberta.** Rodadas 22–23/09 entregues; balanço ampliado em 24/09. Faltam programas humanos por modalidade, alimentação guiada, ensino visual, captura por imagem/dispositivos e integração demonstrada. Consultar a [matriz final do que temos/falta](etapa-01-pesquisa.md). Não avançar automaticamente para a etapa 02.
- [ ] Etapa 2 — Fluxos e conteúdo.
- [ ] Etapa 3 — Sistema visual.
- [ ] Etapa 4 — Protótipo completo.
- [ ] Etapa 5 — Viabilidade técnica e aprovação visual.
- [ ] Etapa 6 — Arquitetura e contratos.
- [ ] Etapa 7 — Banco e fundação.
- [ ] Etapa 8 — Implementação por percurso.
- [ ] Etapa 9 — Beta e publicação.

### Check-in da pesquisa ampliada — 23/09/2026

- [x] Comparar **43 fontes/famílias** de exercícios, programas, ciência, métricas, alimentos, receitas e mídia, com links primários, direitos, limites e próxima ação por fonte. [Catálogo](../conteudo/catalogo-fontes.md).
- [x] Ampliar amostras: 75 exercícios wger únicos; arquivos CoFID e Ciqual com 2.760 e 3.484 alimentos lidos, respectivamente; 20 registros de atividade. Preservar seleção, resultados, falhas e hashes. [Evidências](../conteudo/amostras-e-achados.md).
- [x] Propor cobertura portuguesa, lotes editoriais, requisitos de revisão e perguntas de autorização. [Prioridades](../conteudo/cobertura-e-prioridades.md), [curadoria](../conteudo/qualidade-e-curadoria.md), [direitos](../conteudo/direitos-e-acordos.md).
- [ ] Autor aceitar o público, conteúdo mínimo e caminho para programas completos; as quantidades sugeridas ainda são metas, não conteúdo produzido.
- [ ] Para as fontes escolhidas, resolver os direitos específicos e demonstrar adequação ao público com amostra revista. Não é necessário homologar todos os 43 candidatos; é necessário ter um caminho viável para cada promessa do lançamento.

**Conclusão registrada:** a rodada ampliada de pesquisa terminou. Não há aprovação clínica, contrato de conteúdo, integração ou catálogo de produção nesta entrega. A etapa 1 será encerrada quando as decisões e evidências acima sustentarem o escopo, ou quando o autor aceitar explicitamente uma alternativa para o que permanecer indisponível. As [evidências da primeira rodada](etapa-01-pesquisa.md) continuam preservadas; infraestrutura/mapas estão em [viabilidade operacional](viabilidade-operacional.md).

### Check-in do alinhamento integral — 24/09/2026

- [x] Consolidar visão R01–R18 e pitch; distinguir produto esperado de código existente.
- [x] Revisar etapa 0 e comparar a pesquisa da etapa 01 com modalidades, alimentação, didática, capturas e acompanhamento.
- [x] Especificar [ajustes futuros do Figma](../design/ajustes-visao-integrada.md), sem editar o arquivo visual.
- [x] Corrigir recortes de musculação exclusiva, parceria pressuposta e foto somente como anexo.
- [ ] Resolver as evidências abertas da etapa 01; a revisão documental não conclui essa etapa.
- [x] **Publicação inicial — 24/09/2026:** README e base revisados, 322 arquivos no primeiro commit [`16565d5`](https://github.com/richardcastrogois/TrainForge/commit/16565d5e882e89d094150e79e2a2c0934af758af), push de `main` concluído. Código Flutter, documentação, design próprio e índices publicados; API externa, segredos, caches e evidências brutas excluídos.

## Entregas e critérios

**Complemento da etapa 1 — 23/09/2026:** [x] análise do cenário sem parceiros/produção manual registrada em [programas prontos e cenários clínicos](../conteudo/programas-prontos-e-cenarios-clinicos.md). O autor quer oferecer programas existentes com instruções, inclusive para casos de saúde. A obtenção de conteúdo humano foi distinguida de indicação clínica automática; essa cobertura não foi validada nem implementada. [ ] Decisão sobre o modo de uso clínico e importação piloto de um programa geral permanecem abertas. A etapa 1 não está encerrada.

| Etapa | Trabalho e entrega concreta | Dependência / critério para avançar |
|---|---|---|
| 0 — Base confiável | Inventário das telas, estados, rotas e limitações; preservar versão do Figma; registrar o código ativo e riscos conhecidos. Preparar posteriormente escopo Git e exclusão de segredos. | Usar v0.4 como base histórica; conferir diferenças antes de editar. Nenhum gerador pode apagar refinamentos manuais. |
| 1 — Viabilidade e escopo | Comparar programas por modalidade/contexto, exercícios/mídia, alimentação guiada, rótulos, sensores/conexões, imagens e mapas. Verificar licença comercial, cache/offline, cobertura portuguesa e custo. Definir público, primeiro lançamento e expansões. | Pelo menos um caminho demonstrado por função do lançamento, ou alternativa explicitamente aceita; conservar R01–R18 como visão. Se não houver fonte de programas autorizada, rever a promessa antes de desenhar seleção automática. |
| 2 — Fluxos e conteúdo | Mapear modos guiado/livre, modalidades, configuração, treino, alimentação planeada/consumida, educação, capturas, conexões, acompanhamento e conta. Inventariar cada botão/campo. Consolidar telas repetidas em estados/componentes. | Todo controle tem destino ou comportamento descrito; nenhuma função obrigatória depende de um campo que o utilizador pode ignorar sem explicação. |
| 3 — Sistema visual | Tokens, tipografia, espaçamento, cores, componentes, variantes e acessibilidade. Android como referência de lançamento; variante iOS 26 com Liquid Glass. | Componentes consistentes, contraste e texto ampliado revisados. Conteúdo comum separado de diferenças de plataforma. |
| 4 — Protótipo completo | Refinar formulários, teclado, permissões, skeletons, erros, vazio/offline, confirmação, transições, retorno e estados preservados. Detalhar mapa, reconhecimento com confirmação, instruções multimodais, rótulos e dashboard. | Percursos críticos executáveis no Play; duração, gatilho e fallback de cada animação documentados. Limitações de simulação anotadas fora das telas. |
| 5 — Viabilidade técnica e aprovação visual | Planejar e executar, em incremento próprio, provas de teclado, persistência, GPS/mapa, conexões, captura/estimativas e Liquid Glass no Flutter. Capacidades que mudam a promessa precisam de triagem já na etapa 01. Comparar resultado com Figma e ajustar o que não for sustentável. | Autor aprova visual e comportamento; riscos técnicos/custos conhecidos. Protótipo aprovado com versão identificada. Não exigir terminar iOS para publicar Android. |
| 6 — Arquitetura e contratos | Definir módulos e responsabilidade, navegação, estados, sincronização, modelo conceitual, chamadas, DTOs, headers, erros, OpenAPI e mocks. Rever bibliotecas e runtime de hospedagem. | Cada ação visual liga a um caso de uso e contrato; ownership, unidades, datas, conflitos e falhas definidos. Compatibilidade com backend existente avaliada. |
| 7 — Banco e fundação | Desenhar modelo lógico/físico, índices, restrições, migrações, seeds fictícios, armazenamento local, mídia e política de retenção. Elaborar scripts e skill específica com comandos reais. | Contratos e invariantes aprovados; plano de migração/backup/restauração e testes de concorrência. Só então aplicar mudanças em ambiente autorizado. |
| 8 — Implementação por percurso | Entregar percursos aprovados completos que unam orientação/seleção, execução ou alimentação, registo e acompanhamento, com conta/perfil necessários. Em cada incremento: interface, API, persistência, testes e documentação juntos. | Um percurso funciona de ponta a ponta, incluindo erro e retomada, antes de abrir várias frentes incompletas. |
| 9 — Beta e publicação | Testes em dispositivos, desempenho, acessibilidade, privacidade, assinatura Android, política das lojas, orçamento e operação. iOS segue trilha própria. | Critérios de lançamento cumpridos, custos aceites, testes exigidos pela loja e plano de suporte/rollback preparados. |

O modelo conceitual e os contratos são refinados juntos: não faz sentido fechar todos os endpoints ignorando recorrência, histórico e propriedade dos dados. Já a criação de tabelas/migrações deve esperar essas decisões. A avaliação de fontes antecede os campos finais, mas não deve obrigar o produto a copiar a estrutura de um fornecedor.

## Prioridade de refinamento no Figma

**Figma não será editado neste incremento.** A [especificação F01–F12](../design/ajustes-visao-integrada.md) detalha o trabalho posterior.

Depois da pesquisa e aprovação: entrada/modos/configuração → descoberta/montagem e execução por modalidade → alimentação planeada/consumida e ensino de rótulos → capturas/conexões → Hoje/Evolução e Perfil → estados, teclado, persistência, acessibilidade, movimento e iOS.

A especificação cobre a visão e identifica dependências; não obriga lançar tudo simultaneamente. Estabilizar tarefas/conteúdo antes de animar telas que podem mudar.

## Incrementos e evidências

Cada incremento deve registrar: objetivo, telas/arquivos afetados, critérios de aceite, mudanças, evidências, limitações e próximo passo. Para Figma: versão, IDs, captura do estado final e percurso testado. Para código: diff, testes apropriados e contratos afetados. Commit/push e recursos externos ficam para incrementos explicitamente autorizados, com conteúdo concreto revisável.

No início, consultar o Graphify existente de forma pontual; ao final, atualizar incrementalmente o corpus afetado. Documentação humana é a fonte das decisões de produto: o grafo de `lib/` não contém automaticamente todos os textos de planejamento. Não reindexar projetos históricos sem mudanças nem disparar análise semântica paga para atualizar só Markdown.

## Pendências herdadas que bloqueiam publicação

O [diagnóstico](../diagnostico.md) identifica logs sensíveis, refresh/logout incompletos, recorrência de treino, restrições ignoradas pelo builder, perda de histórico ao trocar plano, índices/concorrência e configuração Android de release. Cada item deve virar cenário reproduzível e correção validada. Um Figma aprovado não elimina esses problemas.

## Próximas cinco ações

1. Autor revisar [visão central](README.md), [pitch](pitch-e-decisoes.md) e balanço da etapa 01, sem presumir lançamento só de musculação.
2. Investigar/importar pilotos de **programas humanos existentes** em modalidades/contextos representativos, comprovando direitos, instruções e progressão sem parceria pressuposta.
3. Aprofundar alimentação guiada, cobertura portuguesa e ensino visual; investigar reconhecimento e conexões por caso de uso, custo, privacidade e limitações.
4. Consolidar capacidade → fonte/método → prova → limite → alternativa; escolher explicitamente lançamento e expansões. Encerrar etapa 01 apenas após os critérios.
5. Retomar Figma Desktop comparando a base viva, aplicar F01–F12 em incrementos e seguir contratos/modelo conceitual, banco e implementação.

Publicar a base existente no GitHub não encerra a etapa 01 nem aprova capacidades ainda condicionais.

## Validação desta entrega

**Revisão da visão integral — 24/09/2026:** 32 documentos revisados passaram no validador documental sem erros/links locais quebrados. Avisos de possível placeholder correspondem a palavras portuguesas e registros de validação anteriores; os avisos de títulos técnicos são heurísticos, e os fluxos/arquitetura/riscos existentes foram preservados. R01–R18 aparecem na visão e no balanço final da etapa 01; F01–F12 especificam a intervenção visual futura.

Graphify consultado no início e atualizado ao final: **0 alterados, 42 inalterados, 0 removidos** em `lib/`. Não houve implementação ou mudança no arquivo Figma. Preparação do primeiro commit: README, código existente, docs/design e índices; caches/segredos e evidências brutas de terceiros excluídos. `flutter analyze --no-pub` passou sem problemas; staged contém 322 arquivos e passou em `git diff --cached --check`. Não houve teste integrado nem upgrade. Primeiro push confirmado em 24/09/2026; este check-in registra a entrega, sem encerrar a etapa 01.


**Validação da expansão — 23/09/2026:** 15 documentos novos/atualizados passaram no validador da skill `documentacao-projeto`, sem erros ou links locais quebrados detectados. Os avisos de possível placeholder foram revistos: correspondem a palavras portuguesas como “todo”, “todos” e “método”, ou à explicação histórica desse aviso, não a campos deixados por preencher. O catálogo gerado contém 43 IDs únicos: 10 candidatos, 10 condicionais, 8 incompatíveis com o caminho gratuito comercial e 15 referências; essa classificação não equivale a aprovação editorial.

O analisador local reproduziu as contagens/amostras e o manifesto dos 25 arquivos de evidência foi conferido por tamanho e SHA-256. As consultas locais por ID e por tema/estado funcionaram. Esses checks não fizeram novas chamadas externas. Graphify: **0 alterados, 42 inalterados e 0 removidos** no corpus Dart; saídas preservadas. Sem testes de aplicativo, pois não houve mudança no código de produto; sem alteração de Figma, banco, GitHub ou hospedagem.

Validação em 17/09/2026: sete documentos desta pasta passaram no validador da skill `documentacao-projeto`, sem erros ou links locais quebrados detectados. Os avisos de possível placeholder foram revistos: a expressão do validador procura `TODO` sem delimitar palavra e encontra usos portugueses como “todo”/“todos”; não representam marcadores de trabalho por preencher.

Graphify foi consultado no início pelo nó `features_auth_data_auth_repository_authrepository`. Ao final, `graphify extract .../lib --code-only --no-cluster --out .../trainforge` registrou **0 alterados, 42 inalterados e 0 removidos**, preservando as saídas. O corpus é código Dart; estes novos documentos não foram submetidos a extração semântica. Não foram executados testes de aplicativo nesta entrega exclusivamente documental. O diretório consultado ainda não é um repositório Git; não houve commit ou push.
