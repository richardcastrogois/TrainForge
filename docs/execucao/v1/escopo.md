# V1: produto real para teste Android

Direção de 21/10/2026. **Produto final Android e iOS; desenvolvimento e primeira entrega em Android.** O primeiro teste da esposa é teste de experiência/funcionamento, sem presumir idade, condição clínica, profissão, elegibilidade ou apoio disponível.

Objetivo ajustado pelas [respostas do autor](decisoes-piloto.md): obter APKs de avaliação durante o desenvolvimento para percorrer o aplicativo como um todo, cenário por cenário, entender o estado real e orientar mudanças antes do produto completo. Cada versão identifica o que funciona, o que falta e o que está restrito, sem simular capacidades. A V1 integrada permite autenticar uma pessoa real, consultar a biblioteca pesquisada, entender fonte/requisitos, registrar ações e recuperar histórico persistido. Alimentação inclui busca em base ampla pesquisada, quantidade/registro e cadastro real de alimento pelo usuário.

## Respostas Q1 incorporadas em24/10

Dois caminhos de treino:escolher programas humanos compatíveis e compor exercícios com regras humanas revisadas(V1-044), sem dose inventada. Cuidador é o praticante nas pausas do próprio trabalho; acompanhamento de pessoa assistida não é requisito desta entrega.

Alimento por foto entra no recorte desejado(V1-042):analisar → revisar/corrigir/remover/adicionar alimentos → informar quantidade por item → calcular pela base/versão → confirmar consumo. Não inferir peso ou nutrientes como fatos da imagem. Histórico visual e continuidade entre aparelhos fazem parte da expectativa; a recuperação das fotos pela conta, com cache no celular, foi aprovada no Q2 descrito abaixo. [Decisões completas](decisoes-piloto.md).

## Respostas Q2 incorporadas em 25/10

Agrupar por refeição e oferecer também a visão por alimento, usando os mesmos registros/cálculos sem dupla contagem (V1-045). **Histórico visual, análise nutricional e dicas revisadas devem ser entregues juntos na primeira versão** (V1-046); não adiar parte do conjunto sem nova decisão.

A análise mostra somente os registros disponíveis, com período/fuso, dias com dados, estimativas, métodos e desconhecidos. Dicas exigem fonte, versão, regra e revisão humana; não diagnosticar deficiência ou criar metas clínicas por diário parcial.

Após a [pesquisa comparativa de fotos](pesquisa-fotos-historico.md), o autor aprovou **recuperar fotos pela conta, com cache no celular**. Fotos já sincronizadas devem acompanhar o histórico em outro aparelho; rascunhos não enviados não têm recuperação garantida. Retenção/limites/exclusão serão definidos antes da liberação. Não autoriza hospedagem ou envio de fotos agora.

## Respostas Q3 incorporadas em 25/10

O autor escolheu configuração completa antes de procurar/selecionar treino (V1-047), troca de exercícios compatíveis e edição de dias/horários (015/044), além de oferecer retomada ou encerramento parcial de treino interrompido (017/023).

Completar o contexto exige finalidade para cada campo, revisão e persistência privada; não herdar obrigatoriedade de peso/altura/idade/gordura do legado ou reativar geração por IA. Consulta de referências e alimentação conservam seu escopo. Mudanças respeitam as regras humanas, direitos e versões; não alteram sessões passadas nem inventam dose, progresso ou conclusão. [Detalhes e matriz de campos](decisoes-piloto.md).

## Compromissos da V1

- Conteúdo de fontes humanas existentes, com autoria/contribuição, evidência, versão e direitos por ativo. Inventariar toda a cobertura pesquisada; importar todo material utilizável e permitido em lotes técnicos. Lote candidato e lote aprovado são manifestos distintos;331 famílias não equivalem a331 importações autorizadas.
- Movimentos, instruções, mídia e programas inteiros são objetos diferentes. Coleção modular informa essa natureza e conserva autoria de cada peça. Não herda a eficácia do programa original.
- Casa, praça/parque, academia, idosos e cuidadores continuam na matriz. Disponibilidade e limites reais são exibidos mesmo quando um recorte só permite consulta. Cuidador é o próprio praticante durante pausas do trabalho; pessoa assistida é possibilidade posterior, não requisito do modo cuidador.
- Frontend consulta nossa API e banco alimentados por lotes revisados. Não há exigência de acesso ao fornecedor a cada toque. Cache não transforma um conteúdo proibido em autorizado.
- Conta, preferências, consumo e atividade vêm de entradas/ações reais do testador. Novo usuário começa sem histórico, sem peso, calorias, refeições, fotos ou progressos pré-preenchidos.
- Interface cobre loading, vazio, falha, bloqueio, rede indisponível e retomada, além do caminho feliz. Ausência não vira zero medido, vídeo falso ou texto criado por IA.
- Mostrar foto e vídeo quando ambos existirem e tiverem uso permitido, ou somente a mídia disponível. Item sem mídia continua visível quando permitido, com ausência explícita; falta de instrução é outra lacuna e não libera prática guiada automaticamente.
- Alimentação permite buscar na base e cadastrar item próprio com dados reais informados; cadastro próprio não herda validação editorial nem vira público por inferência. A base pesquisada deve ter cobertura ampla, com importação/rejeições/pendências contabilizadas.
- Ensino para autonomia é o objetivo; seleção por ambiente/equipamento respeita requisitos da fonte. Não presumir máquina disponível, inventar adaptação doméstica ou retirar acompanhamento exigido pelo material.
- Logs sem segredos/dados físicos, autorização por recurso, refresh/revogação, backup restaurado, endpoint HTTPS e assinatura release são critérios de entrega.

## O que ainda precisa ser decidido com evidência

`V1-001/005/019` selecionam o lote útil e realmente liberado, com quantidades, população, instrução, revisão e direitos. A pesquisa fechou N01–N46 nos recortes, mas não homologou331 fornecedores nem toda prática. Se nenhum item atender a um uso, a V1 mostra a lacuna e não finge treinamento executável. A definição de pronto exige ao menos uma fatia que permita o uso previsto; só navegação em referência não conta como prática liberada.

N15 tem11 componentes para cuidadores no recorte modular; ES2019-DOM-01 tem5 movimentos domésticos para idosos, separados. Protocolos que exigem fisioterapeuta/facilitação não se tornam autônomos no APK. Não presumir parceiros, contato com fornecedor, instrutor ou verba de conteúdo. Sem nova coleta sem pista; não reabrir todas as N para recuperar contexto.

## Depois do primeiro piloto

O [backlog](backlog.md) mantém iOS/TestFlight/lojas emV1.1; expansão de modalidades/importação própria, sensores/GPS, OCR/barcode, imagem deatividade e acompanhamento de terceiros seguem posteriores. Composição controlada044 e alimento por foto042 foram antecipados paraV1 pelas respostasQ1; agrupamento045 e histórico/análise/dicas046 integramV1 apósQ2. Esses recursos não serão simulados no APK para parecer completos. R12/R13 continuam na visão; não estão descartados. Nutrição avançada/prescrição individual exige viabilidade própria, distinta do organizador de consumo.

## APKs intermediários para avaliação

Não exigir o fechamento de todas as histórias da V1 para o autor avaliar a experiência no aparelho. Preparar builds incrementais com roteiro da matriz completa, indicando cenários disponíveis, incompletos e ainda não implementados. Isso não move automaticamente histórias posteriores para a V1 nem declara todos os cenários funcionais. Fluxos habilitados usam API/dados reais, controles de acesso e configuração apropriada ao ambiente; nenhuma operação com dado pessoal é liberada sem os controles correspondentes. O aceite integral abaixo continua sendo o marco da V1 completa.

## Definição de pronto da entrega à esposa

1. Manifesto do lote e uso revisados; nenhuma mídia/instrução incorporada sem direitos demonstrados.
2. API, PostgreSQL e Flutter integrados no ambiente de teste, com login real e registros persistidos.
3. Configuração completa, os dois caminhos de treino com trocas compatíveis/agenda e retomada/parcial, alimentação manual/por foto revisada, visões por refeição/alimento e histórico visual/análise/dicas revisadas verificados contra o banco; dados ausentes e erros honestos, sem práticas ou orientação não aprovadas.
4. Sessões idempotentes, retomada, logout/revogação e isolamento de conta verificados.
5. Análise, testes de contrato/integração, revisão de segurança e backup/restore com evidências reais.
6. APK release assinado, instalado/atualizado, certificado e SHA256 conferidos; link privado e roteiro de teste.
7. Notas de versão explicam cobertura/limites. Aceite e feedback da esposa registrados somente quando acontecerem.

Testes isolados podem ter fixtures explicitamente marcadas; testes de carga podem usar base sintética separada. Não são fontes do app nem seeds do ambiente entregue.
