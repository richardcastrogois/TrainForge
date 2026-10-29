# Handoff vigente — TrainForge

Atualizado em **29/10/2026**. Repositório: **C:/dev/TrainForge/trainforge**.

## Próxima ação

O autor pediu implementar M0–M4 da primeira extração do catálogo, corrigir as verificações, fazer commits e push. Os marcos do catálogo estão concluídos no recorte local. A remediação do histórico Git foi aplicada e verificada no remoto. Próxima história funcional: V1-015 pelas dependências, mantendo explícita a ausência de conteúdo aprovado para prática; continuar os trabalhos independentes do backlog. Não repetir limpeza, migração ou testes do app sem mudança pertinente.

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

A limpeza autorizada foi aplicada somente à main, com lease exato contra o commit de origem. A prova final comparou **95 commits, 88 IDs alterados, sete blobs e 11 ocorrências de query em seis arquivos**; árvore atual, autores, mensagens e datas preservados. Backup local por bundle com SHA256 conferido, demais refs remotos inalterados e Git deste notebook alinhado. [Recibo da aplicação](git-history-remediation-preview.json).

No commit limpo **6894858**, os oito workflows passaram: segredos, Flutter, Go/documentação, vulnerabilidades Go, SQL, restore, imagem e catálogo. [Segredos40888675534](https://github.com/richardcastrogois/TrainForge/actions/runs/40888675534): **85 ocorrências não secretas verificadas, zero bloqueadoras**, autorredação aprovada, sem valores brutos publicados. [Documentação40888675485](https://github.com/richardcastrogois/TrainForge/actions/runs/40888675485). As falhas anteriores permanecem como evidência histórica; os e-mails já enviados não são apagados.

**Não repetir o force-push.** A autorização específica foi usada nesta operação; novas reescritas exigem nova decisão. Outros clones precisam ser reconciliados ou refeitos antes de enviar código, para não reintroduzir o histórico antigo. Objetos inacessíveis/cache do GitHub e cópias externas não foram certificados como apagados. Validade dos tokens externos não foi testada; nenhum replay, rotação ou contato ocorreu. Achados desconhecidos continuam bloqueadores; não imprimir valores nem silenciar URLs por inferência.

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
