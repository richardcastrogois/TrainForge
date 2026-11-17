# TrainForge — instruções para agentes

Estado documental: **17/11/2026**. Checkout ativo `C:/dev/TrainForge/trainforge`; o diretório pai não é este repositório. A solicitação atual do autor prevalece sobre snapshots históricos.

## Primeiro contexto

Ler `docs/README.md`, `docs/execucao/v1/handoff.md`, `docs/execucao/v1/escopo.md` e a história/dependências no `backlog.json`. Para código, `docs/arquitetura/README.md`; para comandos/ensino pessoal, `docs/aprendizado/README.md`. Pesquisas e marcos ficam em `docs/conteudo/README.md` e `docs/historico/README.md`.

## Estado e prioridade

Flutter Android/iOS; API Go0.10.0/38 operações; catálogo 0.2.0; núcleo schema 13/30 tabelas, catálogo schema 2/4 tabelas. pgx/SQL  e Goose, sem ORM atual. Catálogo é a primeira extração delimitada; não reescrever os demais domínios sem decidir ownership/transações/operação. Prisma/Fastify são referências históricas.

Execução017/023 tem motor, eventos/idempotência SQL, quatro rotas privadas e uma superfície na aba Atividade. Continua doing, com015/016 bloqueadas por conteúdo:73 metadados/439 ativos excluídos/zero programa-instrução-dose-mídia liberados para prática. Não inventar rotina, adequação clínica, tradução editorial ou histórico para fechar critérios. Intenção incerta no Flutter é somente em memória; não anunciar offline durável.

O incremento funcional anterior passou337 Flutter/análise0, Go/vet,138 Python e SQL3 testes+23 subtestes descartáveis. APK debug0.4.7+29 gerado/conferido, não instalado/publicado. A limpeza documental não repetiu aceite humano. Estado atual exige observar processos/aparelho; antes dela8082/18083/15432 estavam parados.

## Preservação e operação

`.local` contém bancos, credenciais, assinatura, backups, corpos de pesquisa e capturas: nunca apagar, publicar ou imprimir. Preservar dados reais, inclusive consumo humano e refeição20g declarada teste; não reclassificar/excluir por inferência. Não repetirGoogle por hábito. Configuração047 teve revisão 2/14:00 recuperada; não criar outra para navegar.

Operação diária: `python tools/ambiente.py status`, `start`, logs, `plan-stop` e `stop`. Não usar init/activate/importação/restore/migration como startup. Não parar processos globais. SDK Go sem credenciais: `tools.dev_api.environment(include_api_env=False)` retorna `(env,go)`.

Pesquisa foi compactada com caminhos/bytes/SHA preservados. `tools/evidencias.py listar|mostrar|extrair|verificar` consulta os originais; extrair fica em`.local`, sem download. O leitor resolve paths históricos presentes em JSON sem exigir milhares de arquivos soltos. Catálogos estruturados e recibos únicos continuam canônicos; não sobrescrever recibos datados como se um teste tivesse sido repetido.

SENAS e os42 SVG/7 JSON originais de design foram preservados para a apresentação. SVG de estudo não é screenshot atual doAPK. Não comprar mídia, copiar códigoAGPL/rotinas/traduções ou incorporar ativos com novas obrigações por inferência. Direitos/créditos existentes continuam válidos. Interesse em preço não autoriza pagamento, conta, contato, assinatura, hospedagem ou nova integração.

## Documentação e verificação

Não recriar pastas de snapshots ou MD por toda retomada. Atualizar os guias canônicos e a linha do tempo; detalhes imutáveis ficam nos acervos/recibos. Handoff é curto e atual; histórico não governa operação. Manter status/criteria/completionEvidence do backlog; done exige os critérios reais.

Gerar/conferir com `python tools/gerar_documentacao.py --write --check`; diagramas com `python tools/gerar_diagramas.py` e `--check`; suítePython em tools. Arquitetura e diagramas têm uma entrada comum. Ler `.local/skills/draw-io-diagram-generator/SKILL.md` antes de novos draw.io. Diagramas derivam de mapas/schema/Swagger; não editar os derivados à mão.

Graphify: consultar o grafo existente, atualizar AST incremental de `lib/` com `python tools/atualizar_graphify.py --write`, sem LLM/semântica/clustering/reprocessamento dos dossiês. Go/SQL e docs usam mapas/Swagger/índices próprios. Não rodar testes/análise/gen-l10n em paralelo ao `avaliar_android.py prepare`.

## Git

Usar `git -c safe.directory=C:/dev/TrainForge/trainforge ...`, sem mudar confiança global. Commit/push desta implementação e da reorganização foram explicitamente autorizados. Fazer stage por paths revisados, nunca `git add .`; escanear todo o intervalo/blobs a publicar, incluindo ZIPs descompactados pelo scanner, sem imprimir valores. ConfirmarHEAD remoto/local e ahead/behind0 0 apóspush. Nunca repetir a antiga reescrita histórica/force-push. Memória de fornecedor ou testes antigos não substitui evidência atual.
