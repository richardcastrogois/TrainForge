# TrainForge — instruções para agentes

Estado vigente: **23/10/2026**. Esta raiz é `C:/dev/TrainForge/trainforge`; o diretório pai não é o repositório. Pedidos atuais do usuário prevalecem sobre snapshots históricos.

## Próxima ação e escopo

- Ler [índice](docs/README.md), [plano macro](docs/execucao/v1/plano-macro.md), [escopo](docs/execucao/v1/escopo.md) e [handoff](docs/execucao/v1/handoff.md).
- [Etapa01 encerrada](docs/execucao/v1/etapa-01-fechamento.md): triagem dos512ativos concluída;73metadados de consulta e439excluídos. Nenhuma instrução/mídia/prática liberada. As exclusões continuam vinculantes; não publicar texto por herdar licença ou chamar fim da triagem de homologação clínica.
- [Etapa02 concluída](docs/execucao/v1/etapa-02-fechamento.md): Go real, Swagger2gerado, PostgreSQL isolado/migrations,73metadados importados, reimportação e restore validados. **V1-011 em validação:** retomada autorizada em22/10, authGo/Flutter implementadas e APKdebug instalado em emulador. LoginGoogle real Androiddebug validado em23/10 (consentimento doautor); OAuthrelease confirmado porprint; HTTPS/testeAPKrelease pendentes, não fechar011 indevidamente. Consultar handoff/oauth-android.md. V1-003 concluída com publicação autorizada/CI remota confirmadas em23/10; documentação continua transversal.
- Produto **Android e iOS**; desenvolvimento e primeiro teste da esposa em Android. Não presumir iOS testado por haver pasta nativa.
- [Direção do piloto de21/10](docs/execucao/v1/decisoes-piloto.md): autor quer avaliar o app inteiro, cenário por cenário, em APKs incrementais. Cobrir pesquisa existente e base alimentar ampla com busca/cadastro próprio; mídia conforme disponibilidade e lacunas explícitas. Não reduzir a entrega a uma jornada pequena nem aguardar o produto completo para feedback. Priorizar conteúdo gratuito; teto futuro de avaliação atualizado em22/10:atéR$400, mantendo preferência por pagamento único. Gratuitas primeiro; sem assinatura nem compra automática. Consolidar opções em `docs/conteudo/opcoes-apis-exercicios.md`; apresentar condições antes de qualquer contratação.
- V1-014 concluída em22/10: leitura Go/Flutter dos73metadados reais, filtros/versões/retirada/ETag e detalhe com atribuição. Biblioteca sem login;0programas/prática. [Retomar APK0.1.3+4](docs/execucao/v1/avaliacao-android.md) com tools/avaliar-android.ps1. Autor retornou: loginGoogle real/debug validado. Reabertura/rede/refreshnatural/logout/reentrada passaram; exclusão real explicitamente autorizada e concluída noapp.0contas/sessões privadas,1registro mínimo; fontes preservadas. OAuthrelease confirmado porprint; HTTPS/testeAPKrelease pendentes; ver auth-real-android-verification.json.
- V1-019 concluída para o lote alimentar autorizado:6369registrosCiqual/CoFID noDBisolado,2identidadesconflitantes excluídas,3basesdesconhecidas mantidas. [Importação e restore reais](docs/execucao/v1/alimentacao-importacao.md). Migration00005 aplicada, reimport0/6369, runtimeeditorialsomenteleitura. ConsultaGo/Flutter implementada como preparação parcial020/025; cadastro privado/consumo pendentes; não repetir coleta/preflight/import/restore sem mudança relevante.
- API atual Fastify/Prisma/PostgreSQL em `C:/dev/bootcamp-treinos-api`; Next.js antigo é referência. Go modular tem fundação local em `services/api`; auth/cliente possuem checkpoint local em validação; migração de dados legados não entregue.
- Pedido vigente: remover o painel local, manter documentação arquitetural dinâmica no repositório e gerar Swagger por comentários/tipos Go. Organização, ferramentas documentais e commits locais autorizados; não implica publicar, criar cobrança, alterar DB real ou enviar mensagens.

- 23/10: push autorizado e confirmado em3170c50 e4b922ab (ambasCIs passaram). V1-013 implementada/validada tecnicamente emGo0.4.0/18operações, exportação própria/exclusão confirmada/manutenção/gate de restore e Flutter; [estado013](docs/execucao/v1/privacidade-013.md). Googledebug/aceite privado reais passaram em23/10; continua doing pela011/HTTPS e testeAPKrelease pendentes; não avançar outraV1 antes desse aceite. Novos commits validados/push autorizados, deploy/contratação/contato seguem fora do escopo. Não alegar milhões simultâneos sem carga/infra dimensionada.

## Conteúdo e pesquisa

- N01–N46 fechadas nos recortes:40 pesquisas e6 reusos, sem N ativa. N15 fechada modularmente em 21/10:11 componentes de cuidadores separados de5 movimentos domésticos idosos.
- [Dossiê N15](docs/conteudo/evidencias/2026-10-21/n15c-composicao/relatorio.md) e [índice](docs/conteudo/README.md).331 famílias;840 tentativas GET/694HTTP200/780 hashes conferidos. Não equivalem a fornecedores aprovados ou programas integrais executáveis.
- Separar movimento, instrução, mídia e programa; guardar fonte/autoria/contribuição, versão, dose, público, apoio, direitos e lacunas por ativo. Composição não herda eficácia do programa original.
- Sem treino/instrução/dose/receita/histórico/usuário/métrica fictícios no runtime V1. Fixtures de teste isoladas não entram na base entregue. Sem Gemini/manual-generator como fallback.
- Preservar cuidadores (praticante e pessoa assistida distintos), idosos, casa e praça/parque. Não inferir elegibilidade por idade ou disponibilidade de profissional/parceiro.
- Não repetir pesquisa/coleta sem pista nova. Consulta começa pelos registros locais. Pesquisa fechada não é aprovação editorial, clínica ou comercial.
- Não contactar BeFit/autores nem enviar mensagens sem autorização direta. Não contornar premium/login/proteção/restrição de extração. Não copiar ativos sem direitos.

## Execução e evidência

- Incrementos pequenos por história/dependências; ler código antes de alterar. Não fazer rewrite completo, instalar ferramentas ou migrar produção por inferência de roadmap.
- Backend e frontend com contratos reais; um único escritor/migrador por domínio/schema. Backup só validado após restore conferido. Não apagar volumes para corrigir ambiente.
- Atualizar backlog JSON, contratos/achados/mapa afetados e diário ao concluir; `done` exige completionEvidence. Gerar backlog Markdown, não mantê-lo à mão.
- Leitura sem servidor: [arquitetura dinâmica](docs/arquitetura/README.md). Manutenção: `python tools/gerar_documentacao.py --write --check` e `python -m unittest discover -s tools -p test_documentacao.py`. Validação documental não é teste clínico ou do app.
- [Automação documental](docs/arquitetura/documentacao-dinamica.md): geração determinística na CI; captura do backend externo é explícita/versionada e não depende de caminhos locais. Intenção/fechamento exigem registro humano. Não recriar painel/servidor de leitura.
- [Swagger Go](docs/arquitetura/swagger-go.md): comentários/DTOs são fonte, JSON/YAML gerados não editados à mão. serviço Go e Swagger reais existem; watcher `python tools/dev_api.py` validou geração/build/restart. O gerador exige Go/Swaggo no PATH ou ambiente do projeto.
- [Graphify](docs/graphify.md): query primeiro em grafos existentes; update incremental code-only, corpora separados. Não indexar todo `docs/` semanticamente sem escopo/custo autorizados.
- No Git usar por comando `git -c safe.directory=C:/dev/TrainForge/trainforge ...` se houver erro de propriedade. Não alterar confiança global. Commit/push/publicação conforme autorização do usuário.
- Credenciais, chaves de assinatura, .env, caches e corpos/renders de terceiros fora do Git. Ao descartar temporários após uso, verificar alvos, apagar somente o que não é mais necessário e registrar resultado quando pertinente.

Snapshots antigos: [arquivo](docs/arquivo/README.md). Não usar instruções antigas de N15 aberta, N21 retida ou prioridade exclusiva Figma para contradizer o pedido vigente.
