# TrainForge — instruções para agentes

Estado vigente: **27/10/2026**. Repositório correto: **C:/dev/TrainForge/trainforge**; o diretório pai não é o repositório. A solicitação atual do usuário prevalece sobre snapshots históricos.

## Retomada e próxima ação

1. Antes de alterar, ler AGENTS.md, docs/execucao/v1/handoff.md, backlog.json, plano-macro.md e etapa-02-fechamento.md. Ler também a trilha por área e a história pelas dependências. Conferir Git e arquivos reais.
2. **Continuar V1-048, doing.** Não iniciar outra história antes de fechar seus critérios. A próxima fatia é projetar nomes revisados no histórico e detalhe de consumo: hoje eles leem calculation.food.nameOriginal. Separar a projeção de leitura do snapshot/cálculo imutável, manter idioma/revisão coerentes, evitar N+1, preservar cadastro particular, titular e corpo/chave das mutações. Não criar traduções para testar em dados reais.
3. UI disponível tem 495 mensagens por idioma em pt-BR/pt-PT/en/es; 173 testes Flutter aprovados e análise sem problemas. Biblioteca, detalhe público e seleção/formulário integram nomes revisados por identidade/versão/idioma; histórico ainda tem a lacuna acima. [Recibo atual](docs/execucao/v1/frontend-localization-native-verification.json). completionEvidence de048 permanece vazia.
4. O usuário autorizou implementar/corrigir pelas dependências e fazer commit/push de incrementos validados. Não repetir perguntas genéricas ou pedir a mesma permissão. Intervenção humana só quando material; continuar o trabalho independente e registrar pendências sem conclusão indevida.

## Estado comprovado

- Go **0.6.1 / 25 operações** em services/api; PostgreSQL local **schema 11 / 26 tabelas**. Migrations9–11 foram aplicadas com autorização explícita, checkpoint somente de schema e comparação dos dados. [Ativação](docs/execucao/v1/food-names-local-activation.json). Nenhuma migration nova na correção de preferências.
- **1 conta, 1 consumo humano real e 6.369 versões alimentares** preservados. Nenhum usuário ou consumo foi criado/excluído pelo agente no ensaio de idiomas. A sessão existente foi restaurada; isso não é novo consentimento Google. [Alimentação real](docs/execucao/v1/nutrition-real-android-verification.json).
- Etapas01/02 concluídas no seu recorte: 73 metadados de movimento para consulta, 439 ativos excluídos, zero programas, doses, instruções ou mídias liberados para prática. Triagem documental não é homologação clínica.
- V1-011/012/013: Google Android debug real, sessão e privacidade validados anteriormente; OAuth debug/release conferidos. [Fechamento](docs/execucao/v1/auth-local-fechamento.md). Não repetir Google, importação ou restore sem mudança pertinente. HTTPS/distribuição release e iOS têm gates próprios.
- APK **debug 0.3.6+19 instalado no TrainForge_Benchmark**, hash e assinatura debug conferidos. Ensaio nativo Android15 dos quatro idiomas e restauração de preferência; ficou na raiz Hoje em pt-BR/dark. API local8082 e banco15432 ativos para avaliação; API temporária18082 anterior encerrada. Usar tools/avaliar_android.py status antes de agir. Não atualizar app com rascunho ou envio incerto aberto por inferência.
- Preferências: falha de leitura agora relê sem gravar o padrão; falha de gravação repete a escolha solicitada. Diagnóstico debug usa somente códigos fixos, sem exceção/valor/conta/token. Uma observação de fallback pela janela não teve causa nativa confirmada; não afirmar que ela foi diagnosticada. Capturas finais e semântica nativa vieram do Android, pois o controle da janela foi inconsistente. Acesso à janela foi explicitamente liberado pelo usuário; não automatizar Google.
- Ferramenta editorial local entregue: preflight sem banco, publicação/retirada imutáveis com confirmação do pacote/revisor, e cobertura read-only. CLI real validada somente em banco descartável removido. [Operação e limites](docs/conteudo/nomes-alimentares-revisados.md). **Zero nomes revisados publicados**, revisão0 nos quatro idiomas: 3.484 Ciqual2025 e 2.885 CoFID2021. Hash/booleano/confirmação não autenticam revisor nem provam licença. Publicação real requer verificação humana e retenção dos documentos; sem ela, manter o original.
- V1-021 encerrada no recorte de composição/configuração e uma fatia de estado; não encerrou o frontend inteiro. [Evidência](docs/execucao/v1/frontend-state-verification.json). Configuração047, composição044, foto042, refeições045, histórico/análise/dicas046 e offline026 seguem pelas dependências. Resposta incerta em memória não é fila offline durável.
- [Auditoria24/10](docs/execucao/v1/auditoria-produto-2026-10-24.md) é baseline histórico: Flutter101 testes/78,46% das linhas instrumentadas; Go71 resultados/10 integrações SQL puladas/40,73% das instruções. Não transferir esses percentuais à suíte atual. Sonar, CIFlutter/SQL automático e capacidade de carga ainda não completos. Não prometer milhões de usuários simultâneos sem medição.

## Decisões de produto e conteúdo

- [Q1–Q6](docs/execucao/v1/decisoes-piloto.md): dois caminhos de treino; configuração completa em etapas curtas com revisão final antes da busca; trocas compatíveis e dias/horários; retomar ou encerrar como parcial, sem conclusão automática.
- Cuidador treina para si nas pausas do próprio trabalho. Pessoa assistida é possibilidade futura, sem vínculo/paciente obrigatório. Preservar idosos, cuidadores, casa, praça/parque e academia; Android e iOS permanecem no produto.
- Foto propõe candidatos editáveis/adicionáveis/removíveis; depois o usuário informa quantidade. Não estimar peso ou inventar nutrientes. Agrupar por refeição e oferecer visão por alimento. Histórico visual, análise nutricional e dicas revisadas juntos na primeira versão, sem diagnóstico baseado em diário incompleto.
- Recuperar fotos pela conta com cache no celular; excluir refeição inteira remove a foto. Offline exige fila durável privada, conflitos/idempotência e exclusão sem recriar registros. Nada disso está implementado só por ser requisito.
- Excluir dados próprios é do titular. Exceção master do autor é V1-049 todo: identidade verificada e auditoria, sem papel inferido por e-mail ou GitHub. Todos os cenários da matriz permanecem no aceite; participantes de usabilidade não confirmados. Emulador primeiro e Android físico orientado depois.
- Sem treino, instrução, dose, mídia, nutriente, tradução alimentar, métrica ou histórico inventados. Fixtures só em testes isolados; sem seed na base entregue, Gemini/manual-generator ou exemplos Figma como dados reais. Nomes pessoais e documentos de origem conservam o original.
- PesquisaN01–N46 consolidada, sem nova pesquisa ampla nesta retomada. Fontes humanas exigem autoria, evidência, versão e direitos por movimento, instrução, mídia e programa; composição não herda eficácia. [Opções de API](docs/conteudo/opcoes-apis-exercicios.md): gratuitas primeiro; compra única eventual de até R$400 depende de decisão específica. Sem compra, assinatura, integração paga ou contato externo por inferência.

## Figma e operação

- TF/Inter, dark Grafite e lima e Android sem esticar aprovados. iOS mantém o padrão Flutter; não alegar execução nativa no Windows nem aderência exata ao iOS27 por widget test.
- Arquivo Figma bX6YjBBLIJgoo2MtiFLntl, página0:1/v0.5. [Inventário](docs/execucao/v1/frontend-figma-inventory.json): 401 quadros não equivalem a401 funcionalidades. Limite Starter já registrado; não repetir design calls, contornar cota ou comprar plano. Abrir Figma no PC não remove esse limite.
- [Fonte visual única](docs/execucao/v1/frontend-fidelidade-figma.md). Relatos redundantes anteriores foram consolidados; não recriá-los. Preservar recibos, contratos, licenças e exclusões.
- Sem hospedagem/deploy/recurso cloud agora; não perguntar isso como condição para testar no emulador. Fastify/Prisma e Next.js legados são referências, sem prova de migração funcional.
- Incrementos pequenos, seguros, separados e testados desde já; monólito modular não autoriza acoplamento ou segurança adiada. Sem rewrite completo, instalação nova ou dois escritores/migradores por conveniência. Sem reset/volume apagado; backup só validado após restore.
- Credenciais, assinaturas, logs, dumps/capturas privadas, caches e backups ficam fora do Git. Não publicar dados pessoais em recibos. Para automação nativa, exigir semântica/snapshot novo e dispositivo explícito; não usar XML antigo quando o dump falhar durante o boot.

## Documentação, grafo e Git

- Atualizar backlogJSON, contratos/diagramas afetados, diário e handoff. done exige completionEvidence; backlogMarkdown é gerado. Registrar lacunas e continuar somente trabalho independente.
- python tools/gerar_documentacao.py --write --check; python -m unittest discover -s tools -p test_documentacao.py. Não repetir testes de app/SQL/login numa mudança só documental.
- [Swagger](docs/arquitetura/swagger-go.md): comentários/DTOsGo são fonte; não editar artefatos gerados à mão ou regenerar sem alteração de contrato.
- [Graphify](docs/graphify.md): consultar primeiro; atualizar AST quando Dart mudar, sem extração semântica de todos os docs. Estado atual: 101Dart / 3.420 nós / 3.949 arestas, HTML exportado, sem LLM/clusterização. Go/SQL ficam nos mapas/Swagger.
- Não rodar analyze/gen-l10n/test em paralelo a tools/avaliar_android.py prepare: o guard de fingerprint já detectou regeneração concorrente. SDKs instalados; não reinstalar por hábito.
- Git: git -c safe.directory=C:/dev/TrainForge/trainforge ...; não mudar confiança global. Commit e push autorizados, com escopo e dados sensíveis revisados. Sem mensagens a terceiros. Limpeza somente de alvos exatos verificados, preservando conteúdo útil e referências. [Arquivo histórico](docs/arquivo/README.md) não é instrução vigente.
