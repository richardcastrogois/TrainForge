# Handoff vigente — TrainForge

Atualizado em **27/10/2026**. Repositório: **C:/dev/TrainForge/trainforge**.

## Próxima ação

Ler AGENTS.md, este handoff, backlog.json, plano-macro.md e etapa-02-fechamento.md antes de alterar. Conferir Git e arquivos; preservar dados e não repetir instalações, pesquisas, importações, restore ou login sem mudança pertinente.

**Continuar V1-048, doing, antes de outra V1.** A biblioteca, o detalhe público e a seleção/formulário já integram nomes revisados. A revisão encontrou uma lacuna concreta: nutrition_page.dart e entry_detail_page.dart ainda exibem calculation.food.nameOriginal no histórico/detalhe de consumo. O próximo incremento deve acrescentar uma projeção de leitura por idioma e versão, separada do snapshot e cálculo imutável, sem N+1 e sem alterar o corpo/chave das mutações. Cadastro particular conserva a declaração e privacidade. Estender testes de idioma, versão/retirada, cursor e troca de conta nessa leitura. Não usar ausência atual de traduções como prova de que esse caminho funciona. completionEvidence segue vazia.

A [trilha por área](trilha-implementacao.md) organiza banco → backend → segurança → frontend → qualidade → escala → APK → mídia, com validação em cada incremento. O autor quer avaliar o produto inteiro antes de comprar GIFs; código seguro e separado desde já, capacidade medida em vez de prometida.

## Entrega validada e ambiente atual

- Go **0.6.1 / 25 operações**, schema **11 / 26 tabelas**. [Ativação autorizada](food-names-local-activation.json): migrations9–11 aplicadas após teste descartável e checkpoint de schema, com comparação dos dados. Nenhuma migration na correção de preferências.
- Permanecem **1 conta, 1 consumo humano real, 6.369 versões alimentares**. Zero nomes revisados publicados. O ensaio de interface não criou/apagou usuários nem consumos e não fez novo consentimento Google; restaurou a sessão existente.
- **495 mensagens de UI** em pt-BR/pt-PT/en/es, **173 testes Flutter** aprovados e análise sem problemas. Nove regressões novas: retentativa de leitura não grava padrão; retentativa de gravação repete a escolha solicitada; concorrência/dispose e diagnóstico sem dados privados. A retentativa mantém loaded=true, preservando navegação/conta enquanto relê.
- APK **debug 0.3.6+19 instalado** no AVD TrainForge_Benchmark, Android15, fonte1.0,1080x2340. Assinatura debug e hash instalado conferidos. [Recibo atual](frontend-localization-native-verification.json). Seleção e restauração de idiomas verificadas nativamente; ficou em Hoje, pt-BR/dark, sem formulário aberto. Texto ampliado320px/2x tem testes de widget, sem alegar que a escala nativa foi alterada.
- API local8082, PostgreSQL15432 e emulador estão ativos para avaliação. API temporária18082 anterior foi encerrada. tools/avaliar_android.py status confere estado; start preserva dados, mas exige raiz segura antes de atualizar. Não precisa de hospedagem para o emulador.
- Graphify atual: **101 Dart / 3.420 nós / 3.949 arestas**, AST incremental e HTML;9alterados/92inalterados na passagem final. CincoARB não interpretados. Sem semântica/clusterização/LLM. Go/SQL aparecem nos mapas documentais e Swagger, sem alegação de indexação semântica.

## Preferências e evidência nativa

O botão de recuperação antes usava gravação mesmo após falha de leitura, podendo substituir a preferência salva pelo padrão. Depois de falha de escrita, podia repetir o valor anterior. Agora retry distingue leitura de escrita e mantém o alvo solicitado; controles ficam ocupados durante a leitura. Timeout inicial de2s continua com fallback explícito. Diagnóstico debug emite somente códigos fixos de área/tipo, sem exceção, valores, conta ou tokens.

Uma observação anterior pela janela mostrou fallback; a causa nativa não foi reproduzida com diagnóstico e não deve ser apresentada como estabelecida. O controle/captura Windows foi inconsistente. A autorização de acesso à janela já foi concedida pelo usuário; os checks finais usaram UIAutomator/Android screencap, com snapshot novo e guarda de tela sem formulário. Nunca usar XML antigo após dump falho durante o boot. Helpers/capturas privados ficam em.local; não automatizar autenticação Google.

Os novos controles e mensagens foram conferidos no Android. Isso não é aceite de usabilidade com idosos/cuidadores, release ou iOS nativo. [Fonte visual e limites](frontend-fidelidade-figma.md). Não repetir o consentimentoGoogle histórico: [fechamento011/012/013](auth-local-fechamento.md).

## Nomes revisados: o que existe e o que falta

[Contrato](../../arquitetura/contratos-v1.md): locale/namesVersion opcionais na lista pública e locale no detalhe; reviewedName/nameCatalog separados do original. Snapshot repeatable-read e revisão atômica vinculam cursor/ETag;409reinicia sem mesclar páginas. Retirar a versão mais recente não revive uma antiga. Fonte, identidade, base, hashes e nutrientes não mudam. Flutter preserva busca digitada, descarta respostas antigas e usa fallback explícito.

[Ferramenta editorial](../../conteudo/nomes-alimentares-revisados.md): preflight de arquivos sem banco, publicação/retirada imutáveis e cobertura read-only por idioma/fonte/versão. CLI real e retries passaram apenas em banco descartável removido. [Recibo](food-names-operations-verification.json). Cobertura real **0/6.369 por idioma**, revisão0: Ciqual2025 tem3.484 versões e CoFID2021 tem2.885. Hash/booleano/confirmação não provam identidade humana nem licença. Um operador autorizado precisa verificar e reter documentos antes de publicar conteúdo real. Não inventar traduções para remover o fallback.

A projeção em histórico ainda falta: não alterar snapshots SQL, fontes ou cálculos para exibir nomes; preservar cadastros privados e evitar chamadas por item. A ausência de nomes publicados faz o caso real cair no original, mas não fecha o teste do ramo revisado. Implementar esse caminho com fixtures isoladas e manter a cobertura real explícita. Depois revisar os critérios completos da048 antes de encerrar.

## Decisões e limites preservados

[Q1–Q6](decisoes-piloto.md): ambos os caminhos de treino; configuração completa em etapas curtas/revisão final antes da busca; trocas compatíveis e dias/horários; retomar ou parcial sem conclusão automática. Cuidador treina para si nas pausas, sem paciente obrigatório. Android/iOS, idosos, cuidadores, casa, praça/parque e academia permanecem.

Foto propõe candidatos editáveis; usuário informa quantidade. Sem inferir peso, nutrientes ou deficiência. Visões por refeição e alimento; histórico visual, análise e dicas revisadas juntos na primeira versão. Fotos recuperáveis pela conta com cache; excluir refeição remove foto. Offline026 exige fila durável privada, conflito/idempotência e exclusão sem recriar dados; envio incerto em memória não fecha essa história.

Exclusão de dados próprios pelo titular. Master049 ainda todo, com identidade verificada e auditoria, sem inferência por e-mail/GitHub. Todos os cenários continuam na matriz; participantes de usabilidade não confirmados. Emulador primeiro, Android físico orientado depois.

021 encerrada no recorte de composição/configuração e uma fatia de estado, sem encerrar frontend inteiro. [Evidência](frontend-state-verification.json). Configuração047, composição044, foto042, refeições045 e histórico/análise/dicas046 seguem pelas dependências. A [auditoria24/10](auditoria-produto-2026-10-24.md) é baseline histórico:173 testes não são teste em tudo nem certificação para milhões de usuários. Sonar, CIFlutter/SQL automático e carga ainda não completos.

73 metadados de movimento para consulta,439 ativos excluídos e zero prática/programas/doses/instruções/mídias aprovados. Dados e conteúdo reais não podem ser preenchidos por suposição.

## Operação e documentação

TF/Inter, dark Grafite e lima e Android sem esticar aprovados. Figma bX6YjBBLIJgoo2MtiFLntl/página0:1/v0.5; leituraStarter limitada, sem novas chamadas/contorno/compra. Abrir no PC não remove cota. Não prometer igualdade a quadros sem referência nem execução nativa iOS no Windows.

Commit/push de incrementos validados autorizados. Sem hospedagem/deploy/recurso cloud, compra/assinatura/integração paga ou contato externo. [Opções de API](../../conteudo/opcoes-apis-exercicios.md) consolidadas: gratuitas primeiro; pagamento único eventual atéR$400depende de decisão específica. Não pesquisar fornecedores amplamente nesta retomada. Credenciais, assinaturas, logs, dumps/capturas privadas e backups fora do Git.

Manutenção: python tools/gerar_documentacao.py --write --check e python -m unittest discover -s tools -p test_documentacao.py. Swagger vem dos comentários/DTOsGo; preferências não mudaram HTTP, portanto não regenerar contrato por hábito. Não executar analyze/gen-l10n/test em paralelo ao prepare; o guard já capturou regeneração concorrente. SDKs instalados; não repetir instalação, Google/import/restore sem razão. [Índice](../../README.md), [plano](plano-macro.md), [diário](diario.md).
