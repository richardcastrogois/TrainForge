# Frontend — etapa 01 a 06

Pedido de 23/10: implementar os seis primeiros pontos antes dos pontos 07–12 e de novas funcionalidades. O APK debug **0.2.0+11** contém a implementação técnica dos seis pontos e está instalado no emulador, com conta e consumo reais preservados.

**Os seis pontos estão concluídos no checkpoint Android desta etapa.** O autor confirmou em23/10 a abertura com a marcaTF atual e o dark derivado dessa identidade. Essa decisão aprova a adaptação preparada; não significa comparação exata com quadros Figma não obtidos. Build/execução iOS continuam pendentes na plataforma própria.

| Ponto | Implementação e validação | Fechamento |
|---|---|---|
| 01 · Ícone e identidade | Nome TrainForge, TF/Inter, densidades Android, adaptativo26+, monocromático33+, ícones iOS sem alfa; hashes/dimensões/proveniência e APK conferidos | Checkpoint Android concluído; recursos iOS preparados |
| 02 · Abertura e inicialização | Splash nativo e primeiro frame na mesma marca; aparência antes da sessão; restauração limitada e recuperável; cold/warm start e offline/retentativa sem novo login | Checkpoint Android concluído; direção visual TF aprovada |
| 03 · Hoje | Datas e semana reais; calendário abre diário alimentar por data; resumo Go por titular/dia/fuso; loading/erro/vazio/parcial/sucesso e virada de dia | Checkpoint Android concluído, com lacunas reais explícitas |
| 04 · Loaders | AppLoading/AppProgress/skeletons, ações ocupadas e recuperação nos fluxos ativos; sem porcentagem fictícia; movimento reduzido sem loop animado | Checkpoint dos fluxos ativos concluído |
| 05 · Transições | Entrada sem manter conteúdo privado antigo; abas com estado/foco/voltar preservados; rotas/modais/diálogo; redução de movimento inclusive na troca de tema | Checkpoint Android concluído; gesto iOS mantido no código |
| 06 · Dark | Claro/escuro/sistema; preferência nativa separada da conta; cores semânticas, SVGs, controles e barras; contraste e reabertura conferidos | Checkpoint Android concluído; direção dark aprovada |

## Referências e decisão visual

O Figma v0.5 e os contextos/tokens/componentes já obtidos continuam sendo a base. A marca TF/Inter é a mesma usada no incremento anterior. Nenhuma foto, treino ou novo logo criativo foi inventado.

O conector atingiu a quota Starter. Os contextos completos de 23:765/23:774 (Abertura A/B), carregamentos e uma variante dark completa não foram obtidos. Abertura e dark foram preparados a partir da identidade atual; skeletons derivam da composição Hoje já lida. O autor respondeu à pergunta e escolheu usar a marca TF atual na abertura e criar o dark a partir dessa identidade. A implementação corresponde a essa direção. Não comprar plano nem contornar a quota. As prévias usam fixtures isoladas. O fechamento desta etapa não encerra os pontos07–12 nem significa fidelidade exata de todos os quadros.

## Comportamento real

- Abertura sem atraso mínimo ou progresso inventado. Leitura da aparência limitada a 2s com fallback para sistema; restauração da sessão limitada a 30s, com retentativa e credenciais preservadas quando a rede falha. Login Google consentido não recebeu limite de interação.
- Hoje mostra data/semana reais. O calendário abre o diário alimentar por data; não marca treino como concluído. Não há foto, programa, dose, histórico ou minutos demonstrativos. Energia aparece somente com subtotal único completo de um método da fonte; ausência/incompletude não vira zero.
- Aparência guarda somente system/light/dark no aparelho: Android trainforge_appearance/mode; iOS trainforge.appearance.mode. Não guarda credencial, não altera dados da conta e não se torna dado editorial/pessoal exportável.
- SVGs originais preservados, sem editar paths/dimensões. Dark usa filtro de apresentação nos ícones necessários. Inter/OFL local, proveniência em native-brand-manifest.json. tools/gerar_identidade_nativa.py --write gera43PNGs; sem --write confere hashes/dimensões.
- Nenhum endpoint, migration, fonte, fornecedor ou consumo novo. Swagger permanece Go0.5.1/25operações. Idosos, cuidadores, casa, praça e academia continuam no escopo. Nenhuma prática liberada por aplicar o visual.

## Evidências

[Recibo integrado](frontend-stage01-verification.json) e [APK instalado](android-frontend-checkpoint.json).

- **85 testes Flutter passaram; flutter analyze sem issues.** Cobrem largura320/texto2x, teclado visível, contraste≥4.5 dos tokens de texto relevantes, rótulo acessível do avatar, redução de movimento, estado/rascunho/abas, sessão/troca de conta e estados/virada de dia de Hoje.
- **76 testes Python passaram**, incluindo5 de recursos nativos:43PNGs com SHA256/dimensões, iOS RGB sem alfa, adaptativo/monocromático, splash claro/escuro e pacote OAuth preservado. Documentação derivada regenerada/verificada.
- **15 prévias390x844 de fixtures isoladas inspecionadas.** Não são novo login Google nem aceite humano de consumo; capturas privadas não foram adicionadas ao Git.
- **Android real:** claro/escuro, seguir mudanças do sistema e restaurar configuração original, preferência/sessão após cold/warm start, recuperação offline sem novo Google, cinco áreas/voltar e calendário abrindo diário por data. SHA256 fonte/APK instalado conferido;1 consumo real preservado. Agente não digitou quantidade nem confirmou consumo.
- Observação única cold start debug via am-start-W: **6035ms** neste emulador. Não é benchmark release, garantia de tempo/fps ou evidência de milhões simultâneos.
- Dados preservados:1conta/1consumo/0alimentos próprios/6369referências alimentares/73metadados de movimento. Testes Google, SQL, importação e restore históricos não foram repetidos.
- Graphify:79Dart/1179nós/1573arestas,26alterados/53inalterados; AST somente, HTML exportado, sem extração semântica ou novo custo.

## Avaliar e retomar

No APK instalado: **avatar → Preferências → Aparência**. A entrada também oferece Aparência sem login. A avaliação terminou em Seguir o aparelho, preservando a configuração original do sistema. O calendário Hoje abre o diário na data escolhida.

Código e recursos iOS foram preparados/verificados estruturalmente; build/execução/aceite nativos continuam dependentes de macOS/Xcode. O canal acompanha a [inicialização do engine implícito do Flutter3.41](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate); Android12 usa o [splash nativo oficial](https://docs.flutter.dev/platform-integration/android/splash-screen). Não alegar validação iOS concluída.

Sem hospedagem, deploy, contratação, contato externo ou nova pesquisa de APIs. Pontos01–06 encerrados neste checkpointAndroid, conforme a direção visual aprovada. Próximos pontos07–12 e histórias021/022/025 inteiras continuam abertos; não avançar nesta rodada além do escopo pedido.
