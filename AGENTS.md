# TrainForge — instruções para agentes

Estado vigente: **25/10/2026**. Raiz correta: `C:/dev/TrainForge/trainforge`; o diretório pai não é o repositório. O pedido atual do usuário prevalece sobre snapshots históricos.

## Leitura e próxima ação

1. Ler [trilha por área](docs/execucao/v1/trilha-implementacao.md), [handoff](docs/execucao/v1/handoff.md), [backlog](docs/execucao/v1/backlog.json) e a história pelas dependências.
2. A trilha registra a expectativa do autor: avaliar o produto completo antes de comprar GIFs, distinguir banco/backend/segurança/frontend/testes/escala e encerrar cada recorte por critérios e evidências. Código seguro, organizado e preparado para crescer é exigido desde agora; monólito modular não autoriza acoplamento ou segurança adiada.
3. Q1/Q2 em [decisões do piloto](docs/execucao/v1/decisoes-piloto.md): dois caminhos de treino; cuidador treina para si nas pausas; foto com candidatos editáveis e quantidade informada; visões por refeição e alimento; histórico visual, análise nutricional e dicas revisadas juntos na primeira versão. Após a [comparação de quatro produtos](docs/execucao/v1/pesquisa-fotos-historico.md), o autor aprovou recuperar fotos pela conta, com cache no celular. Q3 respondido: configuração completa antes da busca/seleção; trocar exercícios compatíveis e dias/horários; oferecer retomar ou encerrar como parcial. Configuração privada persistida está planejada na047, ainda todo. Q4 respondido: excluir refeição inteira remove sua foto; registrar alimentação/andamento offline e sincronizar depois (026), com fila durável privada e sem duplicação ou recriação de dados excluídos. Q5 respondido: etapas curtas por assunto com revisão final; nome traduzido quando revisado, original/fonte nos detalhes e fallback original. Localização pt-BR/pt-PT/en/es e nomes revisados estão planejados na048, ainda todo. Próximo bloco Q6, organização dos aceites humanos e conta de avaliação. Sem autorização de hospedagem. Não pedir vínculo com paciente como requisito do cuidador.
4. [Auditoria de24/10](docs/execucao/v1/auditoria-produto-2026-10-24.md) e [recibo](docs/execucao/v1/auditoria-produto-verificacao.json) são o baseline factual, não uma certificação de segurança/capacidade.

## Estado comprovado e limites

- API ativa do APK: Go 0.5.1 / 25 operações em `services/api`; PostgreSQL local isolado. Fastify/Prisma em `C:/dev/bootcamp-treinos-api` e Next.js antigo são referências legadas, sem prova de funcionalidades migradas.
- Etapas01/02 concluídas no seu recorte;73 metadados de movimento para consulta,439 ativos excluídos e nenhuma prática/programa/instrução/mídia liberados. Triagem encerrada não é homologação clínica.
- V1-011/012/013:Google Android debug real, sessão e privacidade validados localmente; clientes OAuth debug/release conferidos. [Aceite](docs/execucao/v1/auth-local-fechamento.md). Não repetir OAuth/login/import/restore sem alteração que justifique. HTTPS/distribuição release e iOS têm gates próprios.
- V1-014/019/020:catálogo de consulta e6.369 referências Ciqual/CoFID; cadastro particular e consumo/histórico/revisões/subtotais reais. Última auditoria confirmou1 conta / 1 consumo humano real; preservar. Testes isolados não autorizam criar/apagar dados do titular.
- APK debug 0.3.0+13; pontos frontend 01–06 têm checkpoint Android,07–12 acabamento dos fluxos disponíveis, sem encerramento integral. [Fonte visual e checkpoints](docs/execucao/v1/frontend-fidelidade-figma.md). Configuração/treino/atividade/cuidador/foto/idiomas completos ainda faltam.
- V1-021 continua doing; não encerrar021/022/025 por haver componentes ou APIs. Foto042 e composição044 estão naV1 pelas respostasQ1; agrupamento045 e histórico/análise/dicas046 são todo naV1 apósQ2. Configuração completa047 é todo apósQ3 e antecede015/044; não herdar exigências/geradores do onboarding legado. Offline026 continua todo; envio incerto em memória não é fila durável.048 planeja idiomas/nomes revisados; não alterar dados/hashes/nutrientes da fonte para traduzir. Sensores041 e acompanhamento043 seguem posteriores. Não inferir peso/deficiência nutricional pela foto ou por diário incompleto.
- Medição24/10:Flutter 101 testes / 78,46% das linhas instrumentadas; Go 71 resultados aprovados / 10 integrações SQL puladas / 40,73% das instruções do perfil padrão. Não contar skip como aprovação nem tratar cobertura como nota do produto. CI atual não executa Flutter/SQL descartável automaticamente; Sonar não configurado e carga não medida.

## Figma e documentação

- Arquivo vigente bX6YjBBLIJgoo2MtiFLntl, página0:1/v0.5. [Inventário](docs/execucao/v1/frontend-figma-inventory.json) separa metadados de design context;401quadros não são401funcionalidades.
- Limite Starter de leitura já registrado. whoami24/10 confirmou plano Starter; não repetir design calls, comprar plano ou contornar cota. Abrir o arquivo não remove esse limite. Alternativas permitidas e nós faltantes na trilha.
- MarcaTF/Inter, dark Grafite e lima e rolagemAndroid sem esticar estão aprovados. iOS mantém padrãoFlutter; não alegar execução nativa em Windows ou aderência exata a iOS 27 por teste dewidget.
- Três relatos de frontend foram consolidados na fonte visual única. Não recriar os arquivos removidos nem duplicar instruções em novos handoffs. Preservar recibos, licenças, exclusões e contratos.
- [Índice](docs/README.md), [arquitetura dinâmica](docs/arquitetura/README.md), [plano macro](docs/execucao/v1/plano-macro.md), [escopo](docs/execucao/v1/escopo.md) e [matriz](docs/execucao/v1/matriz-cenarios.md) são complementares, com papéis definidos.

## Conteúdo, atores e autorizações

- Android e iOS permanecem no produto; primeiros testes em Android. Preservar idosos, cuidador como praticante nas pausas do próprio trabalho, casa, praça/parque e academia. Pessoa assistida é possibilidade futura, não foco/requisito do modo cuidador. Não inferir elegibilidade, condição clínica ou apoio disponível.
- Sem treino, instrução, dose, mídia, nutrientes, tradução alimentar, métrica ou histórico inventados. Fixtures isoladas não entram na base entregue. Sem Gemini/manual-generator como fallback.
- PesquisaN01–N46 consolidada, sem nova varredura sem pista. Fontes humanas exigem autoria/evidência/versão/direitos por movimento, instrução, mídia e programa; composição não herda eficácia.
- Gratuitas primeiro; [opções de API](docs/conteudo/opcoes-apis-exercicios.md) já consolidadas. Possível pagamento único de até R$400 depende de decisão específica. Sem compra/assinatura/integração paga, contratação ou contato externo por inferência.
- Autor não quer hospedagem agora. Não perguntar novamente como condição para teste noemulador. Sem deploy, criação de recurso cloud ou publicação de dados privados.
- Incrementos validados com commit e push autorizados; conferir escopo e dados sensíveis. Não mandar mensagens a terceiros sem autorização direta.

## Execução e evidência

- Incrementos pequenos por história/dependência; ler código antes de alterar. Sem rewrite completo, instalação nova ou dois escritores/migradores do mesmo domínio por conveniência.
- Segurança/testes/organização são transversais desde a primeira mudança. Migrations sem reset, backup só validado após restore; não apagar volumes nem atualizarAPK com rascunho aberto por inferência.
- Atualizar backlogJSON, contratos/diagramas afetados e diário; done exige completionEvidence. BacklogMarkdown é gerado. Registrar parcial/bloqueado com o motivo e continuar somente trabalho independente.
- Manutenção documental:`python tools/gerar_documentacao.py --write --check` e `python -m unittest discover -s tools -p test_documentacao.py`. Não repetir testes deapp/SQL/login sem mudança pertinente em etapa documental.
- [SwaggerGo](docs/arquitetura/swagger-go.md):comentários/DTOs são fonte; não editar JSON/YAML gerados à mão. Sem alteração deAPI não regenerar contrato por hábito.
- [Graphify](docs/graphify.md):query primeiro; updateAST quando código mudar. Não indexar todo docs semanticamente nem recriar painel de leitura.
- Git:`git -c safe.directory=C:/dev/TrainForge/trainforge ...`; não mudar confiança global. Segredos/.env/assinaturas/caches/capturas privadas fora doGit.
- Limpeza só de alvos exatos verificados; consolidar conteúdo útil, corrigir referências e validar antes de remover. [Arquivo histórico](docs/arquivo/README.md) não é instrução vigente.
