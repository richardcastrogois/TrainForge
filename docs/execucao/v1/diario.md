# Diário de execução V1

## 21/10/2026 — preparação inicial (histórica, seguida da revisão abaixo)

- Pesquisa consolidada em commit local `57f623a`; nenhuma publicação remota nesta etapa.
- Inspeção estática Flutter/Fastify/Prisma, proposta Go modular, contratos e modelo lógico; não implementados.
- Backlog canônico com12 épicos/43 histórias, todas `todo`. Próxima história V1-001.
- Pontos de entrada reorganizados, snapshots históricos preservados. Ferramentas do painel e inventário separados de código do aplicativo.
- Resultado final de validação desta entrega em [validacao-planejamento.md](validacao-planejamento.md).

Próximas entradas devem registrar somente ações/resultados efetivos, com história e evidência.

## 21/10/2026 — revisão solicitada: documentação no repositório e Swagger por comentários

- Autor determinou remover o painel local e substituí-lo por documentação arquitetural dinâmica, consultável sem servidor por quem clona o projeto.
- Serviço local encerrado; arquivos do painel/lançador/testes específicos removidos. Diagnóstico, contratos, pesquisa e backlog preservados e atualizados.
- Geração determinística Markdown/Mermaid com caminhos relativos; backend Fastify é referência capturada com commit/hashes, sem acesso implícito a outro checkout.
- Comentários/DTOs Go tornam-se fonte do Swagger; JSON/YAML são derivados. Serviço Go ainda ausente; ferramenta informa pendência e não cria spec fictícia.
- V1-003 em andamento pela publicação e validação da CI no remoto ainda pendentes; V1-008 foi revisada, sem implementação do backend.
- Resultado da verificação local desta revisão em [validação](validacao-planejamento.md). Sem push, deploy, banco, instalação persistente de dependência do app ou alteração funcional Flutter.

## 21/10/2026 — respostas do autor sobre o APK de avaliação

- Registrada a [direção do piloto](decisoes-piloto.md): avaliar o app inteiro por cenários, com conteúdo real e lacunas visíveis, em APKs durante o desenvolvimento. Não aguardar o produto completo nem restringir a avaliação a uma jornada pequena.
- Conteúdo conforme disponibilidade/direitos: fotos e vídeos juntos ou separados, ausência de mídia/instrução explícita. Autonomia como objetivo, sem inventar adaptações ou remover apoio exigido pela fonte.
- Alimentação: cobertura ampla pesquisada, busca por texto e cadastro próprio real; origem, unidades, nutrientes ausentes e privacidade separados do catálogo editorial.
- V1-001 em andamento: decisões registradas, manifesto e matriz de cenários ainda por construir/conferir. Não marcada concluída. Critérios de019/020/022/025 e checkpoints de034/036 ajustados; nomes/rotas de domínio seguem propostas de implementação.
- Custo de conteúdo reformulado ao autor e ainda sem resposta registrada nesta revisão. Nenhuma compra, contato, instalação, mudança funcional Flutter/Go, migration, deploy ou APK executado.
- Validação documental: `python tools/gerar_documentacao.py --write --check` passou com geração reproduzível, backlog/dependências/requisitos/entradas/links locais; `python -m unittest discover -s tools -p test_documentacao.py` passou com13testes. Não são testes do aplicativo nem de conteúdo/prática.

## 21/10/2026 — custo esclarecido, nova pista e conclusão documental V1-001

- Autor permite avaliar alternativas pagas de pagamento único e valor baixo, com condições apresentadas antes da decisão; teto numérico/compra não aprovados. A pendência de resposta citada na entrada anterior foi resolvida.
- Pista ExerciseDB OSS/completo, wger, WorkoutX e marketplaces conferida em páginas oficiais e evidências locais. [Comparação e limites](../../conteudo/avaliacao-apis-exercicios-2026-10-21.md): OSS não comercial; cache não universal; WorkoutX exercícios por assinatura, compra única Body Scan é outro produto; ExerciseDB.io é fornecedor distinto com compra única anunciada. Sem conta, contato, compra, download de mídia ou contorno de barreira.
- [Manifesto candidato](../../../content/manifests/pilot-candidates.json):331famílias/46Ns/34componentes documentais, incluindo22famílias alimentares; não331fornecedores homologados nem34programas completos. [Matriz](matriz-cenarios.md):24cenários e coberturaR01–R18; estados honestos e APK incremental.
- `python tools/validar_manifesto_piloto.py`: PASS,1248checagens de referências, ponteiros, hashes, cobertura e estados; [recibo](verificacao-manifesto.json). Nenhum item runtime aprovado/importado. V1-001 concluída nesse escopo documental, próxima V1-002; V1-003 continua em andamento pela CI remota.
- Flutter, Go, banco, infraestrutura e APK não foram implementados/alterados nesta rodada. Nenhuma compra, novo contato ou publicação. Gerar/conferir derivados e executar suíte documental existente após esta atualização.

- A suíte documental detectou uma premissa antiga no caso negativo `test_cycles_and_done_without_evidence_are_rejected`: a primeira história agora possui evidência real. O teste passou a esvaziar explicitamente `completionEvidence` na cópia inválida, mantendo a rejeição de conclusão sem prova e de ciclo; nenhuma regra de validação foi relaxada.

- Verificação final após regeneração:13testes documentais passaram, `python tools/gerar_documentacao.py --write --check` passou e `git diff --check` passou. Validador do manifesto passou novamente; nenhuma evidência de execução do app foi criada.

## 21/10/2026 — limite de custo e alternativas gratuitas

- Autor considerou os valores anteriores inviáveis e indicou cerca deUS$19 em pagamento único como possibilidade; priorizar gratuitas, sem assinatura nem compra por inferência. A decisão é mais específica que o limite ainda indefinido dos registros anteriores.
- Nova pista conferida em fontes primárias: OSS não comercial/cache por plano; RapidAPI tem fornecedores distintos e múltiplos objetos de cobrança; exercicios-bd-ptbr é candidato de textoCC0 com imagens excluídas; RepDB permite uso comercial in-app gratuito com crédito, mas declara imagens deIA e não tem pt na camada gratuita. Sem adoção automática, scraping, download de mídia, cadastro ou cartão.
- [Comparação atualizada](../../conteudo/avaliacao-apis-exercicios-2026-10-21.md). As331famílias históricas e a conclusão documental V1-001 são preservadas; novas pistas são suplementos, não programas aprovados nem retorno indiscriminado àsN. Nenhuma mudança funcional no app/API/banco.

## 21/10/2026 — continuação efetiva de conteúdo da etapa01

- Autor pediu seguir na etapa01 após fixar prioridade gratuita/cerca deUS$19 em compra única. V1-002Go não foi iniciada; execução segue V1-004/005, sem reabrirN01–N46.
- V1-004: schema editorial, validação do domínio e permissões por operação; movimento, instrução, mídia, protocolo original e coleção distintos. Dose ausente não vira zero; UUID não vira versão publicada; contexto e apoio preservados.
- Preparação local:109movimentos/práticas,329registros textuais,68referências de mídia,1protocolo-fonte e5coleções.512ativos,14bloqueios específicos,0aprovações de runtime e0downloads de mídia. Conteúdo de terceiros derivado fica em `content/local/`, fora do Git; matriz/fila/relatórios são metadados.
- Alimentação:3.484registrosCiqual e2.887por código+nomeCoFID;13tabelasCoFID preservadas, com fatores e bases100gFood/100gFA/exceção alcoólicos100ml separados. Código13-669 duplicado em dois alimentos preservado com conflito;15valoresCoFID não interpretados não foram convertidos silenciosamente.
- Auditoria independente:512ponteiros e1.069.660células originais conferidos; schema acompanha contrato, validador local é de domínio e não alega implementar todo JSONSchema.17testes semânticos isolados verificam permissões/ausências/unidades/apoio, sem fixtures no lote entregue.
- [Resultado, caminhos e próximos passos](../../conteudo/preparacao-local-2026-10-21.md). V1-004 concluída no escopo de contrato/preparação; V1-005 em andamento pela fila real. V1-006/019não concluídas; sem escrita emDB, alteração Flutter/Go, provisão cloud, compra ou APK. Conferência final de geração/testes registrada após execução.

- Conferência final:30testes de conteúdo/documentação passaram; geração e auditoria local passaram; `git diff --check` sem erro. Três arquivos locais derivados de terceiros confirmados como ignorados pelo Git. Commit local autorizado: `chore: prepare real pilot content and editorial review`; sem push.

## 21/10/2026 — primeira revisão efetiva para consulta

- Preparação anterior salva no commit local `7748f18`, sem push. Revisão documental continuou na mesma etapa, identificada como trabalho do agenteCodex, sem revisor humano/profissional presumido.
- Seis textosPTwger conferidos; dois textos preservados para consulta. Outros quatro têm pendências específicas de redação, suficiência ou variante. Movimento1670 retido pela divergência título/corpo;1022 mantém bloqueio anterior.
- Projeção separada:73metadados/2textos,0prática,0mídia,0entregaAPK validada;437ativos fora da projeção. Cada decisão presa ao hash do objeto e com créditos/condições próprios. Nenhuma nova tradução/dose/instrução completada porIA.
- Corrigido desvio do contrato em20ativos: mapas de exceções saem da etiqueta escalar de licença para `sourceRightsFacts`, preservados. Validador e caso de regressão acrescentados; originais intactos.
- [Resultado e limites](../../conteudo/revisao-consulta-2026-10-21.md). TermosCCBYSA3/4conferidos em fontes primárias, sem copiar seus textos integrais. V1-005 permanece em andamento;006/019/Go/banco/Flutter/APK não concluídos por esta revisão.
- Primeira execução de37testes detectou somente inventário gerado desatualizado após novas ferramentas; regenerar e conferir antes do commit. Resultado final registrado após execução.

- Conferência final:37testes passaram; auditoria de512ativos/1.069.660células passou; checks de preparação e revisão passaram. Mapa documental regenerado/conferido e diff sem erro. Quatro arquivos derivados locais continuam ignorados. Commit local autorizado desta revisão: `chore: review pilot consultation content`; sem push.
