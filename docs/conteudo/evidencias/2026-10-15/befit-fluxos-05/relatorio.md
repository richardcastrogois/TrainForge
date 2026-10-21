# BeFit: percurso gratuito observado e propostas TrainForge

15/10/2026. Continuação do [relatório04](../../2026-10-14/befit-fluxos-treinos-04/relatorio.md) após o usuário aceitar Termos/Privacidade e autorizar perfil fictício. Nenhum contato com BeFit, conta nova, pagamento ou trial. O aceite resolve a intervenção pendente; não concede direitos de extração/reutilização.

## Resultado

Acesso à área gratuita com anúncios, sem conta BeFit, pelos controles normais: fechar duas ofertas com X, escolher Continue for Free e dispensar convite de login com X. Não houve contorno de premium, login obrigatório ou proteção. REA capturou estados; toques/digitação/navegação usaram o ADB existente. Appium, Studio, extensões e outras instalações não foram necessários.

Perfil exclusivamente fictício: masculino, melhorar condicionamento, iniciante, prática irregular, sem equipamento, sem lesões declaradas, corpo inteiro,30anos/170cm/70kg/meta65kg, duração até20min, plano próprio/fixo. As medidas foram os valores iniciais exibidos, mantidos para teste. O resumo mostrou3dias/semana sem escolha explícita dessa frequência no percurso registrado. Nenhuma dessas respostas descreve o usuário ou prescreve treino.

## O que foi realmente observado

| Área | Comportamento | Evidências, passos do JSON |
|---|---|---|
| Cadastro | Uma pergunta por tela, voltar, indicador segmentado; objetivo, experiência e regularidade separados; ambiente/equipamento, lesões e foco muscular |02–09 |
| Medidas e projeção | Mesmo com condicionamento como objetivo, pede peso-alvo e mostra previsão de emagrecimento por data. Não apareceu opção de pular nessas telas |11–16 |
| Composição do plano | Oferece IA e plano próprio; renovação2/6semanas ou fixo. Foram selecionados próprio/fixo, não testado algoritmo de IA |18–20 |
| Entrada comercial | Prévia de semana, duas ofertas, depois opção gratuita explícita com anúncios. A prévia não se tornou treino salvo no caminho próprio |27–39 |
| Login | Convite Google/e-mail dispensável pelo X observado; perfil ficou Befit User/Create your account |35–40 |
| Navegação | My Plan, Workouts, Progress, Exercises, Profile; barra recolhe em ícone e pode ser expandida novamente |39–46 |
| Biblioteca de movimentos | Agrupamento por músculo, equipamentos, favoritos, busca e ordenação por popularidade. Busca exibiu454itens antes do filtro e28resultados para Squat |46–52 |
| Detalhe de um movimento | Ilustração anatômica e separação em Target, Instructions, Equipment; estrela de favorito visível |52 |
| Criar treino próprio | Formulário vazio: nome, Add Exercise, reordenação e More Options. Menu mostra descanso padrão, supersérie, séries/repetições e exclusão. Saída sem salvar |54–57 |
| Treinos prontos | Área separa sessões rápidas e planos; filtros por nível e equipamento. Iniciante+Bodyweight retornou explicitamente nenhum treino rápido encontrado |57–60 |
| Progresso | Calendario semanal, sequencia diaria/semanal zeradas e estado sem historico. Nao houve sessao concluida nem sincronizacao testada |63 |
| Perfil | Unidades, idioma, Strava não conectado, Wear OS, lembretes, ajuda/termos, versão1.1.37 e Powered by3apps |40–45 |

Os números da busca são contagens exibidas nesta versão/execução, não inventário integral auditado, programas completos ou conteúdo aprovado. Não foram percorridos ou copiados os28resultados ou454itens. Um exercício foi aberto para observar organização. Favoritar, autenticar, sincronizar, executar sessão e persistir treino não foram validados.

Uma tentativa de abrir Help chegou à configuração Workout reminders: o anúncio inserido no perfil mudou a posição das linhas. Isso foi registrado como desvio de navegação, não como Ajuda testada. Nenhuma configuração foi alterada. A primeira busca também voltou à lista após Back; uma segunda tentativa com foco confirmado validou o filtro. Não ocultar esses limites.

## Conteúdo e direitos

Não foi confirmado fornecedor externo das ilustrações, textos, vídeos ou programas. O rodapé3apps confirma marca/desenvolvedor, não autoria por ativo. Marcas em anúncios e cupons são referências comerciais, não fornecedores de exercícios comprovados. Sem atribuir por semelhança visual a GymVisual, wger, MuscleWiki ou outro.

Não foram extraídos APK, código, banco, URLs de mídia, tráfego, vídeos ou instruções. A aba Instructions teve captura rejeitada pela revisão automática por contrariar o limite de não copiar conteúdo. Não houve captura alternativa, OCR, dump de UI ou outro meio para obter seu roteiro. O relatório descreve apenas a existência da aba já visível na tela de detalhe. As imagens de observação anteriores permanecem locais, sem incorporação ao TrainForge ou publicação.

Os anúncios exibiram rótulo Test Ad. O comportamento observado no emulador não demonstra frequência, segmentação ou experiência de todos os usuários em produção.

## Melhorias próprias sobre o que já temos

Base de comparação: documentos fluxos-v04.md e ajustes-visao-integrada.md, sem nova inspeção do Figma ou do runtime Flutter.

| Prioridade | Decisão proposta | Relação com a especificação existente |
|---|---|---|
|1 | Entrar por programa humano, ajuda para escolher ou plano próprio; permitir conhecer origem e estrutura antes de medidas opcionais | F01/F03 já preveem esses caminhos. Preservar essa vantagem; IA continua opcional |
|1 | Questionário condicionado ao objetivo. Não obrigar peso-alvo nem apresentar data de emagrecimento para todo percurso de atividade | F02, perfil progressivo; tempo/preparo/apoio e contexto do cuidador têm papel próprio |
|1 | Distinguir visualmente biblioteca de movimentos, sessão e programa com duração/frequência/versão/autoria. Não converter454movimentos em454treinos | F03 e contrato documental de conteúdo |
|1 | Mostrar antes de iniciar: público, material, tempo, apoio profissional exigido, fonte/versão e estado da revisão. Ausência de lesão declarada não vira selo automático de liberação | F03/F04, critérios-exercicios-apk |
|1 | Executar unidades próprias da fonte: séries/repetições, trabalho/repouso, posições ou sequência. Defaults de plano pessoal não sobrescrevem dose do programa original | F04, especialmente ReViEEW e demais fichas pesquisadas |
|1 | Tratar falta de plano para combinação com explicação e filtros revisáveis. Não gerar conteúdo por IA para preencher a lacuna silenciosamente | F02/F03: vazio e incompatibilidade já previstos |
|2 | Guardar conclusão parcial, pausa e retomada; para cuidadores, registrar interrupção sem punição de sequência. Progresso útil precisa de histórico real, não pontuação promocional | F04/Evolução; resultado clínico não atribuído ao simples uso do app |
|2 | Manter navegação legível/estável; reservar espaço de conteúdo para não deslocar controles durante carregamento. Pedir avaliação depois de experiência concreta | Melhoria de usabilidade observada, não mudança aplicada |

Preservar os recortes: cuidador exercitando-se para si, idosos, casa, praça/parque. Não presumir que a biblioteca geral estudada resolve esses públicos. N21/praça não iniciada por este benchmark.

## Como isso ajuda a fechar os treinos

O benchmark confirma a necessidade de duas camadas no TrainForge: plano/programa com fonte e condições, e executor de sessão que respeita suas unidades. O BeFit não fornece, por esta observação, conteúdo autorizado para preencher nosso catálogo.

O incremento04 permanece a entrada factual atual da pesquisa: CG01 fechado para pesquisa somente no recorte restrito/profissional; CG04/ReViEEW ganhou grade24, nove fichas/27variantes e partes da sessão, mas cotejo/apresentação/direitos finais não estão concluídos. CG02/03/05 continuam com pendências específicas de material, versão e direitos. Nenhum programa foi publicado ou prescrição nova criada.

A proposta documental é revisar um lote pequeno rastreável e só então levar suas fichas ao app. Não reduzir silenciosamente os cinco itens solicitados, dispensar supervisão ou declarar N15-C fechada porque o protótipo fica navegável. Este incremento não altera a filaCG02 nem inicia pesquisa de outro nicho.

## Limites desta etapa

- Observação estrutural concluída nos caminhos descritos; não auditoria integral do BeFit.
- Sem validação de sessão completa, mídia em reprodução, registro/conclusão, persistência, offline, IA, integração Strava/WearOS ou premium.
- O acesso ao roteiro de instruções ficou bloqueado; não necessário copiar esse roteiro para propor melhorias próprias.
- Preservados código, Figma, banco e fila de pesquisa do TrainForge. Sem commit/push.
- Metadados, hashes e estados em observacoes.json/validacoes.json; retornos REA completos no raw ignorado desta data. Capturas locais em C:/dev/rea-tools/evidence/befit-scope05-*.
