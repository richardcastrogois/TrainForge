# V1: produto real para teste Android

Direção de 21/10/2026. **Produto final Android e iOS; desenvolvimento e primeira entrega em Android.** O primeiro teste da esposa é teste de experiência/funcionamento, sem presumir idade, condição clínica, profissão, elegibilidade ou apoio disponível.

Objetivo ajustado pelas [respostas do autor](decisoes-piloto.md): obter APKs de avaliação durante o desenvolvimento para percorrer o aplicativo como um todo, cenário por cenário, entender o estado real e orientar mudanças antes do produto completo. Cada versão identifica o que funciona, o que falta e o que está restrito, sem simular capacidades. A V1 integrada permite autenticar uma pessoa real, consultar a biblioteca pesquisada, entender fonte/requisitos, registrar ações e recuperar histórico persistido. Alimentação inclui busca em base ampla pesquisada, quantidade/registro e cadastro real de alimento pelo usuário.

## Compromissos da V1

- Conteúdo de fontes humanas existentes, com autoria/contribuição, evidência, versão e direitos por ativo. Inventariar toda a cobertura pesquisada; importar todo material utilizável e permitido em lotes técnicos. Lote candidato e lote aprovado são manifestos distintos;331 famílias não equivalem a331 importações autorizadas.
- Movimentos, instruções, mídia e programas inteiros são objetos diferentes. Coleção modular informa essa natureza e conserva autoria de cada peça. Não herda a eficácia do programa original.
- Casa, praça/parque, academia, idosos e cuidadores continuam na matriz. Disponibilidade e limites reais são exibidos mesmo quando um recorte só permite consulta. Cuidador praticante não equivale à pessoa assistida.
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

O [backlog](backlog.md) mantém iOS/TestFlight/lojas em V1.1, e expansão de modalidades, composição/importação própria, sensores/GPS, captura por imagem/OCR e acompanhamento de terceiros em histórias posteriores. Esses recursos não serão simulados no APK para parecer completos. R12/R13 continuam na visão; não estão descartados. Nutrição avançada/prescrição individual exige viabilidade própria, distinta do organizador de consumo.

## APKs intermediários para avaliação

Não exigir o fechamento de todas as histórias da V1 para o autor avaliar a experiência no aparelho. Preparar builds incrementais com roteiro da matriz completa, indicando cenários disponíveis, incompletos e ainda não implementados. Isso não move automaticamente histórias posteriores para a V1 nem declara todos os cenários funcionais. Fluxos habilitados usam API/dados reais, controles de acesso e configuração apropriada ao ambiente; nenhuma operação com dado pessoal é liberada sem os controles correspondentes. O aceite integral abaixo continua sendo o marco da V1 completa.

## Definição de pronto da entrega à esposa

1. Manifesto do lote e uso revisados; nenhuma mídia/instrução incorporada sem direitos demonstrados.
2. API, PostgreSQL e Flutter integrados no ambiente de teste, com login real e registros persistidos.
3. Uma jornada autorizada de conteúdo/atividade e uma alimentar verificadas contra o banco; histórico vazio e erros honestos.
4. Sessões idempotentes, retomada, logout/revogação e isolamento de conta verificados.
5. Análise, testes de contrato/integração, revisão de segurança e backup/restore com evidências reais.
6. APK release assinado, instalado/atualizado, certificado e SHA256 conferidos; link privado e roteiro de teste.
7. Notas de versão explicam cobertura/limites. Aceite e feedback da esposa registrados somente quando acontecerem.

Testes isolados podem ter fixtures explicitamente marcadas; testes de carga podem usar base sintética separada. Não são fontes do app nem seeds do ambiente entregue.
