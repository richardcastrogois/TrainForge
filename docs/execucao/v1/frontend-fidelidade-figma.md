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

**Ainda não é fidelidade visual concluída.** FonteInter não foi distribuída comoasset; plataforma mantém sua fonte. BotãoGoogle e textos foram adaptados à função real disponível; e-mail/Apple não foram simulados. Hoje, barra inferior, composição das telas e todos os estados ainda precisam da implementação conferida por família. Aplicar umtema não encerra022/025 nem o pedido doautor.

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
