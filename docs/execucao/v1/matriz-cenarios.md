# Matriz de cenários do APK de avaliação

Direção do autor em21/10/2026. O objetivo é percorrer o app inteiro, um cenário de cada vez, enquanto ele é desenvolvido. Atualizada em22/10 com o APKdebug0.1.1+2 e API/DB reais. Biblioteca/detalhe de consulta foram inspecionados no emulador; Google real aguarda autor. [Roteiro de retomada](avaliacao-android.md) e [V1-014](catalogo-consulta.md). Esta avaliação parcial não libera prática nem conclui os demais cenários.

Entrada de conteúdo: [manifesto de candidatos](../../../content/manifests/pilot-candidates.json), com331famílias,46recortesN e34componentes documentais selecionados. Os componentes são11para cuidadores,5domésticos idosos,9de academia e9de praça; não34programas completos. Todas as fontes continuam visíveis no inventário, inclusive referências, condicionais e antigas incompatíveis com custo zero. São22famílias de fontes alimentares, não22alimentos.

## Como registrar o resultado em cada versão

Para cada cenário, registrar versão/commit do APK, ambiente/API, versão do manifesto, estado, passos executados, resultado observado e próximo ajuste. Estados: **disponível para teste**, **incompleto**, **bloqueado por conteúdo/requisito** e **ainda não implementado**. Nenhum estado funcional é atribuído só por existir uma tela, um artigo ou um teste documental. Conteúdo pode permitir consulta sem permitir prática guiada; registrar esses dois usos separadamente.

Conta nova começa sem histórico ou medidas. Para avaliar perfis/ambientes diferentes, usar filtros/contextos documentados, sem criar idade, profissão, condição ou resultado fictícios da testadora. A visita à seção de idosos/cuidadores não exige executar o programa. Ensino voltado à autonomia não elimina exigência documentada de apoio.

## Percurso de avaliação

| Cenário | Requisitos | Conteúdo/evidência de partida | Estado conhecido e o que verificar no APK |
|---|---|---|---|
| C01 — abrir, entrar, sair e retomar | R01/R16/R17/R18 | Base Flutter/Fastify; diagnóstico atual | AuthGo/Flutter implementados e APK0.1.1+2 instalado; loginGoogle real aguarda autor. Conferir conta real, erros, sessão, logout e retomada sem perda indevida. |
| C02 — entrada e escolha por contexto | R01/R02/R04/R06/R16 | CoberturaN15–N34 e biblioteca de fontes | Consulta de metadados disponível semlogin: busca/filtros de valores efetivamente informados, campos desconhecidos explícitos. Contexto/seleção de rotina ainda pendentes. Escolher modalidade/ambiente/recursos sem presumir aparelho, saúde, experiência ou criar prescrição. |
| C03 — casa e pessoa idosa | R03/R04/R05/R06 | N15/N16/N17; PR28/ES2019-DOM-01,5movimentos | Candidato documental separado dos cuidadores; direitos, apresentação e critérios de uso ainda requerem revisão. Conferir requisitos e campos ausentes. |
| C04 — cuidador como praticante | R01/R03/R05/R06 | N15: CG01/PR42,CG04/PR68,CG06/PR261;11componentes | Consulta documental; apoio/população de cada componente não são intercambiáveis. Testar distinção familiar/profissional/pessoa assistida e razões de restrição. |
| C05 — academia | R02/R03/R04/R05 | N18/N19/N20;9correspondências textuais de máquina/pesos livres | Equipamento real e prática não testados nesta rodada. Conferir nome, variante, preparação/instrução disponível, requisitos e falta de mídia; não alegar que toda máquina é equivalente. |
| C06 — praça/parque | R02/R03/R04/R05 | N21;9componentes do pacote modular de praça | Candidatos próprios do ambiente, distintos de academia. Conferir aparelho/variante, apoio, público e lacunas antes de uso. |
| C07 — demais modalidades | R02/R03/R04/R05 | N22caminhada,N23corrida,N24ciclismo,N25natação,N26yoga,N27Pilates,N28mobilidade,N29equilíbrio,N30circuito/HIIT,N31remo | Cobertura de pesquisa não é oferta integral liberada. Mostrar disponibilidade real por modalidade e lacunas sem gerar programa novo. |
| C08 — retorno, dor e limitações | R04/R06 | N32/N33 e requisitos das fontes humanas | Adequação individual não inferida. Conferir limites, explicação e ausência de indicação automática baseada só no nome de uma condição. |
| C09 — aprender a execução | R05/R15/R17 | Instruções/mídias separadas; EX01/EX03/EX04 e comparação oficial | Foto+vídeo quando autorizados e disponíveis; somente um quando for a cobertura. Falta de mídia e falta de instrução têm mensagens distintas. Sem apagar item só por falta de vídeo. |
| C10 — selecionar e organizar rotina | R03/R04/R10/R16 | N19/N34; versões de programa e regras documentadas | Implementação pendente. Conferir identidade de programa integral/coleção modular, versão, opções e horários sem inventar dose/progressão. |
| C11 — iniciar, pausar, registrar e retomar atividade | R10/R11/R14/R17 | Eventos reais; domínio/contratos propostos | Implementação integrada pendente. Conferir persistência, idempotência, parcial/concluído, fuso, rede e recuperação; não registrar atividade apenas ao abrir tela. |
| C12 — buscar alimentos | R07/R08/R10 | N01–N05;22famílias alimentares no manifesto | Lote autorizado importado em22/10:6369registrosCiqual/CoFID noDBisolado,2identidadesconflitantes excluídas,3basesdesconhecidas preservadas; reimportação/restore verificados. Busca no app continua pendente. Conferir pesquisa por texto, preparo, fonte, unidades, paginação, duplicados e ausências; não se limitar a poucos itens como cobertura definitiva. |
| C13 — cadastrar alimento próprio | R08/R10/R18 | Dados reais informados pelo usuário; V1-020/025 | Ainda não implementado. Conferir cadastro/versionamento, origem própria, busca autorizada, privacidade e valores desconhecidos; não virar item editorial público por inferência. |
| C14 — quantidade, refeição e histórico alimentar | R07/R08/R09/R10/R14 | N02/N03/N14; composição e conversões documentadas | Implementação integrada pendente. Confirmar quantidade/base100g/100ml/porção e consumo real; null não vira zero nem porção estimada. |
| C15 — aprendizagem e rotinas alimentares | R07/R09/R15/R16 | N07–N14; guias/receitas existentes | Uso por ativo ainda a revisar. Conferir autoria, objetivo, preparo e limites; referência geral não vira dieta individual ou receita inventada. |
| C16 — Hoje, histórico, perfil e privacidade | R09/R14/R16/R17/R18 | Base inicial e propostas de API/DB | Conferir somente registros reais, estados vazios, edição/exclusão, troca de conta, exportação e revogação; novo fluxo integrado pendente. |
| C17 — foto de alimento e quantidade | R08/R13 | N06/N39/N40 | Função avançada posterior, não implementada por inferência da pesquisa. Na avaliação, registrar essa pendência; mídia do catálogo não reconhece automaticamente o prato nem sua quantidade. |
| C18 — rótulo/OCR/código de barras | R08/R13 | N41/N42 | Posterior, pendente de implementação/validação. Não criar captura ou resultado fictício para aparentar funcionalidade. |
| C19 — GPS, sensores e dispositivos | R11/R17 | N35/N36/N37/N38 | Integração real posterior. Conferir a lacuna no APK; tempo de sessão não equivale a distância ou gasto medidos. |
| C20 — imagem de atividade | R11/R12 | N43 | Posterior; captura/importação por imagem não implementadas. Não inferir execução, tempo ou gasto a partir de uma foto. |
| C21 — acompanhamento de pessoa assistida | R01/R06/R10/R18 | N44; cuidador e titular separados | Posterior. Autorização/vínculo real ainda requerem implementação; papel de cuidador não concede acesso a registros de outra pessoa. |
| C22 — linguagem e acessibilidade | R05/R15/R17 | N45; textos e versões efetivamente disponíveis | Teste widget de texto2x/320x568 e inspeção visual da biblioteca/detalhe passaram; leitor de tela físico ainda não validado. Testar contraste, navegação e linguagem no APK real. Fonte em outro idioma não vira tradução revisada automaticamente. |
| C23 — confiança, custo e operação | R18 | N46; decisão de compra única; política de mídia | Conferir autoria, permissões, versão, rede, segurança e custos. Licença paga depende de proposta/aceite; avaliação não autoriza assinatura, contato ou compra. |
| C24 — paridade de plataformas | R17 | Android inicial; N37/N38; V1-038/039 | APK Android primeiro. iOS mantém implementação e testes próprios; não declarar validado pelo resultado Android. |

## Regras para liberar e registrar lacunas

- Consulta: mostrar metadados e conteúdo cuja exibição tenha permissão demonstrada, com origem e limites; este inventário interno não é licença para publicar todos os ativos.
- Prática guiada: liberar somente a versão com instrução suficiente e requisitos/direitos compatíveis com o uso real. Falta de foto/vídeo, por si só, não é uma proibição universal; falta de instrução não se resolve com texto inventado.
- Bloqueado: manter motivo concreto e próximo passo, distinguindo licença, apoio/população, instrução, acesso e capacidade técnica ainda ausente. Não chamar tudo de “falta pesquisa”.
- Pesquisa complementar: partir da lacuna observada ou de pista específica; preservar conclusões N01–N46 e os componentes já conferidos.
- Não solicitar idade, diagnóstico ou profissão pessoal só para explorar os cenários de interface. A elegibilidade para prática será tratada pelo conteúdo e pelos campos efetivamente necessários.

[Decisões do autor](decisoes-piloto.md), [escopo](escopo.md), [backlog](backlog.md) e [comparação de fornecedores](../../conteudo/opcoes-apis-exercicios.md). Custo atualizado para avaliação: priorizar gratuito; referência de cerca deUS$19 em pagamento único, sem assinatura. Os valores maiores apresentados foram considerados inviáveis; nenhuma compra foi aprovada.
