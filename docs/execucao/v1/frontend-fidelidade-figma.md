# Frontend — prioridade explícita de23/10/2026

Pedido do autor: **ajustar todo o frontend para ficar exatamente igual ao Figma antes de continuar novas funcionalidades**. O checkpoint funcional anterior não era a implementação visual do protótipo. Este documento registra a mudança de prioridade e separa comportamento real de fidelidade visual.

## Fonte vigente conferida

Arquivo[TrainForge](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl), página **0:1 · 01 · Produto interativo · v0.5**, conferida pelo conectorFigma em23/10. Arquivos126:2 e141:2 são históricos; não substituir o desenho atual pelos geradoresv0.4.

[Inventário vivo derivado](frontend-figma-inventory.json):401quadros de primeiro nível,398comlargura390. Inclui variantes, rascunhos, estados de entrada e exemplos do protótipo; não significa398funcionalidades nem398rotas distintas. Reconciliar famílias/estados antes de implementar cada fluxo.

| Referência lida com design context e screenshot | Nó |
|---|---|
| [Entrar](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl?node-id=23-735) |23:735 |
| [Hoje](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl?node-id=25-1667) |25:1667 |
| [Alimentação](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl?node-id=25-1992) |25:1992 |
| [Porção](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl?node-id=104-1233) |104:1233 |

Sessão de leitura do conector iniciada; nenhum elemento doFigma foi alterado. Para retomar o mesmo trabalho, reutilizar a sessão be13df9a-20a4-47d5-ba30-e854be04613e enquanto válida, ou abrir nova sessão se expirada. Antes de get_design_context ler figma-design-to-code e incluir skillNames; screenshot acompanha a referência. Metadados sozinhos não bastam para implementação.

## Primeiro ajuste entregue no código

Tokens extraídos do nóEntrar: fundo#F6F6F1, superfíciebranca, texto#142F2C/secundário#64736E, primária#215E52, acento#D8EB90, alimentação#F5E3D5, superfíciesuave#E8EEE3. MarcaTF/texto, hierarquia, formas e espaçamento inicial aplicados em `lib/core/theme/trainforge_theme.dart`, entrada e cabeçalho deconta. Formulários usam otema central. Texto de erro permite múltiplas linhas.

**Fidelidade visual completa pendente.** O incremento visual01 abaixo atualiza o estado de fonte, navegação, entrada e perfil. Aplicar componentes não encerra todas as famílias nem seus estados.

## Execução a partir daqui

1. Consolidar fundamentos/componentes e o inventário de rotas/estados doFigma vigente; carregar contexto de cada família e assets realmente usados. Reutilizar componentesFlutter e conexões reais. Nenhum geradorv0.4 será reaplicado noFigma.
2. Implementar shell/navegação e Hoje conforme desenho, com perfil peloavatar e comportamento acessível. Preservar sessão, abas e rascunhos; não reativar chamadasFastify/geradores legados.
3. Alinhar entrada/conta/privacidade, biblioteca/catálogo e alimentação, usando os contratosGo existentes. Busca, seleção, quantidade, preparo, data/fuso, confirmação, histórico, revisão/exclusão e subtotais continuam reais.
4. Cobrir demais famílias do protótipo com seus estados reais de disponibilidade e componentes correspondentes. Identificar precisamente onde falta contrato/conteúdo antes de prometer interação persistida.
5. Conferir cada tela noAndroid em tamanho390e em320comtexto ampliado, mais comparações visuais contra os nósFigma correspondentes. Assets locais corretos, geometria/legibilidade/estados/voltar/cancelar/teclado e leitor de tela. iOS continua alvo do produto, sem alegar validação nativa inexistente.
6. Atualizar inventário/diagramas/Graphify/Swagger quando afetados; commits pequenos validados e push já autorizados. Emitir APKs incrementais. Não trocar uma tela validada por mera alegação de semelhança.

As histórias021/022/025 e demais histórias deUI permanecem rastreadas por dependências e critérios; a prioridade visual não transforma serviços ausentes em implementados.020 é a API funcional e consumo real já concluídos, com evidências próprias.

## Dados e lacunas

OFigma contém refeições, calorias, planos, doses, fotos e semanas demonstrativas. Oapp deve usar valores efetivos doGo e estados vazios/desconhecidos/indisponíveis quando faltarem dados ou conteúdo aprovado. Não copiar exemplos de1480kcal, treinos ou históricos. Não converter mídia decorativa em instrução aprovada.

Preservar idosos, cuidadores, casa, praça e academia. Sem inventar nutrientes, instruções, dose, adequação clínica, tradução alimentar ou associação entre métodos. Adaptar visualmente campos extras exigidos pela segurança/consentimento, documentando a diferença necessária.

Sem hospedagem/deploy/compra/contato. Gratuitasprimeiro e eventual compraúnicaatéR$400 continua decisão futura doautor. Meta de escala deve ser testada em sua etapa; aparência não comprova milhões simultâneos.

## Incremento visual01 — shell, entrada e perfil

Implementado em23/10, APKdebug0.1.6+9. FonteInter4.1 regular/negrito distribuída localmente comOFL e registro de licença noapp;22SVGs originais obtidos dos contextosFigma, sem edição de paths/dimensões. Proveniência eSHA256 em assets/fonts/manifest.json e assets/figma/manifest.json. Sem URLs temporárias noruntime.

- CabeçalhoTF/marca/avatar, margem24, Inter, cores e formas doFigma; barra inferior arredondada com os cinco destinosHoje/Planos/Atividade/Diário/Evolução. Ícones originais ativos/inativos com dimensões intrínsecas e slots22/28; navegação66px e áreas de toque≥48px em320.
- Shell novo usa somente os fluxosGo atuais; AppShell legado permanece fora da composição. Abas criadas sob demanda, estado preservado emIndexedStack; voltarAndroid retorna aHoje, teclado perde foco ao mudar deaba. Conta peloavatar; logout/erasure/troca deidentidade retiram rotas privadas e o estado antigo. Uma reconfirmação de rede não desmonta o shell.
- Hoje eDiário compartilham DailySummaryController injetável, com GET do resumo real por dia/fuso e guardas deconta/geração/dispose. Carregamento/erro/ausência distintos. Retorno dohistórico atualiza o resumo. Sem widgets/Dio nodomínio.
- Prévia deenergia mostra apenas um subtotal completo emkcal de um método compatível, com medidas/estimativas explícitas. Métodos múltiplos, dados desconhecidos, subtotal incompleto e erro não viram soma arbitrária ouzero. Origem/método/fração permanecem nodetalhe real.
- Planos consulta disponibilidade real docatálogo e leva à biblioteca existente, incluindo programas vazios quando aAPI informa0. Busca não reativa geradores. Configuração/planos/dispositivos/atividade/medidas ausentes abrem explicação de indisponibilidade, sem persistir fatos fictícios.
- Entrada usaGoogle real, inclusive criação noprimeiro acesso, marca/cabeçalho/card deconvite doFigma. E-mail/senha/Apple permanecem explicitamente indisponíveis, sem campos preenchidos deexemplo.
- Perfil segue composição25:2152 e usa nome/e-mail reais doGoogle. Exportação/exclusão emPrivacidade e confirmação/logout mantidos. Localidade, medidas epreferências não são inferidas.

Contextos adicionais lidos comscreenshots: Planos25:1778, Atividade25:1913, Evolução25:2068, Perfil25:2152 e estadoPlanos23:1110; navegações146:4938/5069/5224. Inventário atualizado por nó. NenhumFigma foi escrito.

Validação:68testesFlutter, analyze0issues. Casos novos cobrem todas as abas/ícones, alvos em320, texto2x, rascunho preservado ao mudar aba, voltarAndroid, recuperação offline sem perder aaba, exclusão retirando rotas privadas, mudança deconta/respostas tardias, virada dedia e regras deenergia. Prévias390x844 geradas e inspecionadas para entrada/Hoje/Planos/Atividade/Diário/Evolução/perfil e componente de navegação. Fixtures ficam somente nostestes, sem novos dados noDBentregue. Isso não é novo aceite humanoGoogle nem aceitação visual de todas as telas.

### Diferenças necessárias e trabalho ainda aberto

A identidade e composição inicial avançaram; **todo o front exatamente igual ainda não foi concluído**. Oinventário mantém flutterVisualAcceptance=pending para os quadros completos.

| Família | Estado atual e limite |
|---|---|
| Navegação/cabeçalho/tokens | Componentes implementados e comparação visual inicial; sistema/status/gestos nativos, sem desenhar relógio fictício |
| Hoje | Estrutura inicial e resumo real; fotografia, treino deexemplo, semana e minutos demonstrativos não copiados |
| Planos | Estrutura e biblioteca real; filtros visuais deambiente/catálogo/detalhe ainda aalinhar. Sem fotos ou prática semdireitos |
| Atividade/Evolução | Composição inicial com lacunas; semmapa/percurso/gráfico/métricas fictícias. Contratos funcionais continuam ausentes |
| Diário | Visão inicial com resumo real e acesso aohistórico; formulários/quantidade/detalhe/revisões/subtotais existentes ainda exigem conversão visual pelos nós próprios |
| Entrada/perfil | Layout inicial e ações reais; canais ausentes explicitados. Preferências/objetivos/localidade ainda não persistidos |
| Privacidade/biblioteca e demais famílias | Comportamento existente preservado; conversão visual/estados e aceite integrado pendentes |

Próxima fatia: biblioteca e alimentação, buscando os contextos vigentes e mantendo fonte, idioma original, base/unidade, quantidade explícita, estimativa/medida, preparo, data/fuso, idempotência, revisão e cancelamento. Não iniciar histórias novas debackend para contornar esta prioridade.

## Composição Flutter vigente — incremento visual01

```mermaid
flowchart TD
  Gate["AuthGate: identidade e sessão"] --> Entry["Entrada Google real"]
  Gate --> Shell["ProductShell: estado por conta"]
  Shell --> Today["Hoje"]
  Shell --> Plans["Planos: consulta e lacunas"]
  Shell --> Activity["Atividade: indisponibilidade explícita"]
  Shell --> Diary["Diário"]
  Shell --> Evolution["Evolução: indisponibilidade explícita"]
  Shell --> Account["Perfil pelo avatar"]
  Today --> Summary["DailySummaryController compartilhado"]
  Diary --> Summary
  Summary --> NutritionAPI["Go: GET food-summary por conta/dia/fuso"]
  Plans --> Catalog["Catálogo e atribuições reais"]
  Diary --> Nutrition["Histórico e formulários reais"]
  Account --> Privacy["Privacidade: exportar e excluir"]
  Account --> Session["Reconfirmar e sair"]
  Gate --> Guard["Troca/erasure: retirar rotas privadas e descartar estado"]
```

UI nova usa os contratosGo existentes; nenhum endpoint novo nesta fatia. Swagger permanece Go0.5.1/25operações. Atividade, sensores, planos e metas não foram implementados por haver navegação. Diagramas são derivados da composição real e não comprovam aceite visual ou capacidade de carga.

## Incremento visual02 — busca alimentar e porção

APKdebug0.1.7+10. Resultados da pesquisa104:1211 e porção104:1233 foram convertidos com os contextos/screenhots já lidos: cabeçalho/marca/voltar, margem24, Inter, cartões22px, cores dafonte, entrada dequantidade emacento e origem/preparo emsuperfíciebranca. Busca/paginação/filtros continuam usandoGo real e versão/licença/idioma/base originais. Não foram criados favoritos ou resultados fictícios.

Quantidade permanece vazia até entrada explícita. Unidade g/ml, medida/estimativa, preparo, data/fuso, validações e confirmação continuam reais. Campos extras de segurança permanecem apesar de não aparecerem noexemplo compacto doFigma. O cálculo da porção é confirmado pelaAPI; não foi reproduzido o exemplo170g/104kcal/macros. TecladoAndroid nativo, sem desenhar ou controlar um teclado fictício doprotótipo156:14612.

Oformulário mantém todos os campos montados ao rolar, inclusive com teclado/texto2x, para validar campos fora daárea visível e preservar seuestado. Busca vazia/erro usa seção de altura natural para manter a ação de recuperação alcançável. Testes exigem quantidade/evidência, corpo/chave congelados após resposta incerta e umúnico envio emtoque duplo.

70testesFlutter/analyze0issues, incluindo320x568/texto2x/teclado240px e preservação daquantidade ao rolar. Prévias390x844 de busca/porção inspecionadas com fixtures isoladas, sem escrever noDBentregue. [Recibo](frontend-food-verification.json). Sem novaAPI/migration; Swagger permanece25operações/Go0.5.1.

### Limite externo de referência

Em23/10 oconectorFigma retornou limite do planoStarter para get_design_context de **104:1260 · cadastro manual**. Contextos de104:1211 e156:14612 da mesma rodada foram recebidos; o104:1233 já estava disponível. Não repetir chamadas, comprar plano, contornar quota ou implementar famílias sem contexto suficiente. Ocadastro próprio funcional permanece acessível noapp; sua conversão visual, detalhes/histórico/privacidade/biblioteca e demais famílias seguem pendentes de referências suficientes e conferência. Oautor pode continuar avaliando os incrementos locais; esta pendência não exige hospedagem nem recriarOAuth.

Não afirmar que todo o front está exatamente igual ou encerrar022/025 devido a estes componentes. Continuar primeiro pelas referências já obtidas; obter os contextos faltantes quando oacesso voltar ou oautor fornecer as referências, sem pesquisa ampla deAPIs.

## Etapa atual — pontos01–06

Pedido posterior doautor: encerrar identidade nativa, abertura, Hoje, loaders, transições e dark antes dospontos07–12. [Plano/evidências](frontend-etapa-01-06.md). APK0.2.0+11 reúne a implementação técnica desses seis pontos; oautor confirmou marcaTF atual naabertura e dark derivado dessaidentidade. Pontos01–06 concluídos no checkpointAndroid conforme a direção aprovada; seus contextos Figma nãoobtidos não foram tratados como comparação exata. Nenhuma nova função backend ou prática foi liberada.

Aparência claro/escuro/sistema agora persiste somente noaparelho e independe daconta; isso substitui a lacuna de aparência registrada nos snapshots anteriores, sem concluir demaispreferências/objetivos/localidade. Hoje mostra semana/data reais abrindo diário por data; nenhum treino demonstrativo. Componentes de carregamento e movimento respeitam texto ampliado/redução de movimento; saída deconta não mantém tela privada antiga emtransição.

```mermaid
flowchart TD
  Native["Ícone e splash TF nativos"] --> Appearance["Aparência local: sistema / claro / escuro"]
  Appearance --> Restore["Restauração de sessão limitada e recuperável"]
  Restore --> Entry["Entrada e retentativa"]
  Restore --> Shell["ProductShell por identidade"]
  Shell --> Today["Hoje: data, semana e estados reais"]
  Today --> Day["Diário alimentar na data escolhida"]
  Today --> Summary["Go: resumo real sem total inventado"]
  Shell --> Profile["Perfil / Aparência"]
  Profile --> Appearance
  Motion["Movimento reduzido, sem reter conteúdo privado antigo"] --> Shell
  Loaders["Carga / erro / vazio / parcial / envio"] --> Today
```

Swagger permaneceGo0.5.1/25operações. Recursos/códigoiOS estão preparados; execuçãoXcode continua pendente e não impede ocheckpointAndroid. Nenhum teste de carga comprova milhões simultâneos nestaetapa.


## Ajuste24/10 — direção dark escolhida e rolagem

Autor rejeitou as cores do primeirodark e escolheu a terceira proposta, Grafite e lima. A implementação usa fundo#111211, cartões#242823 (separação reforçada) e destaque#D8EB90. Tons antes coloridos ficam neutros nodark, navegação selecionada emlima;70–20–10 orienta a composição sem alegar medição exata. Android remove somente a decoração deesticar, preservando física/notificações/atualizar; iOS padrão porplataforma. [Implementação/evidências](frontend-dark-scroll.md), APK0.2.1+12. Não é novo contextoFigma nem validação nativa iOS27; claros/ícones/fontes e dados reais preservados.


## Checkpoint24/10 — pontos07–12

[Implementação e gates por ponto](frontend-etapa-07-12.md), [recibo](frontend-stage07-12-verification.json). APK0.3.0+13/101testesFlutter/analyze0issues: biblioteca/detalhe, composição/cadastro/histórico/subtotais/confirmação/correções, privacidade e ajuda refinados com primitives/tokens já conferidos. Formulários com rascunho/envio/resposta incerta protegidos; busca particular com estado independente.

Famílias sem design context integral continuam sem aceite exato: reaproveitar componentes não supre a referência. Configuração persistida, treino/atividade e demais capacidades ausentes continuam pendentes; guias de disponibilidade não as implementam.20prévias de fixtures claras/escuras inspecionadas, sem dados fictícios no runtime nem novo consumo humano.
