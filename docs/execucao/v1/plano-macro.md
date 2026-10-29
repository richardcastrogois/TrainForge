# Caminho da pesquisa ao APK

## Vigente —29/10/2026

O autor escolheu detalhar microserviços por etapas; a primeira prova de catálogoM1 passou em40860200717/ff8c8bb, com processo/banco/roles próprios emfixturesCI e sem cutover ou migração da avaliação. CI SQL passou oito suítes/12 testes principais em bases descartáveis, com schema13 e remoção conferidos. FonteGo0.8.1 tem prontidão reforçada e diagnósticoHTTP parcial; APKdebug0.4.3+25 permanece o checkpoint instalado. Auditoria028, observabilidade029 e pipeline032 continuam abertos; histórico Git contém links externos tokenizados antigos, com arquivos atuais sanitizados e pendência explícita. [Handoff vigente](handoff.md), [plano gradual](../../arquitetura/reavaliacao-microservicos-2026-10-29.md).

## Último checkpoint do app —28/10/2026

047 encerrada funcionalmente com criação humana, edição autorizada e recuperação da revisão2; refinamento didático continua pendente. 048 permanece concluída no recorte documentado. Treinos015/016 têm bloqueio editorial explícito: zero programas, instruções, doses ou mídia aprovados para prática. Trabalho independente045 tem SQL/HTTP, cliente Flutter e leitura Android integrados: Go0.8.0/34operações, schema13/30tabelas e APK0.4.3+25 instalado após salvar/sair e comparação de dados. A ativação preservou os dados anteriores; o consumo real ficou sem agrupamento. Seleção particular e edição de metadados implementadas. Faltam aceite real/correção/exclusão e foto042; criação/consulta humana foi teste de navegação; outbox026 tem gate próprio. Sem hospedagem, compra ou dados inventados. [Trilha](trilha-implementacao.md), [handoff](handoff.md) e [backlog](backlog.json) detalham dependências e lacunas.

## Registro macro anterior — 25/10/2026

Estado vigente em **25/10/2026**. O roteiro de execução atual é a [trilha por área](trilha-implementacao.md), que registra expectativas, tarefas, dependências, critérios de encerramento e dúvidas do autor. A [auditoria](auditoria-produto-2026-10-24.md) é o baseline factual; o [backlog](backlog.json) governa estados das histórias. Q1 respondido:dois caminhos de treino, cuidador praticante nas pausas e alimento por foto com revisão/quantidade informada. Q2 confirmou visões por refeição/alimento e histórico visual, análise nutricional e dicas revisadas juntos na primeira versão; após a [comparação](pesquisa-fotos-historico.md), aprovou também recuperar fotos pela conta com cache no celular. Q3 confirmou configuração completa antes da busca, trocas compatíveis/agenda editável e retomada/parcial. Configuração047 planejada como todo; Q4 confirmou excluir foto com a refeição e registrar offline/sincronizar depois (026 ainda todo); Q5 confirmou etapas curtas/revisão e nome traduzido quando revisado com original/fonte nos detalhes (nova048todo); Q6 definiu exclusão por usuário/master(nova049todo) e avaliação de todos os cenários. Seguir implementação pelas dependências, sem repetir perguntas genéricas.

FundaçãoFlutter021 encerrada25/10:composição/configuração e uma fatia de estado com108testes/analyze0issues; [critérios](frontend-state-verification.json). 048 está doing:fundação e79mensagens nos quatro idiomas,119testes/analyze0issues eAPK0.3.1+14 preparado, não instalado. Demais telas/plurais e nomes revisados/busca continuam pendentes; não representa encerramento do frontend.

Banco local, autenticação e alimentação manual são reais; treino completo, cuidador, foto e idiomas ainda têm lacunas. Código seguro, organizado e preparado para crescer é exigido desde agora. Não basta trocar paraGo nem comprarGIFs. Segurança/testes entram em cada incremento.

APKdebug **0.3.0+13** preservado. IdentidadeTF, darkGrafite e lima, rolagem e checkpoints01–12 estão na [fonte visual única](frontend-fidelidade-figma.md);01–06 têm checkpointAndroid e07–12 não estão integralmente concluídos. Relatos históricos foram consolidados para reduzir instruções repetidas.

**Sem hospedagem agora.** Os marcos abaixo distinguem o checkpoint local de avaliação do aceite integral de distribuição/staging. Foto042 antecipada paraV1 e composição044 criada; cuidador pratica para si, sem delegação como requisito. OCR/barcode/sensores/terceiros permanecem posteriores. V1-045/046 planejam agrupamento e histórico/análise/dicas naV1; recuperação das fotos pela conta + cache foi aprovada noQ2, com implementação e detalhes do ciclo privado ainda pendentes.

| Ordem / marco | Histórias | Resultado verificável | Condição de saída |
|---|---|---|---|
| M0 — recorte e decisão |001–005,002 em sequência própria,003 transversal | Lote candidato, decisão Go/fronteira e contrato editorial; revisão dos usos | Fontes/limites reais; decisões não confundidas com implementação |
| M1 — fundação e dados |007–010 e006 após revisão | API local Go, Swagger gerado por comentários, banco isolado migrado e lote real importado | Dry run/reimportação, restore e contrato verificados |
| M2 — primeira fatia vertical |011–016,021–022,047–049 | Login Android real → API Go → catálogo no DB → detalhe/autoria/seleção | Sessão segura e conteúdo permitido, sem generator fallback |
| M3 — uso e alimentação |017–020,023–027,042,044–046 | Atividade e treinos permitidos; alimentação manual/por foto, refeições/itens e histórico/análise/dicas juntos | UI/API/DB coerentes com unidades, ausência, idempotência e revisão humana |
| M4 — confiabilidade e infraestrutura |028–033 | Segurança, baseline de carga, telemetria, pipeline e staging HTTPS | Custos/provedor aprovados; deploy e restauração reais |
| M5 — arquivo para teste |034–037 | APK assinado, jornada release validada, instalação e feedback | Roteiro real, checksum e limpeza após uso |
| M6 — iOS e expansão |038–041,043 | macOS/Xcode e paridade, lojas e funcionalidades posteriores | Cada capacidade tem evidência de uso/direitos/custo próprios |

As dependências exatas estão em `backlog.json`; intervalos da tabela são orientação macro e não autorização para pular dependência. É possível avançar em contratos/qualidade independentes de material bloqueado; não fingir que bloqueio editorial fechou. Não iniciar pesquisa/provisionamento de hospedagem enquanto essa decisão estiver adiada.

## Avaliar antes de concluir o produto

As [respostas de21/10](decisoes-piloto.md) ampliam a cobertura do piloto: o autor quer o APK para entender o app inteiro, percorrendo todos os cenários um de cada vez. V1-001 deve mapear a cobertura pesquisada completa e suas lacunas, em vez de escolher uma única jornada ou poucos alimentos como produto final do teste. Importações continuam em lotes técnicos com direitos e qualidade conferidos.

M2 e M3 devem produzir checkpoints de APK de avaliação assim que houver fatias reais instaláveis, com versão, configuração, assinatura, proteção dos fluxos habilitados e roteiro do que pode ser testado. Usar as tarefas de034/036 também como referência de build/distribuição, antecipando somente os requisitos necessários ao checkpoint. Suas dependências e o aceite integral permanecem válidos para fechar a V1; não marcar034/036 concluídas por entregar uma build intermediária. Não aguardar todos os módulos prontos para colher feedback. M5 continua sendo o aceite integrado da V1 e sua entrega completa.

Cada checkpoint relaciona todos os cenários a um estado real: disponível para teste, incompleto, bloqueado por conteúdo/requisito ou ainda não implementado. Não usar telas, dados ou ações simulados para aparentar cobertura. O feedback orienta refinamento ou pesquisa direcionada com nova pista. Custo vigente:priorizar fontes gratuitas; eventual pagamento único de atéR$400 depende de decisão específica doautor. Nenhuma compra, assinatura ou integração paga foi aprovada. O inventário de fontes e cenários independe da decisão sobre uma compra específica.

## Incrementos que o agente deve executar

1. Ler índice, AGENTS e história pronta pelas dependências. Registrar escopo e limites da rodada.
2. Implementar uma fatia concreta, com contrato e dados reais quando for o fluxo integrado. Evitar migrar toda a lib/backend de uma vez.
3. Rodar verificações relevantes. Relatar o que foi executado, qual resultado e qual limitação. Não usar teste documental como comprovação clínica ou teste do app.
4. Atualizar fonte canônica: backlog, OpenAPI/modelo quando existir, achados e intenção do mapa. Regenerar a documentação versionada e conferir os mapas. `done` exige evidência.
5. Fazer commit local da unidade autorizada; push/deploy/publicação conforme o pedido e a aprovação aplicáveis. Deixar handoff com próxima ação, sem nova varredura de pesquisa sem pista.

## Critério para revisitar Go

`V1-002` registra a decisão. Se a primeira fatia exigir prazo incompatível com o objetivo do teste, apresentar o impacto e comparar com adaptar Fastify; não manter dois backends gravando o mesmo domínio para “acelerar”. A recomendação continua Go modular, mas sem alegar que Fastify é incapaz de escalar ou que mudar a linguagem resolve o domínio.

## Cobertura da visão

R01–R06 e R15–R17: catálogo, requisitos, sessão, acessibilidade e evolução multiplataforma. R07–R10/R14: fatia alimentar, registro, histórico e origem das métricas. R11: sessão/recuperação agora, sensores/GPS na041. R13:alimento por foto042 naV1 apósQ1; outros usos deimagem/OCR permanecem posteriores. Composição controlada044 também naV1; expansão na040. Acompanhamento de outra pessoa na043 não é requisito do cuidador praticante; histórico/análise/dicas046 e agrupamento045 foram aprovados noQ2, com conteúdo/regras e implementação pendentes. R18 é transversal a conteúdo, segurança, custo e operação. A matriz exata de IDs está em cada história.

23/10: [V1-013](privacidade-013.md) implementada/validada tecnicamente,18operações/Go0.4.0 e48testesFlutter. LoginAndroiddebug real/aceite privado passaram; OAuthrelease confirmado; HTTPS/testeAPKrelease continuam pendentes; aceite local011/012/013 encerrado; desenvolvimento pode seguir pelas dependências. Push dos incrementos validados autorizado, deploy não. Meta de milhões simultâneos exige carga/infraestrutura próprias, não comprovada neste checkpoint.

**Prioridade atual:** autor não quer hospedagem agora. Teste local pronto;011/012/013 concluídas com [critérios/evidência](auth-local-fechamento.md). DistribuiçãoHTTPS/release/iOS permanece futura, sem bloquear consultas noemulador.
