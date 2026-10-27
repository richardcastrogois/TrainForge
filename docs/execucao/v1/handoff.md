# Handoff vigente — TrainForge

Atualizado em **27/10/2026**. Repositório: **C:/dev/TrainForge/trainforge**.

## Próxima ação

Ler AGENTS.md, este handoff, backlog.json, plano-macro.md e etapa-02-fechamento.md. Conferir Git/arquivos antes de alterar; não repetir instalações, pesquisas, importações, restore ou Google sem mudança pertinente.

**V1-048 encerrada no recorte documentado. Continuar V1-047**, que depende de008/012/013/021/048, todas concluídas. Primeiro detalhar matriz de campos por finalidade/origem/obrigatoriedade/uso: ambiente e recursos, disponibilidade e pausa do próprio cuidador. Não herdar peso/altura/idade/gordura obrigatórios nem inventar aprovação clínica. Implementar configuração privada versionada em Go/SQL/Flutter, etapas curtas com revisão final, retorno/correção e seleção bloqueada antes da configuração. Completar formulário não libera conteúdo de prática inexistente.

[Trilha por área](trilha-implementacao.md) e [decisõesQ1–Q6](decisoes-piloto.md) governam o produto. Código seguro/separado desde agora; capacidade de milhões requer teste de carga, não promessa. Uma história só termina com seus critérios/evidências; continuar trabalho independente quando houver pendência humana material.

## Estado validado e ambiente

- Go **0.6.2 / 26 operações**, schema **11 / 26 tabelas**. Nenhuma migration nova nesta rodada;9–11 já tinham sido aplicadas com autorização/checkpoint/comparação. GET de um consumo próprio e locale/namesVersion opcionais no histórico são aditivos. [Contrato](../../arquitetura/contratos-v1.md), [SQL/HTTP](food-names-consumption-verification.json).
- **495 mensagens por idioma /197 testes Flutter/analyze0issues**; Go test/vet aprovados e SQL isolado executado, não apenas skips da suíte comum.18regressões de consumo +6de leitura tardia desde173. [Fechamento048 por critério](localization-048-fechamento.json).
- APK **debug0.3.8+21 instalado**, assinatura/hash conferidos: ad52a9ff2471f45bf3c2a985e3ba6e46ba80ebee0ed10036fb2949b8ced425a4. AVDTrainForge_Benchmark/emulator-5554/Android15,1080x2340/fonte1.0. Leitura do consumo real noAPK20em inglês e21em pt-BR, nome original/fallback/1g preservados; voltou aHoje/pt-BR/dark sem formulário.
- API127.0.0.1:8082, PostgreSQL127.0.0.1:15432 e emulador ativos. tools/avaliar_android.py status confere o estado. Watcher antigo foi encerrado somente pelo seu stopfile antes de editarGo; o helper iniciou o novo após testes. APItemporária18082 continua encerrada. Não precisa de hospedagem para avaliar no emulador.
- Contagens anônimas depois do ensaio: **1conta /1consumo /6369versões alimentares /0nomes revisados**. Sem novoGoogle ou escrita/exclusão de consumo. A sessão existente foi restaurada; pode renovar seus tokens normalmente, sem afirmar que tabelas de sessão são bitwise iguais durante uso real.
- Graphify **102Dart /3472nós /4015arestas**, ASTincremental+HTML, sem LLM/semântica/clusterização. Backup exato da rodada em.local/graphify-backup-20261027-consumption-names, automáticos dentro deautomatic/automatic-final. CincoARB não interpretados. Go/SQL constam deSwagger/mapas, sem alegar indexação semântica.

## O que048 entregou e seus limites

Biblioteca, detalhe público, seleção/formulário, histórico e detalhe/correção usam nomes revisados por identidade/versão/idioma. Histórico usa uma projeçãofoodDisplay fora decalculation; snapshot/cálculo/nutrientes, corpos/chaves e replay de mutação permanecem inalterados. Conta/filtro/idioma/revisão vinculam cursor;409reinicia sem mesclar páginas. Uma consulta SQL de nomes por página, alvos deduplicados e pool com uma conexão validado; transação privada acaba antes da projeção editorial. Registro alheio/excluído404, revogado401, no-store.

Nomes particulares conservam a declaração e idioma conhecido/und. Retirada do último nome revisado não revive uma versão antiga. Detalhe relê ao abrir/retomar/corrigir; gerações descartam respostas antigas. Formulário usa apresentação separada sem enviar tradução na escrita. Fixtures pertencem somente a testes isolados e não foram publicadas na base entregue.

Padrão de idioma é seguir o aparelho; escolha manual opcional em configurações. Timeout de2s não grava padrão. NoAPK20, códigos fixos do processo atual confirmaram timeout de aparência/idioma; resposta tardia antes era descartada. APK21 aplica resposta tardia somente se nenhuma nova leitura/tentativa/escolha/dispose a invalidou. Restauração pt-BR/dark foi observada mesmo com os dois códigos de timeout. Falha real mantém recuperação explícita; nenhum log serializa exceção/valor/conta/token.

Cobertura real de nomes continua **0/6369 por idioma**, revisão0: Ciqual2025/3484 e CoFID2021/2885. [Ferramenta editorial](../../conteudo/nomes-alimentares-revisados.md) existe, mas hash/confirmação não provam revisão/licença/identidade. Publicação real requer verificar e reter pacote humano/direitos. Não criar traduções para retirar fallback.

Android dos quatro idiomas já teve seleção/restauração nativa noAPK19; novo detalhe revisado tem testes320px/texto2x nos quatro, e leituras reaisEN/PT-BR no20/21. Esses checks do agente não são usabilidade com todos os públicos, release ou iOS nativo. Futuras jornadas devem usar a mesma estrutura conforme forem implementadas;048 não as implementa.

## Decisões e limites preservados

Ambos os caminhos de treino; configuração completa em etapas curtas/revisão antes da busca; trocas compatíveis e dias/horários; retomar ou parcial sem conclusão automática. Cuidador pratica para si nas pausas, sem paciente obrigatório. Preservar idosos, cuidadores, casa, praça/parque e academia, Android/iOS.

Foto propõe candidatos editáveis e usuário informa quantidade. Visões por refeição/alimento; histórico visual/análise/dicas revisadas juntos naV1, sem diagnosticar deficiência com diário incompleto. Fotos recuperáveis pela conta com cache; excluir refeição exclui foto. Offline026 exige fila durável privada, conflito/idempotência e exclusão sem recriar dados; memória de envio incerto não fecha a história.042/044/045/046/047 ainda têm seus critérios.

Exclusão própria pelo titular; master049 ainda todo, com identidade estável verificada, concessão/revogação e auditoria. Não inferir master por e-mail/GitHub nem provisionar por suposição. Todos os cenários permanecem na matriz; participantes de usabilidade não confirmados. Emulador primeiro e Android físico orientado depois.

73metadados de movimento,439ativos excluídos e zero programas/doses/instruções/mídias/prática aprovados. Não inventar conteúdo, nutrientes, adequação clínica ou fatos físicos.011/012/013 têm GoogleAndroiddebug real histórico validado; não repetir esse consentimento. HTTPS/release/iOS conservam gates próprios.

## Operação, documentação e Git

Commit/push de incrementos validados autorizados; sem hospedagem/deploy/recurso cloud, compra/assinatura/integração paga ou contato externo. [Opções deAPI](../../conteudo/opcoes-apis-exercicios.md): gratuitas primeiro; pagamento único eventual atéR$400 depende de decisão específica. Não iniciar nova pesquisa ampla. TF/Inter e Grafite/lima aprovados; Android sem esticar. CotaStarterFigma esgotada, sem nova chamada/contorno/compra; abrir noPC não remove limite.

Credenciais, assinatura, logs, XML/capturas privadas e backups fora do Git. Acesso à janela já autorizado, mas captura/controleWindows foi inconsistente; ensaio atual usou UIAutomator/Androidscreencap. Exigir snapshot novo/dispositivo explícito e nunca usar XML anterior após falha do dump. Não automatizar Google nem atualizar com rascunho aberto por inferência.

Atualizar backlogJSON, contratos/diagramas afetados, diário/handoff. python tools/gerar_documentacao.py --write --check e testes documentais. Swagger vem dos tipos/comentáriosGo; não editar derivados à mão. Não executar analyze/gen-l10n/test junto ao prepare. SDKs já instalados. Auditoria24/10 permanece baseline histórico;197 testes não significam cobertura total, Sonar/CI/carga concluídos ou certificação de segurança.
