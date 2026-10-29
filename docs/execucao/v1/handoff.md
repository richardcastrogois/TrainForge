# Handoff vigente — TrainForge

Atualizado em **29/10/2026**. Repositório: **C:/dev/TrainForge/trainforge**.

## Próxima ação

O autor pediu implementar M0–M4 da primeira extração do catálogo, corrigir as verificações, fazer commits e push. Os marcos do catálogo estão concluídos no recorte local. A próxima ação é fechar a remediação do histórico Git; não repetir a migração ou os testes do app sem mudança pertinente.

Ler também AGENTS.md, backlog.json, plano-macro.md e etapa-02-fechamento.md. Conferir o Git e os arquivos reais. A solicitação atual do autor prevalece sobre relatos históricos no diário.

## Catálogo separado: M0–M4 concluídos localmente

[Critérios e evidências](catalog-rollout-verification.json), [plano e diagrama](../../arquitetura/reavaliacao-microservicos-2026-10-29.md).

- API **0.9.0 / 34 operações**, catálogo **0.2.0 / schema 2**, banco `trainforge_catalog_dev` e reader/migrator próprios. O núcleo permanece **schema 13 / 30 tabelas**.
- M2/M3 passaram em **40874689251/c68b085**: publicação imutável, CAS/replay, consumidor047, retirada, espelho antigo, rollback de projeção, rede e restore antigo com reaplicação de retirada. Duas contas apenas sintéticas em CI; fixtures removidas.
- Rollback verificado passou no CI **40876296947/ba46c3c**. O modo `local-verified` exige autoridade e digest atuais antes/depois da resposta. Não existe fallback automático para conteúdo antigo.
- Ativação local teve checkpoint completo restaurado numa base temporária sem CONNECT do runtime, com comparação das30tabelas. O alvo foi removido; backup e credenciais ficam somente em `.local` com ACL Windows restrita.
- Bootstrap preservou o núcleo; cinco rotas e ETag304 corresponderam ao catálogo separado. Há **73 referências e zero programas**. Detalhe de programa só teve teste negativo, pois não existe programa real liberado.
- APK **0.4.3+25** preservado e não reinstalado. Sessão existente restaurada, sem novo consentimento Google. Android mostrou biblioteca73/0 e um detalhe real com autoria, licença e limites de consulta.
- Rollback local, retorno remoto, parada do catálogo com503 na rota/prontidão e recuperação200 passaram. As30tabelas permaneceram iguais nesses ensaios. Nenhum registro privado foi criado ou excluído pelo agente.
- Primeira comparação agregando linhas completas falhou antes do checkpoint/troca. A versão final calcula SHA256 por linha dentro do PostgreSQL e devolve apenas64hex por tabela; checkpoint e comparações passaram depois.

**Ambiente final:** API8082, catálogo18083, PostgreSQL15432 e emulador ativos; modo `remote`. Última navegação observada foi o detalhe público. Reobservar a tela antes de agir.

Para conferir sem repetir a ativação:

```powershell
python tools/catalog_local.py verify
python tools/avaliar_android.py status
```

`catalog-release` publica na autoridade com pacote/digest exatos. `catalog-transition mirror` avança somente a projeção editorial no núcleo. O importador legado recusa escrita após registro da autoridade. Não mover fontes alimentares, dividir refeição/itens ou usar credencial privada no catálogo.

A captura Windows falhou com `window crop is outside captured monitor`; a evidência veio de semântica Android atual e screenshot nativo. Capturas/XML privados ficam fora do Git. Não reutilizar dump antigo se uma nova captura falhar. Não automatizar Google.

## Verificações e histórico Git

As últimas provas de Go/docs, SQL, imagem, restore e scanner Go passaram para ba46c3c. O gate histórico de segredos continua pendente. Os90candidatos foram reconciliados: **82 falsos positivos e oito ocorrências de URLs históricas com tokens**. O novo CI40882610220/6d62673 confirmou93candidatos:85não secretas (incluindo3hashes novos comprovados automaticamente) e apenas8bloqueadoras históricas. A prévia local do histórico passou:94commits revistos,87reidentificados,6arquivos de pesquisa, árvore atual igual e0bloqueadores; [proposta/evidência](git-history-remediation-preview.json). Backupbundle local e remoto da prévia desabilitado. O autor autorizou expressamente a limpeza da main com force-with-lease em29/10. Autorização limitada aos seis arquivos revisados, com backup e árvore atual preservada; nenhuma outra branch ou contato externo. Atualizar a prévia antes de aplicar. Antes de qualquer aplicação autorizada, atualizar a prévia para o HEAD corrente e conferir novamente árvore/refs e lease. Os três adicionais eram hashes de arquivos e foram comparados aos conteúdos dos commits originais.

Corrigir falsos positivos somente por contexto exato ou SHA256 comprovado do arquivo, mantendo achados desconhecidos bloqueados. Não imprimir valores, reproduzir tokens, contatar fornecedores ou silenciar URLs não comprovadas. Preparar backup e prévia isolada antes de pedir decisão sobre reescrita remota. O push comum não autoriza outras reescritas por inferência; esta limpeza específica foi autorizada pelo autor.

Auditoria028, observabilidade029 e pipeline032 não estão encerrados. Sonar, carga, release e demais critérios mantêm os gates do backlog; não prometer milhões de usuários por contagem de testes.

## Estado funcional preservado

- V1-047 concluída funcionalmente: criação humana, edição autorizada para14:00 e recuperação da revisão2, sem terceira versão. [Fechamento047](training-configuration-047-fechamento.json). Clareza de fuso/hora permanece pendente; não repetir essa confirmação.
- V1-048 concluída no recorte documentado. Cobertura editorial de traduções reais permanece **0/6369** por idioma; usar o nome original quando não houver tradução revisada. [Ferramenta editorial](../../conteudo/nomes-alimentares-revisados.md).
- V1-045 continua doing: SQL/HTTP, Flutter, seleção particular e edição de metadados integrados. O autor criou/reabriu uma refeição, mas confirmou que era teste de navegação. Não classificá-la como consumo real nem excluí-la por inferência. [Estado045](refeicoes-045.md), [cliente](meal-grouping-edit-client-verification.json), [ativação](meal-grouping-local-activation.json).
- Foram preservados a conta, o consumo humano real anterior, a refeição/consumo de teste e duas revisões047. Preparar rascunho não confirma consumo; correção de metadados não envia itens/quantidades.
- Próxima história funcional pelas dependências: **V1-015**. Não há programas, instruções, doses ou mídias autorizados para prática. A configuração não cria elegibilidade. Continuar trabalho independente quando o bloqueio editorial impedir aceite.
- Foto042, composição044, ciclo completo045, histórico/análise/dicas046, offline026 e administração master049 ainda têm seus próprios critérios. M0–M4 fecham apenas esta extração inicial; alimentação, treinos, fotos e identidade ainda precisam de etapas de separação.

## Requisitos e limites do produto

[Decisões Q1–Q6](decisoes-piloto.md) e [trilha por área](trilha-implementacao.md). Dois caminhos de treino; configuração completa em etapas curtas/revisão; trocas compatíveis e agenda; retomar ou encerrar parcial. Cuidador pratica para si nas pausas. Preservar idosos, cuidadores, casa, praça/parque e academia; Android e iOS.

Foto propõe alimentos editáveis; usuário informa quantidades. Visões por refeição/alimento e histórico visual/análise/dicas revisadas juntos naV1. Fotos recuperáveis pela conta com cache; excluir refeição exclui foto. Offline requer fila durável, conflitos/idempotência e exclusão sem recriar dados. Sessão trocada/revogada não acessa pendências de outro titular. Master depende de identidade verificada e auditoria, sem promoção por e-mail/GitHub.

Sem treinos, doses, instruções, mídia, nutrientes, traduções ou histórico inventados. Fixtures pertencem somente aos testes descartáveis. Sem compra, integração paga, pesquisa ampla, hospedagem, deploy ou contato externo. [Opções de API](../../conteudo/opcoes-apis-exercicios.md): gratuitas primeiro; compra única eventual de atéR$400 exige decisão específica.

## Frontend, documentos e Git

TF/Inter, dark Grafite e lima e Android sem esticar aprovados. Idioma segue o aparelho por padrão, com escolha manual opcional; pt-BR/pt-PT/en/es. Não alegar execução iOS no Windows ou aderência comprovada ao iOS27.

[Fonte visual única](frontend-fidelidade-figma.md). Figma Starter atingiu a cota registrada; não repetir chamadas para testar saldo, contornar limites ou comprar plano. Abrir no notebook não elimina a cota.

Graphify permanece **116Dart /4254nós /4998arestas**, sem alteração Dart nesta rodada. Consultado para CatalogRepository; Go/SQL ficam nos mapas e Swagger. Não reextrair todos os documentos. Swagger vem de comentários/DTOsGo; não editar derivados à mão. Não rodar analyze/gen-l10n/test junto a `avaliar_android.py prepare`.

Para Go/Swagger sem iniciar a API, usar `environment(include_api_env=False)`; o default do watcher lê api.env. SDKs estão instalados; não reinstalar por hábito.

Atualizar backlogJSON, recibos, diário, contratos/diagramas afetados e gerar documentos. `done` exige evidência. Commits/push autorizados com staging explícito e revisão de dados sensíveis. Git usa `git -c safe.directory=C:/dev/TrainForge/trainforge ...`; não mudar confiança global. Histórico detalhado está no diário e recibos, não em instruções repetidas para reexecutar trabalho concluído.
