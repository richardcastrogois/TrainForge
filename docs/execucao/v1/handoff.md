# Handoff vigente — trilha de implementação por área

Atualizado em **26/10/2026**. Raiz: **C:/dev/TrainForge/trainforge**.

## Pedido e próxima ação

O autor quer compreender e testar o produto inteiro antes de comprar GIFs. Exige código seguro, organizado, separado por responsabilidade e preparado para crescer desde já. Pediu trilha detalhada por área, limpeza de documentos redundantes, commit/push e depois dúvidas por blocos.

**Q1–Q6 registrados** em [decisões do piloto](decisoes-piloto.md): ambos os caminhos de treino; cuidador é o praticante nas pausas; foto com candidatos editáveis e quantidade informada. Q2 confirmou visões por refeição e por alimento, além de histórico visual, análise nutricional e dicas revisadas juntos na primeira versão. Após a [pesquisa de quatro produtos](pesquisa-fotos-historico.md), o autor aprovou recuperar fotos pela conta, com cache no celular. Q3 confirmou configuração completa antes da busca/seleção de treino, trocas compatíveis com dias/horários editáveis e retomada ou encerramento parcial. Nova047(todo) explicita a configuração Go/SQL/Flutter; campos exigem finalidade/fonte, sem herdar formulário de IA. Q4 confirmou excluir foto com a refeição e salvar alimentação/andamento offline para sincronizar depois.026 exige fila durável privada, recuperação e conflitos;042/045 coordenam exclusão sem reenvio recriar dados. Q5 confirmou etapas curtas por assunto com revisão final (047) e nomes traduzidos quando revisados, original/fonte nos detalhes e fallback original. 048(doing) explicita localização pt-BR/pt-PT/en/es e nomes revisados sem alterar fonte/cálculo. Q6 definiu exclusão dos próprios dados pelo usuário e exceção master do autor (nova049todo), além de avaliação de todos os cenários. Participantes/conta de ensaio não foram confirmados; preservar dados reais e combinar apenas o necessário quando houver APK concreto. Próxima ação:continuar048 na camada de nomes revisados/busca, conforme o incremento abaixo;021 foi encerrada no seu recorte. Ler [trilha](trilha-implementacao.md); não pedir hospedagem/OAuth nem pesquisar APIs amplamente.

A [auditoria24/10](auditoria-produto-2026-10-24.md) é o baseline factual. A trilha é o roteiro de decisões e implementação; [backlog.json](backlog.json) governa dependências/estados. Nenhum bloco foi encerrado só por documentá-lo. V1-021 encerrada no recorte de composição/configuração e uma fatia migrada;048 é a próxima no backlog, sem pular dependências. Permissão master não existe no runtime; sua vinculação exige identidade autenticada verificada antes de ativação.

## Estado do aplicativo preservado

- Último ambiente humano:API Go0.5.1/25operações, PostgreSQL17.5 local isolado,23tabelas. CódigoGo0.6.0 foi validado emSQL/HTTPdescartável;00009/10 não aplicadas àbase entregue eAPI não reiniciada. Última leitura da auditoria:1conta/1consumo humano real,6369referências alimentares e73metadados de movimento. Zero programas/práticas aprovados.
- Último APK instalado registrado:debug **0.3.0+13**. Novo **0.3.2+15** compilado e assinatura conferida para a interface048; [recibo](android-localization-write-checkpoint.json). Não foi instalado pelo agente:inspeção não identificou uma raiz segura do emulador e a UI atual foi preservada. Nenhum consumo/exclusão/loginGoogle novo.
- GoogleAndroiddebug/sessão/privacidade reais já validados; OAuthdebug/release conferido. [Fechamento](auth-local-fechamento.md). DistribuiçãoHTTPS/release/iOS têm gates próprios e não impedem teste local.
- V1-014/019/020 reais:consulta de catálogo/base alimentar e registro manual, revisão/exclusão, histórico e subtotais. Cadastro particular e demais jornadas ainda exigem os aceites da025; não repetir SQL/importação/restore históricos por hábito.
- Faltam configuração persistida, seleção/composição humana permitida, adesão/agenda/execução/histórico de treino, contexto de pausa do cuidador, foto e quatro idiomas completos. Delegação de pessoa assistida não é requisito desta versão.
- Medição da auditoria:101testesFlutter/78,46% das linhas instrumentadas; Go71resultados aprovados/10integraçõespuladas/40,73% das instruções. Não equivale a teste em tudo. Sonar/CIFlutter/SQLautomático/carga não completos.

## Incremento V1-021 — 25/10

Fábricas lazy em lib/composition centralizam os adaptadores de produção. AuthGate, catálogo, alimentos e privacidade recebem dependências por escopo; ProductShell compartilha o mesmo repositório de alimentação com Hoje/diário, vinculado à conta. Dois testes novos cobrem rotas públicas/tema e reutilização/troca de identidade. Suíte completa:103aprovados; analyze:0issues. [Recibo](frontend-composition-verification.json). Fixtures isoladas, sem Google real novo, banco, API, instalaçãoAPK ou alteração visual.

Segundo incremento:estado de consultas/paginação/debounce saiu daNutritionPage paraNutritionController; mensagens de apresentação saíram do adaptadorHTTP. Guardas por conta/geração/dispose preservadas e invalidação não revive controller antigo. APP_ENV separa development/staging/production;HTTP somente local development/debug,HTTPS nos demais.

**021encerrada no seu recorteT01/T02**, conforme [mapeamento de critérios](frontend-state-verification.json):108testesFlutter/analyze0issues e14domínios semFlutter/Dio. Prova histórica de sessão/logs reais preservada; não repetidoGoogle. Formulários ainda mantêm entrada/foco/validação e guardas visuais comrepository injetado; este fechamento não entrega025/026/047/048/049 nem todo frontend. Graphify final88Dart/1294nós/1734arestas eHTML. Próxima048 está pronta por020/021:localização e nomes revisados, mantendo original/fonte e sem tradução alimentar inventada.

## V1-048 — incremento26/10

[Recibo das consultas/resumos](frontend-localization-read-verification.json):282mensagens poridioma. Hoje/Diário/Planos/Atividade/Evolução, biblioteca/filtros/detalhes e consulta alimentar usam recursos locais, datas/plurais e rótulos exatos de traço/ausência/limite/base. Fontes/créditos/valores/seleção preservados.132testesFlutter/analyze0issues e8prévias novas; semAPI/SQL/registro real/novoAPK. Esse código foi incluído depois noAPK15 preparado, sem instalação.

[Recibo dos formulários/privacidade/ajuda](frontend-localization-write-verification.json):486mensagens poridioma;153testesFlutter eanalyze0issues. Troca deidioma noenvio incerto preserva corpo/chave; cadastro mantém desconhecido/null diferente dezero; exclusão cancelada nãoenviaDELETE. Corrigida asserção demenu eminglês comfonte200%/320px:medida/estimativa agora são duasopções visíveis obrigatórias. Política efetiva/exportação efrase canônica deexclusão preservadas. Duasprévias novas sófixtures; conferida porção/en. Nenhum dado real alterado. APKdebug0.3.2+15 compilado/certificado conferido, nãoinstalado; [recibo](android-localization-write-checkpoint.json).

Fundação de nomes048 implementada emnames.go/names_postgres.go e00009:FK exata,hash próprio,até16aliases,locale restrito,evidência humana/direitos,imutabilidade/idempotência ebytes comhash correspondente. TestesGo/vet eSQLdescartável passaram; banco temporário removido ecluster inicialmente parado voltou a parar; dados entregues preservados. [Recibo](food-names-foundation-verification.json).00009 **não aplicada àbase entregue**(23tabelas);0nomes publicados. Hash/booleano não provam revisão humana:publicação operacional autorizada ainda falta.

[LeituraGo0.6.0](food-names-read-verification.json):locale/namesVersion opcionais na lista e locale no detalhe, reviewedName/nameCatalog aditivos. Busca poralias, homônimos separados, fonte/versão/nutrientes preservados; snapshot/00010 vinculam revisão ao cursor eETag;409quando o léxico muda. SQL/HTTP passou, inclusive retirada semreviver antigo, cache entreidiomas e cursor original legado. Nenhum novoendpoint nemnome publicado;Swagger25operações regenerado.00009/10 continuam sóno banco descartável; base entregue ainda23tabelas/migration8.

Próxima fatia048: integrar Flutter em testes (apresentação, original/fonte acessíveis, cache/gerações/409). Antes de ativar os parâmetros no APK, aplicar9/10 e grants com validação que preserve a base entregue. UsarLocale.toLanguageTag(),nãointl.localeName(pt_BR). Falta ferramenta operacional de revisão/publicação, cobertura editorial eaceites. Flutter ainda não deve enviar locale ao ambiente anterior antes das migrations/integração. Não alegar revisão de nomes por traduzir rótulos.048continua doing; aceiteAndroid4idiomas eexecução nativaiOS ainda faltam.

## V1-048 em andamento — 25/10

[Recibo do incremento](frontend-localization-verification.json): infraestrutura oficialFlutter com ARB tipado, escolha system/pt-BR/pt-PT/en/es persistida somente no aparelho e79mensagens da entrada/perfil/aparência/navegação e feedback de sessão. Leitura em paralelo à aparência, timeout2s/fallback; trocar idioma preserva conta/controller/aba. Helpers de datas e decimal exato testados, ainda não aplicados a todos os fluxos. Dependências novas apenas flutter_localizations doSDK eintl0.20.2 já no cache; resolução offline, sem upgrade das existentes.

119testesFlutter/analyze0issues,11testes novos dirigidos com8prévias locais e7testes dohelperAndroid aprovados. APKdebug0.3.1+14 compilado/certificado verificado, não instalado. Preferência Android compilada; preferência/declaração iOS preparadas, sem execução nativa. Graphify96Dart/1699nós/2193arestas eHTML, sem semântica; ARB não é interpretado pelo grafo.

**Ainda falta na048 (após os incrementos26/10 acima):** modelo separado de nome/alias revisado por alimento+versão+idioma com direitos/revisão/retirada; contrato/busca/paginação/cache por idioma/versão, fallback e aceites. CódigoGo0.6.0 já tem contrato aditivo acima, ainda não integrado aoFlutter/ambiente entregue. FoodReference continua exibindo original; importador continua rejeitando namePt. Nenhum nome alimentar/tradução foi publicado, nenhum hash/nutriente/consumo mudou. Não marcar done nem trocar de história por este checkpoint. A tela de idioma informa cobertura parcial.

## Frontend e Figma

[Fonte visual e checkpoints consolidados](frontend-fidelidade-figma.md):pontos01–06 noAndroid,07–12 refinamento dos fluxos disponíveis, sem fechamento integral. MarcaTF, darkGrafite e lima e Android sem esticamento preservados. iOS não foi executado nativamente nesta máquina.

Figma vigente:arquivo bX6YjBBLIJgoo2MtiFLntl, página0:1/v0.5. [Inventário](frontend-figma-inventory.json). Contextos obtidos e nós faltantes na fonte visual/trilha. Limite de leituraStarter foi registrado; whoami nesta rodada confirmou o plano, sem repetir get_design_context. AbrirFigma noPC não altera a cota. Não contornar, comprar plano ou alegar comparação exata sem referência suficiente.

Os relatos frontend-etapa-01-06.md, frontend-dark-scroll.md e frontend-etapa-07-12.md foram incorporados à fonte visual única e removidos. Conteúdo e recibos preservados; não recriar arquivos redundantes.

## Execução e limites

Trabalhar pelos gates da trilha:decisões → banco → backend → segurança → frontend → qualidade → escala → APK → avaliação da mídia, respeitando as dependências do backlog. Segurança/testes entram em cada incremento. Bloqueio humano/editorial não vira done; seguir apenas trabalho independente.

Foto042 foi antecipada e delimitada a alimento por foto, sem inferir quantidade; composição044 cobre o segundo caminho aprovado. Agrupamento045, histórico/análise/dicas046, configuração047 e localização/nomes048 foram planejados naV1;048 agora doing no recorte acima, ainda sem done. Q3 incorporado em015/017/023/044/035; retomada preserva somente eventos reais e edição não reescreve histórico. Regras/fontes/revisão das dicas precisam ser elaboradas; a prioridade conjunta já foi decidida. Sensores041 e acompanhamento de terceiros043 continuam posteriores. Histórico de consumo é dado do servidor; recuperar também as fotos pela conta com cache foi aprovado no Q2, ainda sem implementação. Q4 exige exclusão da foto com a refeição e invalidação de cache/fila; limites/retenção e mecanismo de limpeza ainda precisam ser implementados, sem contratar hospedagem agora. Conteúdo precisa de direitos/revisão apropriados; API deGIFs não aprova treino/dose. Sem história/valor/quantidade/condição fictícios no runtime.

Sem hospedagem/deploy/compra/assinatura/integração paga/contato externo. Gratuitas primeiro; atéR$400 eventual permanece decisão doautor. Commit e push de incrementos validados autorizados; manter credenciais/capturas privadas fora doGit.

## Documentação e validação

- [Índice](../../README.md), [plano macro](plano-macro.md), [escopo](escopo.md), [arquitetura](../../arquitetura/README.md), [diário](diario.md).
- Gerar/check:`python tools/gerar_documentacao.py --write --check`; testes pertinentes:`python -m unittest discover -s tools -p test_documentacao.py`.
- Sem alteração deAPI/migration, Swagger preservado. Código mudou:GraphifyAST/HTML e mapas documentais atualizados. Recibo separa testesFlutter da geração documental; nenhum deles substitui o aceite humano doAPK.
- Comparar Git real antes de continuar; snapshots antigos e recibos mantêm seu valor histórico e seu escopo.
