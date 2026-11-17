# Evolução visual do TrainForge

Registro consolidado das decisões v0.2, v0.3, v0.4 e da especificação F01–F12. Os marcos abaixo descrevem o que foi observado em setembro de 2026; a consolidação documental não reinspecionou nem alterou o Figma. Os [42 SVGs e a prévia histórica](README.md) foram preservados para estudo e apresentação.

Para o produto atual, comece por [Interface e Figma](../execucao/v1/validacao-e-entrega.md#interface-e-figma), [implementação](../execucao/v1/implementacao.md) e [backlog](../execucao/v1/backlog.json). Protótipos não autenticam, não salvam registros e não aprovam conteúdo clínico, nutricional ou jurídico. Dados demonstrativos não se tornam dados reais do aplicativo.

| Marco | Evidência daquela data | Limite |
|---|---|---|
| 10/09, v0.2 | Sete telas locais e Figma editável; navegação e identidade refinadas | Preferências, perfil e logout ilustrativos |
| 14–16/09, v0.3 | 33 telas, 83 rotas, quatro pontos de partida e percursos conferidos | Formulários e serviços simulados |
| 17/09, v0.4 | 105 telas/estados, 372 reações e validação estrutural | 372 reações não equivalem a 372 funções do app |
| 22/09, cópia preservada | Página `126:2`, 105 telas, 372 reações nas telas e 76 nos mapas | Snapshot, sem inspeção viva em 24/09 |
| 24/09, F01–F12 | Especificação visual da visão integrada | Não foi aplicada no incremento que a escreveu |

<a id="v02"></a>

## V0.2 — identidade, navegação e semana

Em 10/09, a partir de seis capturas fornecidas pelo autor, os ajustes foram aplicados no arquivo Figma editável pela aba existente do Comet e reproduzidos localmente. Flutter e API não foram alterados.

- Navegação das cinco áreas: somente o item ativo mostra nome centralizado abaixo do ícone; ativo de 28 px, inativos de 20 px. As áreas de toque permanecem maiores que os desenhos, com nomes acessíveis. Treino em curso e Perfil usam retorno, sem sexta aba.
- Marca: monograma TF verde/branco/lima e nome trainforge de 16 para 24 px, nos cabeçalhos das cinco áreas e do Perfil. A [marca SVG](trainforge-marca.svg) é a proposta daquela etapa.
- Semana: segunda concluída (✓ verde), terça não feita (× terracota), quarta parcial (âmbar), quinta atual e futuro neutro. Legenda explícita; resumo `1 feito · 1 parcial`, sem contar parcial como concluído. Datas e valores eram demonstrativos.
- Perfil: frame 390 × 844 com avatar/iniciais/edição, nome, dados pessoais, objetivos e preferências, notificações, idioma/unidades, privacidade/dados, ajuda/feedback e saída. A identidade clara foi preservada; as capturas orientaram o conteúdo.

Foram vistos Hoje/Perfil ampliados e o conjunto das sete telas no Figma. Texto e vetores eram editáveis. Os nove SVGs passaram no parse XML; sete telas tinham 390 × 844 e cada navbar tinha exatamente um rótulo ativo centralizado. Na prévia, avatar abre Perfil e retorno leva a Hoje; a sintaxe JavaScript foi validada, sem novo teste de interação no navegador nessa etapa. Conexões nativas, subtelas, componentes e auto layout ainda exigiam refinamento.

<a id="v03"></a>

## V0.3 — acesso, configuração e destinos

Em 14/09, o arquivo ainda se chamava `TrainForge · Direção de produto v0.1`, página `01 · Proposta mobile`; o nome não indicava a versão do conteúdo. Após autorização do autor, o Scripter executado no Comet retornou `VERIFICADO`, 33 telas e 83 rotas, com [mapa `54:94`](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl?node-id=54-94). A retomada de 16/09 encontrou os quatro fluxos, sem reaplicar o script.

As reações indevidas dos quadros inteiros foram retiradas: 74 ações por clique ficaram nos grupos de botões e nove transições temporizadas nas telas de abertura/carregamento. Cartões navegáveis e setas no mapa ajudavam a revisão. Havia quatro pontos de partida: Começar, Explorar, Completar alimentação e Mapa. No Play em computador, `Largura e altura ajustáveis` mostrava o quadro inteiro; `Responsivo` esticava esses frames.

| Telas | Conteúdo |
|---|---|
| 01–07 | Hoje, Planos, Treino em curso, Atividade, Alimentação, Evolução e Perfil |
| 08–09 | Dois estados da abertura para animar a marca |
| 10–13 | Entrar, criar conta, recuperar acesso e confirmar e-mail |
| 14–15 | Explicar uso das informações e escolher áreas de configuração |
| 16–18 | Objetivo/experiência, contexto e dados opcionais de treino |
| 19–20 | Preferências e horários de alimentação |
| 21–22 | Rotina e revisão do treino |
| 23–25 | Pendências independentes de treino, alimentação e rotina |
| 26–32 | Carregamento das sete telas principais |
| 33 | Confirmação condicional de recuperação de acesso |

Decisões de percurso: acesso propunha e-mail/utilizador e senha, Google ou Apple no iOS; cadastro levava à confirmação de e-mail. Recuperação não confirmava a existência de uma conta. A pessoa escolhia configurar treino, alimentação ou rotina agora ou depois. Treino passava por objetivo/experiência, local/equipamento/dias/duração, dados opcionais e revisão; a fonte do programa ainda precisaria validar os campos. Alimentação e rotina pendentes abriam somente suas etapas e voltavam à origem. Registro alimentar não dependia de prescrição de dieta. No esboço de rotina, nome/atividade/dias eram obrigatórios e horário/lembrete opcionais. Avatar abria Perfil.

Altura, peso, restrições de movimento, preferências e alergias eram opcionais no desenho. Não constituíam avaliação clínica ou autorização automática de recomendação; necessidade e tratamento de cada dado sensível continuavam em avaliação.

Carregamento por região conservava marca, navegação, pesquisa, filtros e definições. Planos e Perfil (27/32) foram ajustados e observados no Play. Tempos de 250–350 ms eram demonstrativos; não eram esperas a implementar. Redução de movimento, cache, atualização em segundo plano e ausência de rede ainda precisavam de especificação/teste real. Formulários, botões sociais e valores eram ilustrativos, sem persistência, autenticação ou envio de e-mail. Reenvio de e-mail não tinha reação simulada. Erros por campo/envio, salvamento, auto layout, componentes e acessibilidade não estavam concluídos.

A validação estrutural releu os 83 destinos. No Play, foram observados: Hoje → avatar → Perfil; cadastro → confirmação → introdução → áreas → três etapas de treino → continuar sem opcionais → revisão; alimentação pendente → preferências → horários → diário; rotina pendente → configurar → guardar → Hoje; recuperação → instruções → confirmação condicional. A abertura avançou para Entrar e os sete carregamentos avançaram aos destinos. Mapa sem sobreposição e quatro pontos de partida foram vistos; cada clique alternativo não foi ensaiado individualmente.

<a id="v04"></a>

## V0.4 — completar os destinos do protótipo

Aplicada no Figma Desktop em 17/09, na mesma página. As 33 telas anteriores foram preservadas; 63 destinos/estados e nove revisões de formulário elevaram o total a 105, além dos dois mapas. Flutter, API, banco e publicação GitHub não foram alterados nesse incremento.

| Área | Lacuna tratada e destinos criados |
|---|---|
| Perfil | Botões sem destino e edição que abria treino: dados pessoais, perfil, imagem/nome, conta/e-mail/métodos/senha e medidas |
| Preferências | Objetivos por área, notificações/estados, idioma e unidades |
| Privacidade | Resumo provisório, exportação simulada, apagar opcionais/conta, sucesso e cancelamento |
| Ajuda | Perguntas, feedback, prévia e confirmação simulada |
| Sessão | Confirmar saída e cancelar |
| Planos | Pesquisa/filtros/vazio, detalhe/origem/exercícios, guardar e plano próprio; cartão deixou de abrir treino diretamente |
| Treino | Instruções, registro/edição de série, descanso ilustrativo, conclusão e parcial |
| Atividade | Registro manual ilustrativo, edição e confirmação |
| Alimentação | Busca/resultados, porção/nutrientes, registro manual, confirmação e detalhe de pequeno-almoço/almoço |
| Evolução | Histórico de sessões/atividades e medidas |
| Acesso | Reenvio simulado, nova senha, termos e proposta de privacidade |
| Hoje | Detalhe do dia e sessão incompleta |

`v04-input-audit.json` catalogou 28 campos/escolhas dos nove formulários originais: acesso/cadastro/recuperação, três de treino, dois de alimentação e rotina. Cada campo abria uma revisão de exemplos; novos campos ficaram em `v04-spec.json`. Eram cenários de navegação, sem edição livre ou persistência. Notificações/idioma eram combinações predefinidas; timer, mapa, nutrientes e planos eram exemplos. Destino existente não equivalia à lógica implementada.

Para rever aquela versão: abrir `01 · Proposta mobile`, selecionar `07 · Perfil`, usar Shift + Espaço ou Apresentar e os pontos `TrainForge · início`, `TrainForge · perfil` ou `TrainForge · rotas v0.4`. No editor, selecionar o controle no separador Protótipo mostra a ligação exata. O [mapa `104:1974`](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl?node-id=104-1974), à direita, resume percursos; reações dos botões são a fonte exata. Carregamentos foram ligados ao início, sem obrigar toda volta a repeti-los.

A auditoria Scripter reportou `TELAS 105 / ROTAS 372 / QUEBRADAS 0 / SEM ACESSO 0 / OVERFLOW 0`, alcance desde a abertura e textos dentro dos limites dos quadros novos. Havia reações antigas preservadas sob áreas atualizadas; não eram 372 ações distintas. Não houve inspeção pixel a pixel nem validação de negócio.

Percursos observados no Play Desktop: Perfil → Dados pessoais → Conta e acesso → Dados pessoais → Perfil; notificações → exemplo ativado → Perfil; privacidade → eliminar → cancelar → privacidade → Perfil; Hoje → carregamento de Planos → detalhe → treino; treino → terminar → incompleto → histórico → Evolução; Evolução → diário → adicionar → porção/nutrientes → confirmação. As demais ligações foram conferidas estruturalmente, sem clicar cada reação. O rodapé do Perfil indicava v0.4.

A revisão seguinte deveria validar destinos/detalhe e aprofundar formulários, erros, rede/offline, preferências independentes e regras reais. A reprodução dos scripts está no [índice de design](README.md#reproduzir-os-auxiliares-historicos), sem reaplicação automática no arquivo atual.

Nas etapas v0.2–v0.4, o Graphify analisava somente `lib/`: 0 alterados, 42 inalterados e 0 removidos em cada encerramento registrado. A retomada v0.3 consultou `AuthRepository` e nove conexões. Isso não incluía extração semântica de design ou reindexação de API/web inalteradas e não descreve o grafo atual.

<a id="visao-integrada"></a>

## Visão integrada F01–F12 — especificação de 24/09/2026

A base era a página `0:1`, com cópia `126:2`, “Arquivo · Base v0.4 · 22-09-2026”. O inventário de 22/09 registrava 105 telas, 372 reações nas telas e 76 nos mapas; não houve leitura viva em 24/09. A especificação partia dos requisitos R01–R18 e do balanço de pesquisa da época. F01–F12 são famílias de trabalho, não IDs de nodes criados.

O texto histórico abaixo conserva as decisões/propostas e os percursos de aceite sem promovê-los a instrução vigente. Decisões posteriores em escopo/backlog prevalecem: por exemplo, excluir uma refeição deve excluir a foto ligada a ela; intenção offline durável e recuperação de fotos continuam com critérios próprios. Antes de retomar design, conferir o arquivo vivo pelo Figma Desktop, preservar ajustes manuais e trabalhar incrementalmente; não reaplicar geradores v0.3/v0.4 para substituir essa comparação.

### Organização e navegação a testar

Manter a identidade trainforge e o padrão de barra aprovado: ícone inativo menor e sem legenda; ativo maior com nome centralizado abaixo. Validar acessibilidade e forma de encontrar destinos sem legenda. Proposta de áreas: **Hoje, Praticar/Planos, Atividade, Alimentação e Evolução**; decidir o nome da segunda área por teste de compreensão. Perfil abre pelo avatar; aprendizagem aparece no contexto e tem biblioteca acessível, sem criar uma sexta aba obrigatória.

No canvas, organizar páginas/seções para fundamentos/componentes, entrada/configuração, prática, alimentação, atividade, acompanhamento/perfil e mapas de fluxo. Criar setas e ligações reais entre controles e destinos, com caminhos de voltar/cancelar. Estados complementares não devem virar telas duplicadas desnecessárias.

### F01 — Entrada e escolha de percurso (R01, R16, R17)

**Rever:** splash, login Google/Apple/e-mail, cadastro, recuperação, verificação e sessão expirada já documentados.

**Acrescentar/refinar:** apresentação curta do produto; “Quero ajuda para começar”, “Quero escolher um programa” e “Quero montar/trazer o meu plano”. São escolhas reversíveis, não categorias permanentes da pessoa.

Mostrar cadastro com nome, e-mail, palavra-passe e confirmação conforme fluxo aprovado; termos/privacidade; erro por campo; teclado; autofill; envio em curso; autenticação cancelada/indisponível. Apple depende da variante/plataforma definida. Login social não exige inventar uma senha local. Splash não deve criar espera artificial; representar abertura com sessão válida e retomada.

**Percurso de aceite:** pessoa entra sem conhecer exercícios, escolhe ajuda e chega à configuração necessária; pessoa experiente segue diretamente para seleção/montagem sem assistir a tutoriais obrigatórios.

### F02 — Configuração progressiva e objetivos (R04, R06–R09, R16)

**Rever:** as etapas de treino, alimentação e rotina da v0.4. Substituir perguntas genéricas que não tenham finalidade demonstrada.

| Grupo | Campos/escolhas a representar | Regra visual |
|---|---|---|
| Intenção | Saúde/hábito, força, capacidade, mobilidade, massa muscular, redução de gordura, ganho/perda/manutenção de peso, objetivo específico de modalidade | Permitir prioridades; não exigir meta em kg de quem só quer começar a caminhar |
| Contexto de prática | Modalidades de interesse, casa/academia/ar livre, espaço e equipamentos disponíveis | Seleção visual com nomes claros; “não sei” e “sem equipamento” têm percurso |
| Experiência | Familiaridade por modalidade, prática recente, interrupção e retorno | Não usar apenas iniciante/intermediário/avançado nem confundir intensidade com experiência |
| Disponibilidade | Dias, minutos por sessão, horários flexíveis e preferências | Explicar quando nenhum programa cobre a combinação; não inventar adaptação |
| Dados corporais | Medidas e unidades necessárias ao objetivo/função; data/origem | Peso/altura e outras informações só obrigatórios onde o método aprovado exigir; não pedir dados sensíveis por decoração |
| Alimentação | Objetivo, preferências, restrições declaradas, refeições/rotina, tempo/orçamento de preparo se útil | Distinguir preferência, alergia/intolerância e indicação profissional; informação ausente não significa segurança |
| Saúde/retorno | Contexto que a pessoa escolhe declarar, limitações e existência de orientação | Não apresentar lista de diagnósticos como prescrição automática; informar uso do dado e limite do serviço |
| Rotina/conta | Idioma, unidades, lembretes e conexões opcionais | Pedir permissão do sistema no momento útil, com caminho sem permissão |

Antes de cada grupo, explicar de forma curta o que será feito com as informações. Identificar obrigatório/opcional **por função**, permitir adiar e guardar progresso. Ao abrir alimentação incompleta, “Configurar alimentação” abre só o necessário e volta à tela de origem. A obrigatoriedade final depende dos métodos/conteúdos escolhidos na etapa 01.

**Estados:** não iniciado, parcial, completo, dados insuficientes, combinação sem conteúdo, erro de campo, rascunho retomado, edição posterior sem apagar histórico.

### F03 — Descobrir programas e montar planos (R01–R05, R10)

**Rever:** Planos, pesquisa/filtros/vazio, detalhe/origem/exercícios e plano próprio.

**Acrescentar:** descoberta por modalidade/contexto; “ajude-me a escolher”; comparação entre programas humanos; disponibilidade por equipamento; duração/frequência; público e experiência; calendário das sessões; explicação de progressão; guardar/começar/trocar.

Na ficha de programa: título, objetivo declarado, autoria/origem, versão, equipamentos, tempo/dias, estrutura, pré-requisitos, limitações e “como progredir”. Não mostrar “aprovado” sem aprovação registrada. Se o catálogo não cobrir um filtro, dizer o que falta e permitir rever escolhas, sem sugerir programa inadequado.

Construtor: escolher modalidade/estrutura, adicionar da biblioteca, ordenar, configurar dose e descanso conforme o tipo, agendar e revisar. Oferecer importação/plano próprio como percurso distinto. Ao modificar programa original, identificar versão personalizada e quais parâmetros deixaram de ser os da fonte. Alternativa de exercício só conserva equivalência quando prevista e validada.

### F04 — Execução e aprendizagem do movimento (R02, R04–R06, R15)

**Rever:** treino em curso, série/edição, descanso, conclusão completa/parcial e instruções.

**Acrescentar variantes de execução:** força por séries/carga; caminhada/corrida por tempo/distância/intervalos; yoga/Pilates por sequência/posição/tempo; circuitos por rondas e trabalho/descanso; outras unidades definidas pelo conteúdo. Não usar a mesma planilha de repetições para todas as atividades.

Instrução: imagem/vídeo ou ilustração aprovada, posição inicial, execução em passos, dose, erros comuns, equipamentos e alternativas da fonte. Botões “Explicação simples” e “Ver detalhe técnico”; legenda, controles, texto alternativo e conteúdo suficiente sem reprodução de mídia. Demo decorativa não substitui instrução.

**Estados:** instrução sem mídia, mídia não disponível/offline, pausar/retomar, trocar/omitir exercício com contexto, interromper por desconforto, terminar incompleto, revisar realizado, salvar localmente/sincronizar. O percurso de desconforto não diagnostica nem cria treino de tratamento.

### F05 — Contextos de saúde e retorno (R06)

Conteúdo transversal, acessível pela configuração, ficha e ajuda. Evitar transformar a página inicial num portal de lesões.

Representar retorno após pausa e retorno após orientação/lesão/cirurgia separadamente. Exemplos de pesquisa abrangem ombro/pescoço, cotovelo/punho, quadril, tornozelo/pé, tendões, região abdominal/pélvica e outros contextos, além de joelho/coluna. Não criar programas clínicos fictícios para preencher o Figma.

Estados necessários: contexto informado; conteúdo educativo adequado encontrado; apenas plano próprio/orientado disponível; cobertura indisponível; referência externa com origem; edição/remoção de informação sensível. Critérios de procurar ajuda e sinais clínicos só entram com fonte/revisão específica. Os textos finais dependem da etapa 01.

### F06 — Alimentação planeada e consumida (R07–R10, R16)

**Rever:** Diário/Alimentação, pesquisa, detalhe, porções, registro manual e refeições da v0.4.

**Acrescentar:** entrada “aprender / planear / registar”; agenda alimentar; criação/customização de plano/rotina; escolha de modelos humanos elegíveis; composição de refeição; receita própria; substituição de ingrediente; revisão do objetivo e comparação planeado/consumido. Não prometer dieta individual aprovada quando existir apenas uma soma de nutrientes.

Detalhe de alimento: nome, genérico/produto, marca quando houver, preparo, base de quantidade, unidade/porção, ingredientes/alergénios quando disponíveis, origem e nutrientes. Mostrar quantidade com vírgula decimal e unidade clara; tratar cru/cozido, parte consumida e rendimento de receita.

**Estados:** módulo adiado, sem meta, meta escolhida ou com método conhecido, plano incompleto, nenhum alimento adequado, informação ausente, produto desatualizado, ajuste manual, alimento recente/favorito, editar/remover/duplicar refeição com confirmação apropriada. A ausência de caloria/nutriente não deve aparecer como zero.

### F07 — Aprender a escolher e ler embalagens (R08, R15)

Criar sequência didática com embalagem ilustrativa própria/licenciada: localizar tabela nutricional; identificar 100 g/100 ml e porção; informar o que realmente consumiu; distinguir peso/preparo; localizar ingredientes e alergénios; ver uma conta simples.

Cada passo tem imagem/anotação, exemplo, texto curto e detalhe técnico expansível. Incluir exemplo com resultado conhecido para compreensão, não um teste clínico ou dieta prescrita. A lista de restrições pessoais não vira um selo universal de “pode comer”.

Levar ao mesmo conteúdo a partir de ajuda na quantidade, câmera/OCR, configuração e biblioteca. Voltar preserva a refeição em edição.

### F08 — Foto, código e reconhecimento assistido (R12, R13)

Criar escolha do que a pessoa pretende capturar, evitando um botão genérico que promete tudo.

| Entrada | Sequência visual esperada | O que precisa ficar explícito |
|---|---|---|
| Foto de alimento | Permissão → capturar/escolher → prévia → identificar candidatos → confirmar alimento/preparo/quantidade → revisar → guardar | Quantidade não demonstrada exige entrada/validação; ingredientes ocultos e alergénios não são certificados |
| Código de barras | Ler → consultar produto → detalhe/ausente → quantidade → revisão | Código identificado não garante produto na base ou rótulo atualizado |
| Rótulo | Foto → recorte legível → extração → rever valor/unidade/base → confirmar | OCR pode confundir casas decimais e 100 g com porção |
| Foto de atividade | Escolher foto de movimento/equipamento ou painel/resumo → identificar/extrair → rever → preencher o que falta | Foto isolada não comprova duração, séries realizadas ou gasto |
| Foto como lembrança | Capturar → prévia → anexar privadamente | Continua disponível sem ser apresentada como reconhecimento |

Mostrar análise em curso na região pertinente, baixa confiança/candidatos, resultado errado, “não reconheceu”, recusar envio, editar, cancelar, sem rede e recurso indisponível. Não inventar uma percentagem de confiança para o demo. Salvar sugestões só após confirmação; apagar foto sem necessariamente apagar o registro confirmado deve ter regra clara.

Sequência/vídeo é investigação possível para reconhecimento temporal, não função já aceita como implementada. Identificar no canvas os fluxos condicionados à viabilidade, fora da interface de produção.

### F09 — Atividade ao vivo, mapa e conexões (R02, R11)

**Rever:** Atividade manual e mapa ilustrativo. Acrescentar escolher modalidade → iniciar → sessão ao vivo → pausar/retomar → terminar → revisar → histórico.

Mapa deve representar percurso plausível com atribuição, localização, precisão/sinal e distinção entre mapa-base e percurso. Criar estados de GPS negado/fraco, sem tiles, offline, atividade indoor sem percurso, importação e treino interrompido. Um mapa no Figma não prova GPS real.

Conexões pelo Perfil: fontes disponíveis por plataforma, permissões por tipo, conectar/desconectar, sincronização, última atualização, dados indisponíveis e atividades duplicadas. Deixar claro o que veio do celular, relógio, outro app ou entrada manual. Não exigir dispositivo extra; não mostrar frequência cardíaca se nenhuma fonte a forneceu.

Distinguir dados capturados ao vivo de importação posterior. Projetar escolha de registro preferido quando duas fontes representam a mesma atividade, preservando o histórico e a possibilidade de correção.

### F10 — Hoje e Evolução como acompanhamento pessoal (R09, R14)

**Rever:** Hoje, semana, detalhes do dia, Evolução, histórico e medidas.

Hoje deve dar acesso rápido ao que está previsto, sessão em andamento, registo de refeição/atividade e um próximo passo útil. Mostrar realizado completo/parcial/não feito, descanso, futuro e dia sem registo sem confundir estados.

Evolução deve permitir escolher objetivo/período e ver tendências adequadas: continuidade, sessões/tempo/distância/força quando relevantes, alimentação registada, medidas e metas. Separar dados observados, declarados e estimados; mostrar ausência de dados e abrir detalhe/origem ao tocar numa métrica. Evitar coleção de gráficos decorativos ou meta de emagrecer imposta a todos.

Projetar relação atividade/alimentação sem “compensar comida” nem somar gasto basal e total duplicados. Nenhuma foto isolada produz “gordura perdida”. Incluir semanas mistas e dias sem rede, com resumo consistente com o histórico.

### F11 — Perfil, preferências e rotina (R04, R06, R11, R15, R16, R18)

**Rever a tela 07 · Perfil e todos os destinos**: dados pessoais/medidas, objetivos, conta/métodos de entrada, notificações, idioma/unidades, privacidade, ajuda e saída.

Acrescentar ou ampliar: experiência por modalidade, equipamentos/local, metas combinadas, agenda de treino/alimentação, linguagem simples/técnica, tutoriais, conexões, permissões de câmera/localização e preferências de captura. Campo alterado deve mostrar impacto futuro sem reescrever histórico.

Testar exportação/exclusão de dados e mídia, desconectar fonte, apagar informações opcionais e logout com sessão/rascunho pendente. Privacidade, termos e textos de cuidado ainda exigem revisão própria; telas demonstrativas não são parecer jurídico.

### F12 — Regras comuns, movimento e plataformas (R17)

Aplicar [experiência e movimento](../planejamento/decisoes-e-viabilidade.md#experiencia-e-figma): componentes editáveis, variantes, áreas seguras, contraste, leitor de tela, texto ampliado, teclado adequado por campo, foco e erro legível.

Carregamento por região: manter marca, navegação, layout e conteúdo disponível. Mostrar primeira carga, cache disponível, revalidação, envio local, conflito e falha. Trocar aba preserva seleção/scroll/rascunho; retomar sessão restaura dados essenciais. Figma demonstra estados, não garante persistência de processo.

Documentar gatilho, elemento, duração/easing propostos, destino e versão reduzida de cada animação. Ícones podem responder à seleção/conclusão; evitar movimento contínuo ou efeito que esconda informação. Não atrasar conclusão para exibir animação.

Construir variante iOS 26/Liquid Glass após estabilizar componentes comuns; contraste, transparência reduzida e sobreposição a mapa/fotos precisam de estados próprios. Android continua primeiro lançamento; não exigir terminar iOS para validar Android.

### Percursos obrigatórios no Play

1. Iniciante → ajuda → contexto → programa humano disponível → instrução → execução → histórico.
2. Experiente → montar/customizar → agenda → sessão parcial → retomar → concluir.
3. Casa com pouco equipamento → seleção compatível; combinação sem programa → limite/rever filtros.
4. Semana com força e caminhada/corrida → registar modalidades diferentes → resumo sem duplicados.
5. Alimentação adiada → configurar só alimentação → planear refeição → registar quantidade → editar.
6. Aprender rótulo → confirmar base/porção → voltar à refeição sem perder dados.
7. Foto/código/OCR → sugestão incorreta ou ausente → correção manual → confirmação.
8. Atividade por celular/fonte conectada → permissão negada ou duplicado → resolver → histórico.
9. Contexto de saúde sem cobertura → informação e limite claro, sem programa fictício de tratamento.
10. Dashboard por objetivo → detalhe/origem → ajuste de registo → resumo coerente.
11. Perfil → cada configuração/privacidade/conexão → guardar/cancelar → retorno correto.
12. Teclado, interrupção, erro/offline, texto ampliado e movimento reduzido nos percursos principais.

### Entrega e aceite da próxima intervenção visual

- Matriz `R → família F → tela/estado real → controle → destino/retorno → dados → exceção → evidência`, reaproveitando os inventários existentes.
- Setas legíveis no canvas e conexões de protótipo; ícones/CTAs sem destino corrigidos.
- Estados condicionais identificados para discussão, sem alegar integração real no Play.
- Conteúdo demonstrativo com fonte ou claramente fictício; nenhuma dose ou dieta clínica inventada para preencher layout.
- Capturas e validação dos percursos, descrição do que Figma simula e do que exigirá dispositivo/código.
- Comparação antes/depois preservando refinamentos manuais; aprovação da versão pelo autor antes de implementação.

Este registro descreve a especificação de 24/09/2026; a documentação atual de implementação e o backlog governam o estado posterior.
