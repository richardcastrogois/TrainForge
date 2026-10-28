# Trilha de implementação e encerramento por área

Atualizada em **28/10/2026**. Base histórica: [auditoria24/10](auditoria-produto-2026-10-24.md). Estado atual: APK debug0.4.2+24 instalado;0.4.3+25 preparado, não instalado; API0.8.0/34operações; schema13/30tabelas. [backlog.json](backlog.json) governa estados/dependências e [handoff](handoff.md) a próxima ação.

Este é o roteiro humano principal para acompanhar o que existe, o que falta e quando encerrar.021 foi encerrada no recorte de fundação. **048concluída**:495mensagens/idioma,197testes/analyze0, nomes revisados na biblioteca/histórico/detalhe/correção sem mudar cálculo ou mutações, operação editorial e cobertura0/6369 explícita. [Fechamento](localization-048-fechamento.json). Idioma padrão segue o aparelho, com substituição opcional em configurações e recuperação de resposta tardia sem gravar padrão.

**047encerrada no recorte funcional local**: criação/revisão/confirmacão humanas, edição posterior expressamente autorizada e recuperação da revisão2 conferidas. R1/data, demais campos e hashes deconta/consumo/catálogo preservados; semterceiraversão. [Fechamento por critério](training-configuration-047-fechamento.json), [evidência real](training-configuration-human-verification.json). UXfuso/hora/navegação continua pendente para depois dos testes, conforme pedido; isso não é aceite de usabilidade integral. Próxima015pelasdependências; zero conteúdo aprovado mantém o gate de prática.

**045doing — 28/10:** [persistência e contrato HTTP](refeicoes-045.md), Flutter e leitura Android integrados; rollback, ownership, replay, exclusão/exportação e dump/restore verificados em descartável. Schema13/30tabelas ativado com checkpoint e comparação, APK24 instalado/hash conferido;25 preparado e não instalado. O consumo anterior continua intacto e sem agrupamento nas duas visões; nenhuma refeição real criada pelo agente. Seleção particular e edição de metadados implementadas. Faltam aceite real/correção/exclusão e foto042; criação/consulta humana foi teste de navegação; outbox026 tem critérios próprios. O bloqueio editorial de015/016 não impede esse trabalho independente e não autoriza concluir treinos.

## 1. O raciocínio e a expectativa do autor

O autor está disposto a avaliar a compra de uma API que demonstra exercícios por GIF, mas quer primeiro usar o aplicativo e compreender o que já tem. Não basta um exercício demonstrado se o sistema não entrega um treino coerente com o pedido da pessoa. Também quer compreender o registro alimentar, inclusive a expectativa de foto, identificação e quantidade consumida.

Antes de qualquer compra, a avaliação deve responder:

- **Banco:** já existe? Qual? Que tabelas e relações possui? Quem consulta/escreve? O que guarda? O que deve ficar no celular? As decisões são corretas e o que falta?
- **Backend:** está organizado por responsabilidade, com contratos, regras, persistência e integrações separados? O main apenas compõe/inicia? É testável e preparado para crescer? Trocar a linguagem para Go não basta.
- **Segurança:** quais controles existem e quais evidências os sustentam? Onde estão as lacunas? O que precisa melhorar? Sem nota ou garantia inventada.
- **Frontend:** tem os campos necessários aos contratos e evita campos inúteis? As jornadas são claras para idosos e cuidadores? Há acessibilidade, componentes reutilizáveis, estados reais e ausência de dados fictícios? Informação técnica da API não deve dominar a experiência.
- **Qualidade e operação:** há testes úteis, CI, análise estática/Sonar, recuperação, desempenho e ensaio de carga documentados? Há português brasileiro, português europeu, inglês e espanhol? As bases são adequadas aos países e públicos pretendidos?
- **Visão integrada:** o que exatamente impede usar cada cenário hoje, o que posso resolver sem comprar e qual lacuna uma eventual API realmente preencheria?

A expectativa é avaliar **o produto inteiro em incrementos reais**, cenário por cenário. Preservar Android e iOS, idosos, cuidadores, casa, praça/parque e academia. Não substituir esse objetivo por uma demo bonita ou por um catálogo de GIFs.

**Exigência de engenharia desde agora:** código organizado, separado por responsabilidade, seguro, com recuperação e preparado para evolução e escala. “Monólito modular” descreve uma forma de distribuir o backend; não autoriza acoplamento, SQL em telas, regras no main ou adiar segurança. “Extremamente seguro” e “milhões simultâneos” são ambições que exigem critérios e evidências, não garantias absolutas antecipadas.

**Limites preservados:** sem hospedagem/deploy agora, sem compra/assinatura/integração paga automática, sem nova pesquisa ampla de fornecedores, sem conteúdo de treino/dose/nutriente inventado e sem apagar dados reais. A lista de [APIs já pesquisadas](../../conteudo/opcoes-apis-exercicios.md) permanece válida. A indicação de até R$400 não é autorização de compra.

## Respostas Q1 incorporadas — 24/10/2026

- **Treinos:**os dois caminhos entram na versão desejada:escolher programas compatíveis e compor exercícios por regras humanas revisadas. V1-015 e novaV1-044, sem prescrição inventada.
- **Cuidador:**o próprio cuidador é o praticante durante pausas do trabalho. Vínculo/delegação de pessoa assistida não é foco nem bloqueio desta versão; a interpretação anterior foi corrigida.
- **Foto:**reconhecer candidatos, permitir corrigir/remover/adicionar, pedir quantidade explícita, calcular por base/versão e só então confirmar consumo. V1-042 antecipada paraV1.
- **Histórico:**deve ser visual e agradável; registros de consumo são do servidor. Q2 abaixo aprovou recuperar também as imagens pela conta com cache local. Q2 abaixo confirmou histórico, análise nutricional e dicas juntos; regras/fontes/revisão ainda precisam ser elaboradas. Não inferir deficiência de registros incompletos.

Registro detalhado e distinção entre decisão e proposta em [decisoes-piloto.md](decisoes-piloto.md). Nenhuma dessas capacidades foi implementada por esta atualização.

## Respostas Q2 incorporadas — 25/10/2026

- **Organização aprovada:** agrupar por refeição e também permitir visão por alimento, sobre os mesmos registros (V1-045).
- **Entrega conjunta aprovada:** histórico visual, análise nutricional e dicas revisadas juntos na primeira versão (V1-046). A clarificação elimina a resposta ambígua “opção 2 e 3 juntas”; não adiar análise/dicas silenciosamente.
- **Fotos:** a [comparação de quatro produtos](pesquisa-fotos-historico.md) foi concluída documentalmente. Após comparar, o autor aprovou recuperar fotos pela conta com cache no celular. Hospedagem continua adiada; ciclo privado, limites/retenção/exclusão e implementação precisam ser detalhados.
- **Limites:** análise representa somente o registrado, com cobertura/desconhecidos explícitos. Dicas exigem regra/fonte/versão/revisão; não diagnosticar deficiência nem inventar nutrientes ou metas.

Nenhuma história foi concluída por essas decisões. Contratos, modelos, conteúdo revisado e implementação seguem os gates abaixo.

## Respostas Q3 incorporadas — 25/10/2026

- **Configuração:** completa e revisada antes da busca/seleção de treino. Nova V1-047 para persistir o contexto privado em Go/SQL/Flutter, com campos justificados por finalidade/fonte; não reativar geradores nem herdar dados físicos obrigatórios do legado.
- **Ajustes:** permitir trocar exercícios compatíveis e editar dias/horários dentro das regras humanas. Preservar versão/autoria/dose e histórico; V1-015/044.
- **Interrupção:** oferecer retomar ou encerrar como parcial, preservando eventos confirmados e idempotência; V1-017/023. Saída de tela/tempo decorrido não concluem treino.
- **Q4/Q5 posteriores:** escolhas registradas abaixo; Q6 também respondido. Modelos/campos/regras e implementação seguem pendentes; respostas não encerram histórias.

## Respostas Q4 incorporadas — 25/10/2026

- **Exclusão:** apagar refeição inteira também apaga foto/miniaturas; coordenar banco/arquivos/cache/fila. Upload ou resposta atrasada não recria dados excluídos (042/045).
- **Offline:** registrar alimentação e andamento com dados disponíveis, em fila durável privada, com pendência até confirmar/reconciliar (026 existente, sem nova história).
- **Isolamento:** conta trocada/revogação/exclusão bloqueiam acesso/envio indevidos; resposta perdida não duplica registro. Reconhecimento de imagem não foi validado offline.
- **Q5 posterior:** apresentação da configuração e nomes definida abaixo; Q6 também respondido. Nenhum gate funcional ou de segurança foi encerrado por documentar a escolha.

## Respostas Q5 incorporadas — 25/10/2026

- **Configuração:** etapas curtas por assunto, com revisão final e retorno/correção sem perda de respostas (047).
- **Alimentos:** nome traduzido quando revisado para o idioma escolhido; original/fonte/versão nos detalhes, fallback original na ausência de revisão. Não alterar identidade, preparo ou nutrientes.
- **Idiomas:** nova048 explicita UI pt-BR/pt-PT/en/es e nomes revisados separados do lote original;025/027/035 conferem o conjunto. Nenhuma tradução foi publicada nesta rodada.
- **Q6 posterior:** regra de exclusão e cobertura registradas abaixo; organização humana dos aceites será combinada com fluxo concreto. Emulador primeiro e físico guiado já definidos.

## Respostas Q6 incorporadas — 25/10/2026

- **Exclusão:** usuário exclui seus próprios dados; master do autor terá permissão excepcional mantida no servidor, com identidade verificada, confirmação e auditoria (nova049todo). Não conceder por e-mail, body, GitHub ou apenas pela existência do login Google.
- **Aceite:** todos os cenários da matriz devem aparecer com pré-condições, resultado/evidência e estado real. Ausência de função/conteúdo obrigatório não vira aprovação.
- **Limites:** participantes/conta de ensaio não foram confirmados. Preservar dados reais; testes técnicos isolados não substituem aceite humano de público/cenário. Recursos posteriores conservam sua prioridade já acordada.
- **Próxima ação:** 021 encerrada no recorte de fundação; seguir048 pelas dependências. Só perguntar detalhes materiais restantes quando o fluxo concreto exigir, sem nova bateria genérica.

## 2. Como trabalhar um bloco de cada vez

Estados dos itens: **existente validado** (há evidência do recorte), **parcial**, **a fazer**, **decisão pendente**, **bloqueado por dependência**. Os blocos de implementação continuam abertos. Q1–Q6 tiveram decisões registradas. Configuração completa, trocas compatíveis/agenda e retomada/parcial estão aprovadas; a047 detalhou campos por finalidade/fonte e encerrou o aceite funcional local. Entrega conjunta de histórico/análise/dicas e fotos pela conta com cache continuam aprovadas. Q4 aprovou excluir foto com a refeição e registrar offline para sincronizar depois; mecanismo, limites e testes ainda pendentes na026/042/045.

Antes de codificar um bloco: apresentar somente as dúvidas que alteram seu escopo, registrar respostas/decisões e definir seu recorte. Não fazer o autor decidir detalhes técnicos rotineiros. Fazer incrementos pequenos, contratos antes de consumidores, testes relevantes e commits validados. Confirmar o estado real antes de atualizar APK ou banco.

Para dizer **“backend encerrado”**, registrar: escopo acordado, itens concluídos, critérios atendidos, contratos/diagramas atualizados, testes e versão/commit, aceite integrado quando exigido e limitações restantes. Se há dependência que impede um critério, o bloco permanece parcial/bloqueado; pode-se fazer trabalho independente em outra área sem chamar a anterior de concluída.

Banco, segurança e testes acompanham cada mudança de backend; acessibilidade e estados acompanham cada tela. Os blocos de revisão ao final verificam o conjunto, não adiam esses cuidados.

| Ordem | Bloco | Situação atual | Condição para encerrar |
|---|---|---|---|
| 00 | Decisões do produto e contratos de jornada | Decisões pendentes | Perguntas essenciais respondidas e escopo das jornadas aprovado |
| 01 | Banco e armazenamento no aparelho | Fundação real; modelos novos pendentes | Modelos/privilégios/recuperação alinhados ao escopo, migrations e testes aprovados |
| 02 | Backend | Fundação e alimentação reais; treino e foto incompletos | Casos de uso do recorte completos, isolados, documentados e testados |
| 03 | Segurança e privacidade | Controles presentes; revisão completa pendente | Matriz de riscos/controles e correções verificadas, com limites explícitos |
| 04 | Frontend, experiência e idiomas | Checkpoints visuais parciais | Jornadas reais simples, contratos coerentes, acessibilidade e referências conferidas |
| 05 | Testes, CI e análise de qualidade | Cobertura parcial; CI incompleta | Regressões críticas automatizadas e pipeline capaz de detectar falhas do recorte |
| 06 | Observabilidade, desempenho e carga | Fundamentos presentes; baseline ausente | Diagnóstico e capacidade medidos em cenário reproduzível isolado |
| 07 | APK e aceite integrado local | APK de avaliação já existe | Instalação/atualização e jornadas acordadas aceitas, sem perda de dados |
| 08 | Reavaliação da API de mídia | Compra não autorizada | Lacuna de mídia isolada das outras pendências e decisão específica do autor |

### Decisões que não podem ficar escondidas

V1-042 foi antecipada e delimitada ao reconhecimento de alimentos com revisão e quantidade informada; V1-044 foi criada para a composição controlada de treino naV1. V1-045/046 detalham as duas visões alimentares e o conjunto histórico/análise/dicas, também naV1. OCR/barcode, imagem deatividade, sensores/GPS(V1-041), ampliação de modalidades(V1-040) e acompanhamento de terceiros(V1-043) seguem posteriores. Não incluir delegação como requisito de treino para o próprio cuidador.

Configuração completa047 foi implementada e validada funcionalmente; clareza de fuso/hora segue no refinamentofrontend. Quatro idiomas e capacidade de nomes revisados têm história048 concluída no recorte documentado; publicação real permanece condicionada à revisão humana. Delegação de outra pessoa é opção futura, não requisito desta entrega. Identificar a lacuna agora não autoriza inventar campos ou marcar a antiga V1-009 como validação desses novos modelos.

## 3. Bloco 00 — decisões do produto

**Entregável:** matriz simples de jornadas, ator, entrada, resultado esperado, dados necessários, permissão, origem do conteúdo e restrição real. Exemplo de caminho a validar: configurar contexto → encontrar opção permitida → confirmar → acompanhar execução → recuperar histórico. Não preencher a opção de treino com conteúdo fictício.

| ID | Decisão necessária | O que ela desbloqueia |
|---|---|---|
| D-01 | Respondido: programas humanos compatíveis **e** composição por regras revisadas; Q3 permite trocas compatíveis e dias/horários editáveis | V1-015/044; dois caminhos sem dose inventada |
| D-02 | Respondido:cuidador pratica durante pausas do seu trabalho, usando os próprios dados | Contexto de pausa sem cadastro de paciente ou autorização delegada |
| D-03 | Respondido:foto identifica candidatos editáveis; usuário informa quantidade antes do cálculo/registro | V1-042 naV1; recuperação das imagens pela conta com cache aprovada noQ2, ciclo privado a detalhar |
| D-04 | Q3/Q5: configuração completa em etapas curtas/revisão; detalhar campos por finalidade/fonte, sem importar exigências físicas do legado | V1-047; revisão, validação e persistência privada antes de015/044 |
| D-05 | Q4: alimentação/andamento offline e sincronização posterior; operação aceita no aparelho exige durabilidade | V1-026; fila privada por titular, pendente explícito e recuperação sem duplicação |
| D-06 | Q5: pt-BR/pt-PT/en/es preservados; nomes traduzidos quando revisados, original/fonte nos detalhes e fallback original | V1-048; cobertura/traduções auditáveis sem mudar identidade/preparo/nutrientes |
| D-07 | Respondido: agrupar por refeição e também visualizar por alimento | V1-045; duas visões sem duplicar consumo/nutrientes |
| D-08 | Respondido: histórico visual, análise nutricional e dicas revisadas juntos na primeira versão | V1-046; regras/fontes/revisão ainda a elaborar, sem inferência clínica |
| D-09 | Respondido: oferecer retomar ou encerrar como parcial | V1-017/023; persistir somente eventos reais e não concluir automaticamente |
| D-10 | Respondido: excluir refeição inteira também exclui sua foto | V1-042/045; invalidar arquivos/cache/fila e impedir recriação por reenvio |

**Gate 00:** decisões registradas com data e consequência; fluxo local e distribuição pública separados; conteúdo permitido identificado ou bloqueio explícito. Sem decisão essencial, seguir apenas nos ajustes independentes de organização e qualidade.

## 4. Bloco 01 — banco de dados e armazenamento local

**Já existe:** PostgreSQL local isolado, 23 tabelas, migrations, papéis separados, constraints/ownership, versões, proveniência, hash/rotação de sessão, consumo e idempotência. Contagens e privilégios estão na auditoria. Nenhuma hospedagem é necessária para esta etapa.

| ID | Falta ou melhoria | Implementação/decisão necessária | Evidência de encerramento |
|---|---|---|---|
| BD-01 | Inventário compreensível | Por tabela: finalidade, titular, produtor/consumidor, chave, relações, retenção, exportação/exclusão e índice usado; separar tabelas ativas de preparação | Mapa corresponde às migrations e às consultas reais |
| BD-02 | Configuração completa persistida (047) | Modelar campos necessários e justificados em D-04, confirmação/versão e alteração concorrente, unidades/localidade quando usadas | Ciclo criar/consultar/alterar privado validado; novo usuário sem fatos físicos preenchidos e histórico preservado |
| BD-03 | Contexto do cuidador praticante | Usar a conta do próprio cuidador e registrar somente o contexto de pausas aprovado; não coletar dados da pessoa assistida | Nenhuma permissão extra por profissão; contexto respeita requisitos humanos e não inventa dose/duração |
| BD-04 | Treino, agenda e execução | Conferir o modelo existente contra as regras aprovadas; versão de adesão, ocorrência, eventos, dose de origem versus execução observada | Constraints e transações rejeitam duplicidade, vínculo alheio e transição inválida |
| BD-05 | Servidor versus aparelho | Fechar política por dado; servidor autoritativo, tokens no armazenamento seguro, preferência local e outbox privada durável ligada à conta (Q4/026) | Inventário inclui TTL, logout, troca de conta, exclusão, sincronização e falha do processo |
| BD-06 | Recuperação de envio | Q4 exige persistir operação/titular/identidade antes do aceite local e reconciliar resposta perdida sem novo lançamento | Ensaio em banco descartável: servidor confirmou, resposta sumiu, processo encerrou e retomada não duplicou |
| BD-07 | Índices, volume e retenção | Conferir índices com consultas reais, paginação, crescimento de revisões/idempotência e política de expurgo; JSONB somente onde fizer sentido | EXPLAIN em base de teste, ausência de leitura excessiva e expurgo que preserve invariantes |
| BD-08 | Backup e restauração | Preservar ensaios já feitos; ampliar só quando schema/retorno de dados mudar. Definir proteção das cópias, retenção e aplicação do ledger de exclusão | Roteiro e recuperação conferidos no recorte alterado; ausência de retorno indevido de dados excluídos |
| BD-09 | Refeições, itens e análises | Modelar refeição com itens versionados, revisões e anexos conforme política aprovada; preservar entradas antigas sem agrupamento inventado | Duas visões sem dupla contagem, isolamento por titular e cálculos consistentes após correção/exclusão (V1-045/046) |

**Gate 01:** diagrama e inventário atualizados, migrations sem reset, runtime com privilégio mínimo e testes de integridade/isolamento dos novos modelos. Backup antigo validado não comprova automaticamente um schema novo. Dados reais do autor ficam fora das fixtures.

**Histórias relacionadas:** V1-009/010 concluídas para a fundação existente, sem reabertura artificial; novos requisitos alimentam extensões/novas histórias após as decisões. V1-015/017/020/026/045/046/047 conforme recorte; V1-043 só para expansão futura.

## 5. Bloco 02 — backend

**Já existe:** raiz de composição em main, domínios auth/catalog/nutrition/privacy, contratos Swagger gerados, regras de cálculo separadas, SQL parametrizado, limites e controle transacional. A escrita alimentar ainda acopla o handler a NutritionStore concreto. O módulo activity não tem os casos de uso entregues.

### Padrão de engenharia exigido desde o primeiro incremento

- HTTP traduz request/response; caso de uso coordena regras/autorização/transação; domínio expressa invariantes; persistência implementa o contrato necessário. Regra não depende de widget, Dio, net/http ou pgx.
- Interfaces pequenas próximas do consumidor, composição explícita e módulos com donos. Não criar um service genérico ou repository global que acessa tudo. Privacy pode coordenar o ciclo dos módulos por responsabilidade explícita e testada.
- Contratos tipados e versionados; erros estáveis; IDs do titular não são autorização vindos do body; operações concorrentes têm semântica e recuperação definidas.
- Limites, cancelamento e idempotência fazem parte de cada caso de uso; SQL/transações e quantidade de conexões são controlados. Nenhuma consulta ilimitada para “simplificar agora”.
- Separar integrações por capacidades e interfaces. Mídia externa, reconhecimento por foto e treino aprovado não viram uma única dependência de fornecedor.
- Poder adicionar instâncias exige estado consistente no banco/armazenamento compartilhado apropriado; memória local não deve ser o único guardião de sessão, conclusão ou operação.

| ID | Falta ou melhoria | Entrega concreta | Evidência de encerramento |
|---|---|---|---|
| BE-01 | Fronteiras e acoplamento | Revisar imports e responsabilidades; extrair uma interface/caso de uso pequeno para a escrita alimentar onde houver benefício real, preservando transações | Regressão do comportamento existente e injeção em testes sem conexão real obrigatória |
| BE-02 | Contratos da configuração (047) | Ler/salvar/alterar configuração completa do titular, confirmar versão e validar pré-requisitos antes de buscar/selecionar treino; erros de campo e concorrência explícitos | Swagger, testes HTTP/SQL e contrato Flutter; coleta com finalidade e sem liberar conteúdo por completar formulário |
| BE-03 | Seleção/composição de treino | Resolver compatibilidade apenas com regras humanas e opções aprovadas; preservar autoria/versão, explicar ausência/incompatibilidade e alteração do programa | Caso real permitido ou bloqueio editorial explícito; nenhuma dose/treino fabricados |
| BE-04 | Adesão e agenda | Criar/trocar/arquivar adesão; gerar apenas ocorrências previstas pelas regras/fonte, sem progressão inventada | Persistência, troca preservando histórico e rejeição de vínculo inválido |
| BE-05 | Execução e retomada | Estados explícitos e eventos reais; Q3 oferece retomar ou encerrar parcial, sem concluir por saída/tempo decorrido | Corridas/reenvio/interrupção/retomada testados, medido separado do previsto e versões/datas preservadas |
| BE-06 | Histórico e resumo | Consultas paginadas e resumo de origem explícita; execução real separada do plano e alimentação separada de gasto | Respostas não somam métodos incompatíveis nem convertem ausência em zero |
| BE-07 | Alimentação, refeições e análise | Preservar racional/unidades/desconhecidos; refeições/itens sobre os mesmos consumos e agregações por período; erros claros e dicas por regra revisada | Contrato e regressão de ownership/revisões, sem dupla contagem, cálculo divergente no cliente ou diagnóstico por diário parcial (V1-045/046) |
| BE-08 | Cuidador praticante | Filtrar opções aprovadas para o contexto de pausa do próprio usuário, sem acesso delegado | Mesmo ownership do praticante; não exige vínculo ou cadastro de pessoa assistida |
| BE-09 | Alimento por foto, aprovado paraV1 | Captura/análise separadas; lista editável, inclusão/remoção, quantidade pelo usuário e confirmação por alimento | Não inventa ingredientes/nutrientes/quantidades; cancelamento/reanálise não duplica consumo; fallback manual e isolamento privados |
| BE-10 | Documentação e legado | Atualizar Swagger por comentários/tipos, diagramas e mapas; isolar/remover caminho legado após prova de uso | Cliente ativo só usa contratos Go; sem dois escritores do mesmo domínio; referências antigas não parecem entrega atual |

**Gate 02 — “backend encerrado para este recorte”:** todos os casos de uso acordados implementados e integrados ao banco, organização acima conferida, autorização/concorrência/erros/cancelamento testados e Swagger coerente. Se prática real depende de conteúdo ainda não autorizado, o gate funcional continua aberto mesmo que contratos e testes técnicos passem com fixtures isoladas.

**Histórias:** V1-015/016/017/018/020 e extensões de configuração/contexto; V1-042/044/045/046/047 naV1; V1-040/043 permanecem posteriores. Fundação V1-007/008 continua válida no seu escopo.

## 6. Bloco 03 — segurança e privacidade

**Já existe:** validação Google, sessão com hashes/rotação/revogação, filtros por titular, logs redigidos, limites HTTP, proxy explícito, runtime restrito, exclusão/exportação e controles de backup Android. Isso é evidência parcial, não certificação.

| ID | Falta ou melhoria | Entrega concreta | Evidência de encerramento |
|---|---|---|---|
| SEG-01 | Modelo de ameaças por jornada | Mapear atores, dados, fronteiras, abuso, dispositivo perdido, acesso entre contas e fornecedor futuro | Cada risco relevante ligado a controle/teste ou risco residual aceito |
| SEG-02 | Matriz de autorização | Cobrir operações privadas e exceção de exclusão master049, com papel no servidor, confirmação/auditoria; delegação só se aprovada futuramente | Usuário alheio e privilégio forjado negados; master revogado perde acesso e cuidador não ganha permissão por profissão |
| SEG-03 | Credenciais e sessão | Revisar rotação/reuso, logout, falhas de rede, relógio, expiração e armazenamento/recuperação nativos | Rede não apaga sessão válida; credencial revogada não volta por resposta tardia |
| SEG-04 | Superfície da API | Revisar limites por rota, JSON/entrada ambígua, uploads se existirem, paginação, enumeração, proxy e orçamento por instância | Requisição inválida/abusiva é limitada sem vazar conteúdo interno; casos concorrentes testados |
| SEG-05 | Dependências e segredos | Inventário, versões, lockfiles, análise Go/Flutter/nativo, govulncheck e varredura de segredos com resultado real | Achados triados/corrigidos, exceções justificadas e nenhum segredo em Git/APK/log/artefato |
| SEG-06 | Dados em repouso e backup | Comprovar proteção de tokens, outbox e eventuais fotos, transferência/backup Android/iOS, dumps e volume conforme ameaça | Inspeção dos mecanismos e ensaio no ambiente pertinente; não inferir criptografia de uma ACL |
| SEG-07 | Privacidade ao ampliar dados | Incluir fotos/miniaturas/filas em exportação, exclusão e retenção; Q4 exclui foto com a refeição | Sem cópia ativa órfã ou recriada por reenvio; backups e aparelhos offline têm limites explícitos |
| SEG-08 | Artefato de distribuição | Revisar assinatura, permissões, debug flags, configuração de rede, endpoint e falha segura em Android/iOS | APK release e build iOS validados em ambientes próprios; HTTPS exigido fora do desenvolvimento autorizado |

**Gate 03:** requisitos aplicáveis da [ASVS](https://asvs.owasp.org/) e [MASVS](https://mas.owasp.org/MASVS/) ligados a evidência, riscos residuais escritos, nenhuma falha bloqueante conhecida sem tratamento e escopo de revisão explícito. Sem dizer “100% seguro”, sem nota inventada e sem chamar scanner de pentest. Testes locais não encerram homologação de exposição pública.

**Histórias:** V1-028; V1-011/012/013 já encerradas no checkpoint local e mantidas como regressão. Publicação/HTTPS dependem de autorização futura, não impedem continuar no emulador.

## 7. Bloco 04 — frontend, UX, acessibilidade e idiomas

**Já existe:** identidade TF, Inter/SVGs locais, splash/ícone, inicialização, estados, dark Grafite e lima, rolagem Android sem esticar, navegação e fluxos reais de biblioteca/alimentação/conta. Pontos 01–06 têm checkpoint Android; pontos 07–12 não estão integralmente encerrados. Fonte única: [frontend e checkpoints consolidados](frontend-fidelidade-figma.md).

| ID | Falta ou melhoria | Entrega concreta | Evidência de encerramento |
|---|---|---|---|
| FE-01 | Jornada simples | Revisar tarefas principais, ordem e caminhos de retorno; evitar levar a becos sem saída e não multiplicar telas por quantidade de frames do Figma | Usuário entende entrada → ação → confirmação → histórico, inclusive o cuidador como praticante nas pausas |
| FE-02 | Campos e contratos | Matriz campo do usuário / dado automático / regra / endpoint / persistência; DTO e estado tipados | Nenhum campo inútil ou obrigatório ausente; mensagem vinculada ao campo que falhou |
| FE-03 | Componentes e estado | 021encerrada25/10:composição/injeção, NutritionController e ambientes (108testes/analyze0issues); manter o padrão em novas jornadas e tratar melhorias de formulário/aceite025/026 | Mudança de conta, dispose, resposta atrasada e navegação não misturam nem perdem estado indevidamente |
| FE-04 | Configuração e treino | Concluir/revisar configuração antes de buscar treino; integrar trocas compatíveis e dias/horários, adesão/agenda e retomada ou parcial | Jornada real alinhada a047/015/044/017/023; sem gráfico/série/dose fictícios e com limites do conteúdo explícitos |
| FE-05 | Alimentação e histórico compreensíveis | Validar quantidade/unidade/fuso, desconhecidos e correção/exclusão; integrar visões por refeição/alimento, histórico visual, análise e dicas revisadas | Aceite conjunto sem dupla contagem ou inferência clínica; cobertura/limites claros, fonte preservada e cálculo técnico em detalhe acessível (V1-045/046) |
| FE-06 | Retomada/offline | Integrar fila durável privada de alimentação/andamento; estados salvo no aparelho, pendente, confirmado e falha/conflito | Processo encerrado, resposta perdida, conta trocada e exclusão concorrente sem duplicação/recriação ou falso sucesso (026/042/045) |
| FE-07 | Idiomas e nomes revisados (048 doing) | 495 mensagens nos fluxos disponíveis;173 testes Flutter, APK19 instalado e idiomas/restauração conferidos noAndroid. Cliente/cache/409,Go0.6.1/schema11 e ferramenta editorial validados. Cobertura real0/6.369; falta projetar nomes no histórico/detalhe sem mudar snapshots/cálculos; pacote humano é gate da publicação real | UI nos quatro idiomas e cobertura de conteúdo explícita; busca/nome traduzidos preservam ID/preparo/base/nutrientes, sem tradução automática publicada como revisão |
| FE-08 | Acessibilidade completa | TalkBack/VoiceOver, foco/ordem/rótulos, contraste e estados, fonte/display ampliados, toque/teclado e redução de movimento | Testes automatizados pertinentes e validação com pessoas do público; não depender só do tema |
| FE-09 | Figma e estados | Conferir famílias com contexto/exportação autorizada suficiente, tema, loading, erro, vazio, indisponível, teclado, navegação e retorno | Comparação com a referência correta e diferenças necessárias registradas; nada “exatamente igual” sem referência |
| FE-10 | Inicialização e qualidade percebida | Revalidar ícone fechado, splash/primeiro frame, cold/warm start, permissões e transições com os novos fluxos | Sem flash de tema, conteúdo privado antigo, loader sem saída ou regressão da rolagem |

**Gate 04:** matriz de jornadas do recorte sem telas simulando backend ausente; alinhamento aos contratos e ao Figma aprovado, acessibilidade real e traduções; teste Android e limite iOS explícito. Aprovação visual não libera práticas sem conteúdo permitido.

**Histórias:** V1-021–027 e V1-042/045/046/047/048. V1-038 é validação nativa iOS; não substituir por widget test no Windows.

## 8. Bloco 05 — testes, CI e análise de qualidade

**Base medida em 24/10:** Flutter 101 testes e 78,46% das linhas instrumentadas; Go 71 resultados aprovados, 10 integrações SQL puladas e 40,73% das instruções no perfil padrão. Percentuais têm denominadores diferentes e não são nota do aplicativo. Sonar não está configurado; CI atual não roda Flutter nem integração SQL descartável automática.

| ID | Falta ou melhoria | Entrega concreta | Evidência de encerramento |
|---|---|---|---|
| QA-01 | Plano por risco | Ligar requisitos e invariantes aos testes de domínio, HTTP, SQL, widget, nativo e aceite humano | Caminhos críticos e negativos cobertos; sem teste por função apenas para contar |
| QA-02 | Integração SQL automática | Provisionar base descartável isolada na CI, migrar e executar opt-in explícito; falhar quando integração obrigatória for pulada | Run comprova execução, titularidade, transação, concorrência, rollback e cleanup sem tocar banco real |
| QA-03 | Flutter na CI | Analyze e testes com ferramentas/versões fixadas; publicar cobertura redigida | PR falha em regressão Flutter e resultado é visível, não só anotado em diário local |
| QA-04 | Cobertura significativa | Medir separadamente Go/Dart, excluir código gerado com justificativa quando apropriado e melhorar trechos críticos descobertos | Piso/critério acordado por risco e cobertura da mudança; sem esconder lacunas com exclusões |
| QA-05 | Sonar/análise estática | Decidir ferramenta e edição compatíveis com linguagens e custo, integrar se aprovado; manter scanners específicos necessários | Resultado real, regras/versões/gate e triagem; sem serviço pago provisionado por inferência |
| QA-06 | Matriz de falhas | Login/restauração, conta trocada, envio duplicado, erro/rede, término abrupto, unidade/fuso, retirada e acessibilidade | Teste reproduzível evita regressão observada, com dados isolados |
| QA-07 | Artefatos e revisão | Builds reproduzíveis, lockfiles e hashes; revisão de diff e testes proporcionais antes de commit | Código/contratos/artefato correspondem e logs/relatórios não expõem dados pessoais |

**Gate 05:** a CI exercita o que se declara validado, distingue skip de pass e tem gates úteis; revisão manual e dispositivos continuam onde automação não comprova a jornada. Fixtures não validam Google consentido nem uso humano real.

**Histórias:** V1-028/032 e critérios transversais de V1-021–027/035. Não repetir importação, login e restore já concluídos sem mudança que justifique.

## 9. Bloco 06 — observabilidade, desempenho e escala

**Já existe:** limites, timeouts, paginação e cache público/versionado. O pool padrão da API é 10 e o máximo local PostgreSQL é 30; são proteções locais, não prova de capacidade. Rate limit/admissão atuais são por processo.

| ID | Falta ou melhoria | Entrega concreta | Evidência de encerramento |
|---|---|---|---|
| ESC-01 | Diagnóstico por jornada | Correlacionar requestId, rota/status/duração e operação de banco; medir pool sem usar PII como label | Falha controlada pode ser seguida de tela a SQL sem corpo/token no log |
| ESC-02 | Orçamento de desempenho | Definir cenários/hardware/volume/concorrência e metas API + abertura/rolagem/memória/bateria do app | Alvos registrados como proposta até medição; p95 de API não é FPS nem tempo total percebido |
| ESC-03 | Carga progressiva local | Base sintética descartável e mistura de leitura/escrita/refresh/reenvio; cache frio/quente, longa duração e recuperação | Relatório reproduzível com p50/p95/p99, vazão, erro, CPU/RAM/pool/DB e saturação |
| ESC-04 | Queries e tráfego | EXPLAIN, índices, paginação, campos projetados e cache/ETag público; evitar N+1 e cálculos repetidos | Gargalo identificado e correção medida; repetir ensaio somente quando houver mudança relevante |
| ESC-05 | Preparação para múltiplas instâncias | Sessão/idempotência consistentes, orçamento total de conexões, limites distribuídos quando necessários e invalidação de conteúdo | Teste do comportamento conjunto; nenhuma afinidade oculta ou estado indispensável em uma memória |
| ESC-06 | Operação e crescimento | Runbook de falha/backup/expurgo, alertas acionáveis, retenção e estimativa de armazenamento/transferência | Limites medidos e pontos de mudança documentados; hospedagem/custo continuam decisão futura |

**Gate 06:** baseline do cenário acordado, recuperação depois da saturação e gargalos/riscos conhecidos. Meta inicial do backlog p95 leitura <500 ms e escrita <1 s é proposta, não resultado. Nenhuma alegação de milhões simultâneos sem ensaio e dimensionamento correspondentes.

Monólito modular permite executar várias instâncias; microserviços não corrigem ausência de limites, autorização ou índices. Cache distribuído, filas, réplicas e particionamento são escolhas por necessidade medida, preservando fronteiras de código desde agora.

**Histórias:** V1-029/030. Pode preparar e medir localmente sem hospedagem e sem enviar carga a Google/fornecedor externo.

## 10. Bloco 07 — APK e aceite integrado local

**Já existe:** APK debug incremental instalado, assinatura debug/OAuth preservada e uma conta/consumo reais. Há assinatura release preparada e cliente OAuth conferido, mas isso não equivale a distribuição release validada.

| ID | Falta ou melhoria | Entrega concreta | Evidência de encerramento |
|---|---|---|---|
| APK-01 | Roteiro ponta a ponta | Matriz de cenários por ator/ambiente, o que está disponível, restrito e ausente | Autor percorre configuração, treino e alimentação acordados com dados reais e limites claros |
| APK-02 | Instalação/atualização | Versão, hash, assinatura e source fingerprint; conferir rascunhos antes de instalar e nunca limpar dados para atualizar | App atualizado preserva conta/registros/preferências conforme política e pode recuperar falha |
| APK-03 | Aparelhos e permissões | Emulador e Android físico acompanhado; tamanho de fonte, teclado, permissões e baixo recurso | Resultado por dispositivo/versão, instrução exata para conexão/teste e nenhuma permissão desnecessária |
| APK-04 | Modos de build/rede | Separar debug local, eventual release para avaliação e distribuição pública; definir transporte seguro do recorte | Roteiro executado no modo real, sem relaxar release globalmente para fazer teste passar |
| APK-05 | Feedback e correção | Registrar problema reproduzível, expectativa, evidência sem PII e decisão; corrigir antes de anunciar conclusão | Aceite do recorte e limitações assinado pelo comportamento observado, não por screenshot de fixture |

**Gate 07:** APK utilizável nas jornadas aprovadas, com critérios anteriores satisfeitos e sem perda de dados. Avaliação local não depende de contratar hospedagem. V1-031/033 seguem condicionadas a decisão futura; o aceite integral de distribuição/staging das histórias originais não deve ser marcado done só por esse checkpoint local.

**Histórias:** V1-034–037 conforme dependências; V1-038/039 para iOS/lojas. O produto continua multiplataforma, mesmo que o primeiro teste seja Android.

## 11. Bloco 08 — reavaliar compra e mídia

| ID | Entrega antes da decisão comercial | Evidência exigida |
|---|---|---|
| MID-01 | Demonstrar a jornada de treino com a lacuna de mídia explicitamente separada | Seleção/regra/agenda/execução/histórico funcionam no recorte permitido; conteúdo não aprovado continua bloqueado |
| MID-02 | Relacionar campos da API candidata ao nosso contrato | Identificador, exercício, autoria, licença, idioma, tipo de mídia, versionamento, retirada, cache e quota/custo |
| MID-03 | Identificar o que a compra não resolve | Sem inferir programa, dose, adequação clínica, delegação, alimentação ou reconhecimento por foto |
| MID-04 | Apresentar a decisão ao autor | Opções gratuitas já pesquisadas primeiro; condições de pagamento e direitos verificadas quando houver autorização de retomar essa escolha |

**Gate 08:** decisão específica do autor. Nenhuma contratação, cadastro comercial, compra ou integração paga decorre deste plano.

## 12. Perguntas por blocos — sequência de conversa

Q1–Q6 têm decisões registradas. Encerrar a rodada genérica de perguntas e seguir implementação pelas dependências. Identidade master/provisionamento e organização humana dos ensaios serão combinados diante de fluxo concreto. Emulador primeiro/físico guiado e requisitos anteriores não devem ser perguntados novamente. Registrar as respostas aqui e no recorte afetado antes de implementar. Questões técnicas rotineiras são resolvidas com evidência pelo agente.

| Conversa | Tema | Dúvidas a esclarecer quando chegar a vez | Estado |
|---|---|---|---|
| Q1 | Resultado da primeira versão | Dois caminhos; cuidador como praticante; foto com correção e quantidade informada | Respondido24/10; registradas decisões e corrigida interpretação |
| Q2 | Fotos, histórico e observações | Refeições/alimentos; histórico/análise/dicas juntos; recuperação das fotos pela conta com cache | Respondido em 25/10; sem contratação ou implementação por inferência |
| Q3 | Backend e treino | Completa antes da busca; trocas compatíveis/dias/horários; retomar ou encerrar parcial | Respondido25/10;047funcionaldone; refinamentoUXpendente; regras de seleção/composição pertencem a015/044 |
| Q4 | Segurança e privacidade | Excluir foto com a refeição; registrar offline e sincronizar depois | Respondido25/10;026/042/045 e revisão de segurança continuam pendentes |
| Q5 | Frontend e idiomas | Etapas curtas/revisão; nomes traduzidos quando revisados, original/fonte e fallback | Respondido25/10;047funcionaldone/UXpendente e048done, sem repetir chamadas Figma limitadas |
| Q6 | Qualidade e aceite | Exclusão por usuário/master e avaliação de todos os cenários; participantes/conta ainda não confirmados | Decisões25/10 registradas; combinar o restante somente com fluxo concreto |

## 13. Figma — impedimento e alternativa permitida

Em 23/24 de outubro, get_design_context devolveu **limite de chamadas do plano Starter** (ex.: nó 104:1260). Nesta rodada, somente whoami foi consultado: confirmou plano Starter, assento Full e acesso administrativo ao time. Não foi feita nova chamada de design limitada, alteração do arquivo ou contratação.

A [documentação oficial consultada em 24/10](https://developers.figma.com/docs/figma-mcp-server/rate-limits-access/) informa atualmente **até 20 chamadas de leitura por mês** para Starter e isenta whoami dessa contagem. O número disponível e a data de renovação não são devolvidos por whoami; não presumir saldo nem renovação e não repetir chamadas só para testar a cota.

Deixar o Figma aberto no computador **não muda a cota do conector**. O arquivo aberto pode servir a uma revisão visual pela interface autorizada se houver controle dessa superfície; não garante extração de camadas/tokens nem elimina a limitação. No Windows desta sessão, controle nativo não está disponível; eventual inspeção de uma aba do navegador depende da superfície habilitada e deve ser conferida quando necessária.

Alternativas sem compra: reutilizar contextos/assets já obtidos; receber exportações autorizadas dos quadros faltantes e suas especificações; aguardar acesso dentro das condições do plano. Não usar REST/credenciais/contas alternativas para contornar o limite. Comparação baseada só em imagem deve declarar o que não foi comprovado sobre tokens/layout/interação.

Famílias ainda sem contexto integral: cadastro manual 104:1260; privacidade 104:230/260; configuração 23:910/1021/1080; atividade/histórico 104:704/780/810. O [inventário](frontend-figma-inventory.json) distingue metadados de contexto completo. Não é preciso manter o computador com Figma aberto para concluir banco/backend/segurança e esta trilha.

## 14. Limpeza documental e fontes canônicas

| Documento/família | Função após a organização |
|---|---|
| Este roteiro | Expectativa do autor, tarefas/gates e dúvidas por área |
| auditoria-produto-2026-10-24.md + recibo | Baseline factual e medição histórica; não substituir por planejamento |
| backlog.json → backlog.md | Estados/dependências e critérios das histórias; Markdown gerado |
| frontend-fidelidade-figma.md | Referências, direção aprovada e checkpoints do frontend consolidados |
| pesquisa-fotos-historico.md | Comparação delimitada de quatro produtos e direção de recuperação aprovada, sem selecionar serviço |
| handoff.md / AGENTS.md | Retomada e instruções atuais concisas, sem repetir relatos completos |
| Arquitetura/contratos/Swagger/diário/recibos | Responsabilidades, documentação gerada, histórico e prova das validações |
| Conteúdo/licenças/manifestações de exclusão | Evidência e limites de uso preservados; não são lixo documental |

Relatos redundantes removidos após consolidação: `frontend-etapa-01-06.md`, `frontend-dark-scroll.md`, `frontend-etapa-07-12.md`. Suas decisões, critérios e resultados úteis foram incorporados ao documento frontend, os links ativos corrigidos e os recibos JSON preservados. Trechos duplicados e instruções superadas foram retirados da leitura atual; o Git mantém os textos originais completos. Não apagar dossiê, licença, migration, contrato ou evidência apenas por ser antigo.

## 15. Recibo de execução do bloco

Ao terminar um incremento, registrar no diário: IDs dos itens desta trilha e histórias relacionadas, decisões humanas aplicadas, arquivos/contratos/migrations, comandos/resultados, provas reais versus fixtures, dados preservados, risco residual, commit/push e próximo item. Atualizar status somente com evidência.

Modelo de encerramento:

```text
Área/recorte:
Itens planejados e concluídos:
Critérios verificados e resultados:
Dados/contratos/versões afetados:
Pendências e dependências:
Estado: parcial | bloqueado por dependência | encerrado para o recorte
Commit/artefato:
Próxima área/item:
```

Q1–Q6 estão registrados; próxima ação é implementação pelas dependências. A identidade master e o aceite humano conservam seus gates específicos. Implementação dependente aguarda os pontos ainda em aberto. Melhorias independentes continuam possíveis, sem ultrapassar as decisões pendentes.

## Atualização047 — 27/10/2026

IntegraçãoGo/SQL/HTTP/Flutter e privacidade realizada. API0.7.0/29operações,schema12/27tabelas,APKdebug0.4.0+22.213testesFlutter/analyze0issues, Go test/vet, SQL e restore emdescartável. A [matriz](configuracao-treino-047.md) reúne evidências e contrato. Criação humana, edição expressamente autorizada e recuperação da revisão2 validadas; nenhum outro dado foi inventado ou alterado pelo agente. CompletionEvidence está no fechamento047. A [fundação anterior](training-configuration-foundation-verification.json) é evidência histórica, não trabalho a repetir.
