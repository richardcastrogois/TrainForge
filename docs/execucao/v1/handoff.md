# Handoff vigente —22/10/2026

Repositório: `C:/dev/TrainForge/trainforge`. Leia AGENTS, escopo, decisões do piloto e backlog antes de alterar. Pedido vigente: continuar etapas em sequência até limite; commits locais autorizados, sem push/deploy/compra/contato externo.

- [Etapa01 encerrada](etapa-01-fechamento.md): triagem512completa;73metadados de consulta,439excluídos;0ensino/mídia/prática. Não confundir com aprovação clínica. Ns não estão reabertas.
- [Etapa02 / M1 concluída](etapa-02-fechamento.md):007–010+006; Go1.27.3portátil, Swagger por comentários com recarga comprovada, PostgreSQL17.5local separado, três migrations, importação73+reimportação0, restore real e invariantes. API/runtime/testes parados após smoke; cluster pode permanecer durante a continuação: verificar `python tools/db_local.py status`.
- **Próxima história011 em execução**, depois012/013/014 conforme dependências. Validar Google assinatura/issuer/audience/exp sem login simulado; cliente atual ainda usa `/mobile-auth`/`token`, não assumir compatibilidade com `/api/v1`/`accessToken`.
- CI local preparada; publicação/execução remota da003 pendentes. Nenhuma migração de dados legados, exposição externa, integração Flutter ou APK entregue.

## Ambiente e cuidados

Go em `.tools/go/bin/go.exe`; caches em `.tools`, dados/segredos/dump em `.local`, todos ignorados. Helpers `tools/go-api.ps1`, `tools/db_local.py`, `tools/dev_api.py`. Documentação de leitura em `docs/arquitetura/README.md`, sem painel/servidor.

PostgreSQL nativo existente foi reutilizado por binário, sem tocar serviço/bancos antigos. Cluster V1 localhost15432, DB `trainforge_v1_dev`, schema `trainforge_v1`; API localhost8082. Papéis runtime/migrator separados.17.5 está defasado; atualizar patch antes de staging. Docker falhou em `dockerInference`; não resetar volumes para isso.

Conteúdo bruto/preparado permanece local.73registros só permitem consulta metadata; a próxima fatia não pode inventar programa, instrução, dose, apoio ou nutriente. Prática exige material elegível e não se fecha por navegação de catálogo. iOS permanece requisito do produto, primeiro teste Android.

Atualizar backlog/evidências/diário e regenerar documentação ao fechar cada história. Testes reais em `api-connected-verification.json`, `database-verification.json`, `catalog-import-verification.json`. Falta teste Google real, cliente/ownership, e toda a rota posterior atéAPK.
