# Retomada por outro agente

## Ler nesta ordem

1. `AGENTS.md` da raiz real `C:/dev/TrainForge/trainforge`.
2. [Índice](../../README.md), [escopo](escopo.md), [plano macro](plano-macro.md).
3. `backlog.json`: `next` aponta V1-001; conferir dependências antes de escolher trabalho.
4. [Diagnóstico](../../arquitetura/diagnostico-atual.md), [arquitetura](../../arquitetura/arquitetura-alvo.md), [contratos](../../arquitetura/contratos-v1.md) e [domínio](../../arquitetura/dominio-e-banco.md) apenas conforme a história.
5. Para conteúdo, [índice de conteúdo](../../conteudo/README.md) e dossiê/manifesto pertinente, sem reler todos os recibos ou repetir buscas.

## Verdades de partida

- O projeto Git/Flutter é a subpasta `trainforge`, não seu diretório pai. Fastify está em `C:/dev/bootcamp-treinos-api`; Next.js antigo é referência. Não modificar o backend externo sem a história e o pedido da implementação.
- N01–N46 encerradas nos recortes; N15 modular fechada em 21/10. Não há pesquisa N ativa. Conteúdo não foi automaticamente publicado/liberado.
- Planejamento atual não implementou Go, migrations, cliente novo, deploy ou APK. `services/api`, manifestos aprovados e OpenAPI oficial são entregas futuras.
- Android é desenvolvimento/primeiro teste; Android e iOS são o produto. Não testar iOS “por equivalência”.
- Não criar planos/instruções/doses, refeições, perfis, métricas, sessões ou histórico fictícios para preencher a V1. Fixtures isoladas de teste não entram na base entregue.
- Não contactar BeFit/autores nem enviar mensagens sem autorização direta. Não contornar login, premium, proteção contra emulador ou extração. Resultados REA anteriores são dossiês de observação; REA não substitui fonte/autoria/licença.

## Rotina de atualização

No `backlog.json`, marcar doing ao assumir uma história, registrar bloqueio concreto em vez de inventar dado e preencher `completionEvidence` ao fechar. Evidência contém arquivo/commit/comando/resultado/data adequados, sem segredo. Atualizar `next` para uma história com dependências concluídas.

```powershell
# Na raiz real. Reutilize o Python existente; alternativa documentada no painel.
python tools/painel_projeto.py --snapshot --check
python -m unittest discover -s tools -p "test_painel_projeto.py"
```

O painel lê o JSON canônico e código quando mudam; não altera status sozinho. O Markdown do backlog é gerado. Ao introduzir Go, ampliar o scanner para Go/OpenAPI e testar; enquanto isso sua cobertura continua Flutter/Fastify/Prisma. Graphify é uma ferramenta separada com corpora explícitos, não análise semântica de toda a pesquisa.

## Handoff ao terminar cada fatia

Adicionar no [diário](diario.md): história, escopo entregue, caminhos, decisões, validação real, falhas/limitações, alterações de contrato/dados, commit e próxima ação exata. Não escrever “testado” sem comando/resultado. Se faltar decisão que só o autor pode dar, preparar opção concreta e continuar trabalho independente.

Antes de recurso cloud/custo/restart/publicação, apresentar fornecedor, custo/efeitos e ação concreta para aprovação. Instalar somente o que a história exigir e reutilizar SDK/ADB/emulador/terminal existentes. Não criar conta fictícia como teste de produto nem interpretar uma autorização antiga para benchmark como licença para conteúdo.
