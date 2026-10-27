# Handoff vigente — TrainForge

Atualizado em **26/10/2026**. Repositório: **C:/dev/TrainForge/trainforge**.

## Retomada e próxima ação

Ler AGENTS.md, este handoff, backlog.json, plano-macro.md e etapa-02-fechamento.md antes de alterar. Conferir Git/arquivos reais; preservar dados e não repetir instalação, pesquisa, importação, restore ou login sem mudança pertinente.

**Continuar V1-048, que permanece doing.** O cliente já integra nomes revisados por idioma/revisão e o ambiente local foi atualizado. A ferramenta operacional e o relatório real de cobertura estão entregues; faltam os aceites nativos e o uso editorial real quando houver pacote humano aprovado. Não iniciar outra V1 antes de fechar os critérios atuais. completionEvidence continua vazia; não declarar nomes revisados publicados a partir de fixtures.

A [trilha por área](trilha-implementacao.md) organiza banco → backend → segurança → frontend → qualidade → escala → APK → mídia, com segurança/validação em cada incremento. O [backlog](backlog.json) governa estados/dependências. O autor quer avaliar o produto inteiro antes de comprar GIFs; código separado e seguro desde já, capacidade medida em vez de prometida.

## Estado comprovado agora

- Código e Swagger **Go0.6.1/25operações**. Leitura pública testada com a base real nos quatro idiomas. [Ativação local](food-names-local-activation.json): migrations9–11 autorizadas explicitamente pelo autor e aplicadas após teste descartável; schema11/26tabelas. Checkpoint somente de schema em.local; comparação antes/depois preservou usuários, sessões, alimentos, consumo e idempotência.
- Permanecem **1conta,1consumo humano real,6369versões alimentares e73metadados de movimento**. Nenhum dado pessoal ou consumo novo criado pelo agente. Zero programas/doses/instruções/mídias aprovados para prática;439ativos excluídos na triagem histórica.
- **493mensagens deUI** em pt-BR/pt-PT/en/es;164testesFlutter/analyze0issues,11novos cenários de nomes. [Recibo integrado](frontend-food-names-verification.json). Tags com hífen; original/identidade/base/nutrientes preservados. Mais recentes: filtros/consultas, formulários/histórico, rascunhos, controles de privacidade e ajuda.
- APKdebug **0.3.3+16 preparado**, assinaturaOAuthdebug eSHA256 conferidos; [checkpoint](android-food-names-checkpoint.json). **Não instalado**:status atual sem dispositivoADB. Último instalado registrado:0.3.0+13; não afirmar atualização nativa. Primeiro build acionou guard por regeneração concorrente; repetição sequencial com fontes estáveis passou. Não rodar analyze/gen-l10n em paralelo a prepare.
- API temporária127.0.0.1:18082 encerrada e cluster voltou ao estado inicialmente parado. Credenciais/dados locais preservados; nenhum novo consentimentoGoogle. Testes reais deauth/sessão/privacidade anteriores continuam no [fechamento](auth-local-fechamento.md), sem confundir fixtures com Google real.
- GraphifyFlutter:100Dart/3400nós/3924arestas, ASTincremental/HTML;11alterados/89inalterados. Sem semântica/clusterização/LLM;ARB não é interpretado. Go/SQL estão nos mapas documentais/Swagger, sem alegar indexação semântica.

## V1-048: implementação e limites

[Contrato](../../arquitetura/contratos-v1.md): locale/namesVersion opcionais na lista e locale no detalhe; reviewedName/nameCatalog separados dooriginal. Snapshotrepeatable-read e revisão atômica poridioma vinculam cursor/ETag.409descarta paginação antiga; retirar a última versão do nome não revive uma antiga. Cursores originais semlocale continuam válidos. FixturesSQL/HTTP verificaram aliases,homônimos,retirada,cache,permissões eimutabilidade; [recibo](food-names-read-verification.json) é anterior à ativação real e não deve ser reescrito para fingir outra data/escopo.

Flutter usa o contrato tipado opcional, rejeita metadados inválidos e preserva ID/versão/nome original na seleção/formulário. Mudar idioma invalida consultas antigas sem perder busca digitada;409reinicia uma vez sem misturar gerações. Fallback original é explícito. Nomes privados não são traduzidos nem publicados. A00011retira a suposição automática de português: nome sem idioma declarado éund. Nenhuma linha/snapshot histórico foi reescrito. [SQL particular](nutrition-locale-verification.json).

**0nomes revisados publicados**, em todos os idiomas. A [ferramenta editorial](../../conteudo/nomes-alimentares-revisados.md) faz preflight sem banco, publicação e retirada imutáveis com confirmação do pacote/revisor e cobertura read-only por idioma/fonte/versão. A CLI real passou em banco descartável, inclusive retries e permissões. [Recibo](food-names-operations-verification.json). Hash, booleano e confirmação não comprovam autoria humana nem validade de licença; um operador precisa verificar os documentos e retê-los. Não inventar tradução alimentar nem chamar saída deIA de revisão. Fonte/importador/hashes/nutrientes permanecem separados e inalterados.

Próximo recorte: aceite Android dos quatro idiomas, preservando rascunhos/conta, e limite nativo iOS explícito. Não inventar pacote editorial para remover o fallback; a cobertura atual comprovada é 0/6.369 por idioma. Ciqual 2025 tem 3.484 versões e CoFID 2021 tem 2.885. A ferramenta não cria endpoint, migration ou nova tabela; API permanece 0.6.1 / 25 operações, schema 11 / 26 tabelas. APK pronto pode ser instalado quando houver dispositivo e estado seguro; não encerrar app com rascunho/envio incerto por inferência. Não precisa de hospedagem para avaliar noemulador.

## Decisões de produto que continuam válidas

[Q1–Q6](decisoes-piloto.md): ambos os caminhos de treino; configuração completa em etapas curtas por assunto com revisão final(047), antes de procurar treino. Trocar exercícios compatíveis e dias/horários; retomar ou encerrar como parcial, sem conclusão automática. Cuidador é o praticante nas pausas do trabalho, sem exigir paciente ou delegação.

Foto deve propor alimentos editáveis/adicionáveis/removíveis, depois o usuário informa quantidade; sem estimar peso ou inventar nutrientes. Visões por refeição e por alimento(045). Histórico visual, análise nutricional e dicas revisadas juntos na primeira versão(046), sem tratar diário incompleto como diagnóstico. Fotos recuperáveis pela conta com cache no celular; excluir refeição remove a foto. Offline(026) exige fila durável privada, conflitos e exclusão sem recriar dados; envio incerto em memória não fecha essa história.

Exclusão de dados próprios por seu titular. Exceção master do autor é049todo: precisa de identidade verificada e auditoria, sem inferência por e-mail/GitHub. Todos os cenários da matriz continuam no aceite; participantes/conta de ensaio não confirmados. Emulador primeiro, Android físico orientado depois. Android e iOS preservados, com idosos, cuidadores, casa, praça/parque e academia.

021foi encerrada no recorte de composição/configuração e uma fatia de estado: [evidência](frontend-state-verification.json). Não encerrou o frontend. [Auditoria24/10](auditoria-produto-2026-10-24.md) é baseline histórico: cobertura parcial,Sonar/CIFlutter/SQLautomático/carga ainda não completos.164testes não são teste em tudo nem certificação para milhões de usuários simultâneos.

## Figma, autorizações e operação

[Identidade/checkpoints](frontend-fidelidade-figma.md):TF/Inter,darkGrafite e lima,Android sem esticamento. Figma bX6YjBBLIJgoo2MtiFLntl,página0:1/v0.5; [inventário](frontend-figma-inventory.json). LeituraStarter limitada; não repetir chamadas/contornar/comprar plano. AbrirFigma noPC não altera a cota. Não prometer igualdade a quadros sem designcontext; iOS não foi executado nativamente noWindows.

Commit/push de incrementos validados autorizados. Sem hospedagem/deploy,compra/assinatura/integração paga/contato externo. [Opções deAPI](../../conteudo/opcoes-apis-exercicios.md) já consolidadas:gratuitas primeiro; atéR$400eventual depende de decisão específica. Não pesquisar fornecedores amplamente nesta retomada. Credenciais,assinaturas,logs,capturas privadas ebackups ficam fora doGit.

Operação local: tools/avaliar_android.py prepare compila/confere sem instalar; start também instala/inicia serviços e exige estado seguro. Não usar start por hábito. Status atual:apiReadyfalse/apkCurrenttrue/devicesvazio. Não repetir OAuth/import/restore históricos. RealGoogle debug eOAuthrelease já conferidos, distribuiçãoHTTPS/release/iOS têm gates próprios.

Documentação: python tools/gerar_documentacao.py --write --check; python -m unittest discover -s tools -p test_documentacao.py. Swagger vem dos comentários/DTOsGo. Mapas/diagramas afetados atualizados; recibos separam execução real,fixtures eaceite humano. [Índice](../../README.md),[plano](plano-macro.md),[diário](diario.md). Não recriar relatos redundantes de frontend já consolidados/removidos.
