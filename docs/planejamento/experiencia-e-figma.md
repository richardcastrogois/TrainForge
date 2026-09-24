# Experiência, protótipo e movimento

Base de 17/09/2026, alinhada em 24/09/2026. Escopo detalhado em [ajustes F01–F12](../design/ajustes-visao-integrada.md); nenhuma edição de Figma neste incremento. Especificação proposta para refinamento, não descrição de funções já implementadas.

## Como usar o Figma como referência de implementação

“Exatamente como no Figma” deve significar layout, componentes, conteúdo, estados, navegação e movimento aprovados. Para cada interação registrar: gatilho, estado inicial/final, destino, duração, curva, possibilidade de interrupção, comportamento de retorno e alternativa com movimento reduzido. A implementação será comparada também em vídeo e em dispositivo, não apenas por screenshot.

O Play simula percursos e estados; não comprova login real, escrita persistente, edição nativa de texto, reconhecimento de alimentos, GPS ou comportamento do sistema operacional. Cenários predefinidos devem ser identificados como demonstração nas anotações. Evitar inserir explicações de implementação nas telas destinadas ao utilizador.

## Revisão da base existente

A [auditoria v0.4](../design/fluxos-v04.md) é o ponto de partida. Revisar os 105 estados, retirando duplicações e agrupando variações em componentes quando adequado. Revisar hotspots sobrepostos antes de confiar na contagem de reações.

- Campos precisam mostrar foco, edição, preenchimento, validação e erro, não apenas abrir uma página de revisão com valores fixos.
- Preferências devem alternar independentemente. Idioma e unidades não podem mudar juntos sem ação explícita; cada notificação tem seu próprio estado.
- Voltar deve preservar o contexto; abandonar edição deve ter regra explícita. Uma seleção de alimento precisa refletir a porção e o total demonstrados.
- Todo botão de Perfil deve ter destino, retorno, estados e resultado; o mesmo vale para cards do dashboard e menus secundários.

## Matriz de cobertura a produzir

| Fluxo | Estados e telas a rever/criar se ausentes |
|---|---|
| Abertura e autenticação | Splash, login/cadastro, mostrar senha, validação local, envio, erro, conta já existente, verificação/reenvio, recuperação, cancelamento Google/Apple, rede ausente, sessão expirada |
| Configuração | Apresentação, benefício/finalidade dos campos, progresso, obrigatórios/opcionais, voltar preservando, adiar módulo, retomar parcialmente, resumo e editar |
| Hoje e planos | Sem plano, configuração incompleta, carregar com/sem cache, escolher/importar plano, fonte/licença/autoria, detalhes e versão do plano |
| Treino | Instrução, séries editáveis, descanso, pausa, concluir parcial/completo, sair com sessão ativa, retomada após interrupção, conflito/duplicação e histórico |
| Alimentação | Não configurado, configurar só alimentação, pesquisa, nenhum resultado, porção/unidade, foto, edição/exclusão, guardar localmente, falha de sincronização |
| Atividade | Manual ou GPS, permissão negada, GPS fraco, mapa indisponível, iniciar/pausar/retomar/finalizar, recuperação e detalhe da atividade |
| Dashboard | Primeiro uso sem dados, período, comparação coerente, dado desconhecido, detalhe da métrica, histórico fora do plano atual |
| Perfil e conta | Dados pessoais, objetivos, notificações independentes, idioma/unidades, privacidade, exportação, eliminar conta, suporte, logout e nova autenticação quando necessária |

Para cada linha, auditar acessibilidade, scroll, áreas seguras, teclado e modo sem rede. Evitar prometer recuperação de senha/conta que o backend ainda não suporta; registrar a dependência.

## Teclado e formulários

- Selecionar tipo de teclado por campo: e-mail, senha, numérico/decimal e texto. Aceitar vírgula decimal na apresentação portuguesa e normalizar os dados no contrato.
- Definir ordem de foco, Próximo/Concluir, visibilidade de senha, preenchimento automático e mensagens junto ao campo. Nunca apagar todo o formulário após erro.
- Ao abrir o teclado, manter campo e ação principal visíveis por scroll/reorganização; evitar botão encoberto e saltos de layout. Documentar se a barra inferior se oculta durante a edição.
- No Android, o primeiro Voltar com teclado aberto fecha o teclado; o fluxo de navegação deve respeitar o comportamento da plataforma. Tratar gestos e área segura no iOS.
- Alterações não guardadas: escolher salvamento de rascunho ou confirmação de saída por fluxo. Diferenciar rascunho, dado validado e dado sincronizado.
- Simular no Figma pelo menos teclado aberto, erro e conteúdo longo. Validar teclado real, autofill, leitores de tela e retorno do background na prova técnica.

## Carregamento e persistência percebida

Carregar só a região sem informação disponível. Layout, navegação, marca e controles estáveis não devem desaparecer a cada troca de aba. Com cache válido, mostrar conteúdo imediatamente; atualização em segundo plano pode usar indicador discreto sem bloquear a interação.

Usar skeleton com dimensões compatíveis na primeira carga; erro por seção quando possível; estado vazio apenas após resposta válida sem dados. Nunca confundir falha de rede com “não tem treinos”. Não manter um splash por duração artificial para exibir a marca. Os atrasos demonstrativos atuais não são requisito de produção.

Preservar aba, scroll, filtros, período e sessão ativa. Persistência após fechar o processo exige armazenamento local e sincronização, conforme [arquitetura](arquitetura-e-contratos.md); manter um widget vivo não resolve sozinho.

## Movimento proposto

Tempos abaixo são ponto de partida a validar, não exigências da Apple nem medições do app.

| Interação | Direção proposta | Alternativa acessível |
|---|---|---|
| Aba selecionada | Ícone cresce suavemente, indicador acompanha, legenda só no ativo; 150–220 ms | Troca direta ou fade breve, sem deslocamento |
| Navegar/voltar | Transição consistente com hierarquia e plataforma; 200–300 ms | Fade curto; preservar orientação |
| Modal ou folha inferior | Entrada/saída com fundo e foco coerentes; 200–300 ms | Sem movimento amplo; foco no título/primeiro controle |
| Guardar/concluir série | Feedback curto de estado, sem bloquear próximas ações | Texto/ícone de confirmação; não depender de cor |
| Skeleton | Sutil, sem flash, apenas enquanto necessário | Estático com indicação acessível de carregamento |
| Ícones e gráficos | Animar mudança de estado relevante; evitar movimento decorativo contínuo | Valores e estados finais imediatamente legíveis |

Definir curvas, cancelamento e comportamento de toques repetidos. Não acumular transições nem bloquear navegação para “terminar a animação”. Haptics são opcionais, discretos e complementares ao feedback visual.

## Variante Apple: iOS 26 / Liquid Glass

Manter conteúdo e fluxos compartilhados, criando variantes de navegação, barras, folhas e controles para iOS. Aplicar materiais translúcidos nas camadas de controle apropriadas; preservar superfícies legíveis para formulário, treino, alimentos e gráficos. Não transformar todos os cards em vidro.

Prever redução de transparência/movimento, contraste, texto ampliado, fundo variável e teclado. Criar amostras em fundo claro/escuro e sobre mapa. A prova técnica deve verificar o que o Flutter e a solução escolhida reproduzem de forma nativa ou aproximada, incluindo custo de renderização e manutenção. Suporte ao iOS 26 não significa que todo componente Flutter ganha Liquid Glass automaticamente.

Fontes: [orientação Apple](https://developer.apple.com/documentation/TechnologyOverviews/liquid-glass), [materiais](https://developer.apple.com/design/human-interface-guidelines/materials), [Flutter e iOS](https://docs.flutter.dev/platform-integration/ios/ios-latest). A variante Apple pode ser desenhada agora e implementada depois do lançamento Android.

## Mapa, foto e instruções de exercício

**Mapa:** diferenciar mapa-base, posição GPS, percurso gravado, cálculo de rota e geocodificação. São capacidades distintas. O Figma deve mostrar um mapa com atribuição, percurso fictício consistente, pausa, sinal fraco e indisponibilidade. GPS pode continuar a registar coordenadas mesmo quando o mapa não carrega, se isso fizer parte do escopo aprovado. Não prometer mapas offline sem licença e estratégia de armazenamento.

**Captura assistida:** reconhecimento de alimento e atividade por imagem faz parte da visão. Distinguir foto do prato, rótulo/OCR, código, foto de exercício/equipamento e imagem de painel/resumo. Mostrar permissão, captura/prévia, análise, candidatos, correção/confirmação, dados faltantes e alternativa manual. Identificação não comprova gramas/ingredientes ocultos nem duração/gasto. Fonte/modelo, custo, precisão, privacidade e provas permanecem pendentes; foto privada é alternativa, não substituição do requisito.

**Como fazer o exercício:** começar por instrução textual clara e imagem/ilustração licenciada quando disponível; incluir posição inicial, execução, equipamento e autoria. Vídeo pode ser complemento se houver direitos e viabilidade: legenda, controle de áudio, poster, reprodução sob demanda e fallback textual. Não carregar todos os vídeos na abertura nem reutilizar mídia pública sem licença. Não declarar que restrições clínicas foram atendidas apenas por um filtro de catálogo.

**Dashboard:** definir o significado de cada métrica antes do gráfico: sessões previstas/feitas/parciais, minutos, volume quando aplicável, distância e energia registrada/estimada. Exibir unidade e período; distinguir ausência de registro de zero. A contagem semanal e sequência precisam de regra para descanso, dia em curso e fuso horário. Não somar medidas de modalidades diferentes sem definição.

## Aceite visual

Um percurso está aprovado quando é compreensível sem explicação externa, não tem controles sem comportamento, cobre erro/retorno e preserva contexto. Guardar evidência em vídeo do Play e tabela de diferenças permitidas por plataforma. Na implementação, acrescentar evidência em dispositivo para teclado, GPS, câmara, movimento e persistência.
