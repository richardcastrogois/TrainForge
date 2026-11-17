# Como desenvolvi e como explicar o TrainForge

Este é um roteiro pessoal de estudo e apresentação. As afirmações abaixo vêm do código e dos registros do projeto; não atribuem a mim testes nativos ou decisões clínicas que não foram demonstrados. O estado detalhado continua no [handoff](../execucao/v1/handoff.md).

## A sequência que preciso saber contar

| Parte da evolução | O que produziu | O que aprendi a distinguir |
|---|---|---|
| Pesquisa de produto e conteúdo | Requisitos, fontes, direitos e lacunas | Encontrar informação pública é diferente de ter direito de publicar ou executar um programa |
| Protótipo Figma | Identidade, telas, destinos e estados demonstrativos | Navegação de protótipo é diferente de autenticação, persistência e uso no dispositivo |
| Fundação local em Go | API, PostgreSQL isolado, migrations, importação e recuperação | Um backend precisa de contrato, privilégios, dados rastreáveis e operação reproduzível |
| Integração com Flutter | Sessão, consulta de catálogo, dados privados e configuração | A primeira fatia útil atravessa tela, HTTP, regras e banco; não termina no layout |
| Separação do catálogo | Processo/base próprios e fronteira HTTP | Microserviço acrescenta responsabilidade de operação, falha, publicação e reconciliação |
| Execução de atividade | Agregado Go, eventos, idempotência, API e tela reutilizável | Regra implementada e fixture aprovada não liberam conteúdo humano para prática |

A [linha do tempo](../historico/README.md) guarda datas e checkpoints. A [evolução visual](../design/evolucao-visual.md) conserva as decisões antigas do Figma. Não preciso recitar todas as versões: preciso explicar o problema resolvido por cada etapa e mostrar a evidência correspondente.

## Por que estas peças estão aqui

**Flutter/Dart** implementam a experiência móvel e compartilham a base de interface entre Android e iOS. O primeiro ambiente avaliado é Android local; configuração iOS no repositório não comprova build e aceite nativos em macOS/Xcode.

**Go** implementa os serviços HTTP e as regras do backend atual. **PostgreSQL** preserva dados, relações e transações. **pgx** faz a comunicação Go/SQL; **Goose** controla migrations. A ausência de ORM é uma escolha da implementação existente, não uma garantia automática de qualidade ou velocidade.

**Catálogo separado** é a primeira extração efetivamente documentada. O restante do núcleo ainda reúne outros domínios. Para explicar microserviços, mostro essa fronteira real e seus custos; não apresento cada pasta `internal/` como um serviço já separado. As [decisões de arquitetura](../arquitetura/decisoes.md) registram o raciocínio e as alternativas.

**Python** automatiza tarefas locais, verificações e documentação. **GitHub Actions** executa checks em CI. Nem um script local nem um push hospedam o produto. **Graphify**, Swagger e diagramas ajudam a encontrar relações e contratos; cada ferramenta tem um recorte e não substitui a validação de execução.

## Como explicar uma entrega com evidência

Use esta sequência ao apresentar uma alteração:

1. O problema concreto: qual ação a pessoa precisava fazer ou qual erro ocorria.
2. O caminho: tela, estado, chamada HTTP, regra e persistência envolvidos.
3. A decisão: por que a solução cabe nessa fronteira; qual alternativa foi considerada, se houver registro.
4. A verificação: o que foi executado e qual resultado foi observado.
5. O limite: o que ainda depende de conteúdo, uso humano, dispositivo ou distribuição.

Exemplo da execução: “Implementei o motor de sessão em Go e a persistência de eventos com controle de revisão e idempotência. Integrei quatro operações privadas e uma tela na aba Atividade. Os testes exercitaram transições, reenvio, isolamento entre contas e SQL descartável. A prática real continua condicionada à publicação de um programa próprio revisado e à seleção/agenda.” A [implementação da atividade](../execucao/v1/implementacao.md#atividade) permite conferir cada parte dessa afirmação.

Se o trabalho foi auxiliado por ferramentas ou agentes, descreva essa participação conforme ocorreu e explique o código que você revisou. Um recibo de teste informa o que foi verificado naquele checkpoint; não demonstra que todo o produto foi concluído.

## Roteiro curto de apresentação

| Tempo aproximado | O que explicar ou mostrar |
|---|---|
| 30 segundos | O problema: organizar treino, atividade e alimentação com rastreabilidade, preservando o que a pessoa realmente informou |
| 1 minuto | A arquitetura: Flutter → API Go → PostgreSQL; catálogo separado com responsabilidade própria |
| 1–2 minutos | Um fluxo que existe: consulta de biblioteca ou configuração; use o [rastro de código](fluxo-de-uma-acao.md) |
| 1 minuto | Uma decisão técnica: transação, revisão/idempotência ou separação do catálogo, com seu motivo e limite |
| 30 segundos | O estágio real e a próxima unidade funcional; não usar dados fictícios como demonstração de prática |

Para falar da evolução de UI, abra a [galeria preservada](../design/README.md) e diferencie estudo Figma de tela implementada. Os 42 SVGs antigos são material visual de apresentação e mantêm seus dados demonstrativos. O material SeNAS permanece em `docs/apresentacao-senas/`; este roteiro não o substitui nem altera seus arquivos.

Se mostrar o app, planeje o percurso antes e use os dados existentes de forma consciente. Lista vazia por falta de conteúdo aprovado é um estado correto e explicável. Não preciso criar uma refeição, repetir consentimento Google ou inventar um treino para apresentar o projeto.

## Perguntas para conferir meu entendimento

- Consigo mostrar onde uma ação sai da tela e chega ao SQL?
- Sei explicar controller, repository, handler, transação e migration usando um exemplo real?
- Consigo distinguir configuração, prescrição, ocorrência e sessão executada?
- Sei o que continua salvo ao fechar o app ou parar os serviços?
- Sei por que consulta de metadados não autoriza prática?
- Consigo explicar o que meus testes comprovam e quais critérios ainda estão abertos?

Quando faltar uma resposta, siga o arquivo do fluxo e a evidência correspondente. Atualize estes guias quando o comportamento mudar; resultados e status detalhados pertencem às fontes canônicas, para não envelhecerem em vários lugares.
