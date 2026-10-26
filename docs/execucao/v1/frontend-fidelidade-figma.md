# Frontend — referências, estado e checkpoints

## Localização em 26/10 — interface e cliente integrados, V1-048 aberta

493 mensagens por idioma em pt-BR, pt-PT, inglês e espanhol, incluindo os fluxos disponíveis de consulta, escrita alimentar, histórico, privacidade e ajuda. Cliente integrado a Go 0.6.1: nomes revisados por localidade exata, identidade e versão; original e fonte acessíveis, fallback explícito. Troca de idioma preserva busca digitada e descarta respostas antigas; mudança da revisão reinicia a paginação sem misturar resultados. Nenhum nome real revisado foi publicado.

164 testes Flutter aprovados e análise sem problemas; quatro idiomas em 320 px com texto a 200%, incluindo seleção com ID/versão originais. [Recibo](frontend-food-names-verification.json). APK debug 0.3.3+16 preparado e assinado, ainda não instalado: não há dispositivo ADB conectado. [Checkpoint](android-food-names-checkpoint.json). Base local atualizada com autorização: schema 11 / 26 tabelas; conta, consumo e 6.369 versões preservados. Faltam publicação operacional humana, cobertura editorial e aceites nativos. Isso não comprova igualdade a nós Figma sem referência obtida.


Fonte única atualizada em **26/10/2026**. [Trilha por área](trilha-implementacao.md) orienta o próximo trabalho; [auditoria](auditoria-produto-2026-10-24.md) registra o baseline. Os antigos relatos 01–06, dark/rolagem e 07–12 foram consolidados aqui. O Git mantém os textos históricos completos; os recibos originais permanecem no repositório.

## Estado atual e limites

Q1 posterior:cuidador é o próprio praticante, sem vínculo com pessoa assistida como requisito; ambos os caminhos de treino e reconhecimento alimentar com revisão/quantidade informada fazem parte da versão desejada. Q2 confirmou visões por refeição/alimento e histórico visual, análise nutricional e dicas revisadas juntos na primeira versão (V1-045/046); após pesquisa, aprovou também recuperar imagens pela conta com cache no celular. Q3 confirmou configuração completa antes da busca, trocas compatíveis/dias/horários e retomada ou parcial (047/015/044/017/023). Q4 confirmou apagar foto com a refeição e registrar offline/sincronizar depois;026/042/045 ainda precisam de fila durável privada, estados e exclusão coordenada. Q5 confirmou configuração em etapas curtas/revisão final e nomes traduzidos quando revisados, com original/fonte nos detalhes e fallback original (047/048). Nenhuma dessas capacidades foi implementada por alterar o escopo.

Último APK instalado registrado: **debug 0.3.0+13**. Novo **0.3.3+16 preparado**, sem instalação; API Go **0.6.1 / 25 operações**. Marca TF/Inter e direção dark **Grafite e lima** aprovadas. Pontos 01–06 encerrados no checkpoint Android autorizado; pontos 07–12 têm acabamento dos fluxos disponíveis, sem conclusão integral.

Faltam configuração completa persistida (047), treino/agenda/execução com trocas compatíveis e retomada/parcial, contexto de pausa do cuidador, captura/reconhecimento por foto, refeições/itens e o conjunto histórico visual/análise/dicas revisadas, cobertura editorial e aceites da localização pt-BR/pt-PT/en/es e dos nomes revisados (048), além de validação nativa iOS. Melhorar o visual não preenche esses contratos. Não afirmar fidelidade exata sem referência suficiente ou tratar exemplos do Figma como dados do usuário.

| Ponto | Implementado | Falta para o aceite integral |
|---|---|---|
| 01 · Ícone e identidade | TF/Inter, nome, densidades Android, ícone adaptativo26+/monocromático33+, recursos iOS sem alfa | Execução nativa iOS e regressão quando a identidade mudar |
| 02 · Abertura e inicialização | Splash e primeiro frame coerentes, aparência antes da sessão, cold/warm start e recuperação offline | Comparação de abertura sem contexto faltante e aceite nativo iOS |
| 03 · Hoje | Datas/semana reais, diário por data, resumo Go por titular/dia/fuso e estados distintos | Resumo de treino/atividade quando contratos e dados forem entregues |
| 04 · Carregamentos | Loading/progresso/skeletons, ação ocupada e retentativa; redução de movimento | Cobrir os novos fluxos e conferir referências faltantes |
| 05 · Transições | Abas/rascunhos/voltar/foco, remoção de rotas privadas ao trocar identidade, rotas/modais e movimento reduzido | Aceite nativo iOS e regressão das futuras jornadas |
| 06 · Temas e rolagem | Claro/dark/sistema persistidos, Grafite e lima e Android sem esticar | Comparação nativa iOS; Flutter não incorpora automaticamente toda novidade do sistema |
| 07 · Entrada/configuração | Google real, progresso, bloqueio de ações concorrentes e guia de disponibilidade | Configuração persistida, contratos e decisão sobre canais adicionais de entrada |
| 08 · Biblioteca/treino | Busca/filtros/cursor/detalhe/versão/origem/retirada, com recuperação | Material humano/instrução/dose/mídia permitidos, adesão, agenda, sessão e comparação das famílias faltantes |
| 09 · Alimentação | Composição, cadastro particular, confirmação, histórico, revisão/exclusão, subtotais e proteção de formulário | Aceite humano do cadastro particular, melhorias da auditoria e recursos ainda não contratados |
| 10 · Atividade/evolução | Disponibilidade honesta e caminhos úteis | Registro/execução/histórico/medidas/objetivos reais; GPS/sensores/dispositivos/OCR quando aprovados |
| 11 · Perfil/privacidade | Identidade real, aparência, política da API, exportação/exclusão e ajuda | Edição persistida de campos aprovados, idioma/unidades, feedback e termos de distribuição |
| 12 · Acabamento | Teclado, rolagem, voltar/cancelar, foco no erro, escala2x/largura320 e alvos de toque em recortes | Jornadas completas, referências faltantes, acessibilidade humana e execução nativa iOS |

## Localização em andamento — V1-048

26/10:resumos das cinco áreas, filtros/detalhes da biblioteca e consulta alimentar localizados;282mensagens poridioma, datas/plurais e valores sem conversãofloat.132testes/analyze0issues,8prévias novas. [Recibo](frontend-localization-read-verification.json). Formulários/histórico/escrita,privacidade/guias e nomes revisados ainda faltam. Nenhum dado de fonte foi traduzido, nemAPI/SQL alterados. O código ainda não foi incorporado a novoAPK.


Fundação em25/10:recursos ARB e classes tipadas, quatro localidades selecionáveis, seguir aparelho e preferência local separada de credenciais. Entrada/perfil/aparência/navegação e seus feedbacks têm79mensagens por idioma. Calendários e controles podem usar os delegates oficiaisFlutter. [Recibo e limites](frontend-localization-verification.json); [APK0.3.1+14 preparado](android-localization-checkpoint.json), ainda não instalado.

Troca de idioma mantém conta/aba; recursos de data/hora/decimal foram testados sem converter os valores exatos da API emfloat.79mensagens traduzidas não são79% nem100% do app. Faltam outras famílias, plurais/formatos, nomes/aliases alimentares revisados e integração Go/SQL/cliente com versão/revisão e aceites próprios. A tela de idioma avisa que a tradução das demais telas continua em implementação. Fontes, nomes e preparos originais não são traduzidos automaticamente. iOS não executado nativamente.

Fonte técnica:[localizaçãoFlutter](https://docs.flutter.dev/ui/internationalization), conferida25/10; mantidos o framework, os tokens e os componentes vigentes, sem migração de sistema visual ou nova leituraFigma.8prévias locais deIdioma nos quatro idiomas/claro/dark; testes de320px/texto2x e119testes gerais aprovados, analyze0issues. APKinstalado anterior preservado porque inspeção não identificou raiz segura para atualizar.

## Referência Figma e decisões aprovadas

Arquivo [TrainForge](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl), página **0:1 · 01 · Produto interativo · v0.5**. Páginas126:2 e141:2 são arquivo. [Inventário por nó](frontend-figma-inventory.json):401quadros de primeiro nível/398comlargura390, incluindo variantes/estados/rascunhos; não são398funcionalidades. Não reaplicar geradoresv0.4.

Contextos e screenshots obtidos incluem Entrar23:735, Hoje25:1667, Alimentação25:1992, Porção104:1233, Planos25:1778/23:1110, Atividade25:1913, Evolução25:2068, Perfil25:2152, navegações146:4938/5069/5224, busca104:1211 e teclado156:14612. Metadados de outros nós não contam como contexto completo.

Sessão anterior do conector:be13df9a-20a4-47d5-ba30-e854be04613e; reutilizar somente se ainda válida e no mesmo trabalho. Antes de get_design_context, ler a skill figma-design-to-code e cumprir as instruções do conector. Não consumir chamadas enquanto o limite de leitura estiver bloqueando.

**Decisões humanas:** autor aprovou marcaTF atual para abertura e dark derivado da identidade quando os quadros não estavam disponíveis; depois rejeitou o primeiro dark e escolheu Grafite e lima. Isso aprova essa direção, não uma comparação exata de quadros não lidos. Desejo de comportamento iOS atual continua sujeito à comparação nativa.

Não copiar refeições, kcal, doses, semanas, fotos, treino ou progresso demonstrativos do protótipo. Campos adicionais necessários para segurança, consentimento e dados reais permanecem; registrar a diferença visual necessária.

## Componentes e comportamento em execução

- Fonte Inter4.1 regular/negrito local comOFL e22SVGs originais; paths/dimensões preservados. Proveniência/hashes em [fontes](../../../assets/fonts/manifest.json), [assets Figma](../../../assets/figma/manifest.json) e [manifesto nativo](native-brand-manifest.json). Sem URLs temporárias no runtime.
- Primitives FigmaRouteFrame/FigmaPageHeading/FigmaSection, margem24 e seções22px nos fluxos existentes. CabeçalhoTF/avatar e navegação arredondada com cinco destinos, ícones22/28 e áreas de toque≥48px nos recortes testados. Estilo não torna acessível uma jornada ainda não avaliada.
- Composição25/10:lib/composition define fábricas lazy e escopo na raiz; telas ativas recebem repositories por contrato. Hoje/diário compartilham o mesmo repository privado por identidade. [Recibo](frontend-composition-verification.json):103testesFlutter/analyze0issues, incluindo duas jornadas integradas de injeção/troca de conta. APK0.3.0+13 preservado; sem nova comparaçãoFigma ou alteração visual. Segundo incremento encerrou021:estado de consulta/busca/paginação emNutritionController e configuraçãoAPP_ENV por ambiente;108testes/analyze0issues. [Critérios](frontend-state-verification.json). Formulários preservam campos/foco/validação/guardas locais; durabilidade026 e aceite025 não concluídos.
- ProductShell cria abas sob demanda emIndexedStack; AppShell legado não participa da composição. VoltarAndroid retorna aHoje; trocar aba retira foco do teclado. Mudança/logout/exclusão de identidade retira rotas privadas e estado antigo. Reconfirmação de rede preserva o shell.
- DailySummaryController injetado é compartilhado porHoje/Diário, com guardas de titular/geração/dispose. Atualiza por dia/fuso/virada de dia e retorno do histórico. Energia só aparece como subtotal único completo de método compatível; desconhecidos, métodos múltiplos e erro não viram soma arbitrária ouzero.
- Catálogo permite busca com debounce400ms, filtros cancelar/aplicar e paginação vinculada à consulta aplicada até a próxima pesquisa começar. Resultado atrasado não altera a consulta atual. Programas vazios continuam vazios, com origem/licença/requisitos/versão e retirada.
- Busca particular tem geração/estado independentes:digitar não refaz histórico/subtotais; falha não esconde consumos confirmados. Consulta e paginação ficam vinculadas à conta atual.
- Formulários mantêm campos montados ao rolar para validar inclusive nutriente fora da tela; rolagem alcança o primeiro erro. Voltar pede confirmação de descarte; cancelar preserva rascunho. Envio bloqueia saída; resposta incerta preserva corpo/chave e explica que sair não cancela a solicitação. Rascunhos ainda são apenas memória, como registrado na auditoria.
- Quantidade começa vazia; g/ml, medida/estimativa, preparo, data/hora e fuso são explícitos. API confirma cálculo/base/célula/fator/fração e preserva revisões. Não reproduzir números de exemplo nem recalcular com lógica divergente noFlutter.
- Perfil separa identidade/configuração/aparência/privacidade/ajuda. Configuração indisponível não coleta dados fictícios. Privacidade usa política efetiva, exportação paginada e exclusão reautenticada/com frase exata; nova solicitação limpa confirmação antiga. Ajuda não anuncia feedback/termos de distribuição como implementados.

## Inicialização e identidade nativa

Não há atraso mínimo, porcentagem inventada ou timeout para o consentimento humanoGoogle. Leitura de aparência limitada a2s com fallback para sistema; restauração de sessão limitada a30s com retentativa e credenciais preservadas quando a rede falha.

Aparência guarda somente system/light/dark no aparelho:Android trainforge_appearance/mode; iOS trainforge.appearance.mode. Fica separada das credenciais e dos registros do titular. Ícones/splash nativos e43PNGs têm hashes/dimensões no manifesto; iOS RGB sem alfa. Reproduzir com tools/gerar_identidade_nativa.py somente se houver motivo, conferindo antes de usar --write.

Código/recursos iOS foram preparados estruturalmente; build/execução/aceite dependem de macOS/Xcode. Referências da implementação:[engine implícitoFlutter](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate) e [splashAndroid](https://docs.flutter.dev/platform-integration/android/splash-screen).

## Grafite e lima e física de rolagem

| Papel | Valor aprovado |
|---|---|
| Fundo | #111211 |
| Superfície | #242823, mais separada que a prévia#1D1F1D |
| Destaque/seleção | #D8EB90 |
| Texto sobre destaque | #263015 |
| Texto principal/secundário | #F4F6EF / #BFC7BA |

Fundo, superfície e destaque são três papéis de cor; neutros também contam. No dark, cartões antes coloridos usam superfícies neutras; navegação selecionada usa lima e ícone escuro. Modo claro e identidade nativa foram preservados. 70–20–10 foi usado como orientação de predominância/separação/destaque, não medição de pixels ou regra universal de grandes marcas; cores semânticas de erro/aviso continuam necessárias.

TrainForgeScrollBehavior remove a decoração StretchingOverscrollIndicator noAndroid, preservando física, inércia, notificações e gesto de atualizar, inclusive emlista curta. iOS mantém BouncingScrollPhysics padrãoFlutter. Não instalar GSAP/Motion ou alterar ajustes globais do emulador para esse comportamento.

**iOS27 não foi executado nesta máquinaWindows.** Teste dewidget não comprova bordas/barras/gestos da versão nativa. Referências já pesquisadas:[Fluent](https://fluent2.microsoft.design/color), [overscrollFlutter](https://api.flutter.dev/flutter/material/MaterialScrollBehavior/buildOverscrollIndicator.html), [física por plataforma](https://api.flutter.dev/flutter/widgets/ScrollBehavior/getScrollPhysics.html) e [arquiteturaFlutter](https://docs.flutter.dev/resources/architectural-overview). Sem nova pesquisa nessa consolidação.

## Evidências históricas preservadas

| Checkpoint | Validação no seu escopo | Recibo |
|---|---|---|
| Visual01 / APK0.1.6+9 | 68testesFlutter/analyze0issues; shell/conta/Hoje, resumo e isolamento de estado | [Shell](frontend-shell-verification.json) |
| Visual02 / APK0.1.7+10 | 70testesFlutter/analyze0issues; busca/quantidade/teclado, sem consumo inventado | [Alimentação](frontend-food-verification.json) |
| Pontos01–06 / APK0.2.0+11 | 85testesFlutter/analyze0issues;76Python incluindo5nativos;15prévias de fixtures | [Etapa01](frontend-stage01-verification.json) |
| Grafite/rolagem / APK0.2.1+12 | 90testesFlutter/analyze0issues;5novos cenários Android/iOS porwidget | [Dark/scroll](frontend-dark-scroll-verification.json) |
| Pontos07–12 / APK0.3.0+13 | 101testesFlutter/analyze0issues;76Python;20prévias de fixtures | [Etapa07–12](frontend-stage07-12-verification.json) |

Os recortes cobriram escala2x em320, teclado, contraste≥4.5 dos tokens relevantes, rótulos/foco, redução de movimento, erros/vazio/offline, abas/rascunhos, troca de conta/respostas tardias, envio incerto e cancelamento de exclusão semDELETE. Não é homologação global de acessibilidade, nativo iOS ou aceite humano de todas as funções.

Observação histórica única de cold start debug:6035ms via am-start-W noemulador, sem valor de benchmark release/fps/capacidade. Android conferiu modos de aparência/reabertura/offline e recuperação de navegação; builds preservaram assinaturaOAuthdebug e dados reais. Agente não digitou quantidade nem criou consumo/alimento próprio para simular a jornada. Google/SQL/import/restore históricos não foram repetidos nessa sequência visual.

Graphify final dos07–12:83Dart/1235nós/1665arestas, AST somente/HTML exportado. Isso não prova relações SQL/Go ou comportamento nativo. [Artefato atual](android-frontend-checkpoint.json) contém assinatura/hash e fingerprint da fonte; não reconstruirAPK por alteração documental.

## Referências faltantes e próximo trabalho

Erro registrado em get_design_context:limiteStarter para104:1260. Também faltam contextos integrais de104:230/260(privacidade),23:910/1021/1080(configuração) e104:704/780/810(atividade/histórico). [Trilha](trilha-implementacao.md) explica plano/cota conferidos, limitações e alternativas permitidas. Não comprar plano nem contornar limite.

Próxima implementação segue os blocos/dependências da trilha, depois das decisões que alteram o produto. Melhorias conhecidas incluem validação de nutrientes duplicados, mensagens humanas, durabilidade de envio e localização. Não reativar geradoresFastify/Gemini como fallback. V1-021 encerrada no recorte de fundação;022/025 continuam abertas e048 é a próxima pelas dependências.

Idosos, cuidadores, casa, praça e academia permanecem na cobertura. Sem novaAPI/migration/conteúdo, deploy, compra ou hospedagem por esta consolidação. Aparência não comprova milhões simultâneos.
