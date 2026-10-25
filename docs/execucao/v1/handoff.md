# Handoff vigente — trilha de implementação por área

Atualizado em **25/10/2026**. Raiz: **C:/dev/TrainForge/trainforge**.

## Pedido e próxima ação

O autor quer compreender e testar o produto inteiro antes de comprar GIFs. Exige código seguro, organizado, separado por responsabilidade e preparado para crescer desde já. Pediu trilha detalhada por área, limpeza de documentos redundantes, commit/push e depois dúvidas por blocos.

**Q1, Q2, Q3, Q4 e Q5 registrados** em [decisões do piloto](decisoes-piloto.md): ambos os caminhos de treino; cuidador é o praticante nas pausas; foto com candidatos editáveis e quantidade informada. Q2 confirmou visões por refeição e por alimento, além de histórico visual, análise nutricional e dicas revisadas juntos na primeira versão. Após a [pesquisa de quatro produtos](pesquisa-fotos-historico.md), o autor aprovou recuperar fotos pela conta, com cache no celular. Q3 confirmou configuração completa antes da busca/seleção de treino, trocas compatíveis com dias/horários editáveis e retomada ou encerramento parcial. Nova047(todo) explicita a configuração Go/SQL/Flutter; campos exigem finalidade/fonte, sem herdar formulário de IA. Q4 confirmou excluir foto com a refeição e salvar alimentação/andamento offline para sincronizar depois.026 exige fila durável privada, recuperação e conflitos;042/045 coordenam exclusão sem reenvio recriar dados. Q5 confirmou etapas curtas por assunto com revisão final (047) e nomes traduzidos quando revisados, original/fonte nos detalhes e fallback original. Nova048(todo) explicita localização pt-BR/pt-PT/en/es e nomes revisados sem alterar fonte/cálculo. Próximo bloco Q6: organização dos aceites humanos e conta de avaliação. Ler [trilha](trilha-implementacao.md); não pedir hospedagem/OAuth nem pesquisar APIs amplamente.

A [auditoria24/10](auditoria-produto-2026-10-24.md) é o baseline factual. A trilha é o roteiro de decisões e implementação; [backlog.json](backlog.json) governa dependências/estados. Nenhum bloco foi encerrado só por documentá-lo. V1-021 permanece doing e próxima no backlog; adequar o recorte às respostas sem pular dependências.

## Estado do aplicativo preservado

- API Go0.5.1/25operações, PostgreSQL17.5 local isolado,23tabelas. Última leitura da auditoria:1conta/1consumo humano real,6369referências alimentares e73metadados de movimento. Zero programas/práticas aprovados.
- APKdebug **0.3.0+13**, assinatura/configuração e sessão preservadas. [Artefato](android-frontend-checkpoint.json). Não reinstalado nem testado com novos dados nesta rodada documental.
- GoogleAndroiddebug/sessão/privacidade reais já validados; OAuthdebug/release conferido. [Fechamento](auth-local-fechamento.md). DistribuiçãoHTTPS/release/iOS têm gates próprios e não impedem teste local.
- V1-014/019/020 reais:consulta de catálogo/base alimentar e registro manual, revisão/exclusão, histórico e subtotais. Cadastro particular e demais jornadas ainda exigem os aceites da025; não repetir SQL/importação/restore históricos por hábito.
- Faltam configuração persistida, seleção/composição humana permitida, adesão/agenda/execução/histórico de treino, contexto de pausa do cuidador, foto e quatro idiomas completos. Delegação de pessoa assistida não é requisito desta versão.
- Medição da auditoria:101testesFlutter/78,46% das linhas instrumentadas; Go71resultados aprovados/10integraçõespuladas/40,73% das instruções. Não equivale a teste em tudo. Sonar/CIFlutter/SQLautomático/carga não completos.

## Frontend e Figma

[Fonte visual e checkpoints consolidados](frontend-fidelidade-figma.md):pontos01–06 noAndroid,07–12 refinamento dos fluxos disponíveis, sem fechamento integral. MarcaTF, darkGrafite e lima e Android sem esticamento preservados. iOS não foi executado nativamente nesta máquina.

Figma vigente:arquivo bX6YjBBLIJgoo2MtiFLntl, página0:1/v0.5. [Inventário](frontend-figma-inventory.json). Contextos obtidos e nós faltantes na fonte visual/trilha. Limite de leituraStarter foi registrado; whoami nesta rodada confirmou o plano, sem repetir get_design_context. AbrirFigma noPC não altera a cota. Não contornar, comprar plano ou alegar comparação exata sem referência suficiente.

Os relatos frontend-etapa-01-06.md, frontend-dark-scroll.md e frontend-etapa-07-12.md foram incorporados à fonte visual única e removidos. Conteúdo e recibos preservados; não recriar arquivos redundantes.

## Execução e limites

Trabalhar pelos gates da trilha:decisões → banco → backend → segurança → frontend → qualidade → escala → APK → avaliação da mídia, respeitando as dependências do backlog. Segurança/testes entram em cada incremento. Bloqueio humano/editorial não vira done; seguir apenas trabalho independente.

Foto042 foi antecipada e delimitada a alimento por foto, sem inferir quantidade; composição044 cobre o segundo caminho aprovado. Agrupamento045, histórico/análise/dicas046, configuração047 e localização/nomes048 foram planejados como todo naV1, sem implementação ou novo done. Q3 incorporado em015/017/023/044/035; retomada preserva somente eventos reais e edição não reescreve histórico. Regras/fontes/revisão das dicas precisam ser elaboradas; a prioridade conjunta já foi decidida. Sensores041 e acompanhamento de terceiros043 continuam posteriores. Histórico de consumo é dado do servidor; recuperar também as fotos pela conta com cache foi aprovado no Q2, ainda sem implementação. Q4 exige exclusão da foto com a refeição e invalidação de cache/fila; limites/retenção e mecanismo de limpeza ainda precisam ser implementados, sem contratar hospedagem agora. Conteúdo precisa de direitos/revisão apropriados; API deGIFs não aprova treino/dose. Sem história/valor/quantidade/condição fictícios no runtime.

Sem hospedagem/deploy/compra/assinatura/integração paga/contato externo. Gratuitas primeiro; atéR$400 eventual permanece decisão doautor. Commit e push de incrementos validados autorizados; manter credenciais/capturas privadas fora doGit.

## Documentação e validação

- [Índice](../../README.md), [plano macro](plano-macro.md), [escopo](escopo.md), [arquitetura](../../arquitetura/README.md), [diário](diario.md).
- Gerar/check:`python tools/gerar_documentacao.py --write --check`; testes pertinentes:`python -m unittest discover -s tools -p test_documentacao.py`.
- Trilha não mudaAPI/migration; Swagger e GraphifyAST não precisam regeneração de código neste incremento. Não usar validação documental como prova de função doAPK.
- Comparar Git real antes de continuar; snapshots antigos e recibos mantêm seu valor histórico e seu escopo.
