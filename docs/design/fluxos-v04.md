# TrainForge — revisão de destinos e protótipo v0.4

**Próxima revisão especificada em 24/09/2026:** [ajustes da visão integrada F01–F12](ajustes-visao-integrada.md). Este documento mantém evidência do que foi aplicado em 17/09; não afirma que a v0.4 já cobre a visão integral, que foi reinspecionada hoje ou que seus formulários são funcionais.


Incremento aplicado no **Figma Desktop**, em 17/09/2026. Não houve alteração de Flutter, API, banco ou publicação no GitHub.

Arquivo: [TrainForge](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl), página `01 · Proposta mobile`. O título do arquivo ainda contém v0.1; o conteúdo foi ampliado para v0.4.

## O que foi aplicado

As 33 telas anteriores foram preservadas. Foram acrescentados 63 destinos/estados e nove páginas de revisão de formulários: **105 telas/estados**, além dos dois mapas. A auditoria do arquivo contou **372 reações de navegação**, sem destinos inexistentes. Esse total inclui reações antigas preservadas sob áreas de clique atualizadas; não equivale a 372 ações distintas do produto.

| Área | Lacuna encontrada | Destinos acrescentados |
| --- | --- | --- |
| Perfil | Botões sem destino; editar perfil abria dados do treino | Dados pessoais, edição de perfil, imagem, nome, conta, e-mail, métodos de entrada, palavra-passe e medidas |
| Preferências | Opções ausentes | Objetivos por área, notificações e estados de exemplo, idioma e unidades |
| Privacidade | Ausência de telas e confirmações | Resumo provisório, exportação simulada, apagar opcionais, eliminar conta, sucesso e cancelamento |
| Ajuda | Botão sem destino | Perguntas frequentes, feedback, pré-visualização e confirmação simulada |
| Sessão | Saída direta; sem confirmação | Confirmar terminar sessão e cancelar |
| Planos | Cartão abria diretamente o treino | Pesquisa, filtros, vazio, detalhe, origem, exercícios, guardar e registar plano próprio |
| Treino | Instruções, séries e conclusão incompletas | Instruções, registo/edição de série, descanso ilustrativo, conclusão e treino incompleto |
| Atividade | Registar sem destino | Formulário manual ilustrativo, edição e confirmação |
| Alimentação | Adicionar/consultar sem destinos | Pesquisa, resultados, porção/nutrientes, registo manual, confirmação e detalhes de pequeno-almoço/almoço |
| Evolução | Histórico sem destino | Histórico de sessões/atividades e medidas |
| Acesso | Reenvio sem feedback, recuperação incompleta | Reenvio simulado, nova palavra-passe, termos e proposta de privacidade |
| Hoje | Semana sem detalhe | Detalhe de dia e acesso à sessão incompleta |

## Campos e comportamento

Foram catalogados **28 campos/escolhas nos nove formulários originais**: entrar, criar conta, recuperação, três etapas de treino, duas de alimentação e rotina. Inventário exato: `v04-input-audit.json`. Cada campo abre a revisão de exemplos correspondente ao formulário. Campos adicionais das novas telas constam em `v04-spec.json`.

O protótipo demonstra **navegação e estados**, não edição livre. Os exemplos não persistem alterações, não autenticam, não enviam e-mail/feedback, não exportam nem apagam dados. As opções de notificações e idioma mostram cenários predefinidos, não uma combinação independente de todas as preferências. O temporizador, o mapa, os valores nutricionais e os planos são ilustrativos.

Essas limitações são diferentes de um botão sem destino: os destinos foram criados, mas a lógica real continua por implementar. Não considerar esta entrega um aplicativo funcional ou a aprovação final de conteúdo jurídico, clínico ou nutricional.

## Como rever no Figma Desktop

1. Abrir a página `01 · Proposta mobile`.
2. Selecionar `07 · Perfil` e usar **Shift + Espaço** para a pré-visualização no Desktop, ou Apresentar.
3. No Play, usar os pontos de início `TrainForge · início`, `TrainForge · perfil` ou `TrainForge · rotas v0.4`.
4. No editor, selecionar um botão no separador **Protótipo** para ver a seta nativa ao destino.
5. O mapa `00 · Destinos e percursos v0.4`, à direita, oferece cartões navegáveis por área. As setas do mapa resumem os percursos; as reações dos botões são a fonte exata da navegação.

Os carregamentos mantêm a estrutura e demonstram apenas a chegada dos dados. Foram conectados ao início dos percursos; os regressos não precisam repetir todas as telas de carregamento.

## Evidência de validação

Auditoria executada dentro do arquivo real pelo Scripter: 105 telas, 372 rotas, zero destinos inexistentes e zero textos fora dos limites dos quadros novos. Não é uma inspeção pixel a pixel nem validação da lógica de negócio.

Última execução após conectar os carregamentos: `TELAS 105 / ROTAS 372 / QUEBRADAS 0 / SEM ACESSO 0 / OVERFLOW 0`. Todas as telas têm um percurso no grafo a partir da abertura. Mapa v0.4: [abrir no Figma](https://www.figma.com/design/bX6YjBBLIJgoo2MtiFLntl?node-id=104-1974). O rodapé do Perfil agora indica v0.4.

Percursos clicados e observados no Play do Desktop:

- Perfil → Dados pessoais → Conta e acesso → Dados pessoais → Perfil.
- Perfil → Notificações → estado ativado → Perfil.
- Perfil → Privacidade → Eliminar conta → Cancelar → Privacidade → Perfil.
- Perfil → Hoje → carregamento de Planos → Planos → Detalhe → Treino.
- Treino → Terminar → Incompleto → Histórico → Evolução.
- Evolução → Diário → Adicionar alimento → Porção/nutrientes → Alimento adicionado.

As demais ligações foram verificadas estruturalmente; não foi clicada individualmente cada uma das 372 reações.

## Retomada e scripts

- `build_v04.py` gera o catálogo e o script; não altera o Figma sozinho.
- `v04-template.js` / `v04.scripter.js`: criação dos novos quadros e ligações. **Não reaplicar integralmente sem comparar alterações manuais:** ele recria o conteúdo dos quadros marcados como v0.4.
- `v04-loading-fix.scripter.js`: liga os estados de carregamento aos percursos existentes.
- `v04-validate.scripter.js`: verifica destinos, alcance a partir da abertura, limites de textos e pontos de início. Atualiza o relatório em pluginData e a indicação de versão no Perfil.

Não voltar a executar `finish_figma.scripter.js` da v0.3 sobre o arquivo atual: ele contém rotas antigas.

Graphify foi consultado no início e atualizado incrementalmente no encerramento: **0 alterados, 42 inalterados, 0 excluídos** no corpus `lib/`. A documentação de design não faz parte desse corpus; este arquivo e os catálogos são a entrada para retomar o Figma sem reler o código.

Próxima revisão de produto: validar estes destinos e o nível de detalhe das telas; depois aprofundar componentes de formulário, estados de erro/rede/offline, seleção independente de opções e regras reais antes de definir contratos e banco.
