# Handoff vigente — TrainForge

Atualizado em **16/11/2026**. Repositório **C:/dev/TrainForge/trainforge**.

## Retomada — execução persistida e integrada ao Flutter

Autor pediu incorporar comportamentos úteis do openGym com implementação própria, preservar Flutter/Go/PostgreSQL, sem web e sem trabalhar alimentação agora, um problema por vez. Não incorporar código AGPL, programas/traduções ou mídia com obrigações de terceiros por inferência; compra futura de mídia não foi executada. Direitos e créditos do conteúdo já existente continuam preservados.

Motor Go de sessão (iniciar/registrar/pausar/retomar/parcial/concluir/cancelar), persistência pgx nas tabelas existentes, journal reidratável, revisão/replay durável por titular e credencial viva em cada transação. Quatro rotas privadas elevam a API a0.10.0/38operações. Flutter compõe serviço sob demanda e usa uma tela na aba Atividade, com lista/sessão/estados, entradas reais vazias e encerramento confirmado. [Escopo e limites](execucao-treino-017.md). V1-017 eV1-023 estão doing; nenhuma história foi encerrada.

SQL/HTTP isolado: três testes principais e23subtestes aprovados após o ajuste da ordem dos locks; schema13, todas as tabelas entregues inalteradas, descartável removido. [Recibo](activity-session-sql-verification.json). A revisão/flag editorial dos testes é sintética, não aprovação de um programa real. [Fundação anterior](activity-session-foundation-verification.json) conserva os resultados daquele checkpoint.

Integração atual:337Flutter aprovados; analyze0; Go comum/vet;138Python e15documentais após regeneração; Swagger e15mapas conferidos. Prévias sintéticas320px/texto2x e390px inspecionadas, sem aceite nativo. APKdebug **0.4.7+29 gerado**, assinatura/hash/fontes conferidos; **não instalado nem publicado**. [Recibo de integração](activity-session-integration-verification.json).

Operação observada neste incremento: o PostgreSQL próprio estava parado, foi iniciado para os testes e parado ao final, após verificar ausência de outros clientes. Portas8082/18083/15432 sem escuta ao encerrar; API/catálogo/emulador não foram iniciados. Retomar pelo helper diário; não usar init/activate/restore nem reaplicar migrations para iniciar.

Não houve migration, novo grant ou fixture no banco entregue, nem compra/cópia de mídia ou alteração de alimentos. Não iniciar prática por haver código:015/016 mantêm o gate de conteúdo; nenhum programa/instrução/dose foi liberado. A aba apresenta ausência real e caminhos para configuração/biblioteca. Fila offline durável e recuperação de uma intenção não confirmada após matar processo continuam pendentes. Próxima unidade funcional: primeiro programa próprio revisado, seleção/adesão e agenda; depois ensaio Android com ocorrência real e futura distribuição.

Os checkpoints de APK/ambiente abaixo são históricos de outubro, não nova observação do dispositivo.

## Último pedido e entrega

Autor pediu: esclarecerORM/Prisma, avaliar MoveKitR$779, limpar fontes obsoletas, usar a skilldraw.io, criar uma seção visual e ensinar cada peça e como operar/logar/parar. Não pediu compra, hospedagem ou migração deORM.

- [Aprendizado e operação](../../aprendizado/README.md)
- [15diagramas editáveis/SVG](../../diagramas/README.md), [30+4tabelas/colunas](../../diagramas/banco.md), [38APIs](../../diagramas/apis.md)
- [AvaliaçãoMoveKit](../../conteudo/avaliacao-movekit-2026-10-29.md)
- [Recibo da limpeza/validação](repository-cleanup-verification.json)

Removidos31arquivosDart sem referências no app/testes e63arquivos dos scaffoldsLinux/macOS/Windows/web. Android/iOS mantidos. Guias de entrada que ainda diziamGo futuro/Fastify atual foram substituídos por estado atual. Evidências/licenças/recibos e dados/chaves/backups locais preservados.

APKdebug **0.4.6+28 instalado** e assinatura/hash conferidos. Sessão existente restaurada; emulador em **Hoje**, sem formulário ao final. Nenhum consumo/treino criado, editado ou excluído pelo agente. Não foi repetidoGoogle. Reobservar a tela antes de agir.

258testesFlutter/análise0, quatro testes dohelper, dois dosdiagramas e14documentais. Validador original da skill aprovou15XML;SVGs renderizados localmente e amostras inspecionadas. Não foi automatizado o renderer nativo draw.io. Graphify90Dart/4032nós/4628arestas,31removidos/90inalterados,AST/HTML/zeroLLM; backupem.local/graphify-backup-20261029-learning.

tools/ambiente.py status eplan-stop foram conferidos no ambiente atual; start/stop têm testes com mocks, sem repetir parada real. Helper usa registros existentes, nunca activate/init/migration. Guia explica primeiro plano, logs e limites. Sem validação nova de permissões/conta viaGoogle.

## Estado técnico

API Go **0.10.0 /38operações**; catálogo **0.2.0 /schema2/4tabelas**, núcleo **schema13/30tabelas**. Persistência pgx/v5 eSQL;Goose para migrations; semORM. Não instalarPrisma/GORM/Ent/sqlc por inferência; comparação está no aprendizado.

Checkpoint históricoM0–M4 encerrou **somente a primeira extração do catálogo**: base/roles próprios, contrato de cinco rotas, publicação/retirada, rollback, falha/recuperação e checkpoint restaurado passaram. Naquele ensaio, API8082/catálogo18083/PostgreSQL15432/emulador estavam ativos, modo remote; não é estado atual. Não repetir ativação/restauração/login. [ReciboM4](catalog-rollout-verification.json), [arquitetura](../../arquitetura/reavaliacao-microservicos-2026-10-29.md).

Os metadados lidos para diagramas vieram de transaçãoREADONLY, sem linhas de usuário. Núcleo e catálogo têm tabelas de mesmo nome em bases distintas. Tabela existente de treino não é endpoint/jornada pronta.

## Próxima ação pelas dependências

**V1-015** continua próxima funcional: criar adesão/seleção real, exigindo configuração revisada e conteúdo humano liberado. Há73referências/zero programas. Não inventar dose/instrução/mídia para fechar a história. Continuar trabalho independente028/029/qualidade e045/025 conforme dependências/recortes.

- **047** encerrada funcionalmente: pessoa confirmou a configuração, autorizou editar para14:00 e revisão2foi recuperada. Não criar revisão3porhábito. Fuso/horário precisam refinamento didático.
- **045doing:** refeições e duas visões, SQL/HTTP/Flutter e metadados integrados. Faltam aceite/correção/exclusão real e ligação comfoto042. O lançamento20gfoi declarado teste; não excluir ou chamar ingestão real.
- **048** entregue na capacidade documentada; cobertura editorial0/6369. UItem73nomes de movimento e31variantes alimentares em quatro idiomas porID/versão/original. Não foram publicados como traduções profissionais. Demais nomes mantêm original.
- **022/025doing:** jornadas comuns limpas e comprovação emPerfil/Privacidade > Fontes e transparência; treino e ciclos alimentares completos ainda abertos.
- Foto042, composição044, histórico/análise/dicas046, offline026, master049, acessibilidade027 e entrega035conservam critérios próprios. Não são concluídos pela limpeza ou pelos diagramas.
- **028doing:** resetOnErrorfalse preserva erro para retentativa; cifras/formato/logout mantidos. Contrato testado, não houve corrupção real dekeystore. InventárioAPK27é histórico; recibo atual contém metadadosAPK28. Dependências completas, release/iOS, offline/fotos/master/Sonar/carga permanecem gates. [Segurança](../../arquitetura/seguranca-operacao.md).

## Produto e compra

Q1–Q6em[decisões](decisoes-piloto.md): ambos os caminhos de treino; cuidador para si nas pausas; configuração completa; trocas compatíveis/dias/horários; retomar ou encerrar parcial. Foto sugere candidatos editáveis e usuário informa quantidade. Refeição/alimento usam mesmos registros; histórico visual/análise/dicas revisadas juntos. Fotos pela conta/cache; apagar refeição apaga foto; offline requer durabilidade/isolamento/idempotência; master nunca por e-mail/GitHub.

MoveKit consultado em29/10: pricingR$779/582exercícios; formatosMP4 e metadados anunciados; APIfutura, licença perpétua com12meses de novos lançamentos. Não compramos, não contatamos e não integramos. A cláusula3restringe obtenção de arquivo bruto por usuário, portanto cache/offline/entrega precisam esclarecimento. Não é substituto de programa/dose/revisão humana. O antigo tetoR$400é histórico; o interesse deR$779não é autorização de pagamento. Sem hospedagem agora.

## Histórico útil preservado

Auth011/012/013passou no recorte Androiddebug real;OAuthdebug/release conferidos. [Fechamento](auth-local-fechamento.md). A conta, consumo humano anterior e refeição de teste permanecem; capturas/logs privados ficam em.local, não noGit. PreservarAndroid/iOS e todos os públicos/ambientes.

A limpeza histórica da main anterior foi especificamente autorizada e concluída com lease/backup, comparando95commits/88IDs alterados e mantendo árvore/autores/mensagens/datas. Demais refs preservadas; outros clones precisam reconciliação. **Não repetir force-push.** Caches/cópias externas e validade dos tokens não certificados. [Recibo](git-history-remediation-preview.json).

No ajuste visuala8ea84a, oito workflows passaram, inclusiveSQL40977166330. No armazenamento764749f,Flutter40979922367,segredos40979922349 eGo/docs40979922319 passaram. Isso não é aprovação integral do produto. Não repetir sem mudança pertinente.

Antes de nova tarefa: AGENTS.md, backlog.json, plano-macro.md e etapa-02-fechamento.md. Os recibos datados preservam detalhes históricos; este documento governa o estado atual.

Validação complementar deste incremento: suíte completaPython doCI com127testes aprovada; inclui os helpers e a reprodutibilidade dos15diagramas. Não é teste real de parada/start nem validação de compra/licença do pacote adquirido.
