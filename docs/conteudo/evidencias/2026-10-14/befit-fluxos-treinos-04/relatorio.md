# BeFit observado e decisão sobre os treinos

14/10/2026. Escopo atualizado pelo usuário: **nenhum contato com BeFit**; observar funcionalidades acessíveis para melhorar a experiência própria do TrainForge e concluir o conteúdo necessário antes de implementar. Sem Figma, código ou banco nesta etapa.

## Resultado real no BeFit

REA conectado ao agente iniciou `app.befit` no AVD `TrainForge_Benchmark`, serial observado `emulator-5554`. Inicialização retornou `Status: ok`, `MainActivity`, partida a frio, 3811 ms. Uma captura imediata mostrou splash; uma captura posterior mostrou a apresentação inicial. Isso comprova abertura, não desempenho típico.

| Observação | Evidência | Limite |
|---|---|---|
| Apresentação anuncia progresso, gráfico semanal, recordes e sequência de atividade | captura `befit-scope04-settled/screen.png`, SHA256 `983866b1c1ecb0aae4ca59260a6cdd8a6fc53056afbebd8d9cbbc030d2fa57a6` | Imagem promocional dentro do app; não histórico real nem execução dessas funções |
| Entrada oferece começar e acesso para quem já tem conta | mesma captura | Cadastro e autenticação ainda não testados |
| Um toque em começar abre pergunta de gênero com três alternativas, voltar e indicador segmentado | captura `befit-scope04-started/screen.png`, metadados em `observacoes.json` | Nenhuma alternativa selecionada; indicador não comprova número efetivo de perguntas |
| Rodapé informa aceite de Termos e Política de Privacidade ao continuar | mesma captura | Solicitado aceite do usuário e autorização para perfil fictício; nenhuma aceitação presumida |

Capturas locais em `C:/dev/rea-tools/evidence/`; retornos completos REA no diretório raw ignorado desta data. Captura e início de app foram executados por REA. O toque individual usou o ADB existente, coordenada observada 540,1890 na tela 1080×2340. REA não oferece aqui controle genérico de cliques. Nenhuma instalação Appium foi necessária.

**Não observado:** biblioteca, detalhe de programa, player, registro de séries, substituições, conclusão, histórico real, autoria por exercício, limites gratuitos/premium e funcionamento offline. Nenhuma afirmação de paridade funcional ou fornecedor externo pode ser feita a partir destas telas. Não houve extração de APK, código, tráfego, biblioteca, vídeos ou programas BeFit. Nenhuma contratação, trial ou nova conta pelo agente.

Os termos restritivos já registrados no relatório01 continuam um limite; o novo pedido não concede direitos sobre conteúdo ou autoriza engenharia reversa/extração. Prosseguir apenas no uso normal acessível, após a decisão sobre os termos. Se houver proibição aplicável à próxima operação, registrar e continuar a frente independente. Nenhum contato será enviado.

## Comparação com o TrainForge

Comparação documental com `docs/design/fluxos-v04.md` e `ajustes-visao-integrada.md`, não nova inspeção do arquivo Figma.

| Princípio observado ou anunciado | Relação com o projeto | Proposta própria |
|---|---|---|
| Apresentar um resultado antes do cadastro | F01/F02 já preveem entrada por intenção e contexto progressivo | Mostrar exemplo claramente identificado e permitir conhecer a estrutura/origem de um plano antes de pedir medidas opcionais |
| Uma decisão principal por tela e indicador de avanço | Compatível com o perfil progressivo F02 | Explicar por que cada dado é necessário, permitir voltar e conservar respostas; não exigir identidade ou medidas sem finalidade para o plano |
| Anúncio de progresso | Histórico/Evolução já existem na v0.4 documental | Medir sessões realizadas/parciais e contexto; para cuidadores, não transformar interrupção para cuidar em perda punitiva de sequência |
| Atalho para conta existente | Fluxos de acesso já especificados | Manter retorno e recuperação claros; autenticação real permanece implementação futura |

Essas são propostas de produto, não resultados clínicos ou funcionalidades BeFit verificadas. Idosos, autocuidado do cuidador, casa e praça continuam contextos distintos. Praça/N21 não foi pesquisada nesta rodada.

## Treinos: avanço a partir do material recebido

Foi conferida a tese original de Ander Espin Elorza, já recebida legitimamente: 275 páginas, SHA256 `3a9441ae09ece4926b33204b86df0b4681c48549cee6589921eb9643b80ce90f`. Houve leitura textual dirigida e inspeção visual de PDF83–94 e261–272, mais SI2 previamente recebido. Não foi relida integralmente a tese nem feito novo download.

Achados que substituem afirmações anteriores de material ausente:

- PDF261/Apêndice8 contém a grade original de 24 sessões, códigos dos movimentos, aquecimento, alongamentos e respiração.
- PDF262–263/Apêndice9 contém orientações escritas de manutenção. Foi recebido o texto dentro da tese; isso não significa vídeos recebidos nem licença comercial desse apêndice.
- PDF264–272/Apêndice10 contém nove fichas com três progressões ilustradas cada, comando básico e erros a evitar. Portanto, já não cabe dizer que há apenas nomes/fotos sem qualquer comando publicado.
- PDF83–85 traz mobilidade e ativação do aquecimento; PDF90 mostra exemplos de repouso ativo; PDF92–94 detalha encerramento, alongamentos e quatro atividades respiratórias. A nomenclatura/metodologia em basco exige revisão da localização antes de apresentação ao praticante.
- PDF262 restringe os vídeos ao uso pessoal dos participantes e pede que não sejam compartilhados. A pasta não foi aberta nem baixada. Um link encontrado não é autorização.

O cotejo de variantes está em `revieew-cotejo.json`. As nove famílias correspondem ao SI2, mas a tese não repete todos os parâmetros do suplemento. O comando geral não pode virar um roteiro autônomo completo por inferência. Exemplos: manter os 3 s de isometria do SI2 no agachamento; não tratar o título espanhol de ombro como correção anatômica da figura. Não transferir a flexibilização da manutenção para reduzir a dose da fase supervisionada estudada.

**Lacuna reduzida:** a identificação e estrutura das partes da sessão agora têm fonte original e localizadores. A orientação final de variantes/entrada/saída, a correspondência dos parâmetros e os direitos da apresentação escolhida ainda precisam ser concluídos. CG04 e N15-C continuam abertos; a fila canônica não foi marcada como encerrada por esta leitura.

## Decisão concreta para sair da pesquisa ampla

Não buscar mais artigos genéricos para os mesmos campos já conhecidos. Resolver somente o que falta à entrega escolhida:

| Item | O que existe | O que impede liberação |
|---|---|---|
| CG01, alongamento estático | Pesquisa executável fechada no público original restrito e caminho profissional | Revisão da apresentação e suporte real antes de publicar; não é programa semanal geral |
| CG02, Benson | Seis etapas e dose documentadas | Material educativo legal/fiel e revisão, mantendo ensino/reforço; pendência não é falta dos seis comandos |
| CG03, START | Oito componentes vinculados ao programa | Manual participante/áudio e direitos da versão; não oito terapias isoladas |
| CG04, ReViEEW | Programa profissional, grade24, nove fichas/27 variantes e partes da sessão agora localizadas | Cotejo final, apresentação legal/fiel e revisão de variantes; supervisão bidirecional preservada |
| CG05, Pilates | Estrutura, dose e fases originais | Guia exato das variantes, transições divergentes e ativos/direitos |

Proposta de primeiro lote: **CG01 como item restrito já fechado para pesquisa e CG04 como candidato a programa estruturado**, sem excluir CG02/03/05 da pesquisa solicitada. A proposta ainda não altera prioridade nem reduz silenciosamente o compromisso de conferir os cinco. Nenhum dos cinco está publicado. Se a primeira versão do produto exigir somente prática autônoma, esse lote não atende esse requisito: será necessário selecionar um caminho autônomo realmente sustentado pelas fontes.

Para uma futura revisão visual do app, a sessão1 do ReViEEW já pode ser representada documentalmente com dados originais: aquecimento codificado MA/CJ; parte principal L1A,U1A,T1A,L2A,U2A,T2A; quatro séries; trabalho/repouso30:30; alongamentos KC/LG; respiração SM. Os códigos, nomes e seus localizadores estão no JSON. **É um registro para revisão, não prescrição ou autorização para iniciar prática.** O tempo total original e o acompanhamento não podem ser eliminados pela interface.

O pacote doméstico ES2019-DOM-01 de cinco movimentos para idosos permanece preservado e fora de uma nova rodada nesta etapa. Ele não substitui automaticamente o conteúdo específico do cuidador. N15-C não fechada, N21 não iniciada; sem programa novo gerado por IA.

Próxima entrega deve ser o lote com cada campo e ativo efetivamente selecionado, estado e pendência objetiva. Implementação/contratação não serão usadas como novos impedimentos para declarar pesquisa encerrada, mas a publicação precisa manter as condições reais de uso.

## Pendências de intervenção e continuidade

1. Decisão do usuário sobre Termos/Privacidade e perfil fictício do BeFit. O agente não deve inventar dados do usuário nem aceitar em seu lugar.
2. Continuar observação normal do BeFit quando possível; capturar apenas telas necessárias e distinguir material promocional de funções testadas. Não contatar BeFit.
3. Concluir o cotejo/licenças da apresentação CG04; para CG02/03/05, aproveitar materiais já recebidos ou respostas que venham a ser disponibilizadas, sem novos contatos/follow-ups automáticos.
4. Apresentar o lote revisável antes de qualquer alteração no app/Figma/banco. A seleção proposta não foi implementada ou homologada.
