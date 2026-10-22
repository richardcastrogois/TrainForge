# Retomada por outro agente

## Ler nesta ordem

1. `AGENTS.md` da raiz real `C:/dev/TrainForge/trainforge`.
2. [Índice](../../README.md), [escopo](escopo.md), [plano macro](plano-macro.md).
3. `backlog.json`: `next` aponta V1-005 pela direção do autor de continuar a preparação de conteúdo; V1-004 concluída e V1-002 não iniciada; conferir dependências antes de escolher trabalho.
4. [Diagnóstico](../../arquitetura/diagnostico-atual.md), [arquitetura](../../arquitetura/arquitetura-alvo.md), [contratos](../../arquitetura/contratos-v1.md) e [domínio](../../arquitetura/dominio-e-banco.md) apenas conforme a história.
5. Para conteúdo, [índice de conteúdo](../../conteudo/README.md) e dossiê/manifesto pertinente, sem reler todos os recibos ou repetir buscas.

## Verdades de partida

- O projeto Git/Flutter é a subpasta `trainforge`, não seu diretório pai. Fastify está em `C:/dev/bootcamp-treinos-api`; Next.js antigo é referência. Não modificar o backend externo sem a história e o pedido da implementação.
- N01–N46 encerradas nos recortes; N15 modular fechada em 21/10. Não há pesquisa N ativa. Conteúdo não foi automaticamente publicado/liberado.
- Planejamento atual não implementou Go, migrations, cliente novo, deploy ou APK. `services/api`, manifestos aprovados e OpenAPI oficial são entregas futuras.
- Android é desenvolvimento/primeiro teste; Android e iOS são o produto. Não testar iOS “por equivalência”.
- [Direção do piloto](decisoes-piloto.md): avaliar o app inteiro por cenários em APKs incrementais, com todos os recortes e lacunas visíveis. Não reduzir a cobertura a uma única jornada/poucos alimentos nem adiar todo feedback até a V1 completa.
- Mídia conforme disponibilidade/direitos; falta de instrução/mídia explícita. Base alimentar ampla pesquisada e cadastro próprio real são requisitos. Custo: priorizar gratuitas; referência de cerca deUS$19 em pagamento único, sem assinatura. Valores maiores foram considerados inviáveis; nenhuma compra/contato por inferência.
- Não criar planos/instruções/doses, refeições, perfis, métricas, sessões ou histórico fictícios para preencher a V1. Fixtures isoladas de teste não entram na base entregue.
- Não contactar BeFit/autores nem enviar mensagens sem autorização direta. Não contornar login, premium, proteção contra emulador ou extração. Resultados REA anteriores são dossiês de observação; REA não substitui fonte/autoria/licença.

## Rotina de atualização

No `backlog.json`, marcar doing ao assumir uma história, registrar bloqueio concreto em vez de inventar dado e preencher `completionEvidence` ao fechar. Evidência contém arquivo/commit/comando/resultado/data adequados, sem segredo. Atualizar `next` para uma história com dependências concluídas.

```powershell
# Na raiz real. Reutilize o Python existente; comandos apenas para manutenção.
python tools/gerar_documentacao.py --write --check
python -m unittest discover -s tools -p "test_documentacao.py"
```

A [documentação arquitetural](../../arquitetura/README.md) é Markdown/Mermaid no repositório; não recriar servidor/painel de leitura. O gerador usa somente código do clone e referência portátil explícita do Fastify. A CI preparada gera/verifica em PR/push e versiona derivados em job confiável, respeitando regras do remoto; sua execução real depende de publicação autorizada.

O Swagger é gerado de comentários e DTOs Go, com versão de ferramenta fixada; JSON/YAML são derivados. `tools/gerar_swagger.py --check` informa pendência se o serviço ainda não existe. Recarga real Go e validação da integração pertencem à V1-008. Anotação, registro de rota, spec e teste runtime são evidências distintas. [Rotina e limites](../../arquitetura/swagger-go.md).

Graphify permanece separado, com corpora explícitos; não analisa semanticamente toda a pesquisa. Status/direitos/apoio/achados exigem revisão e evidência.

## Handoff ao terminar cada fatia

Adicionar no [diário](diario.md): história, escopo entregue, caminhos, decisões, validação real, falhas/limitações, alterações de contrato/dados, commit e próxima ação exata. Não escrever “testado” sem comando/resultado. Se faltar decisão que só o autor pode dar, preparar opção concreta e continuar trabalho independente.

Antes de recurso cloud/custo/restart/publicação, apresentar fornecedor, custo/efeitos e ação concreta para aprovação. Instalar somente o que a história exigir e reutilizar SDK/ADB/emulador/terminal existentes. Não criar conta fictícia como teste de produto nem interpretar uma autorização antiga para benchmark como licença para conteúdo.

## Conteúdo preparado na continuação da etapa01

Ler [preparação local](../../conteudo/preparacao-local-2026-10-21.md), `content/manifests/pilot-prepared.json` e a fila por ativo antes de repetir pesquisa.109movimentos/práticas,329registros textuais,68referências de mídia;3.484registrosCiqual e2.887CoFID preservados localmente, não importados no app. `content/local/` é excluído do Git e exige os insumos reais para reconstrução. Nenhum ativo foi automaticamente aprovado.

`V1-005` segue com revisão de uso/atribuição/idioma/contexto, sem declarar revisão humana ou apoio inexistentes. A preparação alimentar não concluiV1-019nem seu requisito de banco. OriginalCode13-669CoFID conflita em dois alimentos: não fundir pelo código. `python tools/preparar_conteudo_local.py --check` e `python tools/auditar_conteudo_local.py` conferem dados e fontes locais; clones sem os insumos consultam os relatórios versionados.
