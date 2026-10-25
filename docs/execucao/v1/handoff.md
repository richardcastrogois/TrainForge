# Handoff vigente — trilha de implementação por área

Atualizado em **24/10/2026**. Raiz: **C:/dev/TrainForge/trainforge**.

## Pedido e próxima ação

O autor quer compreender e testar o produto inteiro antes de comprar GIFs. Exige código seguro, organizado, separado por responsabilidade e preparado para crescer desde já. Pediu trilha detalhada por área, limpeza de documentos redundantes, commit/push e depois dúvidas por blocos.

**Q1 respondido e registrado** em [decisões do piloto](decisoes-piloto.md):ambos os caminhos de treino; cuidador é o praticante nas pausas; foto identifica candidatos editáveis e usuário informa quantidade. Próxima conversa:**Q2**, sobre recuperação das fotos, histórico e observações. Ler [trilha](trilha-implementacao.md) antes de mudar o recorte. Não voltar a pedir hospedagem/OAuth nem pesquisar APIs amplamente.

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

Foto042 foi antecipada e delimitada a alimento por foto, sem inferir quantidade; composição044 criada para o segundo caminho aprovado. Sensores041 e acompanhamento de terceiros043 continuam posteriores. Histórico deconsumo é dado doservidor; recuperar também as fotos e regras deobservações aguardamQ2. Conteúdo precisa de direitos/revisão apropriados; API deGIFs não aprova treino/dose. Sem história/valor/quantidade/condição fictícios no runtime.

Sem hospedagem/deploy/compra/assinatura/integração paga/contato externo. Gratuitas primeiro; atéR$400 eventual permanece decisão doautor. Commit e push de incrementos validados autorizados; manter credenciais/capturas privadas fora doGit.

## Documentação e validação

- [Índice](../../README.md), [plano macro](plano-macro.md), [escopo](escopo.md), [arquitetura](../../arquitetura/README.md), [diário](diario.md).
- Gerar/check:`python tools/gerar_documentacao.py --write --check`; testes pertinentes:`python -m unittest discover -s tools -p test_documentacao.py`.
- Trilha não mudaAPI/migration; Swagger e GraphifyAST não precisam regeneração de código neste incremento. Não usar validação documental como prova de função doAPK.
- Comparar Git real antes de continuar; snapshots antigos e recibos mantêm seu valor histórico e seu escopo.
